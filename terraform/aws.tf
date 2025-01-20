# aws.tf - Where we tame the mighty Amazon (Web Services)

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "multi-cloud-vpc"
    Cloud = "AWS"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "multi-cloud-subnet"
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = "t2.micro"

  tags = {
    Name = "Multi-Cloud Web Server"
    Cloud = "AWS"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello from AWS!" > index.html
              nohup python -m SimpleHTTPServer 80 &
              EOF

  vpc_security_group_ids = [aws_security_group.allow_http.id]
  subnet_id              = aws_subnet.main.id

  # In case of fire, break glass
  lifecycle {
    create_before_destroy = true
  }
}

# Because everyone loves a good load balancer
resource "aws_lb" "web" {
  name               = "multi-cloud-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = [aws_subnet.main.id]

  tags = {
    Environment = "production"
    Cloud       = "AWS"
  }
}

# Auto Scaling Group - Because manually scaling is so 2010
resource "aws_autoscaling_group" "web" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  target_group_arns    = [aws_lb_target_group.web.arn]
  vpc_zone_identifier  = [aws_subnet.main.id]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Multi-Cloud ASG"
    propagate_at_launch = true
  }
}

# Launch Template - The blueprint for our instances
resource "aws_launch_template" "web" {
  name_prefix   = "multi-cloud-"
  image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.allow_http.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name  = "Multi-Cloud Web Server"
      Cloud = "AWS"
    }
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Hello from AWS Auto Scaling!" > index.html
              nohup python -m SimpleHTTPServer 80 &
              EOF
  )
}

# Target Group - Where our load balancer sends traffic
resource "aws_lb_target_group" "web" {
  name     = "multi-cloud-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# Because we're not made of money
resource "aws_spot_instance_request" "worker" {
  count         = 2
  ami           = "ami-0c55b159cbfafe1f0"
  spot_price    = "0.03"
  instance_type = "t2.micro"

  tags = {
    Name = "Multi-Cloud Spot Worker"
    Cloud = "AWS"
  }

  vpc_security_group_ids = [aws_security_group.allow_http.id]
  subnet_id              = aws_subnet.main.id
}

