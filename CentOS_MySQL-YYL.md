# MySQL install Document

任务名称：Mysql install

安装文档：https://dev.mysql.com/doc/refman/5.6/en/binary-installation.html

配置文档：https://dev.mysql.com/doc/refman/5.6/en/tutorial.html

支持平台： Debian家族 | RHEL家族 | Windows | SUSE |MAC OS|

任务提交者：YinYeLi

# 介绍
MySQL是一个关系型数据库管理系统，由瑞典MySQL AB 公司开发，属于 Oracle 旗下产品。MySQL 是最流行的关系型数据库管理系统之一，在 WEB 应用方面，MySQL是最好的 RDBMS (Relational Database Management System，关系数据库管理系统) 应用软件之一。
# 环境要求
- 系统要求：Windows Server、Redhat、CentOS、Solaris等主流系统
- 服务器要求：CPU*2 64G以上内存，128G以上存储
- 私网ip:server：192.168.174.30
- 依赖库：gcc gcc-c++ make libtool zlib zlib-devel pcre pcre-devel openssl openssl-devel等

# 安装说明
mysql安装有多种方式，如果要上线的生产环境允许临时接入互联网，则可使用oracle官方仓库进行yum安装，这对于解决安装中mysql依赖库是方便的，但是部署环境不允许接入互联网，则可使用企业自建的仓库，也可将安装包和依赖库下载到企业ftp服务器。

下面基于centos 6.4 x86平台使用linux-glic版本的mysql进行部署

### CentOS mysql-linux-glic

#添加用户组

`groupadd mysql`

#新建mysql用户同时生存用户组并且禁止mysql登陆linux

`useradd -r -s /sbin/nologin -g mysql mysql -d /usr/local/mysql`

#关闭selinux及相关安全策略


```
iptables -F
iptables -X
iptables -Z
service iptables stop
sed -i '/^SELINUX=/s/enforcing/disabled/' /etc/selinux/config
chkconfig iptables off
chkconfig ip6tables off
chkconfig NetworkManager off
service iptables stop
service ip6tables stop
service NetworkManager stop
setenforce 0
```
#删除系统自带mysql
```
service mysql stop
service mysqld stop
rpm -qa |grep -i mysql 
rpm -e *******.rpm  --nodeps  (此处把rpm -qa |grep -i mysql出来的包删除)
删除my.cnf文件
rm -rf my.cnf
```
#创建安装路径

```
mkdir -p /opt/mysql
```

#创建数据存放文件
```
mkdir -p /opt/mysql/mysqldata
```
#解压二进制包
```
cd /home/mals71/soft
tar -zxvf  mysql-5.6.44-linux-glibc2.12-x86_64.tar.gz
```
#移动解压目录到安装路径
```
mv mysql-5.6.44-linux-glibc2.12-i686/ /opt/mysql/mysql5.6
```
#改变mysql目录所有者
```chown -R mysql:mysql /opt/mysql/mysql-5.6```
#创建mysql数据文件存放目录并改变所有者
```
mkdir -p /opt/mysql/mysqldata
chown -R mysql:mysql /opt/mysql/mysqldata
```

#此时mysql已安装完成

## 基本配置
进入mysql/support-files目录，复制配置文件到/etc下并修改配置（此处是基本配置，以确保mysql能正常工作，生产环境以实际调优参数为准）
```
vim /etc/my.cnf
[client]
port = 3306
socket =  /opt/mysqldata/tmp/mysql.sock
[mysqld]
socket = /opt/mysqldata/tmp/mysql.sock
pid-file =  /opt/mysqldata/mysql.pid
basedir =  /opt/mysql-5.6
datadir =  /opt/mysqldata/
tmpdir =  /opt/mysqldata/tmp
```
## 其他配置
将mysql.server加入系统service管理

```
[root@myqslda soft]# cp /opt/mysql-5.6/support-files/mysql.server /etc/init.d/mysql
service mysql start
[root@myqslda soft]# service mysql status
MySQL running (1829)                                       [  OK  ]
```
- 注意，此处需要增加环境变量，以便系统调用mysql

```
echo "MYSQL_HOME=/opt/mysql-5.6" >>/etc/profile 
echo "PATH=$PATH:$MYSQL_HOME/bin" >>/etc/profile 
echo "export PATH MYSQL_HOME" >>/etc/profile
source /etc/profile
```

创建websoft9数据库和用户，开启数据库远程访问
```
1.创建数据库
mysql> create database websoft9 default character set utf8 collate utf8_general_ci;
2.创建用户
mysql> create user 'websoft9'@'%' identified by 'Websoft9@2021';
3.授权
mysql> grant select,insert,update,delete,create on websoft9.* to 'websoft9';
mysql> GRANT ALL PRIVILEGES ON *.* TO 'websoft9'@'%'IDENTIFIED BY 'Websoft9@2021' WITH GRANT OPTION;
mysql> FLUSH PRIVILEGES;
mysql> show grants for 'websoft9';
+------------------------------------------------------------------------------------------------------------------------------------+
| Grants for websoft9@%                                                                                                              |
+------------------------------------------------------------------------------------------------------------------------------------+
| GRANT ALL PRIVILEGES ON *.* TO 'websoft9'@'%' IDENTIFIED BY PASSWORD '*2B64AEE85CA01A3AE0A49D5BF6D4F8D6F155F0FC' WITH GRANT OPTION |
| GRANT SELECT, INSERT, UPDATE, DELETE, CREATE ON `websoft9`.* TO 'websoft9'@'%'                                                     |
+------------------------------------------------------------------------------------------------------------------------------------+
2 rows in set (0.00 sec)
```
此时mysql已全部部署完成

## 使用说明
上述my.cnf配置文件说明如下


！！！注意，以下配置为最基础配置，生产环境应当根据实际需要优化配置
```
[client]-----客户端配置  当客户端与服务端为同一主机时可以同时配置
port = 3306  ------指定mysql访问端口，默认为3306
socket =  /opt/mysqldata/tmp/mysql.sock ----指定sock文件，该文件作为通讯协议的载体，mysql数据库中常用
[mysqld]------服务端配置
socket = /opt/mysqldata/tmp/mysql.sock
pid-file =  /opt/mysqldata/mysql.pid ---mysql数据库pid文件，不指定时默认为主机名.pid
basedir =  /opt/mysql-5.6 -------mysql的工作目录
datadir =  /opt/mysqldata/ --------mysql存储数据路径
tmpdir =  /opt/mysqldata/tmp -----临时文件存放路径
```
## 账号密码
注意：以下密码仅在实验环境使用，生产环境请配置合规的复杂密码！！

centos密码：普通用户mals71    密码：mals71

超级用户root       密码：1234567890

mysql 密码:   用户root  密码：mysql  用户websoft9  密码：Websoft9@2021

## 版本号信息
OS_Version:
```
[root@myqslda soft]# cat /etc/centos-release 
CentOS release 6.5 (Final)
```
kernel_version:

```
[root@myqslda soft]# uname -a
Linux myqslda 2.6.32-431.el6.x86_64 #1 SMP Fri Nov 22 03:15:09 UTC 2013 x86_64 x86_64 x86_64 GNU/Linux
```
mysql_version:
```
mysql> select version();
+-----------+
| version() |
+-----------+
| 5.6.44    |
+-----------+
```

## 端口号
MySQL port 3306


## 常见问题
安装完成后，mysql可能会出现如下异常

```
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: YES)
```
需要依次完成如下配置方可使用

```
service mysql stop
vi /etc/my.cnf
添加如下配置
skip-grant-tables
service mysql start
mysql -uroot -p
mysql> use mysql
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> update user set password=password('mysql') where user='root' and host='localhost';
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> flush privileges;  
Query OK, 0 rows affected (0.00 sec)

service mysql stop
```
把之前的skip-grant-tables注释掉，重启mysql服务，如果再出现
```

ERROR 1820 (HY000): You must SET PASSWORD before executing this statement
执行SET PASSWORD = PASSWORD('mysql');即可
```
**不会linux命令，可以推荐使用SQL SERVER、SQL Lite Manger 等图形化工具**

#### ### 该安装方式请务必注意环境，若缺少依赖包请挂载镜像，yum安装缺少的依赖包！！！
## 日志
- 2021年2月20日完成部署
- 2021年2月21日完成文档整理