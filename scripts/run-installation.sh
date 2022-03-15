#!/bin/bash


DATABASE=$1
USERNAME=$2
PASSWORD=$3


    

install_dependencies(){
    # INSTALL DEPENDENCIES
    sudo apt-get install libcairo2-dev -y
    sudo apt-get install libpng-dev -y
    sudo apt-get install libtool-bin -y
    sudo apt-get install libossp-uuid-dev -y
    sudo apt-get install libavcodec-dev -y
    sudo apt-get install libavformat-dev -y
    sudo apt-get install libavutil-dev -y
    sudo apt-get install libswscale-dev -y
    sudo apt-get install freerdp2-dev -y
    sudo apt-get install libpango1.0-dev -y
    sudo apt-get install libssh2-1-dev -y
    sudo apt-get install libtelnet-dev -y
    sudo apt-get install libvncserver-dev -y
    sudo apt-get install libwebsockets-dev -y
    sudo apt-get install libpulse-dev -y
    sudo apt-get install libssl-dev -y
    sudo apt-get install libvorbis-dev -y
    sudo apt-get install libwebp-dev -y
    sudo apt-get install libjpeg-turbo8-dev -y
    sudo apt-get install libjpeg62-dev -y
}

install_tools(){
    # INSTALL TOOLS
    sudo apt-get install libtool -y
    sudo apt-get install maven -y 
    sudo apt-get install openjdk-8-jdk -y
    sudo apt-get install tomcat8 -y
    sudo apt-get install apache2-bin -y
    sudo apt-get install apache2 -y
    sudo apt-get install libxml2-dev -y
    sudo apt-get install autoconf -y
}

sudo apt-get update -y

cd $HOME

install_dependencies

install_tools

sudo apt-get upgrade -y

# JAVA_HOME
export JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")

# INSTALL GUACAMOLE SERVER
cd $HOME
wget http://archive.apache.org/dist/guacamole/1.3.0/source/guacamole-server-1.3.0.tar.gz
tar -xzf guacamole-server-1.3.0.tar.gz
cd guacamole-server-1.3.0/
sudo autoreconf -fi
sudo ./configure --with-init-dir=/etc/init.d
sudo make
sudo make install
sudo ldconfig

# INSTALL GUACAMOLE CLIENT
cd $HOME
wget http://archive.apache.org/dist/guacamole/1.3.0/source/guacamole-client-1.3.0.tar.gz
tar -xzf guacamole-client-1.3.0.tar.gz
cd guacamole-client-1.3.0/
sudo chown -R ${USER:=$(/usr/bin/id -run)}:$USER guacamole-common
mvn package

# DEPLOYING GUACAMOLE
cd $HOME
cd guacamole-client-1.3.0/guacamole/target/
sudo cp guacamole-1.3.0.war /var/lib/tomcat8/webapps/guacamole.war
sudo service tomcat8 restart
sudo /etc/init.d/guacd start

# INSTALL NGINX 
cd $HOME
sudo apt-get install nginx -y

# SETUP NGINX

sudo cp -f $HOME/guac-installation/config/nginx/site-availables/default /etc/nginx/sites-available/default

sudo service apache2 restart
sudo a2enmod proxy proxy_http
sudo service apache2 restart


# CONFIGURE GUACAMOLE
sudo mkdir /etc/guacamole/
sudo mkdir /usr/share/tomcat8/.guacamole

sudo cp -f $HOME/guac-installation/config/guacamole/guacamole.properties /etc/guacamole/guacamole.properties

# DATABASE AUTHENTICATION
sudo mkdir /var/lib/guacamole/
sudo mkdir /var/lib/guacamole/extensions/
sudo mkdir /var/lib/guacamole/lib/

# Download guacamole-auth-jdbc-1.0.0  and paste jar file to /var/lib/guacamole/extensions/
cd /var/lib/guacamole/extensions/
sudo wget http://archive.apache.org/dist/guacamole/1.3.0/binary/guacamole-auth-jdbc-1.3.0.tar.gz
sudo tar -xzf guacamole-auth-jdbc-1.3.0.tar.gz
cd guacamole-auth-jdbc-1.3.0/mysql
sudo cp guacamole-auth-jdbc-mysql-1.3.0.jar /var/lib/guacamole/extensions/

# Download mysql-connector-java-5.1.38 and paste it to /var/lib/guacamole/lib
cd /var/lib/guacamole/lib
sudo wget http://ftp.jaist.ac.jp/pub/mysql/Downloads/Connector-J/mysql-connector-java-8.0.26.tar.gz
sudo tar -xzf mysql-connector-java-8.0.26.tar.gz
cd mysql-connector-java-8.0.26
sudo cp mysql-connector-java-8.0.26.jar /var/lib/guacamole/lib
#sudo cp -f $HOME/guac-installation/lib/mysql-connector-java-8.0.24.jar /var/lib/guacamole/lib

# CREATE SYMBOLIC LINKS
cd $HOME
sudo ln -s /var/lib/guacamole/extensions /etc/guacamole/extensions
sudo ln -s /var/lib/guacamole/extensions /usr/share/tomcat8/.guacamole/extensions
sudo ln -s /var/lib/guacamole/lib /etc/guacamole/lib
sudo ln -s /var/lib/guacamole/lib /usr/share/tomcat8/.guacamole/lib
sudo ln -s /var/lib/guacamole/extensions extensions
sudo ln -s /var/lib/guacamole/lib lib

# INSTALL MySQL
sudo apt-get install mysql-client-core-5.7 mysql-client-5.7 mysql-server-5.7 -y

sudo mkdir /var/lib/guacamole/classpath
cd /var/lib/guacamole/extensions/guacamole-auth-jdbc-1.3.0/mysql/
sudo cp guacamole-auth-jdbc-mysql-1.3.0.jar /var/lib/guacamole/classpath/
cd /var/lib/guacamole/classpath/
sudo wget http://ftp.jaist.ac.jp/pub/mysql/Downloads/Connector-J/mysql-connector-java-8.0.26.tar.gz
sudo tar -xzf mysql-connector-java-8.0.26.tar.gz
cd mysql-connector-java-8.0.26
sudo cp mysql-connector-java-8.0.26.jar /var/lib/guacamole/classpath/

cd $HOME
sudo bash $HOME/guac-installation/scripts/mysql.sh --database $DATABASE --username $USERNAME --password $PASSWORD

# MAKE A GUACAMOLE_DB
cd /var/lib/guacamole/extensions/guacamole-auth-jdbc-1.3.0/mysql
ls schema/
sudo cat schema/*.sql | sudo mysql -u root guacamole_db

# CONFIGURE IPTABLES
cd $HOME
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -F
sudo iptables -X 
sudo iptables -I INPUT 1 -j ACCEPT
sudo iptables -I OUTPUT 1 -j ACCEPT
sudo iptables -I INPUT 1 -p tcp --dport 4822 -j ACCEPT 

sudo cp -f $HOME/guac-installation/config/guacamole/guacd.conf /etc/guacamole/guacd.conf

# Comment out: bind address 127.0.0.1 
sudo sed -i '43 s/^/#/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Copy cert and key
sudo cp -f $HOME/guac-installation/certs/cert.crt /etc/ssl/certs/cert.crt && sudo cp -f $HOME/guac-installation/certs/cert.key /etc/ssl/private/cert.key


# Set Guacamole_home
sudo sh -c "echo 'GUACAMOLE_HOME=/etc/guacamole/' >> /etc/default/tomcat8"
cd $HOME
sudo sed -i 's/Apache Guacamole/CloudSwyft/g' /var/lib/tomcat8/webapps/guacamole/translations/en.json
sudo sed -i 's/Guacamole/CloudSwyft/g' /var/lib/tomcat8/webapps/guacamole/translations/en.json

sudo /etc/init.d/nginx restart
sudo /etc/init.d/guacd restart
sudo /etc/init.d/apache2 restart
sudo /etc/init.d/tomcat8 restart
sudo /etc/init.d/mysql restart


# ENABLE PORTS (LAST TO RUN)
echo y | sudo ufw status
sudo ufw allow 8080
sudo ufw allow 80
sudo ufw allow 22
sudo ufw allow 3306
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 4822

