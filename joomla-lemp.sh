#! /bin/bash

echo "==============================================================="
echo "============= Welcome to the Joomla CMS installer ============="
echo "==============================================================="
echo -n "Enter your domain name > "
read var01
echo -n "Enter your email address > "
read var02

var011=`echo "$var01" | sudo sed "s/www.//g"`
varnaked=`echo "$var01" | grep -q -E '(.+\.)+.+\..+$' || echo "true" && echo "false"`
varwww=`echo "$var01" | grep -q "www." && echo "true" || echo "false"`


echo ""

if $varnaked;
  then echo "Make sure '$var01' & 'www.$var01' both point towards your server IP address, else installation will fail";
elif $varwww;
  then echo "Make sure '$var011' & '$var01' both point towards your server IP address, else installation will fail";
else 
  echo "Make sure '$var01' point towards your server IP address, else installation will fail";
fi

echo ""


echo -n "Press 'y' to continue > "
read varinput
echo "Yy" | grep -q "$varinput" && echo "continuing..." || echo "exiting..."
echo "Yy" | grep -q "$varinput" || exit 1


echo "============================================================"
echo "======= A robot is now installing Joomla CMS for you ======="
echo "==================== === ETC = 120s ========================"
echo "============================================================"

# initial setup
sudo apt-get update
sudo apt-get install pwgen -y
sudo apt-get install gpw -y
sudo apt-get install nano -y
sudo apt-get install software-properties-common -y
sudo apt-get install mariadb-server mariadb-client -y
sudo apt-get install certbot -y
sudo apt-get install cron -y

sudo apt disable ufw -y
sudo apt remove iptables -y
sudo apt purge iptables -y


# random string generation
var03=$(gpw 1 8)
var04=$(gpw 1 8)
var05=$(pwgen -s 16 1)
var06=$(pwgen -s 16 1)


# STEP1 configuring PHP
echo | sudo add-apt-repository ppa:ondrej/php
echo | sudo add-apt-repository ppa:ondrej/nginx
sudo apt-get update
sudo apt install php8.0-fpm php8.0-common php8.0-mysql php8.0-gmp php8.0-curl php8.0-intl php8.0-mbstring php8.0-xmlrpc php8.0-gd php8.0-xml php8.0-soap php8.0-cli php8.0-zip php8.0-soap -y
sudo apt-get install php-imagick -y
sudo apt-get install php8.0-imagick -y

sudo bash -c 'echo short_open_tag = On >> /etc/php/8.0/fpm/php.ini'
sudo bash -c 'echo cgi.fix_pathinfo = 0 >> /etc/php/8.0/fpm/php.ini'
sudo bash -c 'echo date.timezone = America/Chicago >> /etc/php/8.0/fpm/php.ini'
sudo sed -i "s/max_execution_time = 30/max_execution_time = 600/g" /etc/php/8.0/fpm/php.ini
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 64M/g" /etc/php/8.0/fpm/php.ini
sudo sed -i "s/post_max_size = 8M/post_max_size = 64M/g" /etc/php/8.0/fpm/php.ini
sudo sed -i "s/output_buffering = 4096/output_buffering = Off/g" /etc/php/8.0/fpm/php.ini


# STEP2 configuring DATABASE
sudo mysql -u root -e "CREATE DATABASE $var03;"
sudo mysql -u root -e "CREATE USER '$var04'@'localhost' IDENTIFIED BY '$var05';"
sudo mysql -u root -e "GRANT ALL ON $var03.* TO '$var04'@'localhost' WITH GRANT OPTION;"
sudo mysql -u root -e "FLUSH PRIVILEGES;"
sudo mysqladmin password "$var06"
sudo mysql -u root -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -u root -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -u root -e "DROP DATABASE IF EXISTS test;"
sudo mysql -u root -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"


# STEP3 configuring SSL

sudo systemctl stop nginx.service
sudo systemctl stop apache.service
sudo systemctl stop apache2.service

if $varnaked;
  then yes | sudo certbot certonly --non-interactive --standalone --preferred-challenges http --email "$var02" --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "$var01" -d www."$var01";
elif $varwww;
  then yes | sudo certbot certonly --non-interactive --standalone --preferred-challenges http --email "$var02" --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "$var01" -d "$var011";
else 
  yes | sudo certbot certonly --non-interactive --standalone --preferred-challenges http --email "$var02" --server https://acme-v02.api.letsencrypt.org/directory --agree-tos -d "$var01";
fi


# STEP4 configuring NGINX
sudo apt-get install nginx -y
sudo systemctl restart nginx.service

if $varnaked;
  then sudo wget --no-check-certificate 'https://raw.githubusercontent.com/cmswizard/joomla-lemp/main/config.txt' -O /etc/nginx/sites-enabled/joomla && sudo sed -i "s/domain/$var01/g" /etc/nginx/sites-enabled/joomla;
elif $varwww;
  then sudo wget --no-check-certificate 'https://raw.githubusercontent.com/cmswizard/joomla-lemp/main/config-www.txt' -O /etc/nginx/sites-enabled/joomla && sudo sed -i "s/domain/$var011/g" /etc/nginx/sites-enabled/joomla;
else 
  sudo wget --no-check-certificate 'https://raw.githubusercontent.com/cmswizard/joomla-lemp/main/config-non-www.txt' -O /etc/nginx/sites-enabled/joomla && sudo sed -i "s/domain/$var01/g" /etc/nginx/sites-enabled/joomla;
fi

# optional packages update
# sudo apt-get update
#sudo apt-get upgrade -y
#sudo apt-get dist-upgrade -y
#sudo apt-get clean -y
#sudo apt-get autoclean -y
#sudo apt autoremove -y

# installing the app
sudo mkdir /var/www/joomla
cd /var/www/joomla
wget https://downloads.joomla.org/cms/joomla4/4-0-3/Joomla_4-0-3-main-Full_Package.tar.gz?format=gz -O latest.tar.gz
tar -xzf latest.tar.gz
cd
sudo chown -R www-data:www-data /var/www/joomla
sudo chmod -R 0755 /var/www/joomla


#Database setup
###
 


# Removing obsolete files
sudo rm /var/www/joomla/latest.tar.gz


# Restrating services
sudo systemctl restart nginx.service
sudo systemctl restart mysql.service
sudo systemctl restart php8.0-fpm

echo "========== please save this info in a secure place =========="
echo "your mysql username: root"
echo "your mysql password: $var06"
echo "your database name: $var03"
echo "your database username: $var04"
echo "your database password: $var05"

echo "=======================-== DONE! ============================"
echo "============ Joomla CMS is installed sucessfully ============"
echo "=================== =================== ====================="
