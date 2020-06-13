 provider "aws" {
  region = "ap-south-1"
  profile = "harsh"
}


resource "aws_security_group" "mysecurity" {
  name        = "wizardw"
  description = "Allow TLS inbound traffic"
  vpc_id=   "vpc-91f1ecf9"
  
  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 22
      to_port    = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wizard"
  }
}

resource "aws_instance" "myinstance" {
  ami           = "ami-043b70fe18093fc08"
  instance_type = "t2.micro"
  key_name      =  "new"
  security_groups = ["wizardw"]
	
  tags = {
    Name = "my"
  }
  
}

resource "null_resource" "nulllocal1"{
provisioner "local-exec"{
command = "echo $(aws_instance.myinstance.public_ip)  >> public.txt"
}
}


resource "aws_ebs_volume" "pendrive" {
  availability_zone = aws_instance.myinstance.availability_zone
  size              = 1

  tags = {
    Name = "pendrive"
  }
}

resource "aws_volume_attachment" "attach" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.pendrive.id}"
  instance_id = "${aws_instance.myinstance.id}"
  force_detach=  true
}

resource null_resource "nullremote1"{
depends_on=[
 aws_volume_attachment.attach
]
connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Rishabh garg/Downloads/new.pem")
    host     = aws_instance.myinstance.public_ip
  }

provisioner "remote-exec" {
inline=[
"sudo yum install httpd -y",
"sudo yum install git -y",
"sudo mkfs.ext4 /dev/xvdh",
"sudo mount /dev/xvdh /var/www/html",
"sudo rm -rf /var/www/html",
"sudo git clone https://github.com/Rishabh2000-bot/task.git  /var/www/html",
"sudo systemctl restart httpd"
]
}
}
resource "aws_s3_bucket" "me_bucket" {
  bucket = "rupe000"
  acl    = "private"

  tags = {
    Name = "bucket"
  }
}

locals {
  s3_origin_id = "myS3Origin"
}


resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "bucket-origin-identity"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.me_bucket.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"
    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }
    

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"


  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["US", "CA"]
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output  "my_cloudfront_domain" {
	value =aws_cloudfront_distribution.s3_distribution.domain_name
}

/*
resource "null_resource" "nulllocal2"{
depends_on=[
null_resource.nullremote1
]
provisioner "local-exec"{
command = "chrome  $(aws_instance.myinstance.public_ip)"
}
}*/

