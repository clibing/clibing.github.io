---
layout: post
title: Kubernetes Deployment yml说明
categories: [Kubernetes, Linux]
description: Kubernetes Deployment 部署文件说明，方便快速理解
keywords: kubernetes,Linux
---

#### HttpClient 工具类

```java
package cn.linuxcrypt.utils;

import org.apache.http.*;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.ResponseHandler;
import org.apache.http.client.config.CookieSpecs;
import org.apache.http.client.config.RequestConfig;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpRequestBase;
import org.apache.http.client.protocol.HttpClientContext;
import org.apache.http.config.ConnectionConfig;
import org.apache.http.config.Registry;
import org.apache.http.config.RegistryBuilder;
import org.apache.http.conn.ConnectionKeepAliveStrategy;
import org.apache.http.conn.socket.ConnectionSocketFactory;
import org.apache.http.conn.socket.PlainConnectionSocketFactory;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.entity.ContentType;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.DefaultHttpRequestRetryHandler;
import org.apache.http.impl.conn.PoolingHttpClientConnectionManager;
import org.apache.http.message.BasicHeader;
import org.apache.http.message.BasicHeaderElementIterator;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.protocol.HTTP;
import org.apache.http.protocol.HttpContext;
import org.apache.http.ssl.SSLContextBuilder;
import org.apache.http.util.Args;
import org.apache.http.util.EntityUtils;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.CodingErrorAction;
import java.security.cert.X509Certificate;
import java.util.*;

public final class HttpClients {
    // 设置整个连接池最大连接数
    private static int POOL_MAX_TOTAL = 2;
    /**
     * 设置整个连接池最大连接数
     *
     * @param maxTotal
     */
    public static void setPoolMaxTotal(int maxTotal) {
        synchronized (HttpClients.class) {
            POOL_MAX_TOTAL = maxTotal;
            HttpClientPool.setMaxTotal(maxTotal);
        }
    }

    /**
     * http 连接池
     */
    static class HttpClientPool {
        private static PoolingHttpClientConnectionManager poolingHttpClientConnectionManager = null;
        // 设置每个路由上的默认连接个数，setMaxPerRoute则单独为某个站点设置最大连接个数。
        private static final int POOL_MAX_PER_ROUTER = 1;
        private static final String DEFAULT_USER_AGENT = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:60.0) Gecko/20100101 Firefox/60.0";
        // keepalive
        private static int DEFAULT_KEEP_ALIVE = 30 * 1000;
        /**
         * 从连接池中获取请求连接的超时时间 单位毫秒
         * -1: 系统默认的超时时间，内核级配置
         * 0: 无限制。
         * 具体参考{@link org.apache.http.client.config.RequestConfig#getConnectionRequestTimeout()}
         */
        public static final int DEFAULT_CONNECTION_REQUEST_TIMEOUT = -1;

        // 默认连接超时时间
        public static final int DEFAULT_CONNECT_TIMEOUT = 10000;

        // 默认socket读取数据超时时间,具体的长耗时请求中(如文件传送等)必须覆盖此设置
        public static final int DEFAULT_SO_TIMEOUT = 15000;

        static {
            Registry<ConnectionSocketFactory> socketFactoryRegistry = null;
            try {
                final SSLContext sslContext = SSLContextBuilder.create().build();
                sslContext.init(null, new TrustManager[]{
                        new X509TrustManager() {
                            public X509Certificate[] getAcceptedIssuers() {
                                return null;
                            }

                            public void checkClientTrusted(X509Certificate[] certs, String authType) {
                            }

                            public void checkServerTrusted(X509Certificate[] certs, String authType) {
                            }
                        }
                }, null);
                socketFactoryRegistry = RegistryBuilder
                        .<ConnectionSocketFactory>create()
                        .register("http", PlainConnectionSocketFactory.INSTANCE)
                        .register("https", new SSLConnectionSocketFactory(sslContext)).build();
            } catch (Exception e) {

            }

            poolingHttpClientConnectionManager = new PoolingHttpClientConnectionManager(socketFactoryRegistry);

            //连接池的最大连接数
            poolingHttpClientConnectionManager.setMaxTotal(POOL_MAX_TOTAL);

            /**
             * 设置每个路由上的默认连接个数，setMaxPerRoute则单独为某个站点设置最大连接个数。
             *
             * DefaultMaxPerRoute是根据连接到的主机对MaxTotal的一个细分；比如：
             * MaxtTotal=400 DefaultMaxPerRoute=200
             * 而我只连接到http://a.com时，到这个主机的并发最多只有200；而不是400；
             * 而我连接到http://a.com 和 http://b.com时，到每个主机的并发最多只有200；即加起来是400（但不能超过400；所以起作用的设置是DefaultMaxPerRoute。
             */
            poolingHttpClientConnectionManager.setDefaultMaxPerRoute(POOL_MAX_PER_ROUTER);

            // 默认连接配置
            ConnectionConfig connectionConfig = ConnectionConfig.custom()
                    .setMalformedInputAction(CodingErrorAction.IGNORE)
                    .setUnmappableInputAction(CodingErrorAction.IGNORE)
                    .setCharset(Consts.UTF_8)
                    .build();
            poolingHttpClientConnectionManager.setDefaultConnectionConfig(connectionConfig);
        }

        public static void setMaxTotal(int maxTotal) {
            poolingHttpClientConnectionManager.setMaxTotal(maxTotal);
        }

        /**
         * 增加默认的http 头
         *
         * @return
         * @{link https://www.cnblogs.com/lwhkdash/archive/2012/10/14/2723252.html}
         */
        private static Set<Header> defaultHeaders() {
            Set<Header> header = new HashSet<>();

            Header accept = new BasicHeader(HttpHeaders.ACCEPT,
                    "text/html,application/xhtml+xml,application/json,application/xml;q=0.9,*/*;q=0.8");
            header.add(accept);
            Header acceptEncoding = new BasicHeader(HttpHeaders.ACCEPT_ENCODING, "gzip, deflate");
            header.add(acceptEncoding);
            Header acceptLanguage = new BasicHeader(HttpHeaders.ACCEPT_LANGUAGE, "zh-CN,zh;q=0.8,en-US;q=0.5,en;q=0.3");
            header.add(acceptLanguage);
            Header connect = new BasicHeader(HttpHeaders.CONNECTION, "keep-alive");
            header.add(connect);
            Header acceptCharset = new BasicHeader(HttpHeaders.ACCEPT_CHARSET, Consts.UTF_8.name());
            header.add(acceptCharset);

            // DO NOT TRACK的缩写，要求服务器程序不要跟踪记录用户信息。DNT: 1 (开启DNT) DNT: 0 (关闭DNT)火狐，safari,IE9都支持这个头域，并且于2011年3月7日被提交至IETF组织实现标准化
            Header dnt = new BasicHeader("DNT", "1");
            header.add(dnt);

            return header;
        }

        /**
         * 获取 HttpClient
         * @return
         */
        public static CloseableHttpClient getHttpClient() {
            return getHttpClient(DEFAULT_SO_TIMEOUT, DEFAULT_CONNECT_TIMEOUT, 0);
        }

        /**
         * 默认keepAlive策略：如果响应中存在服务器端的keepAlive超时时间则返回该时间否则返回默认的
         */
        public static class DefaultConnectionKeepAliveStrategy implements ConnectionKeepAliveStrategy {
            public long getKeepAliveDuration(HttpResponse response, HttpContext context) {
                HeaderElementIterator it = new BasicHeaderElementIterator(response.headerIterator(HTTP.CONN_KEEP_ALIVE));
                while (it.hasNext()) {
                    HeaderElement he = it.nextElement();
                    String param = he.getName();
                    String value = he.getValue();
                    if (value != null && param.equalsIgnoreCase("timeout")) {
                        try {
                            return Long.parseLong(value) * 1000;
                        } catch (NumberFormatException ignore) {
                        }
                    }
                }
                return DEFAULT_KEEP_ALIVE; //默认30秒
            }
        }

        public static CloseableHttpClient getHttpClient(int socketTimeout, int connectTimeout, int retryCount) {
            RequestConfig globalConfig = RequestConfig.custom()
                    .setCookieSpec(CookieSpecs.IGNORE_COOKIES)
                    .setSocketTimeout(socketTimeout)
                    .setConnectionRequestTimeout(DEFAULT_CONNECTION_REQUEST_TIMEOUT)
                    .setConnectTimeout(connectTimeout)
                    .build();

            CloseableHttpClient closeableHttpClient = org.apache.http.impl.client.HttpClients
                    .custom()
                    .setConnectionManager(poolingHttpClientConnectionManager)
                    .setKeepAliveStrategy(new DefaultConnectionKeepAliveStrategy())
                    // 另外设置http client的重试次数，默认是3次；当前是禁用掉（如果项目量不到，这个默认即可）
                    .setRetryHandler(new DefaultHttpRequestRetryHandler(retryCount, false))
                    .setUserAgent(DEFAULT_USER_AGENT)
                    .setDefaultHeaders(defaultHeaders())
                    .setDefaultRequestConfig(globalConfig)
                    .setConnectionManagerShared(true)
                    .evictExpiredConnections()// 开启超时清理线程
                    .build();

            return closeableHttpClient;
        }
    }

    /**
     * 对于特殊请求(比如请求涉及到cookie的处理,鉴权认证等),默认的一些配置已经满足不了了,
     * 这时就可以使用一个独立于全局的配置来执行请求,这个独立于全局,又不会干扰其他线程的请求执行的机制就是使用HttpClientContext,
     * 该设置类用于对已经提供的一个基于全局配置的副本,来设置一些配置(见HttpClientContext.setXxx)
     */
    public static interface HttpClientContextSetter {
        public void setHttpClientContext(HttpClientContext context);
    }

    /**
     * <p>执行http请求</p>
     *
     * @param httpMethod              - HTTP请求(HttpGet、HttpPost等等)
     * @param httpClientContextSetter - 可选参数,请求前的一些参数设置(如：cookie、鉴权认证等)
     * @param responseHandler         - 必选参数,响应处理类(如针对httpstatu的各种值做一些策略处理等等)
     * @return 推荐使用 org.apache.http.impl.client.CloseableHttpClient#execute( org.apache.http.HttpHost,
     * org.apache.http.HttpRequest,
     * org.apache.http.client.ResponseHandler,
     * org.apache.http.protocol.HttpContext)
     */
    public static <T> T doHttpRequest(HttpRequestBase httpMethod, HttpClientContextSetter httpClientContextSetter, ResponseHandler<T> responseHandler) {
        Args.notNull(httpMethod, "Parameter 'httpMethod' can not be null!");
        Args.notNull(responseHandler, "Parameter 'responseHandler' can not be null!");
        CloseableHttpResponse response = null;
        try {
            if (httpClientContextSetter != null) {
                HttpClientContext context = HttpClientContext.create();
                httpClientContextSetter.setHttpClientContext(context);
                response = HttpClientPool.getHttpClient().execute(httpMethod, context);
            } else {
                response = HttpClientPool.getHttpClient().execute(httpMethod);
            }
            return response == null ? null : responseHandler.handleResponse(response);
        } catch (Exception e) {
            throw new RuntimeException(e.getMessage(), e);
        } finally {
            if (response != null) {
                try {
                    response.close();
                } catch (IOException e) {
                }
            }
        }
    }

    /**
     * 默认的处理返回值为String的ResponseHandler
     */
    public static class DefaultStringResponseHandler implements ResponseHandler<String> {
        /**
         * 默认响应html字符集编码
         */
        private Charset defaultCharset = Consts.UTF_8;

        public DefaultStringResponseHandler() {
            super();
        }

        public DefaultStringResponseHandler(String defaultCharset) {
            super();
            this.defaultCharset = Charset.forName(defaultCharset);
        }

        public Charset getDefaultCharset() {
            return defaultCharset;
        }

        public void setDefaultCharset(Charset defaultCharset) {
            this.defaultCharset = defaultCharset;
        }

        public String handleResponse(HttpResponse response) throws ClientProtocolException, IOException {
            HttpEntity httpEntity = response.getEntity();
            if (httpEntity != null) {
                return EntityUtils.toString(httpEntity, defaultCharset == null ? ContentType.getOrDefault(httpEntity).getCharset() : defaultCharset);
            }
            return null;
        }
    }

    /**
     * <p>根据URL和参数创建HttpPost对象</p>
     *
     * @param url
     * @param paramMap
     * @return
     */
    public static HttpPost createHttpPost(String url, Map<String, String> paramMap) {
        try {
            HttpPost httpPost = new HttpPost(url);
            if (paramMap != null && !paramMap.isEmpty()) {
                List<NameValuePair> params = new ArrayList<NameValuePair>();
                for (Map.Entry<String, String> entry : paramMap.entrySet()) {
                    params.add(new BasicNameValuePair(entry.getKey(), entry.getValue()));
                }
                UrlEncodedFormEntity formEntity = new UrlEncodedFormEntity(params, Consts.UTF_8.name());
                httpPost.setEntity(formEntity);
            }
            return httpPost;
        } catch (Exception e) {
            throw new RuntimeException(e.getMessage(), e);
        }
    }

    public static String get(String url) {
        HttpGet httpGet = new HttpGet(url);
        String value = doHttpRequest(httpGet, null, new DefaultStringResponseHandler());
        return value;
    }

    public static String post(String url, Map<String, String> param){
        HttpPost post = createHttpPost(url, param);
        return doHttpRequest(post, null, new DefaultStringResponseHandler());
    }
}
```

#### 分析

[参考1](https://blog.csdn.net/undergrowth/article/details/77341760)
[参考2](https://blog.csdn.net/undergrowth/article/details/77203668)
[参考3](http://www.cnblogs.com/kingszelda/p/8988505.html)