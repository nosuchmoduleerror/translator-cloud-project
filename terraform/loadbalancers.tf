# main.tf

# Create a VPC
resource "aws_vpc" "backend_vpc_west" {
  cidr_block = "11.0.0.0/16"

  tags = {
    Name = "backend_vpc_west"
  }
}

# Create subnets for the Network Load Balancer
resource "aws_subnet" "public_backend_vpc_subnet1" {
  vpc_id                  = aws_vpc.backend_vpc_west.id
  cidr_block              = "11.0.1.0/24"
  availability_zone       = "us-west-1a"
}

resource "aws_subnet" "public_backend_vpc_subnet2" {
  vpc_id                  = aws_vpc.backend_vpc_west.id
  cidr_block              = "11.0.2.0/24"
  availability_zone       = "us-west-1b"
}

resource "aws_subnet" "private_backend_vpc_subnet1" {
  vpc_id                  = aws_vpc.backend_vpc_west.id
  cidr_block              = "11.0.3.0/24"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = false
}

resource "aws_subnet" "private_backend_vpc_subnet2" {
  vpc_id                  = aws_vpc.backend_vpc_west.id
  cidr_block              = "11.0.4.0/24"
  availability_zone       = "us-west-1b"
  map_public_ip_on_launch = false
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.backend_vpc_west.id
}

# Create a route table for the public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.backend_vpc_west.id
}

# Create a route table association for the public subnet
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_backend_vpc_subnet1.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create a default route in the public route table that points to the Internet Gateway
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

# Create the Network Load Balancer
resource "aws_lb" "network_load_balancer" {
  name               = "network-load-balancer"
  load_balancer_type = "network"
  subnets            = [aws_subnet.private_backend_vpc_subnet1.id, aws_subnet.private_backend_vpc_subnet2.id]
}

resource "aws_lb_target_group" "alb_target_group" {
  name     = "alb-target-group"
  port     = 8081
  protocol = "TCP"
  vpc_id   = aws_vpc.backend_vpc_west.id
  target_type = "alb"
}

resource "aws_lb_target_group" "translator_ecs_target_group" {
  name     = "translator-ecs-target-group"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.backend_vpc_west.id
  target_type = "ip"
}

# Register target instances with the Network Load Balancer target group (replace with your own target instance IDs)
resource "aws_lb_target_group_attachment" "alb_target_attachment" {
  port             = 8081
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_lb.application_load_balancer.arn
}

#resource "aws_lb_target_group_attachment" "translator_ecs_target_attachment" {
#  port             = 8081
#  target_group_arn = aws_lb_target_group.translator_ecs_target_group.arn
#  target_id        = aws_instance.isdns.id
#}

# Create the Application Load Balancer
resource "aws_lb" "application_load_balancer" {
  name               = "application-loadbalancer"
  load_balancer_type = "application"
  subnets            = [aws_subnet.private_backend_vpc_subnet1.id, aws_subnet.private_backend_vpc_subnet2.id]
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 8081
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.translator_ecs_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.network_load_balancer.arn
  port              = 8081
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    type             = "forward"
  }
}

resource "aws_security_group" "translator_ecs_security_group" {
  name        = "translator-ecs-security-group"
  description = "Security group for ECS instances"

  vpc_id = aws_vpc.backend_vpc_west.id

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
