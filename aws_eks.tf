

resource "aws_iam_role" "tf-eksclusterrole" {
  name = "tf-eks-cluster-role"
  lifecycle {
   ignore_changes = [permissions_boundary]
  }

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "tf-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.tf-eksclusterrole.name
}


resource "aws_iam_role" "tf-eksnodegrouprole" {
  name = "tf-eks-node-group-role"
  lifecycle {
   ignore_changes = [permissions_boundary]
  }
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "tf-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.tf-eksnodegrouprole.name
}

resource "aws_iam_role_policy_attachment" "tf-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.tf-eksnodegrouprole.name
}

resource "aws_iam_role_policy_attachment" "tf-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.tf-eksnodegrouprole.name
}




resource "aws_eks_cluster" "k8s" {
	name 		= "eks-k8s-1"
	role_arn	= aws_iam_role.tf-eksclusterrole.arn
	version		= "1.21"
	vpc_config {
		subnet_ids 		= [aws_subnet.sn2.id, aws_subnet.sn3.id, aws_subnet.sn4.id]
		endpoint_public_access 	= true
	}
	depends_on = [
		aws_iam_role_policy_attachment.tf-AmazonEKSClusterPolicy,
	]
}

resource "aws_eks_node_group" "k8s-nodegrp" {
	cluster_name	= aws_eks_cluster.k8s.name
	node_group_name	= "k8s-nodegrp"
	node_role_arn 	= aws_iam_role.tf-eksnodegrouprole.arn
	subnet_ids	= [aws_subnet.sn2.id, aws_subnet.sn3.id, aws_subnet.sn4.id]
	scaling_config {
		desired_size 	= 1
		max_size 	= 1
		min_size 	= 1
	}
	
	update_config {
		max_unavailable = 1 
	}
	depends_on = [
		aws_iam_role_policy_attachment.tf-AmazonEKSWorkerNodePolicy
	]
}
