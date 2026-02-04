# IAM Role for EC2 Instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    var.tags,
    {
       Name =  "${var.environment}-${var.project_name}-ec2-role"
    }
  )
}

# Attach AWS Managed Policy for SSM (Session Manager)
resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach AWS managed policy for Cloudwatch
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom policy for Secrets Manager access
resource "aws_iam_policy" "secrets_manager" {
  name        = "${var.environment}-${var.project_name}-secrets-manager-policy"
  description = "Allow EC2 instances to read secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = var.secrets_arns
      },
    ]
  })
  tags = var.tags
}

# Attach custom Secrets Manager Policy
resource "aws_iam_policy_attachment" "secrets_manager" {
  name       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_manager.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name

   tags = merge(
    var.tags,
    {
       Name =  "${var.environment}-${var.project_name}-ec2-instance-profile"
    }
  )
}