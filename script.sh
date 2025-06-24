#!/bin/bash
yum install nginx -y
echo "<html><body><h1>Hello!</h1><h3>You are viewing this application from private instance ${instance_id}</h3></body></html>" > /usr/share/nginx/html/index.html
systemctl start nginx