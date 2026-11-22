#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QSurfaceFormat>
#include <QImageReader>
#include <QIcon>
#include <QFileInfo>

#include "ImageTaskModel.h"
#include "ImageMagickManager.h"
#include "CompressionController.h"
#include "MemoryMonitor.h"
#include "ThemeManager.h"

int main(int argc, char *argv[])
{
    // Avoid Windows hybrid-GPU (dGPU->iGPU) D3D11 DXGI Flip-Model + threaded render loop stutter during window drag.
    // OpenGL with basic render loop runs directly on the display-connected iGPU with native DWM window-move smoothness
    // and substantially lower RAM overhead. Allow env-var override for diagnostics.
    if (!qEnvironmentVariableIsSet("QSG_RENDER_LOOP")) {
        qputenv("QSG_RENDER_LOOP", "basic");
    }
    if (!qEnvironmentVariableIsSet("QSG_RHI_BACKEND")) {
        QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
    }
    QSurfaceFormat fmt = QSurfaceFormat::defaultFormat();
    fmt.setSwapBehavior(QSurfaceFormat::DoubleBuffer);
    fmt.setSwapInterval(1);
    QSurfaceFormat::setDefaultFormat(fmt);

    // Cap QImageReader allocation limit to 512MB for large 8K+ photos while keeping UI thumbnails small
    QImageReader::setAllocationLimit(512);
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("PhotoZipper"));
    app.setApplicationName(QStringLiteral("PhotoZipperCpp"));
    app.setApplicationVersion(QStringLiteral("1.0.0"));
    app.setWindowIcon(QIcon(QStringLiteral(":/icons/app_icon.png")));

    ThemeManager themeMgr;
    themeMgr.setIsWarmDay(false); // Default to dark mode on fresh start or user toggle
    MemoryMonitor memMonitor;
    ImageMagickManager engineMgr;
    ImageTaskModel taskModel;
    CompressionController compressCtrl(&taskModel, &engineMgr, &memMonitor);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("Theme"), &themeMgr);
    engine.rootContext()->setContextProperty(QStringLiteral("memMonitor"), &memMonitor);
    engine.rootContext()->setContextProperty(QStringLiteral("engineMgr"), &engineMgr);
    engine.rootContext()->setContextProperty(QStringLiteral("taskModel"), &taskModel);
    engine.rootContext()->setContextProperty(QStringLiteral("compressCtrl"), &compressCtrl);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("PhotoZipper", "Main");

    // Support "--capture-ui=<path>" and "--capture-active-ui=<path>" to render and grab the actual QQuickWindow screenshot for visual verification
    for (const QString& arg : app.arguments()) {
        if (arg.startsWith(QStringLiteral("--capture-active-ui="))) {
            const QString outPng = arg.mid(QStringLiteral("--capture-active-ui=").length());
            QTimer::singleShot(400, &app, [&]() {
                compressCtrl.generateSampleImages();
                QTimer::singleShot(300, &app, [&]() {
                    compressCtrl.startBatchCompression();
                });
            });
            QObject::connect(&compressCtrl, &CompressionController::runningChanged, &app, [&, outPng]() {
                if (!compressCtrl.isRunning() && taskModel.completedCount() > 0) {
                    const auto rootObjs = engine.rootObjects();
                    if (!rootObjs.isEmpty()) {
                        rootObjs.first()->setProperty("selectedTaskIndex", 0);
                        rootObjs.first()->setProperty("showComparePanel", true);
                        QMetaObject::invokeMethod(rootObjs.first(), "refreshSelectedPreview");
                    }
                    QTimer::singleShot(700, &app, [&, outPng]() {
                        const auto objs = engine.rootObjects();
                        if (!objs.isEmpty()) {
                            if (auto* win = qobject_cast<QQuickWindow*>(objs.first())) {
                                QImage shot = win->grabWindow();
                                shot.save(outPng, "PNG");
                            }
                        }
                        QCoreApplication::quit();
                    });
                }
            });
            return app.exec();
        }
        if (arg.startsWith(QStringLiteral("--capture-ui="))) {
            const QString outPng = arg.mid(QStringLiteral("--capture-ui=").length());
            const bool warm = app.arguments().contains(QStringLiteral("--warm"));
            const bool showEngine = app.arguments().contains(QStringLiteral("--dialog"));
            QTimer::singleShot(400, &app, [&, warm, showEngine]() {
                themeMgr.setIsWarmDay(warm);
                const auto rootObjs = engine.rootObjects();
                if (!rootObjs.isEmpty()) {
                    if (showEngine) {
                        QMetaObject::invokeMethod(rootObjs.first(), "openEngineDialog");
                    }
                }
            });
            QTimer::singleShot(1400, &app, [&, outPng]() {
                const auto rootObjs = engine.rootObjects();
                if (!rootObjs.isEmpty()) {
                    if (auto* win = qobject_cast<QQuickWindow*>(rootObjs.first())) {
                        QImage shot = win->grabWindow();
                        shot.save(outPng, "PNG");
                        qInfo() << "UI_CAPTURED:" << outPng << shot.size();
                    }
                }
                QCoreApplication::quit();
            });
            return app.exec();
        }
    }

    // Support "--self-test", "--test-engine-update", and "--test-local-update=<path>" flags for automated verification
    for (const QString& arg : app.arguments()) {
        if (arg.startsWith(QStringLiteral("--test-local-update="))) {
            const QString localPath = arg.mid(QStringLiteral("--test-local-update=").length());
            QObject::connect(&engineMgr, &ImageMagickManager::installationFinished, &app, [&](bool ok, const QString& msg) {
                qInfo() << "LOCAL_UPDATE_FINISHED:" << ok << msg << "currentVersion=" << engineMgr.currentVersion();
                QTimer::singleShot(400, &app, &QCoreApplication::quit);
            });
            QTimer::singleShot(300, &engineMgr, [&, localPath]() {
                if (QFileInfo(localPath).isDir()) {
                    engineMgr.installFromLocalDirectory(QUrl::fromLocalFile(localPath));
                } else {
                    engineMgr.installFromLocalArchive(QUrl::fromLocalFile(localPath));
                }
            });
            return app.exec();
        }
    }

    if (app.arguments().contains(QStringLiteral("--test-engine-update"))) {
        QObject::connect(&engineMgr, &ImageMagickManager::releasesChanged, &app, [&]() {
            const QVariantList rels = engineMgr.availableReleases();
            if (rels.size() >= 2) {
                // Pick the second latest release first, or latest release
                const QString targetTag = rels.at(1).toMap().value(QStringLiteral("tag")).toString();
                qInfo() << "TEST_UPDATE_STARTING: switching to version" << targetTag;
                engineMgr.installVersion(targetTag, QStringLiteral("Q8"));
            }
        });
        QObject::connect(&engineMgr, &ImageMagickManager::installationFinished, &app, [&](bool ok, const QString& msg) {
            qInfo() << "TEST_UPDATE_FINISHED:" << ok << msg << "currentVersion=" << engineMgr.currentVersion();
            QTimer::singleShot(500, &app, &QCoreApplication::quit);
        });
        QTimer::singleShot(300, &engineMgr, [&]() { engineMgr.fetchReleases(5); });
    } else if (app.arguments().contains(QStringLiteral("--self-test"))) {
        QTimer::singleShot(800, &app, [&]() {
            compressCtrl.generateSampleImages();
            QTimer::singleShot(600, &app, [&]() {
                compressCtrl.startBatchCompression();
            });
        });
        QObject::connect(&compressCtrl, &CompressionController::runningChanged, &app, [&]() {
            if (!compressCtrl.isRunning() && taskModel.completedCount() > 0) {
                qInfo() << "SELF_TEST_SUCCESS: completed=" << taskModel.completedCount()
                        << "orig=" << taskModel.totalOriginalSizeText()
                        << "comp=" << taskModel.totalCompressedSizeText()
                        << "saved=" << taskModel.totalSavedText()
                        << "ram=" << memMonitor.appMemoryText();
                QTimer::singleShot(1200, &app, &QCoreApplication::quit);
            }
        });
    }

    return app.exec();
}
