#! /bin/bash
sudo apt-get update
sudo apt install nginx -y
cd /var/www/html
sudo sh -c "$(echo hostname -f) > index.html"
sudo service nginx start