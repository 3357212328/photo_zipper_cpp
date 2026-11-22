#include "ImageTaskModel.h"
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QImageReader>
#include <QUuid>

namespace {
bool isSupportedImageExt(const QString& suffix) {
    static const QStringList exts = {
        QStringLiteral("jpg"), QStringLiteral("jpeg"), QStringLiteral("png"),
        QStringLiteral("webp"), QStringLiteral("avif"), QStringLiteral("jxl"),
        QStringLiteral("bmp"), QStringLiteral("tif"), QStringLiteral("tiff"),
        QStringLiteral("gif"), QStringLiteral("heic"), QStringLiteral("heif"),
        QStringLiteral("ico"), QStringLiteral("psd"), QStringLiteral("tga")
    };
    return exts.contains(suffix.toLower());
}
}

ImageTaskModel::ImageTaskModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

int ImageTaskModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) return 0;
    return m_items.size();
}

QVariant ImageTaskModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const ImageTaskItem& item = m_items.at(index.row());
    switch (role) {
    case IdRole: return item.id;
    case FilePathRole: return item.filePath;
    case FileNameRole: return item.fileName;
    case FileUrlRole: return QUrl::fromLocalFile(item.filePath);
    case FormatRole: return item.format;
    case OriginalSizeRole: return item.originalSize;
    case OriginalSizeTextRole: return formatBytes(item.originalSize);
    case CompressedSizeRole: return item.compressedSize;
    case CompressedSizeTextRole:
        return item.compressedSize > 0 ? formatBytes(item.compressedSize) : QStringLiteral("-");
    case DimensionsTextRole:
        return (item.originalWidth > 0 && item.originalHeight > 0)
                   ? QStringLiteral("%1 × %2").arg(item.originalWidth).arg(item.originalHeight)
                   : QStringLiteral("未知尺寸");
    case OutputDimensionsTextRole:
        return (item.outputWidth > 0 && item.outputHeight > 0)
                   ? QStringLiteral("%1 × %2").arg(item.outputWidth).arg(item.outputHeight)
                   : QStringLiteral("-");
    case SavedPercentTextRole: {
        if (item.compressedSize <= 0 || item.originalSize <= 0)
            return QStringLiteral("-");
        const double diff = static_cast<double>(item.originalSize - item.compressedSize);
        const double pct = (diff / static_cast<double>(item.originalSize)) * 100.0;
        if (pct >= 0.0) {
            return QString::asprintf("-%.1f%%", pct);
        } else {
            return QString::asprintf("+%.1f%%", -pct);
        }
    }
    case SavedPositiveRole:
        return item.compressedSize > 0 && item.compressedSize <= item.originalSize;
    case StatusRole: return item.status;
    case OutputPathRole: return item.outputPath;
    case OutputUrlRole:
        return item.outputPath.isEmpty() ? QUrl() : QUrl::fromLocalFile(item.outputPath);
    case ErrorMessageRole: return item.errorMessage;
    case ElapsedMsRole: return item.elapsedMs;
    default: return {};
    }
}

QHash<int, QByteArray> ImageTaskModel::roleNames() const
{
    return {
        {IdRole, "taskId"},
        {FilePathRole, "filePath"},
        {FileNameRole, "fileName"},
        {FileUrlRole, "fileUrl"},
        {FormatRole, "format"},
        {OriginalSizeRole, "originalSize"},
        {OriginalSizeTextRole, "originalSizeText"},
        {CompressedSizeRole, "compressedSize"},
        {CompressedSizeTextRole, "compressedSizeText"},
        {DimensionsTextRole, "dimensionsText"},
        {OutputDimensionsTextRole, "outputDimensionsText"},
        {SavedPercentTextRole, "savedPercentText"},
        {SavedPositiveRole, "savedPositive"},
        {StatusRole, "status"},
        {OutputPathRole, "outputPath"},
        {OutputUrlRole, "outputUrl"},
        {ErrorMessageRole, "errorMessage"},
        {ElapsedMsRole, "elapsedMs"}
    };
}

int ImageTaskModel::completedCount() const
{
    int count = 0;
    for (const auto& item : m_items) {
        if (item.status == QStringLiteral("已完成") || item.status == QStringLiteral("已跳过")) {
            ++count;
        }
    }
    return count;
}

QString ImageTaskModel::totalOriginalSizeText() const
{
    qint64 sum = 0;
    for (const auto& item : m_items) sum += item.originalSize;
    return formatBytes(sum);
}

QString ImageTaskModel::totalCompressedSizeText() const
{
    qint64 sum = 0;
    for (const auto& item : m_items) {
        if (item.compressedSize > 0) sum += item.compressedSize;
        else sum += item.originalSize;
    }
    return formatBytes(sum);
}

QString ImageTaskModel::totalSavedText() const
{
    qint64 origSum = 0;
    qint64 compSum = 0;
    for (const auto& item : m_items) {
        if (item.compressedSize > 0) {
            origSum += item.originalSize;
            compSum += item.compressedSize;
        }
    }
    const qint64 saved = qMax<qint64>(0, origSum - compSum);
    return formatBytes(saved);
}

double ImageTaskModel::totalSavedPercent() const
{
    qint64 origSum = 0;
    qint64 compSum = 0;
    for (const auto& item : m_items) {
        if (item.compressedSize > 0) {
            origSum += item.originalSize;
            compSum += item.compressedSize;
        }
    }
    if (origSum <= 0) return 0.0;
    return (static_cast<double>(origSum - compSum) / static_cast<double>(origSum)) * 100.0;
}

void ImageTaskModel::addUrls(const QList<QUrl>& urls)
{
    QStringList paths;
    paths.reserve(urls.size());
    for (const QUrl& url : urls) {
        if (url.isLocalFile()) {
            paths.append(url.toLocalFile());
        } else if (!url.toString().isEmpty()) {
            paths.append(url.toString());
        }
    }
    addFilePaths(paths);
}

void ImageTaskModel::addFilePaths(const QStringList& paths)
{
    int before = m_items.size();
    for (const QString& rawPath : paths) {
        const QFileInfo fi(rawPath);
        if (!fi.exists()) continue;

        if (fi.isDir()) {
            QDirIterator it(fi.absoluteFilePath(), QDir::Files, QDirIterator::Subdirectories);
            while (it.hasNext()) {
                it.next();
                if (isSupportedImageExt(it.fileInfo().suffix())) {
                    addSingleFile(it.fileInfo().absoluteFilePath());
                }
            }
        } else if (fi.isFile() && isSupportedImageExt(fi.suffix())) {
            addSingleFile(fi.absoluteFilePath());
        }
    }
    if (m_items.size() != before) {
        emit summaryChanged();
        emit itemAdded(m_items.size() - before);
    }
}

void ImageTaskModel::addSingleFile(const QString& localPath)
{
    const QFileInfo fi(localPath);
    const QString absPath = fi.absoluteFilePath();

    for (const auto& existing : m_items) {
        if (existing.filePath.compare(absPath, Qt::CaseInsensitive) == 0) {
            return;
        }
    }

    ImageTaskItem item;
    item.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    item.filePath = absPath;
    item.fileName = fi.fileName();
    item.format = fi.suffix().toUpper();
    item.originalSize = fi.size();

    // Only read image header without decoding full pixel buffer into memory!
    QImageReader reader(absPath);
    const QSize sz = reader.size();
    if (sz.isValid()) {
        item.originalWidth = sz.width();
        item.originalHeight = sz.height();
    }

    const int row = m_items.size();
    beginInsertRows(QModelIndex(), row, row);
    m_items.append(item);
    endInsertRows();
}

void ImageTaskModel::removeAt(int index)
{
    if (index < 0 || index >= m_items.size()) return;
    beginRemoveRows(QModelIndex(), index, index);
    m_items.removeAt(index);
    endRemoveRows();
    emit summaryChanged();
}

void ImageTaskModel::clearAll()
{
    if (m_items.isEmpty()) return;
    beginResetModel();
    m_items.clear();
    endResetModel();
    emit summaryChanged();
}

void ImageTaskModel::clearCompleted()
{
    for (int i = m_items.size() - 1; i >= 0; --i) {
        if (m_items[i].status == QStringLiteral("已完成") || m_items[i].status == QStringLiteral("已跳过")) {
            beginRemoveRows(QModelIndex(), i, i);
            m_items.removeAt(i);
            endRemoveRows();
        }
    }
    emit summaryChanged();
}

void ImageTaskModel::resetAllStatuses()
{
    if (m_items.isEmpty()) return;
    for (auto& item : m_items) {
        item.status = QStringLiteral("待处理");
        item.compressedSize = 0;
        item.outputWidth = 0;
        item.outputHeight = 0;
        item.outputPath.clear();
        item.errorMessage.clear();
        item.elapsedMs = 0;
    }
    emit dataChanged(index(0), index(m_items.size() - 1));
    emit summaryChanged();
}

QVariantMap ImageTaskModel::getItem(int row) const
{
    QVariantMap map;
    if (row < 0 || row >= m_items.size()) return map;
    const auto& it = m_items.at(row);
    map.insert(QStringLiteral("filePath"), it.filePath);
    map.insert(QStringLiteral("fileName"), it.fileName);
    map.insert(QStringLiteral("fileUrl"), QUrl::fromLocalFile(it.filePath));
    map.insert(QStringLiteral("format"), it.format);
    map.insert(QStringLiteral("originalSize"), it.originalSize);
    map.insert(QStringLiteral("originalWidth"), it.originalWidth);
    map.insert(QStringLiteral("originalHeight"), it.originalHeight);
    map.insert(QStringLiteral("originalSizeText"), formatBytes(it.originalSize));
    map.insert(QStringLiteral("compressedSize"), it.compressedSize);
    map.insert(QStringLiteral("compressedSizeText"), it.compressedSize > 0 ? formatBytes(it.compressedSize) : QStringLiteral("-"));
    map.insert(QStringLiteral("dimensionsText"), (it.originalWidth > 0 && it.originalHeight > 0) ? QStringLiteral("%1 × %2").arg(it.originalWidth).arg(it.originalHeight) : QStringLiteral("未知"));
    map.insert(QStringLiteral("outputDimensionsText"), (it.outputWidth > 0 && it.outputHeight > 0) ? QStringLiteral("%1 × %2").arg(it.outputWidth).arg(it.outputHeight) : QStringLiteral("-"));
    map.insert(QStringLiteral("status"), it.status);
    map.insert(QStringLiteral("outputPath"), it.outputPath);
    map.insert(QStringLiteral("outputUrl"), it.outputPath.isEmpty() ? QUrl() : QUrl::fromLocalFile(it.outputPath));
    map.insert(QStringLiteral("savedPercentText"), data(index(row), SavedPercentTextRole).toString());
    return map;
}

void ImageTaskModel::updateItemStatus(int row, const QString& status, qint64 compressedSize,
                                      const QString& outputPath, int outW, int outH,
                                      qint64 elapsedMs, const QString& errorMsg)
{
    if (row < 0 || row >= m_items.size()) return;
    ImageTaskItem& item = m_items[row];
    item.status = status;
    if (status == QStringLiteral("处理中")) {
        item.elapsedMs = 0;
        item.errorMessage.clear();
    }
    if (compressedSize >= 0) item.compressedSize = compressedSize;
    if (!outputPath.isEmpty()) item.outputPath = outputPath;
    if (outW > 0) item.outputWidth = outW;
    if (outH > 0) item.outputHeight = outH;
    if (elapsedMs > 0) item.elapsedMs = elapsedMs;
    item.errorMessage = errorMsg;

    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx);
    emit summaryChanged();
}

QString ImageTaskModel::formatBytes(qint64 bytes)
{
    if (bytes <= 0) return QStringLiteral("0 B");
    const double kb = 1024.0;
    const double mb = kb * 1024.0;
    const double gb = mb * 1024.0;
    if (bytes >= gb) {
        return QString::asprintf("%.2f GB", static_cast<double>(bytes) / gb);
    } else if (bytes >= mb) {
        return QString::asprintf("%.2f MB", static_cast<double>(bytes) / mb);
    } else if (bytes >= kb) {
        return QString::asprintf("%.1f KB", static_cast<double>(bytes) / kb);
    }
    return QStringLiteral("%1 B").arg(bytes);
}
