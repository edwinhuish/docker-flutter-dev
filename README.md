# Docker Flutter 开发环境

[![Docker Build](https://github.com/edwinhuish/docker-flutter-dev/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/edwinhuish/docker-flutter-dev/actions/workflows/docker-publish.yml)

基于 Docker 的 Flutter 跨平台开发环境，预装 Flutter SDK、Android SDK 和 OpenJDK 21，开箱即用。

## 特性

- 🚀 **开箱即用**：预装 Flutter 3.38.8、Android SDK 36 和 OpenJDK 21
- 💾 **体积优化**：清理 SDK 缓存和临时文件，减小镜像体积
- 🔧 **环境隔离**：所有 SDK 安装在 `/opt` 目录，与宿主机隔离
- 📦 **多架构支持**：基于 Debian 系统，支持 x86_64 架构
- ⚡ **快速启动**：所有依赖预装，无需等待下载
- 🎯 **生产就绪**：通过 flutter doctor 验证安装完整性

## 快速开始

### 使用 Docker 命令

```bash
# 拉取镜像
docker pull edwinhuish/flutter-dev:latest

# 运行容器
docker run -it \
  -v $(pwd):/workspace \
  -w /workspace \
  edwinhuish/flutter-dev:latest bash

# 验证安装
flutter doctor
```

### 使用 Docker Compose

创建 `docker-compose.yml`：

```yaml
version: '3.8'
services:
  flutter-dev:
    image: edwinhuish/flutter-dev:latest
    volumes:
      # 挂载工作目录
      - .:/workspace
      # 可选：持久化 Flutter SDK 缓存
      - flutter-cache:/home/vscode/.pub-cache
    working_dir: /workspace
    environment:
      # 启用 Flutter 国内镜像（中国大陆用户推荐）
      - PUB_HOSTED_URL=https://pub.flutter-io.cn
      - FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
    command: sleep infinity

volumes:
  flutter-cache:
    driver: local
```

启动服务：

```bash
docker compose up -d
docker compose exec flutter-dev bash
```

## 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `JAVA_HOME` | `/opt/jdk` | JDK 安装路径 |
| `ANDROID_HOME` | `/opt/android-sdk` | Android SDK 路径 |
| `FLUTTER_HOME` | `/opt/flutter` | Flutter SDK 路径 |
| `PATH` | 包含所有工具路径 | 已配置好，无需修改 |

## 构建参数

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `VERSION` | `3.38.8` | Flutter 版本 |
| `USER` | `vscode` | 容器内用户名 |

## 已安装的组件

### JDK
- **版本**：OpenJDK 21.0.2
- **来源**：Eclipse Temurin 官方二进制包
- **安装路径**：`/opt/jdk`

### Android SDK
- **版本**：Android API Level 36
- **包含组件**：
  - `platform-tools`（adb、fastboot 等）
  - `platforms;android-36`（Android 36 平台）
  - `build-tools;36.0.0`（构建工具）
- **安装路径**：`/opt/android-sdk`

### Flutter SDK
- **版本**：3.38.8
- **安装方式**：Git 克隆（浅克隆，减少体积）
- **优化**：清理缓存和下载文件
- **安装路径**：`/opt/flutter`

### 系统依赖
- `ca-certificates`、`curl`、`git`、`unzip`、`wget` 等基础工具
- `libgl1`、`lib32z1`（OpenGL 和 32 位库支持）
- `clang`、`cmake`、`ninja-build`、`pkg-config`（编译工具链）
- `libgtk-3-dev`、`mesa-utils`（Linux 桌面支持）

## SDK 目录结构

```
/opt/
├── jdk/                      # JDK 安装目录
│   ├── bin/java             # Java 可执行文件
│   └── ...
├── android-sdk/             # Android SDK 安装目录
│   ├── cmdline-tools/latest/ # SDK 命令行工具
│   ├── platforms/android-36/ # Android 平台
│   └── build-tools/36.0.0/  # 构建工具
└── flutter/                 # Flutter SDK 安装目录
    ├── bin/flutter          # Flutter 命令
    └── ...
```

## 使用示例

### 创建 Flutter 项目

```bash
# 进入容器
docker run -it -v $(pwd):/workspace -w /workspace edwinhuish/flutter-dev bash

# 创建新项目
flutter create my_app
cd my_app

# 运行 Flutter doctor 验证
flutter doctor

# 构建 APK（需要 Android SDK）
flutter build apk

# 构建 Linux 桌面应用
flutter build linux
```

### 在 CI/CD 中使用

```yaml
# .github/workflows/flutter-ci.yml
name: Flutter CI

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: edwinhuish/flutter-dev:latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Build APK
        run: flutter build apk
      
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
```

## 网络优化（中国大陆）

### 使用 Flutter 国内镜像

```bash
docker run -it \
  -v $(pwd):/workspace \
  -e PUB_HOSTED_URL=https://pub.flutter-io.cn \
  -e FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
  -w /workspace \
  edwinhuish/flutter-dev:latest bash
```

### Docker Compose 配置

```yaml
environment:
  - PUB_HOSTED_URL=https://pub.flutter-io.cn
  - FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

## 故障排查

### 问题：flutter doctor 显示 Android license 状态未知

**解决方案**：
```bash
# 在容器内运行
yes | flutter doctor --android-licenses
flutter doctor
```

### 问题：构建时提示 "Android SDK not found"

**原因**：ANDROID_HOME 环境变量未正确设置

**解决方案**：
```bash
# 验证环境变量
echo $ANDROID_HOME  # 应该输出 /opt/android-sdk

# 手动设置（通常不需要）
export ANDROID_HOME=/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
```

### 问题：Java 版本不匹配

**解决方案**：
```bash
# 验证 Java 版本
java -version  # 应该显示 openjdk 21.0.2

# 验证 JAVA_HOME
echo $JAVA_HOME  # 应该输出 /opt/jdk
```

### 问题：权限不足

**解决方案**：
```bash
# 检查目录权限
ls -la /opt/

# 确保当前用户对 workspace 有写入权限
ls -la /workspace
```

### 问题：缓存导致构建失败

**解决方案**：
```bash
# 清理 Docker 缓存
docker system prune -a

# 重新构建镜像
docker build --no-cache -t edwinhuish/flutter-dev:latest .
```

## 构建自定义镜像

### 基本构建

```bash
# 克隆仓库
git clone https://github.com/edwinhuish/docker-flutter-dev.git
cd docker-flutter-dev

# 构建镜像
docker build -t edwinhuish/flutter-dev:latest .

# 构建指定 Flutter 版本
docker build \
  --build-arg VERSION=3.19.6 \
  -t edwinhuish/flutter-dev:3.19.6 .
```

### GitHub Actions 自动构建

本项目使用 GitHub Actions 自动构建镜像：

- **触发条件**：推送到 master 分支
- **镜像标签**：`latest`（最新稳定版）
- **目标仓库**：Docker Hub（edwinhuish/flutter-dev）

## 最佳实践

### 1. 使用特定版本标签

生产环境建议使用具体版本标签，而非 `latest`：

```bash
# 推荐
docker run -it edwinhuish/flutter-dev:3.38.8 bash

# 不推荐（可能导致意外更新）
docker run -it edwinhuish/flutter-dev:latest bash
```

### 2. 持久化 Pub 缓存

```bash
# 挂载 pub 缓存目录
docker run -it \
  -v ~/.pub-cache:/home/vscode/.pub-cache \
  -v $(pwd):/workspace \
  edwinhuish/flutter-dev:latest bash
```

### 3. 使用非 root 用户

镜像默认使用 `vscode` 用户（UID 1000），避免权限问题。

### 4. 多阶段构建

对于生产部署，建议在 Dockerfile 中使用多阶段构建：

```dockerfile
# 构建阶段
FROM edwinhuish/flutter-dev:latest AS builder
WORKDIR /app
COPY . .
RUN flutter pub get && flutter build apk

# 运行阶段（可选，使用更小的基础镜像）
FROM alpine:latest
COPY --from=builder /app/build/app/outputs/flutter-apk/app-release.apk /app/
```

## 更新日志

### v3.38.8
- 初始版本
- 预装 Flutter 3.38.8
- 预装 Android SDK 36
- 预装 OpenJDK 21.0.2
- 优化镜像体积，清理 SDK 缓存

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 相关链接

- [Flutter 官方文档](https://flutter.dev/docs)
- [Android SDK 文档](https://developer.android.com/studio/releases/sdk-tools)
- [Eclipse Temurin JDK](https://adoptium.net/)
- [Docker 官方文档](https://docs.docker.com/)

## 支持

如有问题，请通过以下方式联系：

- 提交 GitHub Issue
- 发送邮件到项目维护者

---

**注意**：本镜像仅供开发和学习使用，生产环境请根据实际需求进行安全加固和优化。
