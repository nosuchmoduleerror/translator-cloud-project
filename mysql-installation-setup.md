# mySQL set-up
sudo apt update
sudo apt-get install mysql-server
systemctl is-active mysql
sudo mysql_secure_installation -> enter "2"
"enter as password: Cloud_08 "
sudo mysql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Cloud_08';
FLUSH PRIVILEGES;
mysql -u root -p
Cloud_08
systemctl status mysql.service
CREATE DATABASE `flask`;
use flask;

CREATE TABLE badTranslations ( 
FROMTAG varchar(2) not null, 
TOTAG varchar(2) not null, 
FROM_TEXT varchar(60) not null, 
TO_TEXT varchar(60) not null,
ID integer(30) not null, 
PRIMARY KEY (ID) 
);


"inside the python environment of the project: pip install flask-mysqldb"




