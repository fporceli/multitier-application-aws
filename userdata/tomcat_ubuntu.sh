#!/bin/bash
sudo apt update
sudo apt update && sudo apt install openjdk-11-jdk software properties-common daemon systemd curl -y
sudo apt install tomcat9 tomcat9-admin -y
sudo snap install aws-cli --classic 