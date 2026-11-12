# Dart 领域层 DDD 命名约定

`app/lib/features/*/domain/` 与 `app/lib/shared/domain/` 内构件命名与文件名后缀。

| DDD 概念 | 类型命名 | 文件命名 |
|----------|----------|----------|
| 领域异常（基类） | `DomainException` | `shared/domain/exceptions/domain_exception.dart` |
| 限界上下文异常 | `{Context}Exception` | `{context}_exceptions.dart` |
| 领域事件 | `sealed class {Context}Event` | `{context}_events.dart` |
| 规约 | `{Name}Specification`（`abstract final class`，静态方法） | `{name}_specification.dart` |
| 策略 / 分支算法 | 枚举 + 纯函数 | `{name}_strategy.dart` |
| 领域服务 | `{Name}DomainService` | `{name}_domain_service.dart` |
| 值对象 | `{Name}`（工厂校验不变式） | `value_objects/{snake_case}.dart` |
| 聚合 / 实体 | 领域名词 | `{aggregate}.dart` |
| 仓储接口 | `{Name}Repository` | `{name}_repository.dart` |

Shared Kernel（ADR-0035）中 FRB 映射 DTO 保持 `models/entity` 与 `value_objects/form` 布局；**例外**：`Comic` 实体、字段锁与元数据草稿已迁 `features/comic/domain/`（ADR-0041），`Series` 实体、成员、锁与表单已迁 `features/series/domain/`，FRB 映射分别 @ `features/comic/infrastructure/comic_entity_mapper.dart` / `features/series/infrastructure/series_frb_mapper.dart`（ADR-0042）。Comic 构造用 `Comic.restore` 绕过校验，新实体走 `Comic.createMetadata`。新增纯 Dart 规约优先放在 owner feature 的 `domain/`。

应用层异常（`core/errors/app_exception.dart`）与 `DomainException` 分离：domain 抛出规则违反，data/presentation 映射为用户可见错误。

**Reader 模块**（`features/reader/`，ADR-0038）额外冻结名实对照：见 [`reader-ddd-lexicon.md`](./reader-ddd-lexicon.md)。`domain/read_session.dart` 只放 `ReadSession` 实体，不得存放路由参数。
