//////////////////////////////////////////////////////////////////
///////////////////////////// ALB ////////////////////////////////
//////////////////////////////////////////////////////////////////

resource "aws_lb" "lb" {
  name               = "lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "test-lb"
    enabled = true
  }

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
}

//////////////////////////////////////////////////////////////////
///////////////////////////// ECS ////////////////////////////////
//////////////////////////////////////////////////////////////////

resource "aws_ecs_cluster" "ecs-cluster" {
  name = "white-hart"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.mongo.arn
  desired_count   = 3
  depends_on      = [aws_iam_role_policy.foo]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "mc"
    container_port   = 8080
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  }
}

# service_connect_configuration {
#     enabled   = true
#     namespace = aws_service_discovery_http_namespace.example.arn

#     log_configuration {
#       log_driver = "awslogs"
#       options = {
#         "awslogs-group"         = aws_cloudwatch_log_group.example.name
#         "awslogs-region"        = data.aws_region.current.region
#         "awslogs-stream-prefix" = "service-connect"
#       }
#     }

#     access_log_configuration {
#       format                   = "TEXT"
#       include_query_parameters = "ENABLED"
#     }

#     service {
#       port_name      = "http"
#       discovery_name = "example"

#       client_alias {
#         dns_name = "example"
#         port     = 8080
#       }
#     }
#   }

# resource "aws_cloudwatch_log_group" "example" {
#   name = "/ecs/example/service-connect"
# }

resource "aws_ecs_task_definition" "task_definition" {
  family = "task_definition"
  container_definitions = jsonencode([
    {
      name      = "task_definition"
      image     = "nginx:latest"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 8080
        }
      ]
    }
  ])

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  }
}