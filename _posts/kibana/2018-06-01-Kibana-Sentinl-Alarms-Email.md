---
layout: post
title: Kibana统计nginx之报警
categories: [Linux, Javascript, ELK, Nginx]
description: 统计线上Nginx日志，将超时响应和>=500状态的请求抓取并整理，发送到指定邮箱
keywords: Kibana, Sentinl, Nginx
---

### 需求

对线上的Nginx入口的日志进行统计与报警，

以下是json格式的数据，数据已经存储elasticsearch中，并且通过kibana进行管理

### 报警

##### 1. 采用sentinl插件，进行数据处理

* [GitHub](https://github.com/sirensolutions/sentinl/releases) `注意: 采用elasticsearch对应的版本`
* [文档](http://sentinl.readthedocs.io/en/latest/)

##### 2. 安装sentinl插件，建议先下载,然后离线安装,在线安装容易断网。速度特别慢
````
${KIBANA_HOME}/kibana-plugin install file:/tmp/sentinl-version.zip
````

##### 3. 配置kibana的启动sentinl的邮件功能

```yml
# /etc/kibana/kibana.yml 在最后追加以下内容
sentinl:
  settings:
    email:
      active: true
      user: no-reply@xx.com
      password: xxxx
      host: mail.xxxx.com
      ssl: true
    report:
      active: true
      tmp_path: /tmp/
```
重启kibana重新加载配置并生效

###### 4. 登录kibana管理UI，点击`Sentinl`菜单创建`Watchers`

直接编辑raw配置文件，如果没有先保存一个，然后直接编辑raw

```yml
#Watchers raw
{
  "_index": "watcher",
  "_type": "sentinl-watcher",
  "_id": "x8vo6ooqek8-94ql4qei88q-yx9dnrq7uth",
  "_version": 127,
  "found": true,
  "_source": {
    "title": "reponse_code(api.xx.com)",
    "disable": false,
    "report": false,
    "trigger": {
      "schedule": {
        "later": "every 30 minutes"
      }
    },
    "input": {
      "search": {
        "request": {
          "index": [],
          "body": {
            "size": 128,
            "query": {
              "bool": {
                "must": [
                  {
                    "range": {
                      "nginx.access.response_code": {
                        "gte": 500
                      }
                    }
                  },
                  {
                    "match": {
                      "nginx.access.host": "api.xx.com"
                    }
                  },
                  {
                    "range": {
                      "@timestamp": {
                        "from": "now-1h"
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      }
    },
    "condition": {
      "script": {
        "script": "payload.hits.total > 100"
      }
    },
    "actions": {
      "api.xx.com": {
        "throttle_period": "0h1m0s",
        "email_html": {
          "to": "xx@xx.com",
          "from": "xx-xx@xx.com",
          "subject": "Sentinl Alarm (api.xx.com 1h)",
          "priority": "high",
          "html": "统计响应状态码：500-505<br/> 一共 {{ payload.hits.total }} <br/> 只获取最近的128(当前{{payload.hits.hits.length}})记录，进行展示。<br/> 具体请求url如下<br/> <pre>{{payload.text}}</pre><br/>",
          "save_payload": false
        }
      }
    },
    "transform": {
      "script": {
        "script": "payload.statistics = {}; payload.hits.hits.forEach( function(hit){ var url = hit._source.nginx.access.host + hit._source.nginx.access.url; if (url in payload.statistics){ payload.statistics[url] = payload.statistics[url] + 1; }else{ payload.statistics[url] = 1; } }); function jsonToText(jsonval){ var html = 'request url   \\t times ->  statistics times\\n'; for (var key in jsonval){ html += key +' \\t times  -> '+ jsonval[key] +'\\n'; } return html; }; payload.text=jsonToText(payload.statistics);"
      }
    }
  }
}
```

transform script
```javascript
// 注意 字符串使用 单引号'进行包装，如果换行使用\\n 制表格\\t
payload.statistics = {}; 
payload.hits.hits.forEach( 
    function(hit){ 
        var url = hit._source.nginx.access.host + hit._source.nginx.access.url; 
        if (url in payload.statistics){ 
            payload.statistics[url] = payload.statistics[url] + 1; 
        } else{ 
            payload.statistics[url] = 1; 
        } 
}); 
function jsonToText(jsonval){
    var html = 'request url  \\t times ->  statistics times\\n';
    for (var key in jsonval){
       html += key +' \\t times -> '+ jsonval[key] +'\\n';
    }
    return html;
}
payload.text= jsonToText(payload.statistics);
```

###### 5. 脚本执行流程

* 1. input中根据query向elasticsearch查询
* 2. 根据condition判断结果是否满足
* 3. 如果满足进行transform数据处理
* 4. 根据处理后的数据进行actions操作

###### 6. 注意事项

* transform 阶段script外面是双引号包裹，内部如果使用双引号需要增加反斜杠，内部脚本如果换行需要使用`\\n`
* transform和condition阶段的script脚本需要是一行，所以编写js脚本需要用分号`;`分割防止一行出现错误编译
* actions中发送有邮件有两种`email`和`email_html`， 
  * `email`发送的内容在body中，次数数据都会被编码。
  * `email_html`发送的内容在html中，此时body失效，只支持html解析，但是在{{}}中的数据不会解析html
* query阶段，elasticsearch默认是size是10，所以根据每次查询结果进行评估选择合适的常量

### 附录

* [个人Github](https://github.com/clibing/dockerfile) 个人编写的一些dockerfile，支持armhf、arrch64、x86_64平台
* [Sentinal GitHub](https://github.com/sirensolutions/sentinl/releases) `注意: 采用elasticsearch对应的版本`
* [文档](http://sentinl.readthedocs.io/en/latest/)