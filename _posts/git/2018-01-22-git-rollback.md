---
layout: post
title: Git撤销更改
categories: [Git, Linux]
description: 使用Git时不小心提交了不想提交的内容，想要会推到上一个点
keywords: Git,Linux
---

### 常用命令

+ 添加用户 
```bash
    git config –global user.name "clibing"
    git config –gloaba user.email "clibing@gmail.com"
```
<!--more-->

+ 查看git配置及用户信息 
```bash
    git config –list
```
+ 生成SSH秘钥(2种方式:1.git GUI图形界面化操作; 2.git命令,即以下流程) 
  * 1查看是否有秘钥,有则备份然后删除文件夹 
    ```bash
        cd ~/.ssh 
        ls 
    ```
  * 2正式生成,输入指令再 按三次回车,也就是第三次回车指纹密码输入可以为空 
    ```bash
        ssh-keygen -t rsa -C "clibing@gmail.com"
    ```
  * 3添加私钥到 ssh(如果配置过指纹密码就要输入验证) 
    ```bash
        ssh -add id_rsa
    ```
+ 进入计算机系统用户文件夹,找到id_rsa.pub,打开复制到github的setting的SSH keys当中(该网站服务器可以添加多个ssh key公钥)
+ 测试本机是否有访问GitHub的权限 
  ```bash
    ssh git@github.com
  ``` 

### 基本概念

#### 3个步骤

`工作区`->`暂存区`->`本地仓库`->`远程仓库`

正常情况下，我们的工作流就是3个步骤，对应上面的的3个箭头线:

```git
git add .   注意"."为当前目录会将全部加入，不建议使用。使用git add 具体到某个文件
git commit -m "填写本次提交的信息"
git push
```

1. `git add .`: 将所选文件加入`暂存区`
2. `git commit -m 'commit message'`: 将所有文件从`暂存区`提交进`本地仓库`
3. `git push`:把所有文件从`本地仓库`推送到`远程仓库`, 如果时分支推送可能会用到`git push -o origin 分支的具体名字`

#### 4个区

用过svn的人知道，`svn add`、`svn ci`这些命令，git比svn多出了一个`暂存区`的概念

+ 工作区（Working Area）
+ 暂存区（Stage）
+ 本地仓库（Local Repository）
+ 远程仓库（Remote Repository）

#### 5中状态

+ 未修改（Origin）
+ 已修改（Modified）
+ 已暂存（Staged）
+ 已提交（Committed）
+ 已推送（Pushed）

根据上面的5中状态会出现一下几种情况

* 已修改-未暂存
* 已暂存-未提交
* 已提交-未推送

### 阶段撤销

根据以上几种情况进行撤销

+ 未加入暂存区

    文件已经修改未执行`git add .`加入暂存区时，如果回退可以执行`git checkout .`或者`git reset --hard` 注意执行后修改的记录会丢失

+ 已暂存未提交
   
    文件修改后，执行了`git add .`当时没有执行`git commit -m "commit message"`，此时需要撤销，可以执行
    ```
    git reset
    git checkout .
    ```      
    `git reset`只是把文件退回到`git add .`之前的状态，注意文件还是处于`已修改未暂存`的状态，如果想回到`未修改`状态还需要执行`git checkout .`或者用一条命令`git reset --hard`
    ```
    git reset --hard
    ```     
+ 已提交未推送

    即已经执行了`git commit -m "commit message"`此时代码已经进入了本地仓库，如果此时想回退可以执行`git reset --hard orgin/master`，此方法多了一个`origin/master`，意思是从远程仓库拉取到本地仓库

+ 已推送

    此时代码已经推送到了中央仓库，此时本地仓库与远程仓库相同了，需要先恢复本地仓库在强`push`到远程仓库
    ```
    git reset --hard HEAD^`
    git push -f
    ```  

+ 当撤销后想再次撤销时

	```
	root@rock64:/share/dockerfile# git reflog
	42d8afa HEAD@{0}: commit: add postgresql and docker-clean shell
	a07c7da HEAD@{1}: reset: moving to origin/master
	6fe27f6 HEAD@{2}: reset: moving to 6fe27f6
	a07c7da HEAD@{3}: reset: moving to origin/master
	6fe27f6 HEAD@{4}: commit: add postgresql and add clean docker no used or exist
	a07c7da HEAD@{5}: commit: add armhf and alpine minirootfs
	a9a7a65 HEAD@{6}: commit: fix glibc lib
	863b8f3 HEAD@{7}: commit: add nginx mariadb dockerfile
	b845e3d HEAD@{8}: commit: add arm64v8 base
	161e612 HEAD@{9}: commit: rename
	3c1b2cc HEAD@{10}: commit: add build date
	0acafff HEAD@{11}: commit: add build base alpine
	e4b6400 HEAD@{12}: commit: rename rock64 to aarch64(arm64v8)
	bd3a2e2 HEAD@{13}: commit: add armhf x86_64 from private version server
	a6fbf52 HEAD@{14}: commit (initial): add rock64 dockerfile from respi
	# 进入到指定版本
	git reset --hard 6fe27f6
	```
	

### 总结

以上4种状态的撤销我们都用到了同一个命令`git reset --hard`，前2种状态的用法甚至完全一样，所以要掌握了`git reset --hard`这个命令的用法


