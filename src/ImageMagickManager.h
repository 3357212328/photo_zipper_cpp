#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QPointer>

class ImageMagickManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentVersion READ currentVersion NOTIFY engineChanged)
    Q_PROPERTY(QString currentQuantum READ currentQuantum NOTIFY engineChanged)
    Q_PROPERTY(QString currentFeatures READ currentFeatures NOTIFY engineChanged)
    Q_PROPERTY(QString magickExecutablePath READ magickExecutablePath NOTIFY engineChanged)
    Q_PROPERTY(QString engineDirectory READ engineDirectory CONSTANT)
    Q_PROPERTY(bool isInstalled READ isInstalled NOTIFY engineChanged)
    Q_PROPERTY(bool isBusy READ isBusy NOTIFY busyChanged)
    Q_PROPERTY(bool isFetchingReleases READ isFetchingReleases NOTIFY busyChanged)
    Q_PROPERTY(double downloadProgress READ downloadProgress NOTIFY progressChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusChanged)
    Q_PROPERTY(QVariantList availableReleases READ availableReleases NOTIFY releasesChanged)
    Q_PROPERTY(QString latestVersionTag READ latestVersionTag NOTIFY releasesChanged)
    Q_PROPERTY(bool hasUpdateAvailable READ hasUpdateAvailable NOTIFY releasesChanged)
    Q_PROPERTY(QString preferredQuantum READ preferredQuantum WRITE setPreferredQuantum NOTIFY preferredQuantumChanged)

public:
    explicit ImageMagickManager(QObject* parent = nullptr);
    ~ImageMagickManager() override;

    QString currentVersion() const { return m_currentVersion; }
    QString currentQuantum() const { return m_currentQuantum; }
    QString currentFeatures() const { return m_currentFeatures; }
    QString magickExecutablePath() const;
    QString engineDirectory() const;
    bool isInstalled() const;
    bool isBusy() const { return m_isBusy; }
    bool isFetchingReleases() const { return m_isFetchingReleases; }
    double downloadProgress() const { return m_downloadProgress; }
    QString statusMessage() const { return m_statusMessage; }
    QVariantList availableReleases() const { return m_availableReleases; }
    QString latestVersionTag() const { return m_latestVersionTag; }
    bool hasUpdateAvailable() const;
    QString preferredQuantum() const { return m_preferredQuantum; }
    void setPreferredQuantum(const QString& quantum);

    Q_INVOKABLE void detectLocalEngine();
    Q_INVOKABLE void fetchReleases(int maxCount = 20);
    Q_INVOKABLE void installVersion(const QString& tagName, const QString& quantum = QString());
    Q_INVOKABLE void installLatestVersion();
    Q_INVOKABLE void installFromLocalArchive(const QUrl& fileUrl);
    Q_INVOKABLE void installFromLocalDirectory(const QUrl& dirUrl);
    Q_INVOKABLE void cancelDownload();
    Q_INVOKABLE void cleanupTempFiles();

signals:
    void engineChanged();
    void busyChanged();
    void progressChanged();
    void statusChanged();
    void releasesChanged();
    void preferredQuantumChanged();
    void installationFinished(bool success, const QString& message);

private:
    void setStatus(const QString& msg);
    void startDownloadUrl(const QString& url, const QString& targetTag, const QString& quantum);
    bool extractAndSlimReplace(const QString& archivePath, const QString& targetTag, const QString& quantum, QString& errorMsg);
    bool slimAndReplaceFromExtractedDir(const QString& sourceRoot, QString& detectedVer, QString& errorMsg);
    QString findAssetUrlForRelease(const QVariantMap& releaseMap, const QString& quantum) const;

    QNetworkAccessManager m_netManager;
    QPointer<QNetworkReply> m_activeDownload;
    QString m_currentVersion = QStringLiteral("未检测到");
    QString m_currentQuantum = QStringLiteral("Q8");
    QString m_currentFeatures;
    QString m_preferredQuantum = QStringLiteral("Q8"); // Q8 (最省内存), Q16, Q16-HDRI
    bool m_isBusy = false;
    bool m_isFetchingReleases = false;
    double m_downloadProgress = 0.0;
    QString m_statusMessage = QStringLiteral("就绪");
    QVariantList m_availableReleases;
    QString m_latestVersionTag;
};
