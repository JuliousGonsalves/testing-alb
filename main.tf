resource "aws_key_pair"  "key" {
    
  key_name = "${var.app}"
  public_key = file("../authentication/terraform.pub")
  tags = {
    Name = var.app
    project = var.app
    environment = var.env
  }
}

resource "aws_security_group" "freedom" {
    
  name        = "${var.app}-freedom"
  description = "allow 22 traffic"
  
  ingress {
    description      = ""
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }
    
  ingress {
    description      = ""
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }
    
  
    
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.app}-freedom"
    project = var.app
     environment = var.env
  }
}

resource "aws_launch_configuration" "lc" {

  name_prefix       = "${var.app}"
  image_id          = var.ami
  instance_type     = var.type
  security_groups   = [ aws_security_group.freedom.id ]
  key_name          =  aws_key_pair.key.id
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "asg" {
  
  name_prefix             = "${var.app}"
  launch_configuration    = aws_launch_configuration.lc.id
  health_check_type       = "EC2"
  min_size                = var.asg_count
  max_size                = var.asg_count
  desired_capacity        = var.asg_count
  vpc_zone_identifier     = var.clb_subnets 
  target_group_arns       = [aws_lb_target_group.tg.arn]
  tag {
    key = "Name"
    propagate_at_launch = true
    value = "${var.app}"
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_lb_target_group" "tg" {


  name_prefix                   = "${var.app}"
  port                          = 80
  protocol                      = "HTTP"
  load_balancing_algorithm_type = "round_robin"
  deregistration_delay          = 5
  vpc_id                        = "${var.vpc_id}"
  stickiness {
    enabled = false
    type    = "lb_cookie"
    cookie_duration = 60
  }


health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = 200

  }

  lifecycle {
    create_before_destroy = true
  }

}



resource "aws_lb" "alb" {
  name_prefix                   = "${var.app}"
  internal                      = false
  load_balancer_type            = "application"
  security_groups   = [ aws_security_group.freedom.id ]
  subnets                       = var.clb_subnets
  enable_deletion_protection    = false
  depends_on                    = [ aws_lb_target_group.tg ]
  tags = {
     Name = "${var.app}"
   }
}


resource "aws_lb_listener" "listner" {

  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = " "
      status_code  = "500"
   }
  }

  depends_on = [  aws_lb.alb ]
}

resource "aws_lb_listener_rule" "main" {

  listener_arn = aws_lb_listener.listner.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    host_header {
      values = ["app.juliousgonsalves94.tk"]
    }
  }
}
