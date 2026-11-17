# VideoParse 快析 · iOS

一款用 **SwiftUI** 编写的 iOS 无水印解析工具，通过 **GitHub Actions（macOS 云端 Runner）** 自动构建未签名 `.ipa`，手机可直接下载安装。

> 粘贴分享链接 → 解析无水印视频 / 图集 / 背景音乐 → 在线预览、下载、收藏。
> 第三方公开接口的客户端，仓库本身不存储任何媒体资源；接口稳定性与内容版权由接口方及原始平台负责。

- 最低系统：**iOS 26.0**
- 当前版本：**v1.4.1**（构建 9）
- 安装包：[Releases 最新直链](https://github.com/yr123466/VideoParse-iOS/releases/latest/download/VideoParse-unsigned.ipa)

---

## ✨ 功能

| 功能 | 说明 |
| --- | --- |
| **液态玻璃 Dock** | iOS 26 Liquid Glass 底栏，通透磨砂、内容从下方穿过；按住有放大提起动效，可左右拖动切页，带液体形变与吸附 |
| **视频播放** | 默认卡片内直接播放（不打断浏览），右上角进全屏；全屏支持进度拖动、下拉关闭、自动隐藏控件 |
| **实况照片** | 视频本地合成真正的 Live Photo：自动取关键帧 + 写入配对元数据，保存到相册可长按播放 |
| **图集** | 卡片内完整显示、全屏分页浏览、双指缩放；支持**单张保存**与**批量保存** |
| **背景音乐** | 解析出的背景原声可在线试听（播放/暂停、缓冲提示） |
| **素材库** | 视频 / 图集 / 音乐分类与收藏，详情页大屏预览 |
| **自动更新** | 启动后定期检测最新 Release，弹窗展示更新说明；设置里可切换「GitHub 官方直连 / 国内加速镜像」 |
| **剪贴板感知** | 回到前台自动识别剪贴板中的分享链接，仅匹配 URL，不弹粘贴授权 |

四个标签页：**解析 / 素材库 / 平台 / 设置**。

---

## 📲 安装

构建产物是**未签名 IPA**，需要先用自签工具签名再安装。

**推荐流程（手机端）**：用自签工具（eSign / 全能签 / AltStore / Sideloadly 等）导入上面的 IPA 直链，使用免费 Apple ID 自签安装。

📖 **详细图文教程**：<https://d.biji.com/H3L2aAkCaxc8FioN>

> 免费开发者证书签名的应用有效期 7 天，到期重新签名即可；付费开发者账号（$99/年）有效期 1 年。

---

## 🔄 更新检测

App 会定期查询本仓库最新 Release，版本号高于当前安装包时弹窗提示，内容包括：

- 新版本号、发布日期
- 从 Release 说明提取的更新日志
- 「不再提醒 / 取消 / 去 GitHub 更新」

更新说明来自仓库根目录的 [`CHANGELOG.md`](CHANGELOG.md)：构建时自动提取 `## v<版本>` 段落写入 Release 介绍，改完 CHANGELOG 发版即可。

检测线路可在 **设置 → 软件源线路** 切换：

| 线路 | 适用 |
| --- | --- |
| GitHub 官方直连 | 网络可直连 GitHub |
| 国内加速镜像 | 直连不稳定时（经 `gh-proxy.com` 加速） |

---

## 🚀 云端构建（无需 Mac）

1. Fork 本仓库，保持默认分支 `main`。
2. 在 **Settings → Secrets and variables → Actions → New repository secret** 添加（可选）：

   | Name | 说明 |
   | --- | --- |
   | `VIDEOPARSE_API_KEY` | 内置 API Key；不配置则需在 App 内手动填写 |

3. **Actions → Build iOS IPA → Run workflow**（推送到 `main` 也会自动触发）。
4. 构建完成后：
   - Actions 页面底部 Artifacts 下载 `VideoParse-unsigned-ipa`；
   - 或访问 Release 固定直链：`https://github.com/<你的用户名>/VideoParse-iOS/releases/latest/download/VideoParse-unsigned.ipa`

每次成功构建会自动打 tag 并发布 Release，App 内即可检测到新版本。

---

## 🛠 本地开发

需要 Mac + Xcode 26（部署目标 iOS 26）。

```bash
brew install xcodegen
cd VideoParse-iOS
xcodegen generate
open VideoParse.xcodeproj
```

- 工程默认 `CODE_SIGNING_ALLOWED=NO`（用于产出未签名包）。真机调试时在 Xcode 的 **Signing & Capabilities** 打开 Automatically manage signing 并选择你的 Team。
- 内置密钥可在 Build Settings → User-Defined 添加 `VIDEOPARSE_API_KEY`，或在 App 内「设置 → API Key」填写。

---

## 📁 目录结构

```
VideoParse-iOS/
├── project.yml                 # XcodeGen 工程描述
├── Support/Info.plist          # 权限、ATS、文件共享等配置
├── Resources/
│   ├── Assets.xcassets         # AppIcon + AccentColor
│   └── metadata.mov            # 实况照片元数据模板
├── Sources/
│   ├── VideoParseApp.swift     # 入口 + 音频会话
│   ├── RootView.swift          # 顶栏 + 四标签 + 液态玻璃 Dock
│   ├── ParseView.swift         # 解析页 + 结果卡片 + 最近记录
│   ├── MediaViews.swift        # 播放器 / 图集 / 音频 / 清晰度 / 统计
│   ├── LivePhotoMaker.swift    # 视频 → Live Photo 本地合成
│   ├── LibraryView.swift       # 素材库 + 详情
│   ├── PlatformsView.swift     # 平台目录
│   ├── SettingsView.swift      # 设置页
│   ├── Sheets.swift            # 免责声明 / 更新 / 下载进度
│   ├── Models.swift            # 数据模型 + 平台清单
│   ├── Networking.swift        # 接口客户端 + 下载 + 相册 + 分享
│   ├── Store.swift             # 全局状态
│   └── Theme.swift             # 颜色 / 卡片 / 通用组件
└── .github/workflows/ios-build.yml
```

---

## ⚠️ 使用须知

- 解析内容版权归原发布者及对应平台所有，仅供个人学习与研究使用，请勿商用或二次分发。
- 下载目录为沙盒 `Documents/VideoParse`，可在系统「文件」App 中查看与导出；保存到相册需授予相册权限。
- 应用退到后台后下载可能被系统挂起，回到前台自动继续；大批量图集建议保持前台。
- 免责声明页选择「不同意」时应用会提示自行删除（iOS 不允许程序主动退出）。

---

## 📄 许可证

仅供学习交流，使用本工具产生的一切责任由使用者自行承担。
