---
layout: post
title: Java 8中的常用函数式接口
categories: [Java]
description: Java 8中的常用函数式接口
keywords: Java,函数式接口
---

### Java 8中的常用函数式接口

| 函数式接口 | 函数描述符 | 原始类型特化 |
| :---------: | :--------: | :--------- |
| Predicate<T> | T->boolean | IntPredicate, LongPredicate, DoublePredicate |
| Consumer<T> | T->void | IntConsumer,LongConsumer, DoubleConsumer |
| Function<T,R> | T->R | IntFunction<R>, IntToDoubleFunction, IntToLongFunction,<br/> LongFunction<R>, LongToDoubleFunction, LongToIntFunction,<br/> DoubleFunction<R>, ToIntFunction<T>, ToDoubleFunction<T>,<br/> ToLongFunction<T> |
| Supplier<T> | ()->T | BooleanSupplier,IntSupplier, LongSupplier, DoubleSupplier |
| UnaryOperator<T> | T->T | IntUnaryOperator, LongUnaryOperator, DoubleUnaryOperator |
| BinaryOperator<T> | (T,T)->T | IntBinaryOperator, LongBinaryOperator, DoubleBinaryOperator |
| BiPredicate<L,R> | (L,R)->boolean | |
| BiConsumer<T,U> | (T,U)->void | ObjIntConsumer<T>, ObjLongConsumer<T>, ObjDoubleConsumer<T> |
| BiFunction<T,U,R> | (T,U)->R | ToIntBiFunction<T,U>, ToLongBiFunction<T,U>, ToDoubleBiFunction<T,U> |

### 测试

对于下列函数描述符(即Lambda表达式的签名),你会使用哪些函数式接口?在上表中
可以找到大部分答案。作为进一步练习,请构造一个可以利用这些函数式接口的有效Lambda

#### 表达式

* T->R
* (int, int)->int
* T->void
* ()->T
* (T, U)->R

#### 答案

* Function<T,R> 它一般用于将类型T的对象转换为类型R的对象(比如Function<Apple, Integer> 用来提取苹果的重量)。
* IntBinaryOperator具有唯一一个抽象方法,叫作`applyAsInt`,它代表的函数描述符是`(int, int)->int`。
* Consumer<T> 具有唯一一个抽象方法叫作`accept`,代表的函数描述符是`T->void`。
* Supplier<T> 具有唯一一个抽象方法叫作`get`,代表的函数描述符是`()->T`。或者,`Callable<T>`具有唯一一个抽象方法叫作`call`,代表的函数描述符是`()->T`。
* BiFunction<T,U,R> 具有唯一一个抽象方法叫作`apply`,代表的函数描述符是`(T,U)->R`。

### 总结

| 使用案例 | Lambda 的例子 | 对应的函数式接口 |
| :---------: | :-------- | :--------- |
| 布尔表达式 | (List<String> list) -> list.isEmpty() | Predicate<List<String>> |
| 创建对象 | () -> new Apple(10) | Supplier<Apple> |
| 消费一个对象 | (Apple a) -> System.out.println(a.getWeight()) | Consumer<Apple>
| 从一个对象中选择/提取 | (String s) -> s.length() | Function<String, Integer> 或 ToIntFunction<String>|
| 合并两个值 | (int a, int b) -> a * b | IntBinaryOperator |
| 比较两个对象 | (Apple a1, Apple a2) -> a1.getWeight().compareTo(a2.getWeight()) | Comparator<Apple> 或 BiFunction<Apple, Apple, Integer> 或 ToIntBiFunction<Apple, Apple> |
