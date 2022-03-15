variable "region" {
  default = "ap-south-1"
}

variable "type" {

  default = "t2.micro"
}

variable "ami" {

  default = "ami-03fa4afc89e4a8a09"
}


variable "app" {
    
  default = "swiggy"
}

variable "env" {
    
  default = "test"
}

variable "asg_count" {

  default = 3
}

variable "clb_subnets" {

  default = ["subnet-04d68644d191b8405" , "subnet-083d0f04dc286d3ad"]

}

variable "vpc_id" {
  default = "vpc-0312dce270fa375e5"

}
