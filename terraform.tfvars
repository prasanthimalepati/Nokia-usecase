configuration = [
  {
    "application_name" : "sles 12",
    "ami" : "ami-0c79914d840ad4560",
    "no_of_instances" : "2",
    "instance_type" : "t2.micro",
    "subnet_id" : "subnet-f12df9bd",
    "vpc_security_group_ids" : ["sg-66ed5009"]
  },
  {
    "application_name" : "sles 15",
    "ami" : "ami-01b40a4bb3e3bd6a7",
    "instance_type" : "t2.micro",
    "no_of_instances" : "1"
    "subnet_id" : "subnet-f12df9bd"
    "vpc_security_group_ids" : ["sg-66ed5009"]
  },
  {
    "application_name" : "windows",
    "ami" : "ami-0129199984784a860",
    "instance_type" : "t3.micro",
    "no_of_instances" : "1"
    "subnet_id" : "subnet-f12df9bd"
    "vpc_security_group_ids" : ["sg-66ed5009"]
  }
  
]