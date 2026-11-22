#pragma once

#include <QObject>
#include <QString>
#include <QTimer>
#include <QUrl>
#include <atomic>

class ImageTaskModel;
class ImageMagickManager;
class MemoryMonitor;

class CompressionController : public QObject {
    Q_OBJECT
    // --- 尺寸调整 ---
    Q_PROPERTY(bool resizeEnabled READ resizeEnabled WRITE setResizeEnabled NOTIFY settingsChanged)
    Q_PROPERTY(int targetWidth READ targetWidth WRITE setTargetWidth NOTIFY settingsChanged)
    Q_PROPERTY(int targetHeight READ targetHeight WRITE setTargetHeight NOTIFY settingsChanged)
    Q_PROPERTY(bool keepAspectRatioShrinkOnly READ keepAspectRatioShrinkOnly WRITE setKeepAspectRatioShrinkOnly NOTIFY settingsChanged)
    Q_PROPERTY(int aspectDimension READ aspectDimension WRITE setAspectDimension NOTIFY settingsChanged) // 0=按宽度锁定, 1=按高度锁定
    // resizeMode: 0=按指定宽高, 1=按百分比缩放
    Q_PROPERTY(int resizeMode READ resizeMode WRITE setResizeMode NOTIFY settingsChanged)
    Q_PROPERTY(int resizePercentage READ resizePercentage WRITE setResizePercentage NOTIFY settingsChanged)
    Q_PROPERTY(int filterType READ filterType WRITE setFilterType NOTIFY settingsChanged) // 0=Lanczos, 1=Mitchell, 2=Catrom, 3=Triangle

    // --- 压缩与质量设置 ---
    Q_PROPERTY(int quality READ quality WRITE setQuality NOTIFY settingsChanged)
    Q_PROPERTY(bool losslessMode READ losslessMode WRITE setLosslessMode NOTIFY settingsChanged)
    Q_PROPERTY(bool targetSizeEnabled READ targetSizeEnabled WRITE setTargetSizeEnabled NOTIFY settingsChanged)
    Q_PROPERTY(int targetMaxKB READ targetMaxKB WRITE setTargetMaxKB NOTIFY settingsChanged)
    Q_PROPERTY(int chromaSubsampling READ chromaSubsampling WRITE setChromaSubsampling NOTIFY settingsChanged) // 0=自动, 1=4:2:0(高压缩), 2=4:4:4(色彩无损)
    Q_PROPERTY(bool progressiveJpeg READ progressiveJpeg WRITE setProgressiveJpeg NOTIFY settingsChanged)
    Q_PROPERTY(bool skipIfLarger READ skipIfLarger WRITE setSkipIfLarger NOTIFY settingsChanged)

    // --- 格式与色彩/隐私管理 ---
    Q_PROPERTY(QString outputFormat READ outputFormat WRITE setOutputFormat NOTIFY settingsChanged) // "original", "jpg", "png", "webp", "avif", "jxl"
    Q_PROPERTY(bool stripMetadata READ stripMetadata WRITE setStripMetadata NOTIFY settingsChanged)
    Q_PROPERTY(bool autoOrient READ autoOrient WRITE setAutoOrient NOTIFY settingsChanged)
    Q_PROPERTY(bool convertToSRGB READ convertToSRGB WRITE setConvertToSRGB NOTIFY settingsChanged)

    // --- 增强、滤镜与水印 (增值功能) ---
    Q_PROPERTY(bool sharpenAfterResize READ sharpenAfterResize WRITE setSharpenAfterResize NOTIFY settingsChanged)
    Q_PROPERTY(int colorFilter READ colorFilter WRITE setColorFilter NOTIFY settingsChanged) // 0=无, 1=黑白灰度, 2=自动色阶增强, 3=复古怀旧
    Q_PROPERTY(bool watermarkEnabled READ watermarkEnabled WRITE setWatermarkEnabled NOTIFY settingsChanged)
    Q_PROPERTY(QString watermarkText READ watermarkText WRITE setWatermarkText NOTIFY settingsChanged)
    Q_PROPERTY(int watermarkOpacity READ watermarkOpacity WRITE setWatermarkOpacity NOTIFY settingsChanged)
    Q_PROPERTY(int watermarkPosition READ watermarkPosition WRITE setWatermarkPosition NOTIFY settingsChanged) // 0=右下, 1=左下, 2=右上, 3=左上, 4=居中
    Q_PROPERTY(int watermarkFontSize READ watermarkFontSize WRITE setWatermarkFontSize NOTIFY settingsChanged)

    // --- 输出目录与命名 ---
    Q_PROPERTY(int outputDirMode READ outputDirMode WRITE setOutputDirMode NOTIFY settingsChanged) // 0=原图同级 compressed 子目录, 1=自定义目录, 2=覆盖原图
    Q_PROPERTY(QString customOutputDir READ customOutputDir WRITE setCustomOutputDir NOTIFY settingsChanged)
    Q_PROPERTY(QString filePrefix READ filePrefix WRITE setFilePrefix NOTIFY settingsChanged)
    Q_PROPERTY(QString fileSuffix READ fileSuffix WRITE setFileSuffix NOTIFY settingsChanged)
    Q_PROPERTY(int maxThreads READ maxThreads WRITE setMaxThreads NOTIFY settingsChanged)

    // --- 界面与状态持久化 ---
    Q_PROPERTY(int activePresetIndex READ activePresetIndex WRITE setActivePresetIndex NOTIFY settingsChanged)
    Q_PROPERTY(int activeSettingsTab READ activeSettingsTab WRITE setActiveSettingsTab NOTIFY settingsChanged)

    // --- 运行状态 ---
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY runningChanged)
    Q_PROPERTY(double batchProgress READ batchProgress NOTIFY progressChanged)
    Q_PROPERTY(QString commandPreview READ commandPreview NOTIFY settingsChanged)

public:
    explicit CompressionController(ImageTaskModel* model,
                                   ImageMagickManager* engineMgr,
                                   MemoryMonitor* memMonitor,
                                   QObject* parent = nullptr);
    ~CompressionController() override;

    bool resizeEnabled() const { return m_resizeEnabled; }
    void setResizeEnabled(bool v);
    int targetWidth() const { return m_targetWidth; }
    void setTargetWidth(int v);
    int targetHeight() const { return m_targetHeight; }
    void setTargetHeight(int v);
    bool keepAspectRatioShrinkOnly() const { return m_keepAspectRatioShrinkOnly; }
    void setKeepAspectRatioShrinkOnly(bool v);
    int aspectDimension() const { return m_aspectDimension; }
    void setAspectDimension(int v);
    int resizeMode() const { return m_resizeMode; }
    void setResizeMode(int v);
    int resizePercentage() const { return m_resizePercentage; }
    void setResizePercentage(int v);
    int filterType() const { return m_filterType; }
    void setFilterType(int v);

    int quality() const { return m_quality; }
    void setQuality(int v);
    bool losslessMode() const { return m_losslessMode; }
    void setLosslessMode(bool v);
    bool targetSizeEnabled() const { return m_targetSizeEnabled; }
    void setTargetSizeEnabled(bool v);
    int targetMaxKB() const { return m_targetMaxKB; }
    void setTargetMaxKB(int v);
    int chromaSubsampling() const { return m_chromaSubsampling; }
    void setChromaSubsampling(int v);
    bool progressiveJpeg() const { return m_progressiveJpeg; }
    void setProgressiveJpeg(bool v);
    bool skipIfLarger() const { return m_skipIfLarger; }
    void setSkipIfLarger(bool v);

    QString outputFormat() const { return m_outputFormat; }
    void setOutputFormat(const QString& v);
    bool stripMetadata() const { return m_stripMetadata; }
    void setStripMetadata(bool v);
    bool autoOrient() const { return m_autoOrient; }
    void setAutoOrient(bool v);
    bool convertToSRGB() const { return m_convertToSRGB; }
    void setConvertToSRGB(bool v);

    bool sharpenAfterResize() const { return m_sharpenAfterResize; }
    void setSharpenAfterResize(bool v);
    int colorFilter() const { return m_colorFilter; }
    void setColorFilter(int v);
    bool watermarkEnabled() const { return m_watermarkEnabled; }
    void setWatermarkEnabled(bool v);
    QString watermarkText() const { return m_watermarkText; }
    void setWatermarkText(const QString& v);
    int watermarkOpacity() const { return m_watermarkOpacity; }
    void setWatermarkOpacity(int v);
    int watermarkPosition() const { return m_watermarkPosition; }
    void setWatermarkPosition(int v);
    int watermarkFontSize() const { return m_watermarkFontSize; }
    void setWatermarkFontSize(int v);

    int outputDirMode() const { return m_outputDirMode; }
    void setOutputDirMode(int v);
    QString customOutputDir() const { return m_customOutputDir; }
    void setCustomOutputDir(const QString& v);
    QString filePrefix() const { return m_filePrefix; }
    void setFilePrefix(const QString& v);
    QString fileSuffix() const { return m_fileSuffix; }
    void setFileSuffix(const QString& v);
    int maxThreads() const { return m_maxThreads; }
    void setMaxThreads(int v);
    int activePresetIndex() const { return m_activePresetIndex; }
    void setActivePresetIndex(int v);
    int activeSettingsTab() const { return m_activeSettingsTab; }
    void setActiveSettingsTab(int v);

    bool isRunning() const { return m_isRunning; }
    double batchProgress() const { return m_batchProgress; }
    QString commandPreview() const;

    Q_INVOKABLE void applyPreset(int presetIndex);
    Q_INVOKABLE void startBatchCompression();
    Q_INVOKABLE void cancelBatchCompression();
    Q_INVOKABLE void compressSingleItem(int row);
    Q_INVOKABLE void openFileInExplorer(const QString& filePath);
    Q_INVOKABLE void saveSettings() const;

signals:
    void settingsChanged();
    void runningChanged();
    void progressChanged();
    void toastMessage(const QString& message, bool isError);
    void itemFinished(int row);

private:
    void loadSettings();
    QString resolveMagickTempRoot(const QString& outputDir) const;
    QStringList buildMagickArguments(const QString& inputPath,
                                     const QString& outputPath,
                                     const QString& targetExt,
                                     int overrideQuality = -1,
                                     const QString& tempDir = QString()) const;
    QString resolveOutputPath(const QString& inputPath, QString& outExt) const;

    ImageTaskModel* m_model = nullptr;
    ImageMagickManager* m_engineMgr = nullptr;
    MemoryMonitor* m_memMonitor = nullptr;
    QTimer m_saveTimer;

    // Default settings
    bool m_resizeEnabled = true;
    int m_targetWidth = 5120;
    int m_targetHeight = 1080;
    bool m_keepAspectRatioShrinkOnly = true;
    int m_aspectDimension = 0; // 0=按宽度, 1=按高度
    int m_resizeMode = 0;
    int m_resizePercentage = 75;
    int m_filterType = 0; // Lanczos

    int m_quality = 82;
    bool m_losslessMode = false;
    bool m_targetSizeEnabled = false;
    int m_targetMaxKB = 300;
    int m_chromaSubsampling = 1; // 4:2:0
    bool m_progressiveJpeg = true;
    bool m_skipIfLarger = true;

    QString m_outputFormat = QStringLiteral("original");
    bool m_stripMetadata = true;
    bool m_autoOrient = true;
    bool m_convertToSRGB = true;

    bool m_sharpenAfterResize = false;
    int m_colorFilter = 0;
    bool m_watermarkEnabled = false;
    QString m_watermarkText = QStringLiteral("© PhotoZipper");
    int m_watermarkOpacity = 65;
    int m_watermarkPosition = 0;
    int m_watermarkFontSize = 28;

    int m_outputDirMode = 0;
    QString m_customOutputDir;
    QString m_filePrefix;
    QString m_fileSuffix = QStringLiteral("_min");
    int m_maxThreads = 4;
    int m_activePresetIndex = 0;
    int m_activeSettingsTab = 0;

    bool m_isRunning = false;
    double m_batchProgress = 0.0;
    std::atomic<bool> m_cancelRequested{false};
};
