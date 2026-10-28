# 配置与数据结构模板

| 文件 | 用途 | 状态 |
| --- | --- | --- |
| [learning.yaml](learning.yaml) | 应用层学习、记忆、检索与预算配置 | 拟新增 schema，需实现解析与校验 |
| [persona.yaml](persona.yaml) | 可信人设与场景风格 | 应用层风格值，不能原样发送到模型 SDK |
| [source.yaml](source.yaml) | 来源白名单与许可审核 | 默认未启用，审核后填写允许用途 |
| [wslc-settings.yaml](wslc-settings.yaml) | WSL Containers 参考会话配置 | 按实际硬件合并，不是普通 WSL2 配置 |
| [nonebot.env.example](nonebot.env.example) | NoneBot 反向 WebSocket 环境变量 | 替换令牌，不提交真实 .env |
| [napcat-connection.json](napcat-connection.json) | NapCat 连接字段示意 | 按部署版本填写，不覆盖完整账户配置 |
| [schema.sql](schema.sql) | SQLite 主实体与 FTS5 基础建表 | 空库语法示例，需补生产迁移与应用逻辑 |

模板与[完整开发方案](../docs/development-plan.md)保持对应。默认配额仅供试运行，启用前校验模型窗口、真实 tokenizer、向量维度、授权、来源用途与容器资源。6 GiB 显存参考档位的重型任务初值见第 17 章。
