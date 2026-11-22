#include "MemoryMonitor.h"
#include <QCoreApplication>
#include <QDirIterator>
#include <QFileInfo>

#ifdef Q_OS_WIN
#include <windows.h>
#include <psapi.h>
#endif

MemoryMonitor::MemoryMonitor(QObject* parent)
    : QObject(parent)
{
    QFileInfo appExe(QCoreApplication::applicationFilePath());
    if (appExe.exists()) {
        double exeMB = static_cast<double>(appExe.size()) / (1024.0 * 1024.0);
        m_appBinarySizeText = QString::asprintf("%.2f MB", exeMB);
    }

    connect(&m_timer, &QTimer::timeout, this, &MemoryMonitor::updateMemoryUsage);
    m_timer.start(3000);
    updateMemoryUsage();
}

void MemoryMonitor::updateMemoryUsage()
{
    QString newMemText = m_appMemoryText;
#ifdef Q_OS_WIN
    PROCESS_MEMORY_COUNTERS_EX pmc;
    if (GetProcessMemoryInfo(GetCurrentProcess(), reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&pmc), sizeof(pmc))) {
        m_appMemoryMB = static_cast<double>(pmc.WorkingSetSize) / (1024.0 * 1024.0);
        newMemText = QString::asprintf("%.1f MB", m_appMemoryMB);
    }
#endif
    if (newMemText != m_appMemoryText) {
        m_appMemoryText = newMemText;
        emit statsChanged();
    }
}

void MemoryMonitor::refreshDiskSizes(const QString& engineDir)
{
    if (!engineDir.isEmpty()) {
        m_lastEngineDir = engineDir;
    }
    if (m_lastEngineDir.isEmpty()) return;

    qint64 totalBytes = 0;
    QDirIterator it(m_lastEngineDir, QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        it.next();
        totalBytes += it.fileInfo().size();
    }

    QString newEngineText = (totalBytes > 0)
        ? QString::asprintf("%.1f MB", static_cast<double>(totalBytes) / (1024.0 * 1024.0))
        : QStringLiteral("未安装");

    if (newEngineText != m_engineSizeText) {
        m_engineSizeText = newEngineText;
        emit statsChanged();
    }
    updateMemoryUsage();
}

void MemoryMonitor::trimWorkingSet()
{
#ifdef Q_OS_WIN
    SetProcessWorkingSetSize(GetCurrentProcess(), static_cast<SIZE_T>(-1), static_cast<SIZE_T>(-1));
#endif
    updateMemoryUsage();
}
