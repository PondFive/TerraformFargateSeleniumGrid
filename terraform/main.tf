# get info re VPC Cidr for security group rules
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# DNS : cloud map private namespace for the hub
resource "aws_service_discovery_private_dns_namespace" "selenium" {
  name        = var.app_name
  description = "private DNS for selenium grid - ${var.app_name}"
  vpc         = var.vpc_id
}

# DNS : cloud map record creation for the hub
resource "aws_service_discovery_service" "hub" {
  name = "hub"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.selenium.id

    dns_records {
      ttl  = 5
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

## security groups
resource "aws_security_group" "elb" {
  name        = "${var.app_name}-elb-sg"
  description = "Allow traffic to the elb in-front of selenium hub"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "elb port"
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "hub" {
  name        = "${var.app_name}-hub-sg"
  description = "Allow access to Hub ports"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 4444
    to_port     = 4444
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Selenium Hub port"
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nodes" {
  name        = "${var.app_name}-nodes-sg"
  description = "Allow access to node ports"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 5555
    to_port     = 5555
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Selenium Node port"
  }
   egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# IAM role 

## ECS fargate cluster
resource "aws_ecs_cluster" "selenium_grid" {
  name = var.app_name
  capacity_providers = ["FARGATE"]
  setting {
      name  = "containerInsights"
      value = "enabled"
  }
}

## load balancer and listener
resource "aws_lb" "selenium_hub" {
  name               = var.app_name
  internal           = true
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.elb.id ] 
  subnets            = var.subnet_ids_elb
  idle_timeout       = var.idle_timeout_elb  

  tags = {
    ROLE = var.app_name 
  }
}

resource "aws_lb_listener" "selenium_hub" {
  load_balancer_arn = aws_lb.selenium_hub.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.selenium-hub.arn
  }
}

## The definition for Selenium hub container
resource "aws_lb_target_group" "selenium-hub" {
  name        = "${var.app_name}-hub-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    protocol            = "HTTP"
    path                = "/status"
    port                = "traffic-port"
    timeout             = 59
    interval            = 60
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200"
  }
}

resource "aws_ecs_task_definition" "seleniumhub" {
  family                = "${var.app_name}-hub"
  network_mode          = "awsvpc"
  container_definitions = templatefile("hub.task.json",
    {
      aws_region = var.aws_region
      image      = var.hub_image
      app_name   = var.app_name    
    }
  )

  requires_compatibilities = ["FARGATE"]
  cpu                      = var.hub_cpu
  memory                   = var.hub_mem
  execution_role_arn       = aws_iam_role.ecs_task_role.arn

}

## Service for selenium hub container

resource "aws_ecs_service" "seleniumhub" {
  name          = "${var.app_name}-hub"
  cluster       = aws_ecs_cluster.selenium_grid.id
  desired_count = 1

  tags = {
    Selenium-Role = "${var.app_name}-Hub"
    ROLE          = "${var.app_name}"
  }
  propagate_tags = "SERVICE"

  network_configuration {
    subnets          = var.subnet_ids_hub
    security_groups  = [aws_security_group.hub.id]
    assign_public_ip = false
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight = 1
  }

  scheduling_strategy = "REPLICA"

  service_registries {
    registry_arn   = aws_service_discovery_service.hub.arn
    container_name = "hub"
  }

  task_definition = aws_ecs_task_definition.seleniumhub.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.selenium-hub.arn
    container_name   = "${var.app_name}-hub"
    container_port   = 4444
  }

}

## Definition for Firefox container
resource "aws_ecs_task_definition" "firefox" {
  family                = "${var.app_name}-firefox"
  network_mode          = "awsvpc"
  container_definitions = templatefile("firefox.task.json",
    {
      aws_region    = var.aws_region
      image         = var.firefox_image
      app_name      = var.app_name
    }
  )

  requires_compatibilities = ["FARGATE"]
  cpu                      = var.firefox_cpu
  memory                   = var.firefox_mem
  execution_role_arn       = aws_iam_role.ecs_task_role.arn

}

## Service for firefox  container

resource "aws_ecs_service" "firefox" {
  name          = "${var.app_name}-firefox"
  cluster       = aws_ecs_cluster.selenium_grid.id
  desired_count = var.firefox_min_tasks

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Selenium-Role = "${var.app_name}-Firefox"
    ROLE          = "${var.app_name}"
  }
  propagate_tags = "SERVICE"

  network_configuration {
    subnets          = var.subnet_ids_nodes
    security_groups  = [ aws_security_group.nodes.id ]
    assign_public_ip = false

  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  platform_version    = "LATEST"
  scheduling_strategy = "REPLICA"


  task_definition = aws_ecs_task_definition.firefox.arn

}

## Definition for Chrome container
resource "aws_ecs_task_definition" "chrome" {
  family                = "${var.app_name}-chrome"
  network_mode          = "awsvpc"
  container_definitions = templatefile("chrome.task.json",
    {
      aws_region    = var.aws_region
      image         = var.chrome_image
      app_name      = var.app_name
    }
  )

  requires_compatibilities = ["FARGATE"]
  cpu                      = var.chrome_cpu
  memory                   = var.chrome_mem
  execution_role_arn       = aws_iam_role.ecs_task_role.arn

}

## Service for chrome container

resource "aws_ecs_service" "chrome" {
  name          = "${var.app_name}-chrome"
  cluster       = aws_ecs_cluster.selenium_grid.id
  desired_count = var.chrome_min_tasks

  tags = {
    Selenium-Role = "${var.app_name}-Chrome"
    ROLE          = "${var.app_name}"
  }
  propagate_tags = "SERVICE"

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    subnets          = var.subnet_ids_nodes
    security_groups  = [aws_security_group.nodes.id]
    assign_public_ip = false

  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  platform_version    = "LATEST"
  scheduling_strategy = "REPLICA"


  task_definition = aws_ecs_task_definition.chrome.arn

}
