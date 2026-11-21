#include "ImageMagickManager.h"
#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>
#include <QProcess>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>
#include <QtConcurrent>

ImageMagickManager::ImageMagickManager(QObject* parent)
    : QObject(parent)
{
    QSettings settings(QStringLiteral("PhotoZipper"), QStringLiteral("PhotoZipperCpp"));
    m_preferredQuantum = settings.value(QStringLiteral("engine/preferredQuantum"), QStringLiteral("Q8")).toString();
    detectLocalEngine();
}

QString ImageMagickManager::engineDirectory() const
{
    return QDir(QCoreApplication::applicationDirPath()).filePath(QStringLiteral("engine/imagemagick"));
}

QString ImageMagickManager::magickExecutablePath() const
{
    return QDir(engineDirectory()).filePath(QStringLiteral("magick.exe"));
}

bool ImageMagickManager::isInstalled() const
{
    return QFileInfo::exists(magickExecutablePath());
}

bool ImageMagickManager::hasUpdateAvailable() const
{
    if (!isInstalled() || m_latestVersionTag.isEmpty() || m_currentVersion.isEmpty() || m_currentVersion == QStringLiteral("未检测到")) {
        return !m_latestVersionTag.isEmpty();
    }
    return m_currentVersion != m_latestVersionTag;
}

void ImageMagickManager::setPreferredQuantum(const QString& quantum)
{
    if (m_preferredQuantum == quantum) return;
    m_preferredQuantum = quantum;
    QSettings settings(QStringLiteral("PhotoZipper"), QStringLiteral("PhotoZipperCpp"));
    settings.setValue(QStringLiteral("engine/preferredQuantum"), m_preferredQuantum);
    emit preferredQuantumChanged();
}

void ImageMagickManager::setStatus(const QString& msg)
{
    m_statusMessage = msg;
    emit statusChanged();
}

void ImageMagickManager::detectLocalEngine()
{
    const QString exePath = magickExecutablePath();
    if (!QFileInfo::exists(exePath)) {
        m_currentVersion = QStringLiteral("未安装");
        m_currentQuantum = QStringLiteral("-");
        m_currentFeatures = QStringLiteral("请点击「引擎管理」一键下载并内嵌官方 ImageMagick");
        emit engineChanged();
        return;
    }

    QProcess proc;
    proc.setWorkingDirectory(engineDirectory());
    proc.start(exePath, {QStringLiteral("-version")});
    if (!proc.waitForFinished(4000)) {
        m_currentVersion = QStringLiteral("检测超时");
        emit engineChanged();
        return;
    }

    const QString output = QString::fromUtf8(proc.readAllStandardOutput());
    // Example: Version: ImageMagick 7.1.2-36 Q8 x64 dcec873:20261116 https://imagemagick.org
    static const QRegularExpression verRe(QStringLiteral(R"(ImageMagick\s+([0-9]+\.[0-9]+\.[0-9]+(?:-[0-9]+)?)\s+(Q16-HDRI|Q16|Q8))"));
    auto match = verRe.match(output);
    if (match.hasMatch()) {
        m_currentVersion = match.captured(1);
        m_currentQuantum = match.captured(2);
    } else {
        m_currentVersion = QStringLiteral("已知内嵌版");
    }

    static const QRegularExpression delRe(QStringLiteral(R"(Delegates \(built-in\):\s*([^\r\n]+))"));
    auto delMatch = delRe.match(output);
    if (delMatch.hasMatch()) {
        m_currentFeatures = delMatch.captured(1).trimmed();
    } else {
        m_currentFeatures = QStringLiteral("内置全格式编解码器 (JPEG / PNG / WebP / AVIF / HEIC / JXL / TIFF)");
    }

    emit engineChanged();
    emit releasesChanged();
}

void ImageMagickManager::fetchReleases(int maxCount)
{
    if (m_isFetchingReleases) return;
    m_isFetchingReleases = true;
    emit busyChanged();
    setStatus(QStringLiteral("正在从 GitHub 获取 ImageMagick 官方版本列表..."));

    QUrl url(QStringLiteral("https://api.github.com/repos/ImageMagick/ImageMagick/releases?per_page=%1").arg(maxCount));
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("PhotoZipperCpp/1.0 (Qt6)"));
    req.setRawHeader("Accept", "application/vnd.github+json");

    QNetworkReply* reply = m_netManager.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        m_isFetchingReleases = false;
        emit busyChanged();

        if (reply->error() != QNetworkReply::NoError) {
            setStatus(QStringLiteral("获取版本列表失败: %1").arg(reply->errorString()));
            return;
        }

        const QByteArray data = reply->readAll();
        const QJsonDocument doc = QJsonDocument::fromJson(data);
        if (!doc.isArray()) {
            setStatus(QStringLiteral("GitHub API 返回格式异常"));
            return;
        }

        QVariantList parsedList;
        const QJsonArray arr = doc.array();
        for (const QJsonValue& val : arr) {
            const QJsonObject obj = val.toObject();
            const QString tag = obj.value(QStringLiteral("tag_name")).toString();
            const QString publishedAt = obj.value(QStringLiteral("published_at")).toString().left(10);
            const QString name = obj.value(QStringLiteral("name")).toString();

            QVariantMap assetsByQuantum;
            QVariantMap sizeByQuantum;

            const QJsonArray assets = obj.value(QStringLiteral("assets")).toArray();
            for (const QJsonValue& aval : assets) {
                const QJsonObject aobj = aval.toObject();
                const QString aname = aobj.value(QStringLiteral("name")).toString();
                const QString durl = aobj.value(QStringLiteral("browser_download_url")).toString();
                const qint64 asize = aobj.value(QStringLiteral("size")).toVariant().toLongLong();

                // Match Windows x64 portable 7z or zip
                // e.g. ImageMagick-7.1.2-36-portable-Q8-x64.7z
                if (aname.contains(QStringLiteral("portable-")) &&
                    aname.contains(QStringLiteral("-x64.")) &&
                    !aname.contains(QStringLiteral("linux")) &&
                    (aname.endsWith(QStringLiteral(".7z")) || aname.endsWith(QStringLiteral(".zip")))) {

                    QString qType;
                    if (aname.contains(QStringLiteral("portable-Q16-HDRI-x64"))) {
                        qType = QStringLiteral("Q16-HDRI");
                    } else if (aname.contains(QStringLiteral("portable-Q16-x64"))) {
                        qType = QStringLiteral("Q16");
                    } else if (aname.contains(QStringLiteral("portable-Q8-x64"))) {
                        qType = QStringLiteral("Q8");
                    }
                    if (!qType.isEmpty()) {
                        assetsByQuantum.insert(qType, durl);
                        sizeByQuantum.insert(qType, QString::asprintf("%.2f MB", static_cast<double>(asize) / (1024.0 * 1024.0)));
                    }
                }
            }

            if (!assetsByQuantum.isEmpty()) {
                QVariantMap item;
                item.insert(QStringLiteral("tag"), tag);
                item.insert(QStringLiteral("name"), name.isEmpty() ? tag : name);
                item.insert(QStringLiteral("date"), publishedAt);
                item.insert(QStringLiteral("assets"), assetsByQuantum);
                item.insert(QStringLiteral("sizes"), sizeByQuantum);
                parsedList.append(item);
            }
        }

        m_availableReleases = parsedList;
        if (!m_availableReleases.isEmpty()) {
            m_latestVersionTag = m_availableReleases.first().toMap().value(QStringLiteral("tag")).toString();
            setStatus(QStringLiteral("已获取 %1 个官方版本，最新版: %2").arg(m_availableReleases.size()).arg(m_latestVersionTag));
        } else {
            setStatus(QStringLiteral("未找到适用的 Windows x64 Portable 版本"));
        }
        emit releasesChanged();
    });
}

QString ImageMagickManager::findAssetUrlForRelease(const QVariantMap& releaseMap, const QString& quantum) const
{
    const QVariantMap assets = releaseMap.value(QStringLiteral("assets")).toMap();
    if (assets.contains(quantum)) {
        return assets.value(quantum).toString();
    }
    if (assets.contains(QStringLiteral("Q8"))) return assets.value(QStringLiteral("Q8")).toString();
    if (assets.contains(QStringLiteral("Q16"))) return assets.value(QStringLiteral("Q16")).toString();
    if (assets.contains(QStringLiteral("Q16-HDRI"))) return assets.value(QStringLiteral("Q16-HDRI")).toString();
    return QString();
}

void ImageMagickManager::installLatestVersion()
{
    if (m_availableReleases.isEmpty()) {
        // Fetch first, then auto-install latest
        fetchReleases(10);
        auto conn = std::make_shared<QMetaObject::Connection>();
        *conn = connect(this, &ImageMagickManager::releasesChanged, this, [this, conn]() {
            disconnect(*conn);
            if (!m_latestVersionTag.isEmpty()) {
                installVersion(m_latestVersionTag, m_preferredQuantum);
            }
        });
        return;
    }
    installVersion(m_latestVersionTag, m_preferredQuantum);
}

void ImageMagickManager::installVersion(const QString& tagName, const QString& quantum)
{
    if (m_isBusy) return;
    const QString targetQuantum = quantum.isEmpty() ? m_preferredQuantum : quantum;

    QString downloadUrl;
    for (const QVariant& v : m_availableReleases) {
        const QVariantMap map = v.toMap();
        if (map.value(QStringLiteral("tag")).toString() == tagName) {
            downloadUrl = findAssetUrlForRelease(map, targetQuantum);
            break;
        }
    }

    if (downloadUrl.isEmpty()) {
        // Fallback direct URL pattern used by ImageMagick GitHub releases
        downloadUrl = QStringLiteral("https://github.com/ImageMagick/ImageMagick/releases/download/%1/ImageMagick-%1-portable-%2-x64.7z")
                          .arg(tagName, targetQuantum);
    }

    startDownloadUrl(downloadUrl, tagName, targetQuantum);
}

void ImageMagickManager::startDownloadUrl(const QString& url, const QString& targetTag, const QString& quantum)
{
    m_isBusy = true;
    m_downloadProgress = 0.0;
    emit busyChanged();
    emit progressChanged();
    setStatus(QStringLiteral("正在下载 ImageMagick %1 (%2)...").arg(targetTag, quantum));

    const QString tempRoot = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QDir().mkpath(tempRoot);
    const QString archivePath = QDir(tempRoot).filePath(QStringLiteral("im_update_%1.7z").arg(targetTag));
    QFile::remove(archivePath);

    QFile* outFile = new QFile(archivePath);
    if (!outFile->open(QIODevice::WriteOnly)) {
        delete outFile;
        m_isBusy = false;
        emit busyChanged();
        setStatus(QStringLiteral("无法创建临时下载文件: %1").arg(archivePath));
        emit installationFinished(false, m_statusMessage);
        return;
    }

    QNetworkRequest req{QUrl(url)};
    req.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("PhotoZipperCpp/1.0"));
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

    QNetworkReply* reply = m_netManager.get(req);
    m_activeDownload = reply;

    connect(reply, &QNetworkReply::readyRead, this, [reply, outFile]() {
        if (outFile->isOpen()) {
            outFile->write(reply->readAll());
        }
    });

    connect(reply, &QNetworkReply::downloadProgress, this, [this](qint64 received, qint64 total) {
        if (total > 0) {
            m_downloadProgress = static_cast<double>(received) / static_cast<double>(total);
            emit progressChanged();
            setStatus(QStringLiteral("正在下载引擎包... %1% (%2 / %3 MB)")
                          .arg(static_cast<int>(m_downloadProgress * 100))
                          .arg(received / (1024.0 * 1024.0), 0, 'f', 1)
                          .arg(total / (1024.0 * 1024.0), 0, 'f', 1));
        }
    });

    connect(reply, &QNetworkReply::finished, this, [this, reply, outFile, archivePath, targetTag, quantum]() {
        outFile->flush();
        outFile->close();
        delete outFile;
        reply->deleteLater();
        m_activeDownload.clear();

        if (reply->error() != QNetworkReply::NoError) {
            QFile::remove(archivePath);
            m_isBusy = false;
            emit busyChanged();
            setStatus(QStringLiteral("下载已取消或失败: %1").arg(reply->errorString()));
            emit installationFinished(false, m_statusMessage);
            return;
        }

        setStatus(QStringLiteral("正在解压、瘦身并清理旧版本 (严格保持单版本)..."));

        // Run extraction and atomic replacement on worker thread
        (void)QtConcurrent::run([this, archivePath, targetTag, quantum]() {
            QString err;
            const bool ok = extractAndSlimReplace(archivePath, targetTag, quantum, err);
            QFile::remove(archivePath);

            QMetaObject::invokeMethod(this, [this, ok, err, targetTag, quantum]() {
                m_isBusy = false;
                m_downloadProgress = ok ? 1.0 : 0.0;
                emit busyChanged();
                emit progressChanged();
                detectLocalEngine();

                if (ok) {
                    setStatus(QStringLiteral("已成功切换至 ImageMagick %1 (%2)，旧版本已彻底清除").arg(targetTag, quantum));
                    emit installationFinished(true, m_statusMessage);
                } else {
                    setStatus(QStringLiteral("安装引擎失败: %1").arg(err));
                    emit installationFinished(false, m_statusMessage);
                }
            }, Qt::QueuedConnection);
        });
    });
}

void ImageMagickManager::cancelDownload()
{
    if (m_activeDownload) {
        m_activeDownload->abort();
    }
}

void ImageMagickManager::installFromLocalArchive(const QUrl& fileUrl)
{
    if (m_isBusy) return;
    const QString localPath = fileUrl.isLocalFile() ? fileUrl.toLocalFile() : fileUrl.toString();
    const QFileInfo fi(localPath);
    if (!fi.exists() || !fi.isFile()) {
        setStatus(QStringLiteral("所选本地文件不存在: %1").arg(localPath));
        emit installationFinished(false, m_statusMessage);
        return;
    }

    m_isBusy = true;
    m_downloadProgress = 0.3;
    emit busyChanged();
    emit progressChanged();
    setStatus(QStringLiteral("正在从本地压缩包 (%1) 导入并替换 ImageMagick 引擎...").arg(fi.fileName()));

    (void)QtConcurrent::run([this, localPath, fileName = fi.fileName()]() {
        QString err;
        const bool ok = extractAndSlimReplace(localPath, fileName, QStringLiteral("Local"), err);

        QMetaObject::invokeMethod(this, [this, ok, err]() {
            m_isBusy = false;
            m_downloadProgress = ok ? 1.0 : 0.0;
            emit busyChanged();
            emit progressChanged();
            detectLocalEngine();

            if (ok) {
                setStatus(QStringLiteral("已成功从本地压缩包更新至 ImageMagick %1 (%2)，旧版本已彻底清除")
                              .arg(m_currentVersion, m_currentQuantum));
                emit installationFinished(true, m_statusMessage);
            } else {
                setStatus(QStringLiteral("本地压缩包导入失败: %1").arg(err));
                emit installationFinished(false, m_statusMessage);
            }
        }, Qt::QueuedConnection);
    });
}

void ImageMagickManager::installFromLocalDirectory(const QUrl& dirUrl)
{
    if (m_isBusy) return;
    const QString localDir = dirUrl.isLocalFile() ? dirUrl.toLocalFile() : dirUrl.toString();
    const QFileInfo fi(localDir);
    if (!fi.exists() || !fi.isDir()) {
        setStatus(QStringLiteral("所选本地目录不存在: %1").arg(localDir));
        emit installationFinished(false, m_statusMessage);
        return;
    }

    m_isBusy = true;
    m_downloadProgress = 0.5;
    emit busyChanged();
    emit progressChanged();
    setStatus(QStringLiteral("正在从本地目录 (%1) 校验、瘦身并替换 ImageMagick 引擎...").arg(fi.fileName()));

    (void)QtConcurrent::run([this, localDir]() {
        const QString appDir = QCoreApplication::applicationDirPath();
        const QString stagingDir = QDir(appDir).filePath(QStringLiteral("engine/staging_im"));
        QDir(stagingDir).removeRecursively();
        QDir().mkpath(stagingDir);

        // Locate magick.exe in localDir
        QString sourceRoot = localDir;
        if (!QFileInfo::exists(QDir(sourceRoot).filePath(QStringLiteral("magick.exe")))) {
            QDirIterator it(localDir, {QStringLiteral("magick.exe")}, QDir::Files, QDirIterator::Subdirectories);
            if (it.hasNext()) {
                it.next();
                sourceRoot = it.fileInfo().absolutePath();
            }
        }

        // Copy only required files (magick.exe, *.xml, *.icc, *.txt, *.dll if dll build) to stagingDir
        QDir srcDir(sourceRoot);
        const QStringList redundantFiles = {
            QStringLiteral("compare.exe"), QStringLiteral("composite.exe"),
            QStringLiteral("conjure.exe"), QStringLiteral("identify.exe"),
            QStringLiteral("mogrify.exe"), QStringLiteral("montage.exe"),
            QStringLiteral("stream.exe"),  QStringLiteral("convert.exe"),
            QStringLiteral("ChangeLog.md")
        };

        const QFileInfoList entries = srcDir.entryInfoList(QDir::Files | QDir::NoDotAndDotDot);
        for (const QFileInfo& entry : entries) {
            if (redundantFiles.contains(entry.fileName(), Qt::CaseInsensitive)) continue;
            QFile::copy(entry.absoluteFilePath(), QDir(stagingDir).filePath(entry.fileName()));
        }

        QString detectedVer;
        QString err;
        const bool ok = slimAndReplaceFromExtractedDir(stagingDir, detectedVer, err);
        QDir(stagingDir).removeRecursively();

        QMetaObject::invokeMethod(this, [this, ok, err]() {
            m_isBusy = false;
            m_downloadProgress = ok ? 1.0 : 0.0;
            emit busyChanged();
            emit progressChanged();
            detectLocalEngine();

            if (ok) {
                setStatus(QStringLiteral("已成功从本地目录切换至 ImageMagick %1 (%2)，旧版本已彻底清除")
                              .arg(m_currentVersion, m_currentQuantum));
                emit installationFinished(true, m_statusMessage);
            } else {
                setStatus(QStringLiteral("本地目录导入失败: %1").arg(err));
                emit installationFinished(false, m_statusMessage);
            }
        }, Qt::QueuedConnection);
    });
}

bool ImageMagickManager::extractAndSlimReplace(const QString& archivePath, const QString& targetTag, const QString& quantum, QString& errorMsg)
{
    Q_UNUSED(targetTag);
    Q_UNUSED(quantum);

    const QString appDir = QCoreApplication::applicationDirPath();
    const QString stagingDir = QDir(appDir).filePath(QStringLiteral("engine/staging_im"));
    QDir(stagingDir).removeRecursively();
    QDir().mkpath(stagingDir);

    // Use Windows built-in bsdtar (tar.exe) which natively supports .7z, .zip, .tar.xz, .tar.gz
    QProcess tarProc;
    tarProc.start(QStringLiteral("tar.exe"), {QStringLiteral("-xf"), archivePath, QStringLiteral("-C"), stagingDir});
    if (!tarProc.waitForFinished(60000) || tarProc.exitCode() != 0) {
        errorMsg = QStringLiteral("解压失败: %1").arg(QString::fromLocal8Bit(tarProc.readAllStandardError()));
        QDir(stagingDir).removeRecursively();
        return false;
    }

    QString detectedVer;
    const bool ok = slimAndReplaceFromExtractedDir(stagingDir, detectedVer, errorMsg);
    QDir(stagingDir).removeRecursively();
    return ok;
}

bool ImageMagickManager::slimAndReplaceFromExtractedDir(const QString& stagingDir, QString& detectedVer, QString& errorMsg)
{
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString finalDir = engineDirectory();
    const QString backupDir = QDir(appDir).filePath(QStringLiteral("engine/old_im"));
    QDir(backupDir).removeRecursively();

    // Locate magick.exe (either directly in stagingDir or inside a subfolder)
    QString extractedRoot = stagingDir;
    if (!QFileInfo::exists(QDir(extractedRoot).filePath(QStringLiteral("magick.exe")))) {
        QDirIterator it(stagingDir, {QStringLiteral("magick.exe")}, QDir::Files, QDirIterator::Subdirectories);
        if (it.hasNext()) {
            it.next();
            extractedRoot = it.fileInfo().absolutePath();
        } else {
            errorMsg = QStringLiteral("未找到有效的 magick.exe 核心程序");
            return false;
        }
    }

    // Remove redundant 31MB duplicate executables to keep only magick.exe + configs (~31MB total instead of 250MB)
    const QStringList redundantFiles = {
        QStringLiteral("compare.exe"),
        QStringLiteral("composite.exe"),
        QStringLiteral("conjure.exe"),
        QStringLiteral("identify.exe"),
        QStringLiteral("mogrify.exe"),
        QStringLiteral("montage.exe"),
        QStringLiteral("stream.exe"),
        QStringLiteral("convert.exe"),
        QStringLiteral("ChangeLog.md")
    };
    for (const QString& rfile : redundantFiles) {
        QFile::remove(QDir(extractedRoot).filePath(rfile));
    }

    // Verify the extracted magick.exe actually runs
    {
        QProcess testProc;
        testProc.setWorkingDirectory(extractedRoot);
        testProc.start(QDir(extractedRoot).filePath(QStringLiteral("magick.exe")), {QStringLiteral("-version")});
        if (!testProc.waitForFinished(5000) || testProc.exitCode() != 0) {
            errorMsg = QStringLiteral("magick.exe 校验运行失败，请确认选择了 Windows x64 版本的 ImageMagick");
            return false;
        }
        detectedVer = QString::fromUtf8(testProc.readAllStandardOutput());
    }

    // Atomic single-version swap: move existing finalDir -> backupDir, move extractedRoot -> finalDir, delete backupDir
    QDir parentDir(QDir(appDir).filePath(QStringLiteral("engine")));
    if (QDir(finalDir).exists()) {
        if (!parentDir.rename(QStringLiteral("imagemagick"), QStringLiteral("old_im"))) {
            if (!QDir(finalDir).removeRecursively()) {
                errorMsg = QStringLiteral("无法清理旧版 ImageMagick 目录，请确保没有正在进行的压缩任务");
                return false;
            }
        }
    }

    QDir().mkpath(finalDir);
    QDir srcDir(extractedRoot);
    const QFileInfoList entries = srcDir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QFileInfo& fi : entries) {
        const QString destPath = QDir(finalDir).filePath(fi.fileName());
        QFile::remove(destPath);
        if (!QFile::rename(fi.absoluteFilePath(), destPath)) {
            QFile::copy(fi.absoluteFilePath(), destPath);
        }
    }

    // Purge old backup so ONLY ONE VERSION exists on disk
    QDir(backupDir).removeRecursively();
    return true;
}
