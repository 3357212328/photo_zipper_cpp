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
    connect(&m_timer, &QTimer::timeout, this, &MemoryMonitor::updateMemoryUsage);
    m_timer.start(2000);
    updateMemoryUsage();
}

void MemoryMonitor::updateMemoryUsage()
{
#ifdef Q_OS_WIN
    PROCESS_MEMORY_COUNTERS_EX pmc;
    if (GetProcessMemoryInfo(GetCurrentProcess(), reinterpret_cast<PROCESS_MEMORY_COUNTERS*>(&pmc), sizeof(pmc))) {
        m_appMemoryMB = static_cast<double>(pmc.WorkingSetSize) / (1024.0 * 1024.0);
        m_appMemoryText = QString::asprintf("%.1f MB", m_appMemoryMB);
    }
#endif
    QFileInfo appExe(QCoreApplication::applicationFilePath());
    if (appExe.exists()) {
        double exeMB = static_cast<double>(appExe.size()) / (1024.0 * 1024.0);
        m_appBinarySizeText = QString::asprintf("%.2f MB", exeMB);
    }
    emit statsChanged();
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

    if (totalBytes > 0) {
        m_engineSizeText = QString::asprintf("%.1f MB", static_cast<double>(totalBytes) / (1024.0 * 1024.0));
    } else {
        m_engineSizeText = QStringLiteral("未安装");
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
