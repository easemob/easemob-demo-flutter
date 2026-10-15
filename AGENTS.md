# AGENTS.md

本项目是环信 Flutter IM Demo 应用，用于展示 `em_chat_uikit` 与 `em_chat_callkit` 的集成方式，包括 Token 登录、会话与联系人、用户资料、群组、Presence、消息扩展、音视频通话、App Server 和本地缓存。本文档记录当前版本的实际结构和开发约束，具体实现以代码为准。

## 文档基线

| 项目 | 当前值 |
|---|---|
| Demo 版本 | `2.2.2` |
| `em_chat_uikit` | `2.4.0` |
| `em_chat_callkit` | Git ref `0.0.5` |
| `im_flutter_sdk` override | `5.0.0` |
| `agora_rtc_engine` override | `6.5.1` |
| Dart | `^3.3.0` |
| Android | minSdk 24，仅构建 `arm64-v8a` |
| iOS | 15.0 |

本文档是带版本的开发说明。修改 `pubspec.yaml` 中的 Demo 版本、UIKit、CallKit、IM SDK、RTC SDK，或修改 Android/iOS 支持基线时，必须在同一次变更中更新本表。如果升级改变了初始化、登录、数据同步、通话或平台处理方式，还要同步修订对应章节，不能只改版本号。

## 协作约定

- 本文件使用中文，与项目主 `README.md` 保持一致。
- 排查方向不确定、或同一问题卡住超过几分钟时，先向用户同步现象和当前假设，再继续深入。
- 修改集成功能时明确影响范围：UIKit、CallKit、App Server、本地存储、Android、iOS 中哪些环节发生变化。
- 未经用户授权，不执行 commit 或 push。

### 工作日志

- 每完成一个任务，或做出重要决策、收到用户纠正时，追加到 `dailylog/YYYY-MM-DD.md`（本地日期），文件不存在则创建。
- 只追加，不修改已有内容。每条格式：`- HH:MM <做了什么/决定了什么>，原因：<…>`。
- 日志可以记录进度和过程。
- `dailylog/` 下的工作日志纳入 Git 版本管理，不加入 `.gitignore`；在执行用户授权的 Git 提交时，将本次日志变更一并提交。记录日志本身不自动触发 commit 或 push。

## 项目结构

| 路径 | 职责 |
|---|---|
| `lib/main.dart` | 配置 `DemoConfig`、初始化 `ChatUIKit`、设置数据同步、本地化、主题和总路由 |
| `lib/demo_config.dart` | 保存 App Key、RTC App ID、App Server 和验证码相关配置 |
| `lib/demo_localizations.dart` | Demo 自有中英文文案键和值 |
| `lib/custom/chat_route_filter.dart` | 通过 UIKit 路由参数和 builder 定制消息、联系人及群组页面 |
| `lib/custom/call_helper.dart` | 从 UIKit 页面发起单人或多人通话，并格式化通话记录 |
| `lib/custom/demo_helper.dart` | Demo 级辅助状态与黑名单操作 |
| `lib/pages/` | 登录、主页、会话、联系人、个人中心、设置、帮助和通话页面 |
| `lib/pages/call/call_handler_widget.dart` | 注册 CallKit observer、提供 RTC Token/UID 映射、接听来电并刷新通话记录 |
| `lib/tool/app_server_helper.dart` | 封装手机号登录、头像、群头像、RTC Token 和 UID 映射等 App Server 请求 |
| `lib/tool/login_data_store.dart` | 在本机保存和清理 Demo 登录用的用户 ID 与 Token |
| `lib/tool/settings_data_store.dart` | 持久化语言和 UIKit 功能开关，并同步到 `ChatUIKitSettings` |
| `lib/tool/user_data_store.dart` | 使用 SQLite 按 App Key 和当前用户缓存联系人、群组展示资料 |
| `lib/tool/user_provider_handler_widget.dart` | 连接 SDK、SQLite、App Server 与 `ChatUIKitProvider` |
| `lib/tool/token_status_handler_widget.dart` | 处理断线、鉴权失败和 Token 过期后的凭证清理与登录跳转 |
| `android/`, `ios/` | 应用平台配置以及 AOSL 冲突处理 |

## 启动与会话流程

1. `main.dart` 先写入 `DemoConfig`，再用 `Options.withAppKey` 初始化 `ChatUIKit.instance`，并开启会话、联系人和已加入群组的数据同步。
2. `SettingsDataStore` 恢复语言与功能开关，`OnlineStatusHelper` 初始化在线状态处理。
3. `WelcomePage` 从 `LoginDataStore` 读取本地用户 ID 和 Token，并显式调用 Token 登录；失败则进入登录页。
4. 登录成功后进入 `HomePage`，注册 UIKit observers，并组合用户资料、Token 状态和 CallKit handler。
5. 显式退出、Token 过期或鉴权失效时清理 `LoginDataStore`，再返回登录页。

IM SDK 5.0.0 不支持密码登录和 SDK 自动登录。不要重新引入旧密码登录或依赖 SDK 自动恢复会话。当前 SharedPreferences Token 存储只用于 Demo 展示，不应被描述为生产环境安全存储方案。

## 模块边界与扩展方式

- 页面优先通过 `em_chat_uikit/chat_uikit.dart` 的公开 API 工作，不直接依赖 IM SDK 内部实现。
- UIKit 页面定制集中在 `ChatRouteFilter`：复制强类型 route arguments，注入 builder、controller 或 observer，再交回 `ChatUIKitRoute`。优先使用这些扩展点，不复制整套 UIKit 页面。
- Demo 级业务协调放在 `custom/` 或 `tool/`，页面负责交互和展示，避免把 App Server、数据库或通话协议直接堆进 Widget build 方法。
- `ChatUIKitProvider` 是头像、昵称、备注和群资料进入 UIKit 的统一入口；SQLite 是 Demo 的持久缓存，不建立第二套页面级资料缓存。
- `SettingsDataStore` 是功能开关与本地设置的入口。修改设置时同时更新持久值和相应的 `ChatUIKitSettings`。
- 新增 observer 的对象必须在 `dispose` 中移除；异步回调操作界面前检查 `mounted`。

## UIKit 定制约定

- 新增路由定制时，保留原 `RouteSettings.name` 和对应的 `ChatUIKitViewArguments` 类型，不使用无类型 Map 替代。
- 消息页面的自定义发送、长按菜单、气泡、附件下载和通话记录逻辑集中在 `ChatRouteFilter.messagesView` 及相关 helper。
- 用户或群组资料更新后，同时更新 `UserDataStore` 和 `ChatUIKitProvider`，保证重启缓存与当前 UI 一致。
- 新增可见文案时，在 `DemoLocalizations` 中定义键，并同时补齐 `zh` 与 `en`；界面通过 `localString(context)` 获取文案。
- 主题和颜色优先使用 `ChatUIKitTheme`、`ChatUIKitThemeMixin` 与现有 UIKit token，避免在共享页面增加不随主题切换的硬编码颜色。

## CallKit 与 App Server 约定

- `DemoConfig.isValid` 当前同时影响手机号/App Server 流程和 CallKit 包装。修改配置判断时必须分别验证配置完整模式与用户 ID + Token 模式。
- `CallHandlerWidget` 负责注册和移除 `ChatCallKitObserver`，设置 RTC Token handler 与 RTC UID 到 IM 用户 ID 的 mapper。
- RTC Token 和 UID 映射通过 `AppServerHelper` 获取；不要在客户端生成服务端密钥或提交真实用户 Token。
- 发起通话前请求麦克风和相机权限；异步授权结束后必须确认 `context.mounted`。
- 通话邀请消息会注入 UIKit 消息流，通话结束后重新读取对应会话的最新消息。修改 CallKit 回调时同时验证通话页面和会话中的通话记录。
- 修改 `AppServerHelper` 时保持请求路径、参数、响应模型和调用方一致，并覆盖非 200、空数据和配置无效场景。

## 本地数据与生命周期

- `LoginDataStore` 只保存恢复 Token 登录所需的用户 ID 和 Token；所有退出和鉴权失效路径都必须清理它。
- `UserDataStore` 的数据库名包含 App Key 和当前用户，数据表名使用当前用户 ID。只能在登录用户已确定后打开数据库。
- 切换用户时不得复用上一个用户的 profile 缓存或数据库连接。
- `ChatUIKitProvider.profilesHandler` 可以先返回缓存缺失，再异步拉取资料并通过 `addProfiles` 通知界面；保持这一异步回填模型。
- Widget、controller、observer、timer、notifier 和数据库连接由创建者负责释放。

## 平台配置

- Android 使用 minSdk 24、Java/Kotlin 17，并通过 `android/app/aosl-fix.gradle` 和 `extra["aosl_prefer"] = "easemob"` 处理 AOSL 依赖冲突。
- Android 当前只保留 `arm64-v8a`。改变 ABI 范围前确认安装包和原生依赖支持，并更新本文档。
- iOS `Podfile` 使用 15.0，通过 `ios/fix_aosl_conflicting.rb`、`pre_install` 和 `post_install` 清理重复 AOSL 依赖及链接参数。
- 升级 `em_chat_callkit`、`agora_rtc_engine` 或相关原生依赖时，不要删除 AOSL 处理钩子；必须重新执行依赖解析并验证 Android/iOS 构建。

## 版本与依赖更新

- 修改 Demo `version:` 时，同步更新本文档“文档基线”。
- 修改 UIKit、CallKit、IM SDK 或 RTC SDK 版本时，同时检查直接依赖、`dependency_overrides`、Git ref、锁文件、平台依赖解析和本文档基线。
- `pubspec.lock` 纳入版本管理；依赖升级后应随授权提交一并更新。
- 本地 `pubspec_overrides.yaml` 仅用于把 UIKit 和 CallKit 指向工作区源码进行验证，不提交其中的本机绝对路径。
- 依赖升级后的最低验收范围包括启动、Token 登录、数据同步、会话、联系人、用户资料、退出/Token 失效，以及启用 App Server 后的音视频通话。

## 代码约定

- 遵循 `flutter_lints` 和现有 Dart 命名：文件使用 snake_case，类型使用 UpperCamelCase，成员使用 lowerCamelCase。
- import 按现有文件风格组织：项目包、组件依赖、Flutter/Dart 标准库分组，避免新增无用 import。
- 网络、数据库和 SDK 调用保持异步错误边界；用户可感知操作需要给出 loading、成功或失败反馈。
- 不在源码中提交真实用户 ID、Token、手机号、验证码或服务端密钥。
- 修改用户可见行为时同步更新中文 `README.md`；依赖和运行条件变化必须更新快速跑通说明。

## 验证

所有命令都在本仓库执行，不在父工作区根目录执行 Flutter 命令。

- 基础检查：运行 `flutter pub get`、`dart format --output=none --set-exit-if-changed lib` 和 `flutter analyze`。
- 登录改动：验证用户 ID + Token 登录、本地凭证恢复、显式退出、Token 过期和鉴权失败。
- UIKit 改动：验证会话、消息收发、联系人、群组、资料缓存、路由定制、语言和主题切换。
- CallKit 改动：在 App Server 配置完整时验证呼入、呼出、音频、视频、多人通话、权限拒绝、挂断和通话记录刷新。
- 平台或依赖改动：至少构建所有受影响的平台；AOSL 相关修改必须同时验证 Android 和 iOS。
- 本仓库当前没有 Dart 自动化测试目录，不能把 `flutter test` 作为已有覆盖。新增可独立验证的业务逻辑时补充有行为价值的测试。
