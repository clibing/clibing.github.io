---
layout: post
categories: Docker Kubernetes
title: kubeadm 续坑篇
date: 2016-11-21 20:16:51 +0800
description: 记录 kubeadm 一些其他的坑
keywords: kubeadm kubernetes docker
---

> 断断续续鼓捣 kubeadm 搭建集群已经很长时间了，目前 kubeadm 已经进入了 beat 阶段，各项功能相对稳定，但是继上篇 [kubeadm 搭建 kubernetes 集群](https://mritd.me/2016/10/29/set-up-kubernetes-cluster-by-kubeadm/) 之后还是踩了许多坑，在此记录一下


### 一、etcd 单点问题

默认 kubeadm 创建的集群会在内部启动一个单点的 etcd，当然大部分情况下 etcd 还是很稳定的，**但是一但 etcd 由于某种原因挂掉，这个问题会非常严重，会导致整个集群不可用**。具体原因是 etcd 存储着 kubernetes 各种元数据信息；包括 `kubectl get pod` 等等基础命令实际上全部是调用 RESTful API 从 etcd 中获取的信息；**所以一但 etcd 挂掉以后，基本等同于 `kubectl` 命令不可用，此时将变为 '瞎子'，集群各节点也会因无法从 etcd 获取数据而出现无法调度，最终挂掉**。

**解决办法是在使用 kubeadm 创建集群时使用 `--external-etcd-endpoints` 参数指定外部 etcd 集群，此时 kubeadm 将不会在内部创建 etcd，转而使用外部我们指定的 etcd 集群，如果外部 etcd 集群配置了 SSL 加密，那么还需要配合 `--external-etcd-cafile`、`--external-etcd-certfile`、`--external-etcd-keyfile` 三个参数指定 etcd 的 CA证书、CA签发的使用证书和私钥文件，命令如下**

``` sh
# 非 SSL
kubeadm init --external-etcd-endpoints http://192.168.1.100:2379
# etcd SSL
kubeadm init --external-etcd-endpoints https://192.168.1.100:2379 --external-etcd-cafile /path/to/ca --external-etcd-certfile /path/to/cert --external-etcd-keyfile /path/to/privatekey
```

### 二、etcd 不可与 master 同在

'愿上帝与你同在'......这个坑是由于 kubeadm 的 check 机制的 bug 造成的，目前还没有修复；表现为 **当 etcd 与 master 在同一节点时，kubeadm init 会失败，同时报错信息提示 '已经存在了 `/var/lib/etcd` 目录，或者 2379 端口被占用'**；因为默认 kubeadm 会创建 etcd，而默认的 etcd 会占用这个目录和 2379 端口，**即使你加了 `--external-etcd-endpoints` 参数，kubeadm 仍然会检测这两项条件是否满足，不满足则禁止 init 操作**

**解决办法就是要么外部的 etcd 更换数据目录(`/var/lib/etcd`)和端口，要么干脆不要和 master 放在同一主机即可**

### 三、巨大的日志

熟悉的小伙伴应该清楚，基本上每个 kubernetes 组件都会有个通用的参数 `--v`；这个参数用于控制 kubernetes 各个组件的日志级别，在早期(alpha)的 kubeadm 版本中，如果不进行调整，默认创建集群所有组件日志级别全部为 `--v=4` 即最高级别输出，这会导致在业务量大的时候磁盘空间以 **'我去尼玛'** 的速度增长，尤其是 `kube-proxy` 组件的容器，会疯狂吃掉你的磁盘空间，然后剩下懵逼的你不知为何。在后续的版本中(beta)发现日志级别已经降到了 `--v=2`，不过对于完全不怎么看日志的我来说还是无卵用......

**解决办法有两种方案:**

**如果已经 `--v=4` 跑起来了(检查方法就是随便 describe 一个 kube-proxy 的容器，看下 command 字段就能看到)，并且无法停止重建集群，那么最简单的办法就是使用 `kubectl edit ds xxx` 方式编译一下相关 ds 文件等，然后手动杀掉相关 pod，让 kubernetes 自动重建即可，如果命令行用着不爽也可以通过 dashboard 更改**

**如果还没开始搭建，或者可以停掉重建，那么只需在 `kubeadm init` 之前 `export KUBE_COMPONENT_LOGLEVEL='--v=0'` 即可**

### 四、新节点加入 dns 要你命

当 kubeadm 创建好集群以后，如果有需要增加新节点，那么在 `kubeadm join` 之后务必检查 `kube-dns` 组件，dns 在某些(weave 启动不完整或不正常)情况下，会由于新节点加入而挂掉，此时整个集群 dns 失效，**所以最好 join 完观察一会 dns 状态，如果发现不正常马上杀掉  dns pod，让 kubernetes 自动重建；如果情况允许最好全部 join 完成后直接干掉 dns 让 kubernetes 重建一下**

### 五、单点的 dns 浪起来让你怕

kubeadm 创建的 dns 默认也是单点的，而 dns 至关重要，只要一挂瞬间整个集群全部 `game over`；**不过暂时还是没有发现能在 init 时候创建多个 dns 的方法；不过在集群创建后可以通过 `kubectl edit deploy kube-dns` 的方式修改其副本数量，让其创建多个副本即可**

### 六、永远的 v1.4.4 

在一开始 kubeadm 创建集群时，采用的基础组件基本都是写死的，不过现在增加了 `--use-kubernetes-version` 选项，在 init 时使用该选项可以指定使用的基础组件(kube-proxy、apiserver 等)的版本，如 `kubeadm init --use-kubernetes-version v1.4.6` 即可使用 1.4.6 的镜像，目前最新版本的 rpm kubelet 版本为 1.4.4，从目前测试来看 1.4.4 的 kubelet 与 1.4.6 的其他版本组件一起运行尚未出现问题，不过最好在准备超版本运行之前，把 kubelet 的二进制文件也换成相应版本的

### 七、reset 让你一无所有

kubeadm 在 `alpha` 时官方文档页面提供了重建集群脚本，如下

``` sh
systemctl stop kubelet;
docker rm -f -v $(docker ps -q);
find /var/lib/kubelet | xargs -n 1 findmnt -n -t tmpfs -o TARGET -T | uniq | xargs -r umount -v;
rm -r -f /etc/kubernetes /var/lib/kubelet /var/lib/etcd;
```

从脚本上看很容易知道**第二条命令很危险**，他会干掉所有正在运行的容器，如果你的 node 上恰好有 `docker-compose` 启动的重要服务，这么这一下后果可想而知；**kubeadm 到了 `alpha2` 之后，提供了 `kubeadm reset` 命令来重建集群，我已开始以为这是个很好的事情，既然重写了肯定很好用；但是上帝总是跟你讲 'Hello World'，经过测试(实际上是躺枪了)我发现 reset 其实就是把这四条 shell 命令封装一起变成一个 `kubeadm reset` 而已，所以说此命令慎用，不行就用上面的脚本手动档删除，否则一条 `reset` 倾家荡产**


**未完待续，欢迎补充，如果有坑继续添加......**

> 本文参考 [kubeadm reference](http://kubernetes.io/docs/admin/kubeadm/)

转载请注明出处，本文采用 [CC4.0](http://creativecommons.org/licenses/by-nc-nd/4.0/) 协议授权
