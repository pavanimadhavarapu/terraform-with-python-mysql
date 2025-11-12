# terraform-with-python-mysql
Goal: Create an EC2 (ap-south-1, t3.micro) via Terraform, install Docker, run a MySQL container, then run a Python script to create DB/table + insert dummy data and print it in a table format


step1 : create aws user accesskey and secretkey then open vs code configure with accesskey and secretkey.
step2 : take main.tf  --> code main.tf
 provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_instance" "mysql_instance" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install docker python3 -y
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              docker run -d --name mysql -e MYSQL_ROOT_PASSWORD=root -p 3306:3306 mysql:latest
              EOF

  tags = {
    Name = "Terraform-MySQL"
  }
}


step3: security.tf -->code security.tf
	resource "aws_security_group" "mysql_sg" {
  name        = "allow_ssh_mysql"
  description = "Allow SSH and MySQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL access"
    from_port   = 3306
    to_port     = 3306
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
    Name = "allow_ssh_mysql"
  }
}

step4 : variables.tf -->code variables.tf

	variable "region" {
  default = "ap-south-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami" {
  default = "ami-0305d3d91b9f22e84"
}

variable "key_name" {
  description = "Your AWS key pair name"
  type        = string
}

step5 : terraform.tfvars
  region        = "ap-south-1"
instance_type = "t3.micro"
key_name      = "newpro11"


step6 : outputs.tf
output "instance_public_ip" {
  value = aws_instance.mysql_instance.public_ip
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnet_id" {
  value = data.aws_subnets.default.ids[0]
}


output "security_group_id" {
  value = aws_security_group.mysql_sg.id
}

step7 : python_mysql.py
import pymysql
import time
from prettytable import PrettyTable

# Wait for MySQL container to be ready
print("Waiting for MySQL to be ready...")
time.sleep(10)

# Connect to MySQL (update host if different)
connection = pymysql.connect(
    host="43.204.22.247",  # use '127.0.0.1' if Python is inside EC2 with MySQL container
    user="root",
    password="root",
    port=3306
)

cursor = connection.cursor()

# Create database and table
cursor.execute("CREATE DATABASE IF NOT EXISTS company;")
cursor.execute("USE company;")
cursor.execute("""
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    role VARCHAR(50),
    salary INT
);
""")

# Insert dummy data
data = [
    ("Pavan", "DevOps Engineer", 60000),
    ("Vini", "Python Developer", 55000),
    ("Eswari", "Tester", 50000)
]
cursor.executemany("INSERT INTO employees (name, role, salary) VALUES (%s, %s, %s)", data)
connection.commit()

# Fetch data
cursor.execute("SELECT * FROM employees;")
rows = cursor.fetchall()

# Display data as table
table = PrettyTable()
table.field_names = ["ID", "Name", "Role", "Salary"]

for row in rows:
    table.add_row(row)

print("\nEmployee Table Data:\n----------------------")
print(table)

# Close connection
connection.close()

step8 : in that folder run these commands 
terraqform init
terraform apply -auto-approve

step9 : ssh into ec2 from your localmachine
-->from the folder with your pem (keep your pem into .ssh folder)
-->ssh -i<your pem key path> ec2-user@<instance_publicip>

step10 : on the ec2-instance setup to run python script and chesk docker (docker ps)
--> python3 --version 
--> pip3 --version (if it is not installed CMD->sudo dnf install python3-pip3 -y)
-->install prittytable (CMD-> pip3 install pymysql prittytable)
--> ls
--> python3 python_mysql.py
expected python output

step11 :verify inside mysql container
--> docker exec -it contid bash  (--bash#)
-->MySQL -u root -p
-->password:root (MySQL)
-->SHOW DATABASES;
-->USE company;
-->SHOW TABLES;
-->SELECT * from employyes;
(you should see company and employees table with three rows).


 Troubleshooting(common issues and fixes):
   
--> Terraform error: Invalid data source aws_subnet_ids → Use data "aws_subnets" ... (we used aws_subnets). 
--> InvalidKeyPair.NotFound → key name must be without .pem (key_name = "new-project").
--> ModuleNotFoundError: No module named 'pymysql' → install: python3 -m pip install pymysql
    pip3: command not found → install sudo dnf install python3-pip -y (Amazon Linux 2023) or sudo yum install python3 -y.
--> use host ="127.0.0.1" when you python runs on the same ec2

