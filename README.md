# chat_uikit_demo

本项目是依赖 环信 flutter uikit 和 环信 flutter callkit 实现的完整示例。
flutter uikit: https://github.com/easemob/chatuikit-flutter
flutter callkit: https://github.com/easemob/ease-callkit-flutter

## 项目讲解

### 项目结构

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

## AppServer

AppServer 为 Demo 提供

1. 通过手机号获取验证码；
2. 通过验证码和手机号返回环信id和环信token;
3. 上传头像并返回服务器地址；
4. 音视频通话时根据环信id，agora channel 返回对应的agora uid;
5. 音视频通话中根据channel返回参与人的agora uid和环信id;