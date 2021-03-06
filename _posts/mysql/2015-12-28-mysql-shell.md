---
layout: post
title: MySQL 常用操作
categories: [Linux, MySQL]
description: MySQL 的一些常用操作
keywords: Linux,MySQL
---

<!--more-->

``` bash
#开启远程登录
grant all privileges on *.* to 'user'@'%' identified by 'passwd' with grant option;

#创建数据库
create database DB;

#创建用户
insert into mysql.user(Host,User,Password) values("localhost","user",password("passwd"));

#删除用户
DELETE FROM user WHERE user="username" and HOST="localhost";

#修改指定用户密码
update mysql.user set password=password('new passwd') where user="username" and host="localhost";

#用户授权
grant all privileges on DB.* to 'user'@'localhost' identified by 'passwd';
grant select,update on DB.* to 'user'@'localhost' identified by 'passwd';

#刷新权限
flush privileges;

#数据库导出
mysqldump -uUSRENAME -pPASSWD DATABASE > DATABASE.sql

#数据库导出(只导出表结构 -d)
mysqldump -uUSRENAME -pPASSWD -d DATABASE > DATABASE.sql

#数据库导入

#1.切换数据库
use DATABASE;
#2.设置编码
set names utf8;
#3.执行导入操作
source /home/abc/abc.sql;

#直接导入
mysql -uUSERNAME -p DATABASE < DATABASE.sql
```
转载请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权
