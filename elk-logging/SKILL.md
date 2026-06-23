---
name: elk-logging
description: ELK 日志方案 — Log4j2 JSON 输出、Filebeat 采集、Elasticsearch 索引、Kibana 查询与告警、Spring Boot 整合
---

# ELK 日志方案

## 架构

```
应用 → Log4j2 JSON 文件 → Filebeat → Elasticsearch → Kibana
                                      ↑
                                Logstash（可选，复杂清洗时加）
```

### 推荐走文件（不推荐 Log4j2 直连 ES）

| 方式 | 可靠性 | 复杂度 |
|------|--------|--------|
| Log4j2 → JSON 文件 → Filebeat → ES | ✅ 高 | 低 |
| Log4j2 → Socket → Logstash → ES | ⚠️ 中 | 中 |
| Log4j2 → ES Appender | ❌ 低 | 低 |

---

## Log4j2 配置

### JSON 格式输出

```xml
<Appenders>
  <RollingFile name="JsonFile" fileName="/logs/app.json.log"
               filePattern="/logs/app-%d{yyyy-MM-dd}.%i.json.log.gz">
    <JsonLayout compact="true" eventEol="true"
                properties="true" objectMessageAsJsonObject="true">
      <KeyValuePair key="service" value="user-service" />
      <KeyValuePair key="env" value="${env:ENV:-dev}" />
    </JsonLayout>
    <Policies>
      <TimeBasedTriggeringPolicy interval="1" modulate="true" />
      <SizeBasedTriggeringPolicy size="500MB" />
    </Policies>
  </RollingFile>
</Appenders>

<Loggers>
  <AsyncRoot level="INFO">
    <AppenderRef ref="JsonFile" />
  </AsyncRoot>
</Loggers>
```

### 标准日志字段

```json
{
  "timestamp": "2024-01-15T10:30:00.123+08:00",
  "level": "ERROR",
  "logger": "com.example.UserService",
  "thread": "http-nio-8080-exec-3",
  "message": "用户登录失败",
  "service": "user-service",
  "env": "prod",
  "traceId": "a1b2c3d4e5f6",
  "spanId": "abc123",
  "userId": 10086,
  "duration": 152,
  "exception": "NullPointerException",
  "stackTrace": "..."
}
```

### MDC 自动注入 traceId

```java
@Component
public class TraceFilter implements Filter {
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) {
        String traceId = request.getHeader("X-Trace-Id");
        if (traceId == null) traceId = UUID.randomUUID().toString();
        MDC.put("traceId", traceId);
        MDC.put("userId", SecurityContext.getUserId());
        try { chain.doFilter(request, response); }
        finally { MDC.clear(); }
    }
}
```

`<JsonLayout properties="true" />` 自动将 MDC 中的 traceId、userId 等写入 JSON。

### Spring Boot 依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-logging</artifactId>
        </exclusion>
    </exclusions>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-log4j2</artifactId>
</dependency>
```

---

## Filebeat 配置

```yaml
filebeat.inputs:
  - type: log
    paths:
      - /logs/*.json.log
    json.keys_under_root: true
    json.add_error_key: true
    json.message_key: message

output.elasticsearch:
  hosts: ["http://es01:9200", "http://es02:9200"]
  index: "myapp-%{+yyyy.MM.dd}"
  worker: 4
  bulk_max_size: 2000
  flush_interval: 3s

queue.mem:
  events: 4096
  flush.min_events: 512
  flush.timeout: 1s
```

---

## Elasticsearch 索引模板

```json
PUT _template/myapp-logs
{
  "index_patterns": ["myapp-*"],
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1,
    "refresh_interval": "30s"
  },
  "mappings": {
    "dynamic_templates": [
      {
        "strings_as_keyword": {
          "match_mapping_type": "string",
          "mapping": {
            "type": "keyword",
            "ignore_above": 1024,
            "fields": { "text": { "type": "text" } }
          }
        }
      }
    ],
    "properties": {
      "timestamp": { "type": "date" },
      "level":     { "type": "keyword" },
      "logger":    { "type": "keyword" },
      "message":   { "type": "text" },
      "traceId":   { "type": "keyword" },
      "userId":    { "type": "long" },
      "duration":  { "type": "integer" },
      "service":   { "type": "keyword" },
      "env":       { "type": "keyword" },
      "status":    { "type": "short" }
    }
  }
}
```

`level`、`traceId`、`service` → **keyword**（精确匹配+聚合），`message` → **text**（分词搜索）。

---

## Kibana

### 索引模式

Management → Stack Management → Index Patterns → 创建 `myapp-*`

### KQL 查询

```kql
level: "ERROR"
traceId: "a1b2c3d4e5f6"
duration > 1000
level: "ERROR" AND service: "user-service"
NOT level: "DEBUG"
```

### Dashboard 可视化

| 图表 | 用途 |
|------|------|
| 柱状图 | 日志量/错误量时间趋势 |
| 饼图 | 错误类型分布、服务分布 |
| 数据表 | Top N 慢接口、Top N 错误日志 |
| Tag Cloud | 高频错误关键词 |

### 告警规则

```
Stack Management → Rules → Create Rule
Query: level: "ERROR"
条件: count > 50  in 5m
行动: Webhook (飞书/钉钉)
```

---

## 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| 搜不到新日志 | 索引模式没刷新 | 刷新字段列表 |
| level 无法聚合 | 被映射为 text | 改 keyword |
| 查询慢 | 分片太多 | 缩小时间范围、减少分片 |
| ES 挂了解耦 | Filebeat 有缓冲队列 | ✅ 不阻塞应用 |
