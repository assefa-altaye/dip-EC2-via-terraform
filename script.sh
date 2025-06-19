#!/bin/bash
yum install nginx -y
echo "Hello from Server" > /usr/share/nginx/html/index.html
systemctl start nginx