---
layout: post
title: Java内存优化之Reference分析
categories: [Java, J2SE]
description: Java的内存优化之Reference，SoftReference、WeakReference、StrongReference
keywords: Java,J2SE
---

### 引用对象类型定义
首先，引用对象在Java定义中有三种类型，从弱到强依次为：软引用、弱引用与虚引用，三种级别也各有所不同(软引用>弱引用)。本文浅析下软引用与弱引用。大概的解释，软引用适合应用在需要cache的场景，一般面向实现内存敏感的缓存；弱引用则是适用在某些场景为了无法防止被回收的规范性映射，它优先级最低，一般与引用队列联合使用。

### 详情

#### 强引用（默认存在）

强引用，是在实际开发中最为普遍的引用。有时候你开发的时候，申请一个内存空间的时候，就已经是强引用了。例如：
````java
Object obj = new Object(); // 强引用
````
在强引用中，如果不让该对象指向为空，垃圾回收器绝对不会回收它。除非当出现内存空间不足的时候。jvm抛出oom导致程序异常种植的时候，才会回收具有强引用的对象来解决内存空间不足问题。
````java
Object obj = new Object(); // 强引用
obj = null;// 这时候为垃圾回收器回收这个对象，至于什么时候回收，取决于垃圾回收器的算法。
System.gc();// 手动出发
````

#### 软引用（SoftReference ）

软引用对象也比较好理解，它是一个比较特殊的存在，拥有强引用的属性，又更加安全。如果有一个对象具有软引用。在内存空间足够的情况下，除非`内存空间接近临界值、jvm即将抛出oom的时候`，垃圾回收器才会将该引用对象进行回收，避免了系统内存溢出的情况。（前提也是对象指向不为空）因此，SoftReference 引用对象非常适合实现内存敏感的缓存，例如加载图片的时候，bitmap缓存机制。
````java
String value = new String(“admin”);
SoftReference sfRefer = new SoftReference (value );
sfRefer.get();//可以获得引用对象值
````
#### 弱引用（WeakReference）

1. 顾名思义，一个具有弱引用的对象，与软引用对比来说，前者的生命周期更短。`当垃圾回收器扫描到弱引用的对象的时候，不管内存空间是否足够，都会直接被垃圾回收器回收`。不过也不用特别担心，垃圾回收器是一个优先级比较低的现场，因此不一定很快可以发现弱引用的对象。
````java
String value = new String(“sy”);
WeakReference weakRefer = new WeakReference(value );
System.gc();
weakRefer.get();//null
````
2. 在WeakReference指向的对象被回收后，WeakReference本身其实也就没有用了。Java提供了一个ReferenceQueue来保存这些所指向的对象已经被回收的reference。用法是在定义WeakReference的时候将一个ReferenceQueue的对象作为参数传入构造函数.
3. 一般用WeakReference引用的对象是有价值被cache， `而且很容易被重新被构建, 且很消耗内存的对象`。

### Soft与Weak
SoftReference和WeakReference一样，但被GC回收的时候需要多一个条件:
当系统内存不足时(GC是如何判定系统内存不足? 是否有参数可以配置这个threshold?)，SoftReference指向的object才会被回收。
正因为有这个特性，SoftReference比WeakReference更加适合做cache objects的reference. 因为它可以尽可能的retain cached objects, 减少重建他们所需的时间和消耗.
