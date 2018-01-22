---
layout: post
title: Java中init和clinit方法的区别
categories: [Java, J2SE]
description: clinit在jvm第一次加载class时调用，init在实例创建出来的时候调用
keywords: Java,J2SE
---

### 调用时机 

+ clinit在jvm第一次加载class文件时调用，包括`静态变量初始化语句和静态块的执行`
+ init在实例创建出来的时候调用，包括调用new操作符；调用Class或java.lang.reflect.Constructor对象的newInstance()方法；调用任何现有对象的clone()方法；通过java.io.ObjectInputStream类的getObject()方法反序列化。

### 详情 

1. clinit方法是由编译器自动收集类中的所有类变量的赋值动作和静态语句块（static）中的语句合并产生的，编译器收集的顺序是由语句在源文件中出现的顺序所决定的，静态语句块只能访问到定义在静态语句块之前的变量，点贵在他之后的变量，在前面的静态语句块中可以赋值但不能访问。
    ```java
    public class Test{
      static{
        i = 0;//给变量赋值可以正常通过
        System.out.println(i);//这句编译器会提示“非法向前引用”
      }
      static int i = 1;
    }
    ````
2. clinit方法与类的构造函数（或者说实例构造器中的<init>()方法）不同， 它不需要显示的调用父类构造器，虚拟机会保证在`子类的<init>()方法执行之前，父类的<clinit>()方法已经执行完毕`。因为在虚拟机中第一个被执行的<clinit>()方法的类肯定是java.lang.Object
3. 由于父类的clinit方法先执行，也就意味着父类中定义的静态语句块要优先于子类类的变量赋值操作。
4. clinit方法对于类或者接口来说并不是必须的，如果一个类没有静态语句块，也就没有变量的赋值操作，那么编译器可以不为这个类生成<clinit>()方法。
5. 接口中不能使用静态语句块，但仍然可以有变量初始化的赋值操作，因此接口与类一样都会生成<clinit>()方法。但接口与类不同，执行接口的<clinit>()方法不需要先执行父接口的<clinit>()方法。只有当父接口中定义的变量使用时，父接口才会初始化。另外，接口的实现类在初始化时也一样不会执行接口的<clinit>()方法。
6. 虚拟机会保证一个类的<clinit>()方法在多线程环境中被正确地加锁、同步，如果多个线程同时去初始化一个类，那么只有一个线程去执行这个类的<clinit>()方法中有耗时很长的操作，就可能造成多个线程阻塞。

### 举例

````java
    class Single {
        private static Single single = new Single();
        public static int count1;
        public static int count2 = 0;

        private Single() {
            count1++;
            count2++;
        }
        public static Single getInstance() {
            return single;
        }
    }

    public class Test {
        public static void main(String[] args) {
            Single single = Single.getInstance();
            System.out.println("count1=" + single.count1);
            System.out.println("count2=" + single.count2);
        }
    }
````

输出结果：

` javac Test.java && java Test `

````text
clibing:~$:count1=1
clibing:~$:count2=0
````

原因：

1. Single single = Single.getInstance();调用了类的Single`调用了类的静态方法，触发类的初始化`
2. 类加载的时候在准备过程中为类的静态变量分配内存并初始化默认值 single=null count1=0,count2=0
3. 类初始化化，为类的静态变量赋值和执行静态代码块。single赋值为new Single()调用类的构造方法
4. 调用类的构造方法后count=1;count2=1
5. 继续为count1与count2赋值,此时count1没有赋值操作,所有count1为1,但是count2执行赋值操作就变为0
