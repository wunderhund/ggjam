resource "aws_db_instance" "ghost" {
  identifier                = "ghostdb"
  allocated_storage         = 20
  storage_type              = "gp2"
  engine                    = "mariadb"
  engine_version            = "10.3"
  instance_class            = "db.t2.micro"
  name                      = "ghostdb"
  username                  = var.ghostdb_user
  password                  = var.ghostdb_pass
  db_subnet_group_name      = aws_db_subnet_group.ghost-db.name
  vpc_security_group_ids    = [aws_security_group.ghost-db.id]
  final_snapshot_identifier = "mariadb-final"

  tags = merge(
    {
      Name = "ggjam-mariadb"
    },
    var.base_tags
  )
}

resource "aws_db_subnet_group" "ghost-db" {
  name       = "ghost"
  subnet_ids = ["${aws_subnet.private-a.id}", "${aws_subnet.private-b.id}"]

  tags = merge(
    {
      Name = "ghost"
    },
    var.base_tags
  )
}

resource "aws_security_group" "ghost-db" {
  name        = "ghost-db"
  description = "Allow Ghost to reach MariaDB"
  vpc_id      = aws_vpc.ggjam.id

  ingress {
    description     = "Access to MariaDB"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ghost.id, aws_security_group.jumpbox.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "ghost-db"
    },
    var.base_tags
  )
}
