---
layout: post
title: Kubernetes Deployment yml说明
categories: [Kubernetes, Linux]
description: Kubernetes Deployment 部署文件说明，方便快速理解
keywords: kubernetes,Linux
---

部署 调度

```yml
apiVersion: apps/v1
kind: Deployment
# 元数据
metadata:
  name: linuxcrypt-web
  labels:
    app: linuxcrypt-web
# 属性
spec:
  # 副本数量
  replicas: 3
  # 滚动升级时，容器准备就绪时间最少为30s
  minReadySeconds: 30 
  # 选择器
  selector:
    # 匹配lables， 从metadata.labels中匹配
    matchLabels:
      # 匹配lables， 从metadata.labels.app中匹配
      app: linuxcrypt-web
  strategy:
    # 升级方式 recreate和rollingUpdate
    # recreate--删除所有已存在的pod，重新创建新的; recreate策略将会在升级过程中，停止服务，但会保证应用版本一致；
    # rollingUpdate--滚动升级，逐步替换的策略，同时滚动升级时，支持更多的附加参数，例如设置最大不可用pod数量，最小升级间隔时间等等。使用rollingUpdate不会中断服务，但会导致调用时出现应用版本不一致的情况，输出内容不一致。
    #
    type: RollingUpdate
    # 由于replicas为3个， 则整个升级，pod个数在2-4个之间
    rollingUpdate:
      # 滚动升级时会先启动1个pod
      maxSurge: 1
      # 滚表示滚动升级时允许的最大Unavailable的pod个数。由于replicas为3,则整个升级,pod个数在2-4个之间
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: linuxcrypt-web
    spec:
      # k8s将会给应用发送SIGTERM信号，可以用来正确、优雅地关闭应用,默认为30秒
      # 如果需要更优雅地关闭，则可以使用k8s提供的pre-stop lifecycle hook 的配置声明，将会在发送SIGTERM之前执行
      terminationGracePeriodSeconds: 60 
      containers:
      - name: linuxcrypt-web
        image: hub.docker.com/linuxcrypt-web:2.0.0-20180607.0749
        #command: [ "sh", "/etc/run.sh"]
        ports:
        - name: linuxcrypt-web
          containerPort: 8080
          protocol: TCP
        # 容器资源分配
        resources: 
          requests: 
            cpu: 0.05 
            memory: 16Mi 
          limits: 
            cpu: 0.1 
            memory: 32Mi
        # 表示container是否以及处于可接受service请求的状态了。如果ReadinessProbe失败，endpoints controller将会从service所匹配到的endpoint列表中移除关于这个container的IP地址。
        # 因此对于Service匹配到的endpoint的维护其核心是ReadinessProbe。默认Readiness的初始值是Failure，如果一个container没有提供Readiness则被认为是Success。
        #
        # readinessProbe是K8S认为该pod是启动成功的，这里根据每个应用的特性，自己去判断，可以执行command，也可以进行httpGet。
        readinessProbe:
          # exec:
          #   command: 
          #   - cat
          #   - /tmp/health
          httpGet:
            path: /health
            port: 8080
            # host: dig.chouti.com
            # scheme: HTTP
          # 用来表示初始化延迟的时间，也就是告诉监测从多久之后开始运行，单位是秒
          initialDelaySeconds: 60
          # 用来表示监测的超时时间，如果超过这个时长后，则认为监测失败
          timeoutSeconds: 10
          # 告诉kubelet每5秒探测一次
          periodSeconds: 5
          # 探测失败后成功1次就认为是成功的
          successThreshold: 1
          # 探测失败阈值
          failureThreshold: 3
        # 表示container是否处于live状态。如果LivenessProbe失败，LivenessProbe将会通知kubelet对应的container不健康了。
        # 随后kubelet将kill掉container，并根据RestarPolicy进行进一步的操作。
        # 默认情况下LivenessProbe在第一次检测之前初始化值为Success，如果container没有提供LivenessProbe，则也认为是Success；
        # 
        # livenessProbe是K8S认为该pod是存活的，不存在则需要kill掉，然后再新启动一个，以达到RS指定的个数。
        livenessProbe:  
          httpGet:
            path: /health
            port: 8080
          # 用来表示初始化延迟的时间，也就是告诉监测从多久之后开始运行，单位是秒
          initialDelaySeconds: 60
          # 告诉kubelet每5秒探测一次
          periodSeconds: 5
          # 探测失败后成功1次就认为是成功的
          successThreshold: 1
          # 探测失败阈值
          failureThreshold: 3
          # 用来表示监测的超时时间，如果超过这个时长后，则认为监测失败
          timeoutSeconds: 10
```

常用命令

* 查看部署状态
```shell
kubectl rollout status deployment/linuxcrypt-web
kubectl describe deployment linuxcrypt-web

Name:                   linuxcrypt-web
Namespace:              default
CreationTimestamp:      Thu, 07 Jun 2018 14:45:08 +0800
Labels:                 app=linuxcrypt-web
Annotations:            deployment.kubernetes.io/revision=6
Selector:               app=linuxcrypt-web
Replicas:               4 desired | 4 updated | 4 total | 4 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  0 max unavailable, 1 max surge
Pod Template:
  Labels:  app=linuxcrypt-web
  Containers:
   linuxcrypt-web:
    Image:        hub.docker.com/linuxcrypt-web:2.0.0-20180607.0910
    Port:         8080/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Progressing    True    NewReplicaSetAvailable
  Available      True    MinimumReplicasAvailable
OldReplicaSets:  <none>
NewReplicaSet:   linuxcrypt-web-d5f8c55c9 (4/4 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  1h    deployment-controller  Scaled up replica set linuxcrypt-web-d5f8c55c9 to

```
* 升级
```shell
kubectl set image deployment linuxcrypt-web linuxcrypt-web=image-name:tag
``
* 暂停升级
```shell
kubectl rollout pause deployment linuxcrypt-web
```
* 继续升级 
```shell
kubectl rollout resume deployment linuxcrypt-web
```
* 回滚
```shell
kubectl rollout undo deployment linuxcrypt-web
```
* 查看deployments版本 
```shell
kubectl rollout history deployment
kubectl rollout history deployment linuxcrypt-web

deployments "linuxcrypt-web"
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>
```
* 回滚到指定版本
```shell
kubectl rollout undo deployment linuxcrypt-web --to-revision=2 # 2 从查看deployments版本查看
```

