# PhotoZipper C++ (Qt Quick 6.8 + Embedded ImageMagick)

一款基于 **C++20** 与 **Qt 6.8 (Qt Quick / QML)** 构建的现代化、超低内存占用、高压缩率桌面图片压缩与批量处理软件。底层内嵌官方 **ImageMagick** 引擎，并支持在软件内直接检测、切换任意指定版本或一键更新至最新版本（严格保持本地单版本存在并自动瘦身 87% 冗余体积）。

---

## ✨ 核心特性

### 1. 内嵌 ImageMagick 引擎与在线单版本热更新
- **官方源直连**：直接对接 `https://github.com/ImageMagick/ImageMagick` 官方 Releases。
- **任意版本切换 / 一键更新最新版**：在顶部点击 **「引擎管理」**，即可查看官方版本列表，自由切换至任意历史版本或更新至最新版，并支持选择 `Q8`（推荐，内存减半、速度最快）、`Q16`、`Q16-HDRI` 位深规格。
- **严格单版本 & 极致体积控制**：官方 Portable 压缩包解压后包含 8 个各 31MB 的重复静态可执行文件（总计约 250MB）。本程序在热更新解压时自动剔除冗余副命令，仅保留核心 `magick.exe` 与色彩/策略配置文件（`sRGB.icc`, `*.xml`），并通过原子目录替换彻底清除旧版本，将内嵌引擎体积从 **250MB 降至 32.6MB（立省 87%）**，主程序 `PhotoZipper.exe` 仅 **654 KB**。

### 2. 尺寸调整（1:1 还原现代深色浮动标签 UI 并扩展）
- **浮动边框标签输入框**：支持 **宽度 (px)** 与 **高度 (px)** 独立设置（默认 `5120 × 1080`）。
- **保持宽高比 (仅缩小)**：对应 ImageMagick `WxH>` 几何修饰符，仅对超出目标尺寸的大图按比例缩小，绝不拉伸放大低分辨率小图。
- **多种缩放模式与重采样滤波器**：额外支持「按百分比缩放 (%)」、「限制最长边 (px)」以及 `Lanczos`、`Mitchell`、`Catrom`、`Triangle` 专业重采样算法。

### 3. 对标并超越主流压缩软件的专业功能
- **目标文件体积锁定 (Target File Size)**：可锁定单张图片压缩后的最大 KB 数（例如 `≤ 200 KB`），结合 `-define jpeg:extent` / `webp:target-size` 与自适应质量搜索，轻松应对证件照或网站上传限制。
- **纯无损模式 & 有损精细调优**：支持 `10% - 100%` 质量滑块、`4:2:0 / 4:4:4` 色度采样控制、渐进式 JPEG (`Plane` interlace)、智能防反向膨胀（若压缩后体积变大则自动保留原图）。
- **全格式批量互转**：支持保持原格式，或批量转换为 `JPEG`、`WebP`、`AVIF`、`PNG`、`JPEG XL (JXL)`。
- **隐私清理与色彩管理**：一键剥离 EXIF / GPS 拍摄定位隐私元数据 (`-strip`)、自动根据 EXIF 旋转回正 (`-auto-orient`)、统一转换至标准 `sRGB` 网页色域。
- **画质增强与防盗水印**：支持缩放后自适应 Unsharp 锐化补偿、色彩滤镜（黑白灰度、自动色阶增强、复古怀旧）、以及矢量文字水印叠加（可选位置与透明度）。
- **交互式前后画质分屏对比 (Before / After Split View)**：在列表中点击任意图片，即可拖动分屏滑块实时对比「原图 vs 压缩后」画质细节与压缩比。
- **实时资源监控**：顶部状态栏实时显示当前进程物理内存占用（通过延迟头部解析、缩略图 `sourceSize` 限制、进程池 `-limit memory 256MiB` 及 `SetProcessWorkingSetSize` 自动回收，处理完 6K/4K 大图后主程序内存仅 **~10 MB**）。

---

## 🛠️ 编译与运行指南

### 环境要求
- **操作系统**：Windows 10 / 11 (x64)
- **编译器**：Visual Studio 2022 / 2026 (MSVC 64-bit)
- **Qt SDK**：`D:\Qt\6.8.3\msvc2022_64` (Qt 6.5+ 均可)
- **构建工具**：CMake 3.21+ & Ninja

### 快速编译 (PowerShell / Developer Command Prompt)

```powershell
# 1. 进入 MSVC x64 编译环境并配置 CMake
cmd.exe /c '"D:\Microsoft Visual Studio\Community\VC\Auxiliary\Build\vcvars64.bat" && "D:\Microsoft Visual Studio\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="D:\Qt\6.8.3\msvc2022_64" -DCMAKE_MAKE_PROGRAM="D:\Microsoft Visual Studio\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe" && "D:\Microsoft Visual Studio\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" --build build --config Release'

# 2. 部署 Qt 运行时依赖
D:\Qt\6.8.3\msvc2022_64\bin\windeployqt.exe --release --no-translations --qmldir ./qml ./build/PhotoZipper.exe

# 3. 启动程序
./build/PhotoZipper.exe
```
