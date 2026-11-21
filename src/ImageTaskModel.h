#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QUrl>
#include <QVector>

struct ImageTaskItem {
    QString id;
    QString filePath;
    QString fileName;
    QString format;
    qint64 originalSize = 0;
    qint64 compressedSize = 0;
    int originalWidth = 0;
    int originalHeight = 0;
    int outputWidth = 0;
    int outputHeight = 0;
    QString status = QStringLiteral("待处理"); // 待处理, 处理中, 已完成, 已跳过, 失败
    QString outputPath;
    QString errorMessage;
    qint64 elapsedMs = 0;
};

class ImageTaskModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int totalCount READ totalCount NOTIFY summaryChanged)
    Q_PROPERTY(int completedCount READ completedCount NOTIFY summaryChanged)
    Q_PROPERTY(QString totalOriginalSizeText READ totalOriginalSizeText NOTIFY summaryChanged)
    Q_PROPERTY(QString totalCompressedSizeText READ totalCompressedSizeText NOTIFY summaryChanged)
    Q_PROPERTY(QString totalSavedText READ totalSavedText NOTIFY summaryChanged)
    Q_PROPERTY(double totalSavedPercent READ totalSavedPercent NOTIFY summaryChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        FilePathRole,
        FileNameRole,
        FileUrlRole,
        FormatRole,
        OriginalSizeRole,
        OriginalSizeTextRole,
        CompressedSizeRole,
        CompressedSizeTextRole,
        DimensionsTextRole,
        OutputDimensionsTextRole,
        SavedPercentTextRole,
        SavedPositiveRole,
        StatusRole,
        OutputPathRole,
        OutputUrlRole,
        ErrorMessageRole,
        ElapsedMsRole
    };

    explicit ImageTaskModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int totalCount() const { return m_items.size(); }
    int completedCount() const;
    QString totalOriginalSizeText() const;
    QString totalCompressedSizeText() const;
    QString totalSavedText() const;
    double totalSavedPercent() const;

    Q_INVOKABLE void addUrls(const QList<QUrl>& urls);
    Q_INVOKABLE void addFilePaths(const QStringList& paths);
    Q_INVOKABLE void removeAt(int index);
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE void clearCompleted();
    Q_INVOKABLE void resetAllStatuses();
    Q_INVOKABLE QVariantMap getItem(int index) const;

    const QVector<ImageTaskItem>& items() const { return m_items; }
    void updateItemStatus(int row, const QString& status, qint64 compressedSize = 0,
                          const QString& outputPath = QString(), int outW = 0, int outH = 0,
                          qint64 elapsedMs = 0, const QString& errorMsg = QString());

    static QString formatBytes(qint64 bytes);

signals:
    void summaryChanged();
    void itemAdded(int count);

private:
    void addSingleFile(const QString& localPath);
    QVector<ImageTaskItem> m_items;
};
