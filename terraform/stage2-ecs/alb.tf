resource "aws_lb" "app_alb" {
  name               = "${local.prefix}-ecs-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.terraform_remote_state.stage1.outputs.public_subnet_ids
}

resource "aws_security_group" "alb" {
  name   = "alb-sg"
  vpc_id = data.terraform_remote_state.stage1.outputs.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_lb_target_group" "ecs_tg" {
  name        = "${local.prefix}-ecs-app-tg"
  port        = 8080 # must match containerPort
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.stage1.outputs.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}
