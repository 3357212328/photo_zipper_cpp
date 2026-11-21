# PhotoZipper C++ (Qt Quick + Embedded ImageMagick) Design Specification

## 1. Intent & Goals
Design and implement a modern, lightweight, high-performance image compression and batch processing desktop application in **C++20** and **Qt 6.8.3 (Qt Quick / QML)** on Windows (MSVC 2022 64-bit).

### Key Requirements
1. **Embedded ImageMagick Engine**:
   - Embed the official ImageMagick (`https://github.com/ImageMagick/ImageMagick`) portable engine directly inside the application (`engine/imagemagick`).
   - **Single-version policy & Size Control**: The official ImageMagick portable archive contains 8 redundant 31MB executables (`magick.exe`, `mogrify.exe`, `identify.exe`, `convert.exe`, etc.), totaling ~250MB. Since ImageMagick 7 unifies all subcommands into `magick.exe`, our engine installer/updater extracts only `magick.exe` and the required runtime configuration files (`*.xml`, `sRGB.icc`, `LICENSE.txt`), shrinking the embedded engine from **250MB down to ~31MB** (an 87% reduction!).
   - **In-App Version Management**: Query GitHub Releases (`api.github.com/repos/ImageMagick/ImageMagick/releases`) to list available versions, update to the **latest** version or switch to any **specific version** (plus quantum depth selection: `Q8` for lowest memory/size, `Q16`, `Q16-HDRI`), atomically replacing the old engine so **only one version exists on disk at any time**.
2. **Core Resize Settings (Matching Reference UI)**:
   - Dark modern card UI for **尺寸调整 (Dimension Adjustment)**:
     - `宽度 (px)` (Width input with floating label border style)
     - `高度 (px)` (Height input with floating label border style)
     - `保持宽高比 (仅缩小)` (Keep aspect ratio, shrink only — maps to ImageMagick `WxH>` geometry modifier, plus additional resize modes:按宽高比缩放、强制拉伸、按百分比缩放、长边限制).
3. **Competitive Feature Set (Beyond Basic Compression)**:
   - **Smart Compression Modes**:
     - Quality-based compression (`1-100` slider) with chroma subsampling (`4:2:0` / `4:4:4`), progressive JPEG (`Plane` interlace), and PNG/WebP/AVIF/JXL compression level controls.
     - **Target File Size Mode (目标体积锁定)**: Specify a maximum target KB (e.g., `200 KB`), leveraging ImageMagick's `-define jpeg:extent=200KB` or iterative quality search for non-JPEG formats.
     - **Lossless / Near-Lossless Optimization**: Dedicated switch for lossless pixel preservation while stripping bloat and optimizing Huffman/LZ77 tables.
   - **Format Conversion**: Keep original format, or batch convert to `JPEG`, `PNG`, `WebP`, `AVIF`, `JXL (JPEG XL)`, `TIFF`, `BMP`, `ICO`.
   - **Privacy & Color Management**:
     - Strip EXIF / GPS / XMP metadata (`-strip`).
     - Auto-orient (`-auto-orient`) before stripping metadata so portrait photos never rotate unexpectedly.
     - Convert to standard `sRGB` color space for web compatibility.
   - **Image Enhancement & Watermark Pipeline**:
     - Adaptive post-resize sharpening (`-unsharp`) to keep downscaled images crisp.
     - Color adjustments / filters (Grayscale, Sepia, Auto-Level/Contrast).
     - Text Watermark support (custom text, opacity, position: Bottom-Right, Center, etc., font size) rendered directly via ImageMagick inside the same pass.
   - **Interactive Before/After Split-View Comparison & Live Estimate**:
     - Built-in split-screen slider in QML comparing Original vs. Compressed preview image, showing zoom/pan, exact byte reduction, and compression ratio.
   - **Batch Processing & Output Management**:
     - Drag-and-drop files or entire folders (recursive scan).
     - Quick presets (Web 极速优化、摄影高清归档、社交媒体 1080p、证件照/限制大小、无损瘦身).
     - Output to custom folder, subfolder (`./compressed`), or overwrite original, with customizable filename prefix/suffix (e.g., `_min`).
4. **Strict Memory & Binary Size Control**:
   - UI thumbnails use `QQuickAsyncImageProvider` / `sourceSize` capped at `120x120` for list items and bounded preview dimensions so main process RAM stays under ~50-80MB even with 1,000+ 4K photos in the queue.
   - Worker processes pass `-limit memory 256MiB -limit map 512MiB` to ImageMagick so even massive images never spike system RAM.
   - Parallel task queue (`QThreadPool` / bounded concurrent `QProcess` workers based on CPU cores).
