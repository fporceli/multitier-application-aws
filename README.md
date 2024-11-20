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

### Dependencies
- Git
- JDK 17.0.13
- Apache Maven 3.9.9
- AWS Cli

# Security Groups
With the visualization from the image, the construction of security groups becomes an easier task. However, it is always important to pay attention to the ports.
### Elastic Load Balancer Security Group (elb-sg)
[![ELB-SG](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/ELB-SG.png "ELB-SG")](http://https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/ELB-SG.png "ELB-SG")
### Tomcat Security Group (tomcat-sg)
[![tomcat-sg](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/TOMCAT-SG.png "tomcat-sg")](http://https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/TOMCAT-SG.png "tomcat-sg")
### Back End Security Group (backend-sg)
[![backend-sg](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/BACKEND-SG.png "backend-sg")](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/BACKEND-SG.png "backend-sg")

# EC2 Instances
### vprofile-db01
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
### vprofile-mc01
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
### vprofile-rmq01
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
### vprofile-tomcat01
This instance will be the only one where we will use another AMI, in which we will use Ubuntu Server 22.04. Be very careful not to select another version, as incompatibility errors with the JDK and Tomcat may occur.
```bash
#!/bin/bash
sudo apt update
sudo apt update && sudo apt install openjdk-11-jdk software properties-common daemon systemd curl -y
sudo apt install tomcat9 tomcat9-admin -y
sudo snap install aws-cli --classic 
```
# Route 53 (Private DNS Server)
Setting up Route 53 is relatively simple, but be careful not to use it too much, as you may end up leaving your account's free tier. Simply access the service through the AWS console and create a private zone. After that, you can create multiple hosted zones using the private IP address of each EC2 instance, as shown in the image:
[![route53](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/ROUTE53-ZONE.png "route53")](http://https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/ROUTE53-ZONE.png "route53")
To test whether it is working or not, just try to ping from one machine to another using the resolved name.
[![PingRota53](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/PINGROUTE53.png "PingRota53")](https://felipe-vprofile-artifacts.s3.sa-east-1.amazonaws.com/PINGROUTE53.png "PingRota53")

# Build and Deploy Artifcats
### S3 Permissions
To configure permissions in AWS, the first step is to create an IAM user. In the AWS console, you need to access the IAM service and create a new user with programmatic access permissions, such as Access Key and Secret Key. After creating the user, it is necessary to assign it the appropriate permission policy, we will use AmazonS3FullAccess, ensuring that it has the necessary privileges to manage S3 resources.

After configuring the IAM user, it is time to create an IAM role that will be linked to the vprofile-tomcat01 instance. This role must have permissions equivalent to those of the user created using the policy mentioned above. Once this is done, you must access the AWS EC2 console, locate the vprofile-tomcat01 instance, and assign the IAM role you created to it. This will configure the instance to interact with S3 with administrative permissions.

### Build 
Para fazermos o deploy da aplicação vamos fazer sua construção em nosso computador utilizando o AWS CLI e o Maven. Vamos acessar nosso o diretório do nosso repositório

multitier-application-aws/userdata/application.properties

Certifique-se de alterar todos os endereços para o do DNS que configuramos. Por exemplo, vamos alterar a variável memcached.active.host para

`memcached.active.host=mc01.vprofile.in`

```bash
#JDBC Configutation for Database Connection
jdbc.driverClassName=com.mysql.jdbc.Driver
jdbc.url=jdbc:mysql://db01.vprofile.in:3306/accounts?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull
jdbc.username=admin
jdbc.password=admin123

#Memcached Configuration For Active and StandBy Host
#For Active Host
memcached.active.host=mc01.vprofile.in  
memcached.active.port=11211
#For StandBy Host
memcached.standBy.host=127.0.0.2
memcached.standBy.port=11211

#RabbitMq Configuration
rabbitmq.address=rmq01.vprofile.in
rabbitmq.port=5672
rabbitmq.username=test
rabbitmq.password=test

#Elasticesearch Configuration
elasticsearch.host =192.168.1.85
elasticsearch.port =9300
elasticsearch.cluster=vprofile
elasticsearch.node=vprofilenode
```

After that, you can run it inside the Visual Studio Code terminal.

`mvn install`

Once complete, a directory called "target" will be created. Inside it there will be a .war file, which will be our artifact to deploy to Tomcat.

After that, we will transfer the .war file to an s3 bucket. Let's run the command.

`aws s3 cp target/vprofile-v2.war s3://bucket-name/vprofile-v2.war`

Note: remember to run "aws configure" to configure your user with access permission to S3.

After that, we can log in to our ec2 instance vprofile-tomcat01 and run the pull of our artifact into the s3 bucket. To do this, we will need to install. You can run the following command:
```bash
systemctl stop tomcat9
aws s3 cp s3://bucket-name/vprofile-v2.war /tmp/
sudo rm -rf /var/lib/tomcat9/webapps/ROOT
cp /tmp/vprofile-v2.war /var/lib/tomcat9/webapps/ROOT.war
systemctl start tomcat9
```
