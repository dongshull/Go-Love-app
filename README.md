# Go-Love-app 💑

一个充满爱意的情侣社交应用 - 记录你们的美好时刻

## 项目简介 🎯

Go-Love-app 是一个专为情侣设计的社交应用，旨在为恋人们提供一个私密、温馨的空间来记录和分享他们的美好时刻。通过这个应用，情侣可以共同创建和保存他们的回忆，记录重要的纪念日，以及进行私密的交流。

## 主要功能 ✨

### 1. 美好回忆 📸
- 上传和分享照片
- 添加文字描述和心情标签
- 时间线展示
- 支持编辑和删除

### 2. 纪念日 📅
- 创建和管理重要的纪念日
- 自定义纪念日内容和描述
- 倒计时提醒

### 3. 悄悄话 💌
- 私密消息交流
- 支持文字和表情
- 实时对话体验

### 4. 个人中心 👤
- 用户信息管理
- 头像上传
- 密码修改
- 情侣状态绑定

## 技术栈 🛠

- **前端框架**: Flutter
- **状态管理**: Flutter 内置状态管理
- **网络请求**: http package
- **图片处理**: image_picker, cached_network_image
- **数据格式化**: intl
- **API 集成**: RESTful API

## 项目结构 📁

```
lib/
├── models/          # 数据模型
├── screens/         # 页面
├── services/        # 服务
├── utils/          # 工具类
└── widgets/        # 可复用组件
```

## 安装和运行 🚀

1. 确保已安装 Flutter 开发环境
2. 克隆项目
```bash
git clone https://github.com/yourusername/Go-Love-app.git
```
3. 安装依赖
```bash
flutter pub get
```
4. 运行项目
```bash
flutter run
```

## API 配置 ⚙️

在 `lib/services/api_service.dart` 中配置你的 API 地址：

```dart
String baseUrl = 'http://your-api-url';
```

## 贡献指南 🤝

欢迎提交 Pull Request 或提出 Issue！

## 许可证 📄

MIT License

## 联系我们 📧

如有任何问题或建议，欢迎联系我们。

---

Made with ❤️ by Go-Love Team