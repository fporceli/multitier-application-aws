# Multitier v-profile application in AWS
#### EN-US
Hello! In this project, I will be presenting a way to deploy a multi-tier application within AWS. We will use the following services within the platform.
- EC2 instances
- S3 storage
- IAM
- Route 53 (private DNS server).

NOTE: Although most services are free, be careful when implementing this application for academic purposes.

The application that we will implement is a web application called vprofile, which is the combination of a stack of services, namely: MariaDB (Mysql) database, RabbitMQ, Memcached and Apache Tomcat.

Its operation is relatively simple, but to better illustrate it, below is the flowchart of how the application will be built.

#### PT-BR
Olá! Nesse projeto eu estarei apresentando uma maneira de implantar uma aplicação multi tier dentro da AWS. Usaremos os seguintes serviços dentro da plataforma.
- Instâncias EC2
- Armazenamento S3
- IAM
- Rota 53 (servidor DNS privado).
OBS: Apesar da maioria dos serviços serem de nível gratuito, se atente no momento de realizar essa aplicação para meios acadêmicos.

A aplicação que iremos implementar é uma aplicação web chamada de vprofile, ela é a junção de uma pilha de serviços, sendo elas: Banco de dados MariaDB (Mysql), RabbitMQ, Memcached e o Apache Tomcat.

Seu funcionamento é relativamente simples, mas para ficar melhor ilustrado. Segue abaixo o fluxograma de como será construído a aplicação.

[![Fluxograma](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/Diagrama+em+branco.png "Fluxograma")](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/Diagrama+em+branco.png "Fluxograma")

###Dependencies
- Git
- JDK 17.0.13
- Apache Maven 3.9.9
- AWS Cli

#Security Groups
With the visualization from the image, the construction of security groups becomes an easier task. However, it is always important to pay attention to the ports.
###Elastic Load Balancer Security Group (elb-sg)
[![ELB-SG](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/ELB-SG.png "ELB-SG")](http://https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/ELB-SG.png "ELB-SG")
###Tomcat Security Group (tomcat-sg)
[![tomcat-sg](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/TOMCAT-SG.png "tomcat-sg")](http://https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/TOMCAT-SG.png "tomcat-sg")
###Back End Security Group (backend-sg)
[![backend-sg](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/BACKEND-SG.png "backend-sg")](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/BACKEND-SG.png "backend-sg")

#EC2 Instances
###vprofile-db01
You may be launching an instance with an Amazon Linux 2023 AMI. Link the backend-sg security group and run the script below to install the packages and create the initial database. Remember to bind a key
```bash
#!/bin/bash
DATABASE_PASS='admin123'
sudo dnf update -y
sudo dnf install git zip unzip -y
sudo dnf install mariadb105-server -y
# starting & enabling mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
cd /tmp/
git clone -b main https://github.com/hkhcoder/vprofile-project.git
#restore the dump file for the application
sudo mysqladmin -u root password "$DATABASE_PASS"
sudo mysql -u root -p"$DATABASE_PASS" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DATABASE_PASS'"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"
sudo mysql -u root -p"$DATABASE_PASS" -e "create database accounts"
sudo mysql -u root -p"$DATABASE_PASS" -e "grant all privileges on accounts.* TO 'admin'@'localhost' identified by 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" -e "grant all privileges on accounts.* TO 'admin'@'%' identified by 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" accounts < /tmp/vprofile-project/src/main/resources/db_backup.sql
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"
```
###vprofile-mc01
You may be launching an instance with an Amazon Linux 2023 AMI. Link the backend-sg security group and run the script below to install the packages. Remember to bind a key
```bash
#!/bin/bash
sudo dnf install memcached -y
sudo systemctl start memcached
sudo systemctl enable memcached
sudo systemctl status memcached
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached
sudo systemctl restart memcached
sudo memcached -p 11211 -U 11111 -u memcached -d
```
###vprofile-rmq01
You may be launching an instance with an Amazon Linux 2023 AMI. Link the backend-sg security group and run the script below to install the packages. Remember to bind a key
```bash
#!/bin/bash
## primary RabbitMQ signing key
rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc'
## modern Erlang repository
rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key'
## RabbitMQ server repository
rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key'
curl -o /etc/yum.repos.d/rabbitmq.repo https://raw.githubusercontent.com/hkhcoder/vprofile-project/aws-LiftAndShift/al2023rmq.repo
dnf update -y
## install these dependencies from standard OS repositories
dnf install socat logrotate -y
## install RabbitMQ and zero dependency Erlang
dnf install -y erlang rabbitmq-server
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
sudo sh -c 'echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config'
sudo rabbitmqctl add_user test test
sudo rabbitmqctl set_user_tags test administrator
rabbitmqctl set_permissions -p / test ".*" ".*" ".*"
sudo systemctl restart rabbitmq-server
```
###vprofile-tomcat01
This instance will be the only one where we will use another AMI, in which we will use Ubuntu Server 22.04. Be very careful not to select another version, as incompatibility errors with the JDK and Tomcat may occur.
```bash
#!/bin/bash
sudo apt update
sudo apt update && sudo apt install openjdk-11-jdk software properties-common daemon systemd curl -y
sudo apt install tomcat9 tomcat9-admin -y
sudo snap install aws-cli --classic 
```