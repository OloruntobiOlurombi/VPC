# Step 1
terraform{
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.4.0"
        }
    }
}
# Step 2
provider "aws" {
    region = "us-east-1"
    profile = "default"
  
  }



# Step 3
# Main VPC
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/18"
    # instance_type = default
    enable_dns_hostnames = "true"
    tags = {
        Name = "Main VPC"
    }
}


#STEP 4
# Public Subnet with Default Route to Internet Gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/Subnet

resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = "true"
    

    tags = {
        Name = "Public Subnet"
    }
}

# STEP 5 
# Private Subnet with Default Route to NAT Gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnets

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = "false"

    tags = {
        Name = "Private Subnet"
    }
}

# STEP 6
# Main Internal Gateway for VPC
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "Main IGW"
    }
}

# STEP 7
# Creating a Elastic ip
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
resource "aws_eip" "nat_eip" {
  vpc      = true
}



#Step 8
# Main NAT Gateway for VPC
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.private.id

    tags = {
        Name = "Main NAT Gateway"
    }
}

#Step 9
# Route Table for Public Subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
        # Name = "Public Route Table"
    }
}
 
#Step 10
# Association between Public Subnet and Public Route Table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

#Step 11
# Route Table for Private Subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat.id
    }

    tags = {
        Name = "Private Route Table"
    }
}

#Step 12
# Association between Private Subnet and Private Route Table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table   

resource "aws_route_table_association" "private" {
    subnet_id = aws_subnet.private.id
    route_table_id = aws_route_table.private.id
}

#Step 13
# Create an S3 bucket 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "ec2s3" {
    bucket = "ec2bucketqdb"
    force_destroy = false
}

# STEP 14
# Make the S3 bucket private
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
resource "aws_s3_bucket_public_access_block" "esa" {
    bucket = aws_s3_bucket.ec2s3.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
}

# STEP 15
# Create the policy that will allow access to the S3 bucket
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
resource "aws_iam_policy" "bucket_policy" {
    name = "ec2bucketqdbpolicy"
    path = "/"
    description = "Allow"
    policy = "${file("allowaccess.json")}"
}

# STEP 16
# Create an IAM role 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "qdb_ec2_role" {
    name = "qdb_ec2_role"
    assume_role_policy = "${file("ec2-assume-policy.json")}"
}

# STEP 17
# Policy Attachment (Attach the policy to the role)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "bucket_policy_attach" {
    role = aws_iam_role.qdb_ec2_role.name
    policy_arn = aws_iam_policy.bucket_policy.arn
}

# STEP 18
# Create Security Group for Ec2 instance 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "Webserver_Apache_SG" {
    name = "Webserver_Apache_SG"
    vpc_id = aws_vpc.main.id
    ingress {
        description = "Allow_http"
        from_port = 80
        protocol = "tcp"
        to_port = 80
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow_icmp"
        from_port = 8
        protocol = "icmp"
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow_ssh"
        from_port = 22
        protocol = "tcp"
        to_port = 22
        cidr_blocks = ["0.0.0.0/0"]
    }



    egress {
        from_port = 0
        protocol = "-1"
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "allow_http_icmp_ssh"
    }
}


# STEP 19
# Create aws_iam_instance_profile
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
resource "aws_iam_instance_profile" "qdb_ec2_profile" {
    name = "qdb_ec2_profile"
    role = aws_iam_role.qdb_ec2_role.name
}

# STEP 20
# Create an application load balancer security group 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "alb_SG" {
    name = "alb_SG"
    description = "Load Balancer Security Group"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # EFS -checking for stability
    # ingress {
        # description = "EFS mount target"
        # from_port   = 2049
        # to_port     = 2049
        # protocol    = "tcp"
        # cidr_blocks = ["0.0.0.0/0"]
  # }

    # Allow all outbound traffic
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "Load Balancer Security Group"
    }
}    

# STEP 21
# Create a new application load balancer in public subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
resource "aws_alb" "alb" {
    name = "alb"
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_SG.id]
    subnets = [aws_subnet.public.id, aws_subnet.private.id]
    tags = {
        Name = "Load Balancer"
    }
}  

# STEP 22
# Create a new target group for the application load balancer 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group

resource "aws_alb_target_group" "alb-tar-group" {
    name = "alb-tar-group"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.main.id
    stickiness {
        type = "lb_cookie"
    }
# Alter the destination of the health check to be the login page
health_check {
    path = "/"
    port = 80
    protocol = "HTTP"
    healthy_threshold = 3
    unhealthy_threshold = 2
    interval = 90
    timeout = 20
    matcher = 200
}
depends_on = [aws_alb.alb]
}


# STEP 23

# Creating a listener 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
resource "aws_alb_listener" "http" {
    load_balancer_arn = aws_alb.alb.arn
    port = "80"
    protocol = "HTTP"
    default_action {
        target_group_arn = aws_alb_target_group.alb-tar-group.arn
        type = "forward"
    }
}


# STEP 24

# Creating a target group attachment for the target group
 # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment
  resource "aws_alb_target_group_attachment" "one" {
  target_group_arn = aws_alb_target_group.alb-tar-group.arn
  target_id = "${aws_instance.web.id}"
    port = 80
}

# STEP 25

# Creating a placement_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/placement_group
# resource "aws_placement_group" "alb_placement_group" {
#    name = "alb_placement_group"
#    strategy = "cluster"
# }

# STEP 26

# Create a new ALB Target Group attachment
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.alb_scaling_group.id
  alb_target_group_arn   = aws_alb_target_group.alb-tar-group.arn
}

# STEP 27

# Creating an auto scaling group 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
resource "aws_autoscaling_group" "alb_scaling_group" {
   
    name = "${aws_launch_configuration.web_instances.name}-asg"
    max_size = 3
    min_size = 1
    desired_capacity = 2
    health_check_grace_period = 100
    health_check_type = "EC2"
    target_group_arns = [
        aws_alb_target_group.alb-tar-group.arn
    ]

launch_configuration = aws_launch_configuration.web_instances.name

    enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"
    force_delete = true
    # placement_group = aws_placement_group.alb_placement_group.id
    vpc_zone_identifier = [
        aws_subnet.private.id,
        aws_subnet.public.id
        ]

# Required to redeploy without an outage

  lifecycle {
    create_before_destroy = true
  }
    

    tag { 
        key = "Name" 
        value = "alb_scaling_group" 
        propagate_at_launch = true
        }
}  

# STEP 28

# Write a life cycle policy to scale up 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy
resource "aws_autoscaling_policy" "alb-scale-up" {
    name = "alb-scale-up"
    scaling_adjustment = 1
    adjustment_type = "PercentChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.alb_scaling_group.name}"
}

# STEP 29

# Write a life cycle policy to scale down
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy
resource "aws_autoscaling_policy" "alb-scale-down" {
    name = "alb-scale-down"
    scaling_adjustment = -1
    adjustment_type = "PercentChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.alb_scaling_group.name}"
}

# STEP 30

# Write a trigger using a CloudWatch alarm  
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm
resource "aws_cloudwatch_metric_alarm" "alb-cpu-high-up" {
    alarm_name = "alb-cpu-high-up"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "80"
    alarm_description = "This metric monitors EC2 CPU Utilization for high utilization on agent hosts"
    alarm_actions =[
        "${aws_autoscaling_policy.alb-scale-up.arn}"
    ]
    dimensions ={
        AutoScalingGroupName= "${aws_autoscaling_group.alb_scaling_group.name}"
   
    }
}

# STEP 31

# Write a trigger using a CloudWatch alarm
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm
resource "aws_cloudwatch_metric_alarm" "alb-cpu-down" {
    alarm_name = "alb-cpu-down"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "60"
    alarm_description = "This metric monitors ec2 CPU Utilization for low utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.alb-scale-down.arn}"
    ]
    }


# STEP 32

# Create Elastic Block Storage for our second EC2 instance
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume

resource "aws_ebs_volume" "ebs" {
  availability_zone = "us-east-1b"
  size              = 10

  tags = {
    Name = "HelloWorld"
  }
}

# STEP 33
# Create a Volume ttachment for our second EC2 instance
resource "aws_volume_attachment" "ebs_att" {
device_name = "/dev/sdh"
volume_id = aws_ebs_volume.ebs.id
instance_id = aws_instance.web.id
} 

