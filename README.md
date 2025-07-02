# 环信即时通讯 IM Demo 

环信即时通讯 IM Demo 提供用户登录、单聊、群组、子区、消息(文字、表情、语音、视频、图片、文件等)发送及管理、会话管理、好友管理、用户属性、用户在线状态（Presence）以及实时音视频通话等功能。

## Demo 体验  

你可以进入 [环信官网](https://www.easemob.com/download/demo) 体验即时通讯 IM Demo。
注意：Demo里登录时获取验证码功能在模拟器上不支持，请使用真机。

## 快速跑通 Demo 源码

### 开发环境要求

- flutter 3.3.0+
- ios 12+
- android sdk api 21+

### 跑通步骤

1. [创建应用](https://doc.easemob.com/product/enable_and_configure_IM.html#%E5%88%9B%E5%BB%BA%E5%BA%94%E7%94%A8)。   
2. [获取应用的 App Key](https://doc.easemob.com/product/enable_and_configure_IM.html#%E8%8E%B7%E5%8F%96%E7%8E%AF%E4%BF%A1%E5%8D%B3%E6%97%B6%E9%80%9A%E8%AE%AF-im-%E7%9A%84%E4%BF%A1%E6%81%AF)。
3. [创建用户](https://doc.easemob.com/product/enable_and_configure_IM.html#%E5%88%9B%E5%BB%BA-im-%E7%94%A8%E6%88%B7)。
4. [下载即时通讯 IM Demo 项目源码](https://github.com/easemob/easemob-demo-flutter)。
5. 下载完毕，打开 lib/main.dart
6. 将你的应用的 App Key 填写到 `appkey` 中。
7. 编译运行项目。
8. 使用注册的用户 ID 和密码登录。


### App Server

为方便开发者快速体验即时通讯 IM 功能，跑通本工程 Demo 源码默认使用开发者注册的用户 ID 和密码直接登录，不需要依赖部署服务端 App Server。但是在此模式下，手机验证码、用户头像和 EaseCallKit 实时音视频等相关功能不可用，你可以通过部署 App Server 完整体验这些功能。

App Server 为 Demo 提供以下功能：

- 通过手机号获取验证码。
- 通过手机号和验证码返回环信用户 ID 和环信用户 Token。
- 上传头像并返回地址。
- 根据用户的信息生成 [EaseCallKit](https://github.com/easemob/ease-callkit-flutter.git) 登录所需的 Token。
- 获取音视频通话时环信用户 ID 和 Agora UID 的映射关系。

你通过以下步骤部署 App Server：

1. 部署 App Server。详见 [服务端源码](https://github.com/easemob/easemob-im-app-server/tree/dev-demo)。
2. 在 lib/main.dart 填写 App Server 的域名 和 rtcAppId。

**服务端中的 App Key 要跟客户端的 App Key 保持一致。**

## Demo 项目结构

### Demo 架构

```shell
.
├── custom
│   └── chat_route_filter.dart // chat-uikit 自定义拦截类，所有对chat-uikit 的自定义通过该文件实现。
├── demo_config.dart           // demo 运行的配置类，包含appkey， agoraAppId， appServer
├── demo_localizations.dart    // demo 国际化类，用于对demo中文字国际化
├── main.dart                  // 项目入口，包括了初始化sdk，设置主题
├── notifications
│   └── app_settings_notification.dart      // 主题变更通知
├── pages
│   ├── call                                // 呼叫相关页面
│   │   ├── call_handler_widget.dart        // 呼叫监听页面，当home页启动时会初始化，用于监听语音会叫回调。
│   │   ├── call_helper.dart                // 呼叫工具类，集成了1v1音视频呼叫和多人呼叫的方法。
│   │   ├── call_pages                      // 呼叫相关的ui页面
│   │   │   ├── call_button.dart            // 呼叫使用的自定义按钮
│   │   │   ├── call_user_info.dart         // 用于展示呼叫的头像昵称
│   │   │   ├── multi_call_item_view.dart   // 多人呼叫时的单人展示信息
│   │   │   ├── multi_call_page.dart        // 多人呼叫时的总页面
│   │   │   ├── multi_call_view.dart        // 多人呼叫中的page页面
│   │   │   └── single_call_page.dart       // 单人呼叫页面
│   │   └── group_member_select_view.dart   // 群成员选择页面，用户多人呼叫时选则参与人
│   ├── contact
│   │   └── contact_page.dart               // 通讯录页面
│   ├── conversation
│   │   └── conversation_page.dart          // 会话列表页面
│   ├── help
│   │   └── download_page.dart              // 附件消息下载页面
│   ├── home_page.dart                      // 主页
│   ├── login_page.dart                     // 登录页面
│   ├── me
│   │   ├── about_page.dart                 // about 页面
│   │   ├── my_page.dart                    // 个人页面
│   │   ├── personal
│   │   │   └── personal_info_page.dart     // 个人详情页
│   │   └── settings
│   │       ├── advanced_page.dart          // 特性开关页面
│   │       ├── general_page.dart           // 设置页面
│   │       ├── language_page.dart          // 语言选择页面
│   │       └── translate_page.dart         // 选择翻译目标语言页面
│   └── welcome_page.dart                   // 启动页
├── tool
│   ├── app_server_helper.dart              // appServer 请求封装页面，用于封装向AppServer的请求
│   ├── format_time_tool.dart               // 时间工具，用于格式化通话时间
│   ├── settings_data_store.dart            // 配置存储工具
│   └── user_data_store.dart                // 用户属性存储类
└── widgets
    ├── list_item.dart                      // 设置页面的item
    ├── toast_handler_widget.dart           // toast 页面，对uikit中事件结果的封装，如添加好友的loading toast等
    ├── token_status_handler_widget.dart    // token 过期监听页，用于监听sdk登录用户token过期。
    └── user_provider_handler_widget.dart   // 用户数据配置类，用于把用户信息传给uikit和根据 uikit 的请求返回对应用户数据
```

### 核心模块

| 模块               | 描述   | 
| :------------------- | :----- |
| 聊天模块    | 展示如何依赖 [ChatUIKit](https://doc.easemob.com/uikit/chatroomuikit/flutter/roomuikit_overview.html) 实现聊天页面，如何发送消息、消息管理、扩展消息类型及如何增加扩展菜单等的逻辑。    | 
| 会话列表模块 | 展示如何依赖 [ChatUIKit](https://doc.easemob.com/uikit/chatroomuikit/flutter/roomuikit_overview.html) 实现会话列表的逻辑及实现系统消息的具体逻辑。   | 
| 联系人模块  | 展示如何依赖 [ChatUIKit](https://doc.easemob.com/uikit/chatroomuikit/flutter/roomuikit_overview.html) 实现联系人列表的逻辑。   | 
| 我的模块  | 账户管理、用户状态管理及APP的一些功能样式设置    | 
| 开发者模块  | 展示 IM SDK 提供的一些常规的开发者可以设置的功能。   |

## Demo 设计

关于 Demo 的设计，详见 [设计文档](https://www.figma.com/community/file/1327193019424263350/chat-uikit-for-mobile) 。

## Q&A

如有问题请联系环信技术支持或者发邮件到 [issue@easemob.com](mailto:issue@easemob.com)。

