# Data source for latest Ubuntu 
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Launch Template
resource "aws_launch_template" "backend" {
  name_prefix = "${var.environment}-${var.project_name}-backend"
  image_id = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  key_name = var.key_name
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  vpc_security_group_ids = [var.security_group_id]

   user_data = base64encode(templatefile("${path.root}/../../scripts/frontend_user_data.sh", {
    docker_image         = var.docker_image
    dockerhub_username   = var.docker_username
    dockerhub_password   = var.docker_password
    backend_internal_url = var.backend_internal_url
    environment          = var.environment
    project              = var.project_name
  }))

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
      volume_type = "gp3"
      delete_on_termination = true
      encrypted = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
    var.tags,
    {
       Name =  "${var.environment}-${var.project_name}-backend"
    }
  )
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
    var.tags,
    {
       Name =  "${var.environment}-${var.project_name}-backend-volume"
    }
  )
}
}

# Auto Scaling Group
resource "aws_autoscaling_group" "backend" {
  name                      = "${var.environment}-${var.project_name}-backend-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnets_ids
  target_group_arns = [var.target_group_arn]

  launch_template {
    id = aws_launch_template.backend.id
    version = "$Latest"
  }

  enabled_metrics = [ 
      "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
   ]

  tag {
    key                 = "Name"
    value               = "${var.environment}-${var.project_name}-backend"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
       key                 = tag.key
    value               = tag.value
    propagate_at_launch = true
    }
  }
  lifecycle {
    create_before_destroy = true
  }

}

# Target Tracking Scaling Policy - CPU
resource "aws_autoscaling_policy" "backendend_cpu" {
  name                   = "${var.environment}-${var.project_name}-backend-cpu-tracking"
  policy_type =  "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.backend.name

    target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}

# CloudWatch Alarm -High CPU
resource "aws_cloudwatch_metric_alarm" "backendend_high_cpu" {
  alarm_name                = "${var.environment}-${var.project_name}-backend-high-cpu"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 80
  alarm_description         = "This metric monitors frontend EC2 cpu utilization"
  alarm_actions = var.alarm_actions

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.backend.name
  }

  tags = var.tags
}

# CloudWatch Alarm - Unhealthy Hosts
resource "aws_cloudwatch_metric_alarm" "backendend_unhealthy" {
  alarm_name                = "${var.environment}-${var.project_name}-backend-unhealthy-hosts"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  metric_name               = "UnhealtyHostCount"
  namespace                 = "AWS/ApplicationELB"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 0
  alarm_description         = "Alert when frontend instances are unhealthy"
  alarm_actions = var.alarm_actions

  dimensions = {
    TargetGroup = split(":", var.target_group_arn)[5]
  }

  tags = var.tags
}