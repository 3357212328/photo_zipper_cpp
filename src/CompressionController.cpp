#include "CompressionController.h"
#include "ImageTaskModel.h"
#include "ImageMagickManager.h"
#include "MemoryMonitor.h"

#include <QCoreApplication>
#include <QDesktopServices>
#include <QDir>
#include <QElapsedTimer>
#include <QFile>
#include <QFileInfo>
#include <QImageReader>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>
#include <QThread>
#include <QtConcurrent>
#include <atomic>

CompressionController::CompressionController(ImageTaskModel* model,
                                             ImageMagickManager* engineMgr,
                                             MemoryMonitor* memMonitor,
                                             QObject* parent)
    : QObject(parent)
    , m_model(model)
    , m_engineMgr(engineMgr)
    , m_memMonitor(memMonitor)
{
    m_maxThreads = qBound(1, QThread::idealThreadCount() / 2, 8);
    loadSettings();

    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(400);
    connect(&m_saveTimer, &QTimer::timeout, this, &CompressionController::saveSettings);
}

CompressionController::~CompressionController()
{
    saveSettings();
}

#define DEFINE_SETTER(Name, Member, Type) \
void CompressionController::Name(Type v) { \
    if (Member == v) return; \
    Member = v; \
    m_saveTimer.start(); \
    emit settingsChanged(); \
}

DEFINE_SETTER(setResizeEnabled, m_resizeEnabled, bool)
DEFINE_SETTER(setTargetWidth, m_targetWidth, int)
DEFINE_SETTER(setTargetHeight, m_targetHeight, int)
DEFINE_SETTER(setKeepAspectRatioShrinkOnly, m_keepAspectRatioShrinkOnly, bool)
DEFINE_SETTER(setAspectDimension, m_aspectDimension, int)
DEFINE_SETTER(setResizeMode, m_resizeMode, int)
DEFINE_SETTER(setResizePercentage, m_resizePercentage, int)
DEFINE_SETTER(setFilterType, m_filterType, int)
DEFINE_SETTER(setQuality, m_quality, int)
DEFINE_SETTER(setLosslessMode, m_losslessMode, bool)
DEFINE_SETTER(setTargetSizeEnabled, m_targetSizeEnabled, bool)
DEFINE_SETTER(setTargetMaxKB, m_targetMaxKB, int)
DEFINE_SETTER(setChromaSubsampling, m_chromaSubsampling, int)
DEFINE_SETTER(setProgressiveJpeg, m_progressiveJpeg, bool)
DEFINE_SETTER(setSkipIfLarger, m_skipIfLarger, bool)
DEFINE_SETTER(setOutputFormat, m_outputFormat, const QString&)
DEFINE_SETTER(setStripMetadata, m_stripMetadata, bool)
DEFINE_SETTER(setAutoOrient, m_autoOrient, bool)
DEFINE_SETTER(setConvertToSRGB, m_convertToSRGB, bool)
DEFINE_SETTER(setSharpenAfterResize, m_sharpenAfterResize, bool)
DEFINE_SETTER(setColorFilter, m_colorFilter, int)
DEFINE_SETTER(setWatermarkEnabled, m_watermarkEnabled, bool)
DEFINE_SETTER(setWatermarkText, m_watermarkText, const QString&)
DEFINE_SETTER(setWatermarkOpacity, m_watermarkOpacity, int)
DEFINE_SETTER(setWatermarkPosition, m_watermarkPosition, int)
DEFINE_SETTER(setWatermarkFontSize, m_watermarkFontSize, int)
DEFINE_SETTER(setOutputDirMode, m_outputDirMode, int)
DEFINE_SETTER(setCustomOutputDir, m_customOutputDir, const QString&)
DEFINE_SETTER(setFilePrefix, m_filePrefix, const QString&)
DEFINE_SETTER(setFileSuffix, m_fileSuffix, const QString&)
DEFINE_SETTER(setMaxThreads, m_maxThreads, int)
DEFINE_SETTER(setActivePresetIndex, m_activePresetIndex, int)
DEFINE_SETTER(setActiveSettingsTab, m_activeSettingsTab, int)

void CompressionController::loadSettings()
{
    QSettings s(QStringLiteral("PhotoZipper"), QStringLiteral("PhotoZipperCpp"));
    s.beginGroup(QStringLiteral("compression"));
    m_resizeEnabled = s.value(QStringLiteral("resizeEnabled"), m_resizeEnabled).toBool();
    m_targetWidth = s.value(QStringLiteral("targetWidth"), m_targetWidth).toInt();
    m_targetHeight = s.value(QStringLiteral("targetHeight"), m_targetHeight).toInt();
    m_keepAspectRatioShrinkOnly = s.value(QStringLiteral("keepAspectRatioShrinkOnly"), m_keepAspectRatioShrinkOnly).toBool();
    m_aspectDimension = qBound(0, s.value(QStringLiteral("aspectDimension"), m_aspectDimension).toInt(), 1);
    m_resizeMode = qBound(0, s.value(QStringLiteral("resizeMode"), m_resizeMode).toInt(), 1);
    m_resizePercentage = qBound(1, s.value(QStringLiteral("resizePercentage"), m_resizePercentage).toInt(), 200);
    m_filterType = qBound(0, s.value(QStringLiteral("filterType"), m_filterType).toInt(), 3);

    m_quality = qBound(10, s.value(QStringLiteral("quality"), m_quality).toInt(), 100);
    m_losslessMode = s.value(QStringLiteral("losslessMode"), m_losslessMode).toBool();
    m_targetSizeEnabled = s.value(QStringLiteral("targetSizeEnabled"), m_targetSizeEnabled).toBool();
    m_targetMaxKB = qMax(5, s.value(QStringLiteral("targetMaxKB"), m_targetMaxKB).toInt());
    m_chromaSubsampling = qBound(0, s.value(QStringLiteral("chromaSubsampling"), m_chromaSubsampling).toInt(), 2);
    m_progressiveJpeg = s.value(QStringLiteral("progressiveJpeg"), m_progressiveJpeg).toBool();
    m_skipIfLarger = s.value(QStringLiteral("skipIfLarger"), m_skipIfLarger).toBool();

    m_outputFormat = s.value(QStringLiteral("outputFormat"), m_outputFormat).toString();
    m_stripMetadata = s.value(QStringLiteral("stripMetadata"), m_stripMetadata).toBool();
    m_autoOrient = s.value(QStringLiteral("autoOrient"), m_autoOrient).toBool();
    m_convertToSRGB = s.value(QStringLiteral("convertToSRGB"), m_convertToSRGB).toBool();

    m_sharpenAfterResize = s.value(QStringLiteral("sharpenAfterResize"), m_sharpenAfterResize).toBool();
    m_colorFilter = qBound(0, s.value(QStringLiteral("colorFilter"), m_colorFilter).toInt(), 3);
    m_watermarkEnabled = s.value(QStringLiteral("watermarkEnabled"), m_watermarkEnabled).toBool();
    m_watermarkText = s.value(QStringLiteral("watermarkText"), m_watermarkText).toString();
    m_watermarkOpacity = qBound(10, s.value(QStringLiteral("watermarkOpacity"), m_watermarkOpacity).toInt(), 100);
    m_watermarkPosition = qBound(0, s.value(QStringLiteral("watermarkPosition"), m_watermarkPosition).toInt(), 4);
    m_watermarkFontSize = qBound(10, s.value(QStringLiteral("watermarkFontSize"), m_watermarkFontSize).toInt(), 200);

    m_outputDirMode = qBound(0, s.value(QStringLiteral("outputDirMode"), m_outputDirMode).toInt(), 2);
    m_customOutputDir = s.value(QStringLiteral("customOutputDir"), m_customOutputDir).toString();
    m_filePrefix = s.value(QStringLiteral("filePrefix"), m_filePrefix).toString();
    m_fileSuffix = s.value(QStringLiteral("fileSuffix"), m_fileSuffix).toString();
    m_maxThreads = qBound(1, s.value(QStringLiteral("maxThreads"), m_maxThreads).toInt(), 8);
    m_activePresetIndex = qBound(0, s.value(QStringLiteral("activePresetIndex"), m_activePresetIndex).toInt(), 4);
    m_activeSettingsTab = qBound(0, s.value(QStringLiteral("activeSettingsTab"), m_activeSettingsTab).toInt(), 2);
    s.endGroup();
}

void CompressionController::saveSettings() const
{
    QSettings s(QStringLiteral("PhotoZipper"), QStringLiteral("PhotoZipperCpp"));
    s.beginGroup(QStringLiteral("compression"));
    s.setValue(QStringLiteral("resizeEnabled"), m_resizeEnabled);
    s.setValue(QStringLiteral("targetWidth"), m_targetWidth);
    s.setValue(QStringLiteral("targetHeight"), m_targetHeight);
    s.setValue(QStringLiteral("keepAspectRatioShrinkOnly"), m_keepAspectRatioShrinkOnly);
    s.setValue(QStringLiteral("aspectDimension"), m_aspectDimension);
    s.setValue(QStringLiteral("resizeMode"), m_resizeMode);
    s.setValue(QStringLiteral("resizePercentage"), m_resizePercentage);
    s.setValue(QStringLiteral("filterType"), m_filterType);

    s.setValue(QStringLiteral("quality"), m_quality);
    s.setValue(QStringLiteral("losslessMode"), m_losslessMode);
    s.setValue(QStringLiteral("targetSizeEnabled"), m_targetSizeEnabled);
    s.setValue(QStringLiteral("targetMaxKB"), m_targetMaxKB);
    s.setValue(QStringLiteral("chromaSubsampling"), m_chromaSubsampling);
    s.setValue(QStringLiteral("progressiveJpeg"), m_progressiveJpeg);
    s.setValue(QStringLiteral("skipIfLarger"), m_skipIfLarger);

    s.setValue(QStringLiteral("outputFormat"), m_outputFormat);
    s.setValue(QStringLiteral("stripMetadata"), m_stripMetadata);
    s.setValue(QStringLiteral("autoOrient"), m_autoOrient);
    s.setValue(QStringLiteral("convertToSRGB"), m_convertToSRGB);

    s.setValue(QStringLiteral("sharpenAfterResize"), m_sharpenAfterResize);
    s.setValue(QStringLiteral("colorFilter"), m_colorFilter);
    s.setValue(QStringLiteral("watermarkEnabled"), m_watermarkEnabled);
    s.setValue(QStringLiteral("watermarkText"), m_watermarkText);
    s.setValue(QStringLiteral("watermarkOpacity"), m_watermarkOpacity);
    s.setValue(QStringLiteral("watermarkPosition"), m_watermarkPosition);
    s.setValue(QStringLiteral("watermarkFontSize"), m_watermarkFontSize);

    s.setValue(QStringLiteral("outputDirMode"), m_outputDirMode);
    s.setValue(QStringLiteral("customOutputDir"), m_customOutputDir);
    s.setValue(QStringLiteral("filePrefix"), m_filePrefix);
    s.setValue(QStringLiteral("fileSuffix"), m_fileSuffix);
    s.setValue(QStringLiteral("maxThreads"), m_maxThreads);
    s.setValue(QStringLiteral("activePresetIndex"), m_activePresetIndex);
    s.setValue(QStringLiteral("activeSettingsTab"), m_activeSettingsTab);
    s.endGroup();
    s.sync();
}

void CompressionController::applyPreset(int presetIndex)
{
    m_activePresetIndex = presetIndex;
    switch (presetIndex) {
    case 0: // 默认均衡瘦身
        m_resizeEnabled = true;
        m_resizeMode = 0;
        m_targetWidth = 5120;
        m_targetHeight = 1080;
        m_keepAspectRatioShrinkOnly = true;
        m_aspectDimension = 0;
        m_quality = 82;
        m_losslessMode = false;
        m_targetSizeEnabled = false;
        m_stripMetadata = true;
        m_autoOrient = true;
        m_convertToSRGB = true;
        m_outputFormat = QStringLiteral("original");
        break;
    case 1: // Web 极速优化
        m_resizeEnabled = true;
        m_resizeMode = 0;
        m_targetWidth = 1920;
        m_targetHeight = 1080;
        m_keepAspectRatioShrinkOnly = true;
        m_aspectDimension = 0;
        m_quality = 78;
        m_losslessMode = false;
        m_targetSizeEnabled = false;
        m_stripMetadata = true;
        m_autoOrient = true;
        m_convertToSRGB = true;
        m_outputFormat = QStringLiteral("webp");
        break;
    case 2: // 摄影高清归档
        m_resizeEnabled = false;
        m_quality = 92;
        m_losslessMode = false;
        m_chromaSubsampling = 2; // 4:4:4
        m_targetSizeEnabled = false;
        m_stripMetadata = false;
        m_autoOrient = true;
        m_outputFormat = QStringLiteral("original");
        break;
    case 3: // 严格体积限制
        m_resizeEnabled = true;
        m_resizeMode = 0;
        m_targetWidth = 2560;
        m_targetHeight = 1440;
        m_keepAspectRatioShrinkOnly = true;
        m_aspectDimension = 0;
        m_quality = 80;
        m_losslessMode = false;
        m_targetSizeEnabled = true;
        m_targetMaxKB = 200;
        m_stripMetadata = true;
        m_outputFormat = QStringLiteral("jpg");
        break;
    case 4: // 纯无损极限瘦身
        m_resizeEnabled = false;
        m_losslessMode = true;
        m_quality = 100;
        m_targetSizeEnabled = false;
        m_stripMetadata = true;
        m_outputFormat = QStringLiteral("original");
        break;
    default:
        break;
    }
    saveSettings();
    emit settingsChanged();
    emit toastMessage(QStringLiteral("已应用预设配置"), false);
}

QString CompressionController::resolveOutputPath(const QString& inputPath, QString& outExt) const
{
    const QFileInfo fi(inputPath);
    outExt = (m_outputFormat == QStringLiteral("original") || m_outputFormat.isEmpty())
                 ? fi.suffix().toLower()
                 : m_outputFormat.toLower();
    if (outExt == QStringLiteral("jpeg")) outExt = QStringLiteral("jpg");

    if (m_outputDirMode == 2) {
        // Overwrite original (or replace extension in same folder)
        return QDir(fi.absolutePath()).filePath(fi.completeBaseName() + QStringLiteral(".") + outExt);
    }

    QString targetDir;
    if (m_outputDirMode == 1 && !m_customOutputDir.trimmed().isEmpty()) {
        QUrl url(m_customOutputDir);
        targetDir = url.isLocalFile() ? url.toLocalFile() : m_customOutputDir;
    } else {
        targetDir = QDir(fi.absolutePath()).filePath(QStringLiteral("compressed"));
    }

    QDir().mkpath(targetDir);
    const QString baseName = m_filePrefix + fi.completeBaseName() + m_fileSuffix;
    return QDir(targetDir).filePath(baseName + QStringLiteral(".") + outExt);
}

QStringList CompressionController::buildMagickArguments(const QString& inputPath,
                                                        const QString& outputPath,
                                                        const QString& targetExt,
                                                        int overrideQuality) const
{
    QStringList args;

    // 1. Strict memory caps per worker process so large images never spike system RAM
    args << QStringLiteral("-limit") << QStringLiteral("memory") << QStringLiteral("256MiB")
         << QStringLiteral("-limit") << QStringLiteral("map") << QStringLiteral("512MiB")
         << QStringLiteral("-limit") << QStringLiteral("thread") << QStringLiteral("2");

    args << inputPath;

    // 2. Auto-orient before stripping EXIF
    if (m_autoOrient) {
        args << QStringLiteral("-auto-orient");
    }

    // 3. Resizing (matching the uploaded screenshot's Width / Height / Keep aspect ratio shrink only)
    if (m_resizeEnabled) {
        static const QStringList filters = {
            QStringLiteral("Lanczos"),
            QStringLiteral("Mitchell"),
            QStringLiteral("Catrom"),
            QStringLiteral("Triangle")
        };
        const QString filterName = filters.value(m_filterType, QStringLiteral("Lanczos"));
        args << QStringLiteral("-filter") << filterName;

        QString geometry;
        if (m_resizeMode == 0) {
            if (m_keepAspectRatioShrinkOnly) {
                if (m_aspectDimension == 0) {
                    if (m_targetWidth > 0) geometry = QStringLiteral("%1x>").arg(m_targetWidth);
                } else {
                    if (m_targetHeight > 0) geometry = QStringLiteral("x%1>").arg(m_targetHeight);
                }
            } else {
                const QString wStr = m_targetWidth > 0 ? QString::number(m_targetWidth) : QString();
                const QString hStr = m_targetHeight > 0 ? QString::number(m_targetHeight) : QString();
                if (!wStr.isEmpty() && !hStr.isEmpty()) {
                    geometry = QStringLiteral("%1x%2!").arg(wStr, hStr);
                } else if (!wStr.isEmpty()) {
                    geometry = QStringLiteral("%1x").arg(wStr);
                } else if (!hStr.isEmpty()) {
                    geometry = QStringLiteral("x%1").arg(hStr);
                }
            }
        } else if (m_resizeMode == 1) {
            geometry = QStringLiteral("%1%").arg(qBound(1, m_resizePercentage, 200));
        }

        if (!geometry.isEmpty()) {
            args << QStringLiteral("-resize") << geometry;
        }

        if (m_sharpenAfterResize) {
            args << QStringLiteral("-unsharp") << QStringLiteral("0x0.75+0.75+0.008");
        }
    }

    // 4. Color space & filters
    if (m_convertToSRGB) {
        args << QStringLiteral("-colorspace") << QStringLiteral("sRGB");
    }

    if (m_colorFilter == 1) {
        args << QStringLiteral("-colorspace") << QStringLiteral("Gray");
    } else if (m_colorFilter == 2) {
        args << QStringLiteral("-auto-level") << QStringLiteral("-contrast");
    } else if (m_colorFilter == 3) {
        args << QStringLiteral("-sepia-tone") << QStringLiteral("80%");
    }

    // 5. Watermark (text overlay via ImageMagick annotate)
    if (m_watermarkEnabled && !m_watermarkText.trimmed().isEmpty()) {
        static const QStringList gravities = {
            QStringLiteral("SouthEast"),
            QStringLiteral("SouthWest"),
            QStringLiteral("NorthEast"),
            QStringLiteral("NorthWest"),
            QStringLiteral("Center")
        };
        const QString gravity = gravities.value(m_watermarkPosition, QStringLiteral("SouthEast"));
        const double alpha = qBound(10, m_watermarkOpacity, 100) / 100.0;
        args << QStringLiteral("-gravity") << gravity
             << QStringLiteral("-pointsize") << QString::number(qMax(10, m_watermarkFontSize))
             << QStringLiteral("-fill") << QString::asprintf("rgba(255,255,255,%.2f)", alpha)
             << QStringLiteral("-undercolor") << QString::asprintf("rgba(0,0,0,%.2f)", alpha * 0.45)
             << QStringLiteral("-annotate") << QStringLiteral("+16+16") << m_watermarkText;
    }

    // 6. Metadata stripping
    if (m_stripMetadata) {
        args << QStringLiteral("-strip");
    }

    // 7. Format-specific compression & quality arguments
    const int effQuality = overrideQuality > 0 ? overrideQuality : m_quality;
    const QString ext = targetExt.toLower();

    if (ext == QStringLiteral("jpg") || ext == QStringLiteral("jpeg")) {
        if (m_progressiveJpeg) {
            args << QStringLiteral("-interlace") << QStringLiteral("Plane");
        }
        if (m_chromaSubsampling == 1) {
            args << QStringLiteral("-sampling-factor") << QStringLiteral("4:2:0");
        } else if (m_chromaSubsampling == 2) {
            args << QStringLiteral("-sampling-factor") << QStringLiteral("4:4:4");
        }
        args << QStringLiteral("-define") << QStringLiteral("jpeg:optimize-coding=true");
        if (m_targetSizeEnabled && m_targetMaxKB > 0) {
            args << QStringLiteral("-define") << QStringLiteral("jpeg:extent=%1KB").arg(m_targetMaxKB);
        }
        args << QStringLiteral("-quality") << QString::number(m_losslessMode ? 100 : effQuality);
    } else if (ext == QStringLiteral("png")) {
        // High-compression zlib level 9 + adaptive filtering
        args << QStringLiteral("-define") << QStringLiteral("png:compression-level=9")
             << QStringLiteral("-define") << QStringLiteral("png:compression-strategy=1");
        if (!m_losslessMode && effQuality < 95) {
            // Quantize colors slightly when user chooses lossy PNG compression
            const int colors = qBound(32, (effQuality * 256) / 100, 256);
            args << QStringLiteral("-colors") << QString::number(colors);
        }
    } else if (ext == QStringLiteral("webp")) {
        args << QStringLiteral("-define") << QStringLiteral("webp:method=6")
             << QStringLiteral("-define") << QStringLiteral("webp:thread-level=1");
        if (m_losslessMode) {
            args << QStringLiteral("-define") << QStringLiteral("webp:lossless=true");
        } else if (m_targetSizeEnabled && m_targetMaxKB > 0) {
            args << QStringLiteral("-define") << QStringLiteral("webp:target-size=%1").arg(m_targetMaxKB * 1024);
        }
        args << QStringLiteral("-quality") << QString::number(effQuality);
    } else {
        args << QStringLiteral("-quality") << QString::number(m_losslessMode ? 100 : effQuality);
    }

    args << outputPath;
    return args;
}

QString CompressionController::commandPreview() const
{
    QString dummyExt = (m_outputFormat == QStringLiteral("original")) ? QStringLiteral("jpg") : m_outputFormat;
    QStringList args = buildMagickArguments(QStringLiteral("input.jpg"),
                                            QStringLiteral("output_min.") + dummyExt,
                                            dummyExt);
    return QStringLiteral("magick ") + args.join(QLatin1Char(' '));
}

void CompressionController::startBatchCompression()
{
    if (m_isRunning) return;
    if (!m_engineMgr || !m_engineMgr->isInstalled()) {
        emit toastMessage(QStringLiteral("未检测到内嵌 ImageMagick 引擎，请先点击顶部「引擎管理」安装！"), true);
        return;
    }
    if (!m_model || m_model->totalCount() == 0) {
        emit toastMessage(QStringLiteral("队列为空，请先拖入或添加要压缩的图片！"), true);
        return;
    }

    m_isRunning = true;
    m_cancelRequested.store(false);
    m_batchProgress = 0.0;
    emit runningChanged();
    emit progressChanged();

    const QString magickExe = m_engineMgr->magickExecutablePath();
    const QString magickDir = m_engineMgr->engineDirectory();
    const int total = m_model->totalCount();
    const int threads = qBound(1, m_maxThreads, 8);

    (void)QtConcurrent::run([this, magickExe, magickDir, total, threads]() {
        std::atomic<int> finishedCounter{0};
        QThreadPool pool;
        pool.setMaxThreadCount(threads);

        QVector<QFuture<void>> futures;
        futures.reserve(total);

        for (int row = 0; row < total; ++row) {
            futures.append(QtConcurrent::run(&pool, [this, row, total, magickExe, magickDir, &finishedCounter]() {
                if (m_cancelRequested.load()) return;

                const QVariantMap itemMap = m_model->getItem(row);
                const QString inputPath = itemMap.value(QStringLiteral("filePath")).toString();
                const qint64 origSize = itemMap.value(QStringLiteral("originalSize")).toLongLong();

                QMetaObject::invokeMethod(m_model, [this, row]() {
                    m_model->updateItemStatus(row, QStringLiteral("处理中"));
                }, Qt::QueuedConnection);

                QElapsedTimer timer;
                timer.start();

                QString outExt;
                const QString finalOutputPath = resolveOutputPath(inputPath, outExt);

                // Write to a temporary file first so we can safely compare sizes & overwrite if needed
                const QString tempOutputPath = finalOutputPath + QStringLiteral(".tmp_pz.") + outExt;
                QFile::remove(tempOutputPath);

                const QStringList args = buildMagickArguments(inputPath, tempOutputPath, outExt);

                QProcess proc;
                proc.setWorkingDirectory(magickDir);
                proc.start(magickExe, args);
                const bool finished = proc.waitForFinished(120000);
                const qint64 elapsed = timer.elapsed();

                if (!finished || proc.exitCode() != 0 || !QFileInfo::exists(tempOutputPath)) {
                    const QString err = QString::fromLocal8Bit(proc.readAllStandardError()).trimmed();
                    QFile::remove(tempOutputPath);
                    QMetaObject::invokeMethod(this, [this, row, elapsed, err]() {
                        m_model->updateItemStatus(row, QStringLiteral("失败"), 0, QString(), 0, 0, elapsed,
                                                  err.isEmpty() ? QStringLiteral("ImageMagick 转换失败") : err);
                    }, Qt::QueuedConnection);
                } else {
                    // Iterative target-size fallback for formats where extent wasn't enough
                    if (m_targetSizeEnabled && m_targetMaxKB > 0) {
                        const qint64 maxBytes = static_cast<qint64>(m_targetMaxKB) * 1024;
                        int tryQ = 70;
                        while (QFileInfo(tempOutputPath).size() > maxBytes && tryQ >= 20 && !m_cancelRequested.load()) {
                            QProcess retryProc;
                            retryProc.setWorkingDirectory(magickDir);
                            retryProc.start(magickExe, buildMagickArguments(inputPath, tempOutputPath, outExt, tryQ));
                            retryProc.waitForFinished(60000);
                            tryQ -= 15;
                        }
                    }

                    const QFileInfo outFi(tempOutputPath);
                    qint64 compSize = outFi.size();
                    bool skipped = false;

                    // Smart skip-if-larger when format is unchanged
                    const QString origExt = QFileInfo(inputPath).suffix().toLower();
                    const bool sameFormat = (origExt == outExt) || (origExt == QStringLiteral("jpeg") && outExt == QStringLiteral("jpg"));
                    if (m_skipIfLarger && sameFormat && compSize >= origSize) {
                        QFile::remove(tempOutputPath);
                        if (finalOutputPath.compare(inputPath, Qt::CaseInsensitive) != 0) {
                            QFile::remove(finalOutputPath);
                            QFile::copy(inputPath, finalOutputPath);
                        }
                        compSize = origSize;
                        skipped = true;
                    } else {
                        QFile::remove(finalOutputPath);
                        QFile::rename(tempOutputPath, finalOutputPath);
                    }

                    QImageReader reader(finalOutputPath);
                    const QSize outSz = reader.size();
                    const int outW = outSz.isValid() ? outSz.width() : 0;
                    const int outH = outSz.isValid() ? outSz.height() : 0;
                    const QString statusStr = skipped ? QStringLiteral("已跳过") : QStringLiteral("已完成");

                    QMetaObject::invokeMethod(this, [this, row, statusStr, compSize, finalOutputPath, outW, outH, elapsed]() {
                        m_model->updateItemStatus(row, statusStr, compSize, finalOutputPath, outW, outH, elapsed);
                        emit itemFinished(row);
                    }, Qt::QueuedConnection);
                }

                const int doneNow = ++finishedCounter;
                QMetaObject::invokeMethod(this, [this, doneNow, total]() {
                    m_batchProgress = static_cast<double>(doneNow) / static_cast<double>(total);
                    emit progressChanged();
                }, Qt::QueuedConnection);
            }));
        }

        for (auto& f : futures) {
            f.waitForFinished();
        }

        QMetaObject::invokeMethod(this, [this]() {
            m_isRunning = false;
            emit runningChanged();
            if (m_memMonitor) {
                m_memMonitor->trimWorkingSet();
            }
            if (m_cancelRequested.load()) {
                emit toastMessage(QStringLiteral("已中止批量压缩任务"), true);
            } else {
                emit toastMessage(QStringLiteral("全部图片压缩处理完成！共节省 %1").arg(m_model->totalSavedText()), false);
            }
        }, Qt::QueuedConnection);
    });
}

void CompressionController::cancelBatchCompression()
{
    if (!m_isRunning) return;
    m_cancelRequested.store(true);
}

void CompressionController::compressSingleItem(int row)
{
    if (m_isRunning || !m_model || row < 0 || row >= m_model->totalCount()) return;
    startBatchCompression();
}

void CompressionController::openFileInExplorer(const QString& filePath)
{
    if (filePath.isEmpty()) return;
    const QFileInfo fi(filePath);
    if (!fi.exists()) return;
#ifdef Q_OS_WIN
    QProcess::startDetached(QStringLiteral("explorer.exe"),
                            {QStringLiteral("/select,"), QDir::toNativeSeparators(fi.absoluteFilePath())});
#else
    QDesktopServices::openUrl(QUrl::fromLocalFile(fi.absolutePath()));
#endif
}
