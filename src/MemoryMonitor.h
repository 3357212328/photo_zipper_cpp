#pragma once

#include <QObject>
#include <QTimer>
#include <QString>

class MemoryMonitor : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString appMemoryText READ appMemoryText NOTIFY statsChanged)
    Q_PROPERTY(double appMemoryMB READ appMemoryMB NOTIFY statsChanged)
    Q_PROPERTY(QString engineSizeText READ engineSizeText NOTIFY statsChanged)
    Q_PROPERTY(QString appBinarySizeText READ appBinarySizeText NOTIFY statsChanged)

public:
    explicit MemoryMonitor(QObject* parent = nullptr);

    QString appMemoryText() const { return m_appMemoryText; }
    double appMemoryMB() const { return m_appMemoryMB; }
    QString engineSizeText() const { return m_engineSizeText; }
    QString appBinarySizeText() const { return m_appBinarySizeText; }

    Q_INVOKABLE void refreshDiskSizes(const QString& engineDir);
    Q_INVOKABLE void trimWorkingSet();

signals:
    void statsChanged();

private slots:
    void updateMemoryUsage();

private:
    QTimer m_timer;
    double m_appMemoryMB = 0.0;
    QString m_appMemoryText = QStringLiteral("0.0 MB");
    QString m_engineSizeText = QStringLiteral("未安装");
    QString m_appBinarySizeText = QStringLiteral("0.0 MB");
    QString m_lastEngineDir;
};
