#!/bin/bash

sudo apt-get update -y
sudo apt-get upgrade -y

cd $HOME
# INSTALL DEPENDENCIES
sudo apt-get install libcairo2-dev -y
sudo apt-get install libjpeg-turbo8-dev -y
sudo apt-get install libjpeg62-dev -y
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

# INSTALL TOOLS
sudo apt-get install libtool -y
sudo apt-get install autoconf -y
sudo apt-get install maven -y 
sudo apt-get install openjdk-8-jdk -y
sudo apt-get install tomcat8 -y
sudo apt-get install apache2-bin -y
sudo apt-get install apache2 -y
sudo apt-get install libxml2-dev -y

# JAVA_HOME
export JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")

# INSTALL GUACAMOLE SERVER
cd $HOME
sudo wget http://archive.apache.org/dist/guacamole/1.3.0/source/guacamole-server-1.3.0.tar.gz
sudo tar -xzf guacamole-server-1.3.0.tar.gz
cd guacamole-server-1.3.0/
autoreconf -fi
./configure --with-init-dir=/etc/init.d
make
make install
ldconfig

# INSTALL GUACAMOLE CLIENT
cd $HOME
sudo wget http://archive.apache.org/dist/guacamole/1.3.0/source/guacamole-client-1.3.0.tar.gz
sudo tar -xzf guacamole-client-1.3.0.tar.gz
cd guacamole-client-1.3.0/
mvn package

# DEPLOYING GUACAMOLE
cd $HOME
cd guacamole-client-1.3.0/guacamole/target/
cp guacamole-1.3.0.war /var/lib/tomcat8/webapps/guacamole.war
sudo /etc/init.d/ tomcat8 restart
sudo /etc/init.d/guacd start

# INSTALL NGINX 
sudo apt-get install nginx -y

# SETUP NGINX

sudo cp -f ../config/nginx/site-availables/default /etc/nginx/sites-available/default

sudo service apache2 restart
sudo a2enmod proxy proxy_http
sudo service apache2 restart


# CONFIGURE GUACAMOLE
sudo mkdir /etc/guacamole/
sudo mkdir /usr/share/tomcat8/.guacamole

sudo cp -f ../config/guacamole/guacamole.properties /etc/guacamole/guacamole.properties

# DATABASE AUTHENTICATION
sudo mkdir /var/lib/guacamole/
sudo mkdir /var/lib/guacamole/extensions/
sudo mkdir /var/lib/guacamole/lib/

# Download guacamole-auth-jdbc-1.0.0  and paste jar file to /var/lib/guacamole/extensions/
cd /var/lib/guacamole/extensions/
sudo wget http://archive.apache.org/dist/guacamole/1.3.0/binary/guacamole-auth-jdbc-1.3.0.tar.gz
sudo tar -xzf guacamole-auth-jdbc-1.3.0.tar.gz
cd guacamole-auth-jdbc-1.3.0/mysql
sudo cp guacamole-auth-jdbc-1.3.0.jar /var/lib/guacamole/extensions/

# Download mysql-connector-java-5.1.38 and paste it to /var/lib/guacamole/lib
cd /var/lib/guacamole/lib
sudo wget http://ftp.jaist.ac.jp/pub/mysql/Downloads/Connector-J/mysql-connector-java-8.0.24.tar.gz
sudo tar -xzf mysql-connector-java-8.0.26.tar.gz
cd mysql-connector-java-8.0.26
sudo cp mysql-connector-java-8.0.26.jar /var/lib/guacamole/lib

# CREATE SYMBOLIC LINKS
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



# ENABLE PORTS (LAST TO RUN)
sudo ufw enable
sudo ufw allow 8080
sudo ufw allow 80
sudo ufw allow 22
sudo ufw allow 3306
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 4822

