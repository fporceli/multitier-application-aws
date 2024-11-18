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


