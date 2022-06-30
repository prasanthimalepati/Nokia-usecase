
provider "aws" {
  region = "us-east-2"
}

#####Fetching data block##########

data "aws_vpc" "my-test-vpc" {
  default = true
}

data "aws_availability_zones" "all" {}

data "aws_security_groups" "my-sg" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.my-test-vpc.id]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.my-test-vpc.id]
  }
  
  tags = {
    name = "Private"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.my-test-vpc.id]
  }
  
  tags = {
    name = "Public"
  }
}


locals {
  serverconfig = [
    for srv in var.configuration : [
      for i in range(1, srv.no_of_instances+1) : {
        instance_name = "${srv.application_name}-${i}"
        instance_type = srv.instance_type
        subnet_id   = srv.subnet_id
        ami = srv.ami
        security_groups = srv.vpc_security_group_ids
      }
    ]
  ]
}


// We need to Flatten it before using it
locals {
  instances = flatten(local.serverconfig)
}

#Creating EC2 instances

resource "aws_instance" "web" {
  for_each = {for server in local.instances: server.instance_name =>  server}
  
  ami           = each.value.ami
  instance_type = each.value.instance_type
  vpc_security_group_ids = each.value.security_groups
  subnet_id = each.value.subnet_id
  tags = {
    Name = "${each.value.instance_name}"
  }
}

output "instances" {
  value       = "${aws_instance.web}"
  description = "All Machine details"
}

########Network Interfaces###############

##Create Internal ENI

resource "aws_network_interface" "my-test-internal-eni" {
  for_each          = {for server in local.instances: server.instance_name =>  server}
  #subnet_id         = var.privatesubnet
  subnet_id         = "data.aws_subnets.private.ids"

  attachment {
    instance     = aws_instance.web[each.key].id
    device_index = 1
  }
}

#Create External ENI

resource "aws_network_interface" "my-test-external-eni" {
  for_each          = {for server in local.instances: server.instance_name =>  server}
  subnet_id         = "data.aws_subnets.public.ids"

  attachment {
    instance     = aws_instance.web[each.key].id
    device_index = 0
  }
}


##############EBS########

resource "aws_ebs_volume" "my-test-ebs" {
  for_each          = {for server in local.instances: server.instance_name =>  server}
  #availability_zone = "eu-east-1a"
  availability_zone = "data.aws_availability_zones.all.zone_ids"
  size              = 200

  tags = {
    Name = "my-ebs-${each.value.instance_name}"
  }
}

resource "aws_volume_attachment" "my-test-ebs-attachment" {
  for_each          = {for server in local.instances: server.instance_name =>  server}
  device_name = "/dev/sda1"
  volume_id   = "${aws_ebs_volume.my-test-ebs[each.key].id}"
  instance_id = "${aws_instance.web[each.key].id}"
}


##################High Availability###############

####Security groups for ASG#########
resource "aws_security_group" "asg-sg" {
  name   = "my-test-sg"
  vpc_id = data.aws_vpc.my-test-vpc.id

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress Security Port 22
resource "aws_security_group_rule" "http_inbound_access" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]

  lifecycle {
    create_before_destroy = true
  }
}

# All OutBound Access
resource "aws_security_group_rule" "all_outbound_access" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.asg-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_launch_configuration" "my-test-lc" {
  for_each = {for i,v in local.instances: i=>v}
  #for_each        = flatten(var.configuration.ami)
  #name            = "${each.value.instance_name}"
  image_id        = each.value.ami
  instance_type   = each.value.instance_type
  security_groups = [aws_security_group.asg-sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "my-test-asg" {
  for_each = {for i,v in local.instances: i=>v}
  #for_each        = flatten(var.configuration.ami)
  #name                 = "${each.value.instance_name}"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.my-test-lc[each.key].name
  vpc_zone_identifier  = ["data.aws_subnets.public"]

  tag {
    key                 = "Name"
    value               = "${each.value.instance_name}-asg"
    propagate_at_launch = true
  }
}
