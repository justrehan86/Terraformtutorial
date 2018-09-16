provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

#S3_access

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3_access"
  role = "${aws_iam_role.s3_access_role.name}"
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = "${aws_iam_role.s3_access_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
  {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
  },
      "Effect": "Allow",
      "Sid": ""
      }
    ]
}
EOF
}

resource "aws_vpc" "wp_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    name = "wp_vpc"
  }
}

resource "aws_internet_gateway" "wp_internet_gateway" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  tags {
    name = "wp_igw"
  }
}

resource "aws_route_table" "wp_public_rt" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wp_internet_gateway.id}"
  }

  tags {
    name = "wp_public_rt"
  }
}

resource "aws_default_route_table" "wp_private_rt" {
  default_route_table_id = "${aws_vpc.wp_vpc.default_route_table_id}"

  tags {
    name = "wp_private_rt"
  }
}

#subnet

resource "aws_subnet" "public1_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    name = "public1_subnet"
  }
}

resource "aws_subnet" "public2_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    name = " public2_subnet"
  }
}

resource "aws_subnet" "private1_Subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    name = " private1_subnet"
  }
}

resource "aws_subnet" "private2_Subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["private2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    name = " private2_subnet"
  }
}

resource "aws_subnet" "rds1_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    name = " rds1_subnet"
  }
}

resource "aws_subnet" "rds2_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    name = " rds2_subnet"
  }
}

resource "aws_subnet" "rds3_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds3"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[2]}"

  tags {
    name = " rds3_subnet"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = ["${aws_subnet.rds1_subnet.id}", "${aws_subnet.rds2_subnet.id}", "${aws_subnet.rds3_subnet.id}"]

  tags {
    name = "rds_sng"
  }
}

#subnet association

resource "aws_route_table_association" "public1_subnet_assoc" {
  subnet_id      = "${aws_subnet.public1_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

resource "aws_route_table_association" "public2_subnet_assoc" {
  subnet_id      = "${aws_subnet.public2_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

#----Security Group------

resource "aws_security_group" "wp_dev_sg" {

 	name = " wp_dev_sg"
	description = " Dev Instance Security Group"
	vpc_id= "${aws_vpc.wp_vpc.id}"
      
        #SSH
	ingress {
	to_port = 22
	from_port = 22
	protocol = "tcp"
	cidr_blocks =[ "${var.localip}"]
}

         #Http 
         ingress {
         
	to_port = 80  
	from_port = 80
	protocol = "tcp"
	cidr_blocks = [ "${var.localip}"]
}

	egress {

	to_port = 0
	from_port = 0
	protocol = -1
	cidr_blocks = ["0.0.0.0/0"]
}

}
resource "aws_security_group" "wp_public_sg" {
        name = " wp_public_sg"
        description =  " load balancer  Security Group"    
        vpc_id= "${aws_vpc.wp_vpc.id}"
   

         #Http 
         ingress {
        to_port = 80
        from_port = 80
        protocol = "tcp"
        cidr_blocks= ["${var.localip}"]

}

  egress {
        to_port = 0
        from_port = 0
        protocol = -1
        cidr_blocks =[ "0.0.0.0/0"]

}
}


resource "aws_security_group" "wp_private_sg" {
        name = " wp_private_sg"
        description = " Private inctance Security Group"    
        vpc_id= "${aws_vpc.wp_vpc.id}"
        
         #Http 
         ingress {
        to_port = 80
        from_port = 80
        protocol = "tcp"
	cidr_blocks = ["${var.vpc_cidr}"]
}
  egress {
        to_port = 0
        from_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]

}
}

resource "aws_security_group" "wp_rds_sg" {
        name = " wp_rds_sg"
        description = " rds Security Group"
        vpc_id= "${aws_vpc.wp_vpc.id}"
         #SQL
         ingress {
        to_port = 3306
        from_port = 3306
        protocol = "tcp"
        security_groups = ["${aws_security_group.wp_dev_sg.id}", "${aws_security_group.wp_public_sg.id}", "${aws_security_group.wp_private_sg.id}"] 
  	}
}




































