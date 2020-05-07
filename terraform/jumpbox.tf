resource "aws_security_group" "jumpbox" {
  name        = "jumpbox"
  description = "SSH access to jumpbox"
  vpc_id      = aws_vpc.ggjam.id

  ingress {
    description = "SSH Access to Jumpbox"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.jumpbox_access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "jumpbox"
    },
    var.base_tags
  )
}

resource "aws_key_pair" "ghost-jumpbox" {
  key_name   = "ghost-jumpbox"
  public_key = var.jumpbox_key
}

data "aws_ami" "jumpbox" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-????????"]
  }
}

resource "aws_instance" "jumpbox" {
  ami                         = data.aws_ami.jumpbox.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ghost-jumpbox.key_name
  vpc_security_group_ids      = [aws_security_group.jumpbox.id]
  subnet_id                   = aws_subnet.public-a.id
  associate_public_ip_address = true
  user_data                   = templatefile("templates/jumpbox.sh.tpl", {})
  tags = merge(
    {
      Name = "jumpbox"
    },
    var.base_tags
  )
}

output "jumpbox-pulic-ip" {
  value = aws_instance.jumpbox.public_ip
}