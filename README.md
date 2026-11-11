# VideoParse 快析 · iOS 版

Android（Kotlin + Jetpack Compose）应用的 iOS 完整移植版，使用 **SwiftUI** 重写，并通过 **GitHub Actions（macOS 云端 Runner）** 自动构建出可直接安装的 `.ipa`。

> 第三方公开接口打包客户端：粘贴分享链接 → 解析无水印视频 / 图集 / 背景音乐 → 下载、预览、收藏。
> 本仓库不存储任何媒体资源，接口稳定性与内容版权由第三方接口与原始平台负责。

**新版本**: 已在 GitHub Release（tag `v1.3.0`）上启用，App 内打开自动检测最新版本。

## ✨ 功能亮点（iOS 特有）

| 功能 | 说明 |
| --- | --- |
| **沉浸式全屏播放** | 视频点击全屏，横屏切换；画中画、双击求下一帧、进度条拖动；暂停呈显示缩略图。 |
| **实时动图 & 实况照片** | `type: "live"` 动图全屏内联播放，支持批量下载、保存为真正的 Live Photo。 |
| **按 Release 自动更新** | 每次推送到 `main` 构建发包，并打 tag（如 `v1.3.0`）；App 内“检查更新”调用 GitHub API 对比当前包与最新 Release。 |
| **iOS 26 新视觉** | 白色暗纹底、圆角卡片、浮动 TabBar、UI 16pt radius 等。 |
| **零排异安装** | 不上传应用市场，eSign/Sideloadly/AltStore 方案随选。 |
| **剪贴板静默探测** | 启动时仅匹配 URL，不弹出粘贴授权。 |

## 主要更新（v1.3.0）

- 沉浸式全屏播放（横屏/竖屏自由切换、媒体组合）+ 悬浮小按钮
- FullscreenOverlay / fullScreenCover 统一入口，去 Footer 条目、Footnote 文本隐藏
- 版本检测从 `API/GitHub APIs/Release` 到 `tag_name/code`，避免误报
- 术语翻译统一，移除部分冗余/重复的 UI 元素

---

## ✨ 功能对照（Android → iOS）

---

## ✨ 功能对照（Android → iOS）

| 功能 | Android 实现 | iOS 实现 |
| --- | --- | --- |
| 界面框架 | Jetpack Compose + Material3 | SwiftUI + 自定义主题（同色板 0x0284C7 / 0x4F46E5） |
| 解析 | Retrofit + Moshi | URLSession + async/await + 字典宽松解析 |
| 本地库 | Room | Codable + JSON（Application Support） |
| 视频预览 | ExoPlayer/Media3 | AVKit `VideoPlayer` |
| 音频试听 | MediaPlayer | AVPlayer + 周期观察者 |
| 图集预览 | Pager + 手势缩放 | TabView 分页 + 双击/Magnification 缩放 |
| 下载 | OkHttp → SAF 目录 | URLSessionDownloadDelegate → 沙盒 `Documents/VideoParse` |
| 保存相册 | MediaStore | PHPhotoLibrary（addOnly 权限） |
| 分享 | Intent.ACTION_SEND | UIActivityViewController |
| 剪贴板感知 | ClipboardManager | UIPasteboard（回到前台时检测） |

四个 Tab 与 Android 完全一致：**解析 / 素材库 / 平台 / 设置**，并保留免责声明弹窗、版本更新检测、接口连通性诊断、赞赏入口。

## 📁 目录结构

```
VideoParse-iOS/
├── project.yml                 # XcodeGen 工程描述（不提交 .xcodeproj）
├── Support/Info.plist          # 权限、ATS、文件共享等配置
├── Resources/Assets.xcassets   # AppIcon（1024 单尺寸）+ AccentColor
├── Sources/
│   ├── VideoParseApp.swift     # 入口 + 音频会话
│   ├── RootView.swift          # 顶栏 + 四 Tab
│   ├── ParseView.swift         # 解析页 + 结果卡片 + 最近记录
│   ├── MediaViews.swift        # 播放器 / 图集 / 音频 / 清晰度 / 统计
│   ├── LibraryView.swift       # 素材库 + 详情
│   ├── PlatformsView.swift     # 平台目录 + 详情
│   ├── SettingsView.swift      # 设置页
│   ├── Sheets.swift            # 免责声明 / 更新 / 下载进度
│   ├── Models.swift            # 数据模型 + 平台清单
│   ├── Networking.swift        # 接口客户端 + 下载管理 + 相册 + 分享
│   ├── Store.swift             # 全局状态（ObservableObject）
│   └── Theme.swift             # 颜色 / 卡片 / 按钮 / 通用组件
├── tools/make_icon.py          # 图标生成脚本（可选）
└── .github/workflows/ios-build.yml
```

## 🔍 更新检测（App 内）

App 启动后每 24 小时主动查询一次 latest Release。如果 `tag_name` 大于当前 `CFBundleShortVersionString`，则弹出：

- 新版本号、发布日期
- 从 Release body 提取的更新说明
- 按钮：**不再提醒 / 取消 / 去 GitHub 更新**

不想再弹窗可在设置里勾选“不再提醒”。

## 🚀 云端构建（无需 Mac）

1. 把本仓库推到 GitHub（默认分支 `main`）。
2. 在 **Settings → Secrets and variables → Actions → New repository secret** 添加：

   | Name | Value |
   | --- | --- |
   | `VIDEOPARSE_API_KEY` | 你的内置 API Key（可选，未配置则需在 App 内手动填写） |

3. 进入 **Actions → Build iOS IPA → Run workflow**（推送到 main 也会自动触发）。
4. 构建完成后：
   - 页面底部 Artifacts 下载 `VideoParse-unsigned-ipa`；
   - 或直接访问 Release 固定直链：
     `https://github.com/<你的用户名>/VideoParse-iOS/releases/latest/download/VideoParse-unsigned.ipa`

   另外，在新版中推荐 **Release 发布**：每次构建成功会自动打 tag（如 `v1.3.0`）并发布 Release，App 内“检查更新”会按 `tag_name` 对比版本。

构建产物是**未签名 IPA**，需要自签后安装。

## 📲 安装方式

| 工具 | 说明 |
| --- | --- |
| **eSign / 全能签** | 手机端直接导入上面的 IPA 直链，用免费 Apple ID 自签（7 天有效，可自动续签） |
| **AltStore / SideStore** | 电脑或手机安装 AltStore，导入 IPA，同一 Wi-Fi 下自动续签 |
| **Sideloadly** | 电脑 + 数据线，拖入 IPA，输入 Apple ID 签名安装 |
| **TrollStore** | 仅支持特定系统版本，可永久签名（免 7 天限制） |

> 免费开发者证书签名的应用有效期 7 天，到期需重新签名；付费开发者账号（$99/年）为 1 年。

## 📲 安装方式

| 工具 | 说明 |
| --- | --- |
| **eSign / 全能签** | 手机端直接导入上面的 IPA 直链，用免费 Apple ID 自签（7 天有效，可自动续签） |
| **AltStore / SideStore** | 电脑或手机安装 AltStore，导入 IPA，同一 Wi-Fi 下自动续签 |
| **Sideloadly** | 电脑 + 数据线，拖入 IPA，输入 Apple ID 签名安装 |
| **TrollStore** | 仅支持特定系统版本，可永久签名（免 7 天限制） |

> 免费开发者证书签名的应用有效期 7 天，到期需重新签名；付费开发者账号（$99/年）为 1 年。

## 🛠 本地开发（需要 Mac + Xcode）

```bash
brew install xcodegen
cd VideoParse-iOS
xcodegen generate
open VideoParse.xcodeproj
```

- 工程默认 `CODE_SIGNING_ALLOWED=NO`（为了产出未签名包）。要在真机调试，在 Xcode 的 *Signing & Capabilities* 里勾选 Automatically manage signing 并选择你的 Team 即可。
- 本地调试若要使用内置密钥，在 Xcode 的 Build Settings → User-Defined 添加 `VIDEOPARSE_API_KEY`，或在 App 内「设置 → API Key」填写自定义 Key。

## 📝 iOS 与 Android 的行为差异

1. **保存目录**：iOS 无法像 Android SAF 那样自选任意目录。文件统一写入沙盒 `Documents/VideoParse`，通过 `UIFileSharingEnabled` 暴露到「文件」App（我的 iPhone → VideoParse），可在其中移动/分享到任意位置；相册保存走系统权限。
2. **后台下载**：应用退到后台后下载可能被系统挂起，回到前台会自动继续；大批量图集建议保持前台。
3. **剪贴板**：iOS 14+ 读取剪贴板会显示系统提示条，且只在回到前台时检测（不做后台轮询）。
4. **应用退出**：iOS 不允许程序主动退出，免责声明页以「不同意则删除应用」替代 Android 的 `finishAffinity()`。
5. **平台清单**：与 Android 保持一致，目录页仅展示国内合规平台；海外 / 腾讯系平台可在接口支持时直接粘贴链接解析。

## ⚠️ 免责声明

本项目为第三方公开 API 的客户端打包工具，开发者非接口服务提供方，不存储任何媒体文件。
所有解析内容版权归原发布者及对应平台所有，仅供个人学习与研究使用，严禁商用、二次分发或任何侵权行为。
使用本工具产生的一切法律责任由使用者自行承担。
