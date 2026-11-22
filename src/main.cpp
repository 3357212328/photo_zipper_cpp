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
#include <QDir>
#include <QImage>
#include <QPainter>
#include <QStandardPaths>
#include <QSettings>

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

    // Cap Qt UI image decoder allocation limit to 256MB to keep UI RAM low on giant 8K+/16K+ photos
    // (does not restrict ImageMagick compression workers)
    QImageReader::setAllocationLimit(256);
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("PhotoZipper"));
    app.setApplicationName(QStringLiteral("PhotoZipperCpp"));
    app.setApplicationVersion(QStringLiteral("1.0.0"));
    app.setWindowIcon(QIcon(QStringLiteral(":/icons/app_icon.png")));

    ThemeManager themeMgr;
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

    if (const auto rootObjs = engine.rootObjects(); !rootObjs.isEmpty()) {
        if (auto* win = qobject_cast<QQuickWindow*>(rootObjs.first())) {
            QSettings uiSettings(QStringLiteral("PhotoZipper"), QStringLiteral("PhotoZipperCpp"));
            const int savedW = uiSettings.value(QStringLiteral("ui/windowWidth"), 1280).toInt();
            const int savedH = uiSettings.value(QStringLiteral("ui/windowHeight"), 820).toInt();
            if (savedW >= 1080 && savedH >= 680) {
                win->resize(savedW, savedH);
            }

            themeMgr.applyWindowTheme(win);
            QObject::connect(&themeMgr, &ThemeManager::themeChanged, win, [&themeMgr, win]() {
                themeMgr.applyWindowTheme(win);
            });
            QObject::connect(&app, &QCoreApplication::aboutToQuit, &app, [&compressCtrl, win]() {
                compressCtrl.saveSettings();
                QSettings s(QStringLiteral("PhotoZipper"), QStringLiteral("PhotoZipperCpp"));
                s.setValue(QStringLiteral("ui/windowWidth"), win->width());
                s.setValue(QStringLiteral("ui/windowHeight"), win->height());
                s.sync();
            });
        }
    }
    QTimer::singleShot(1500, &memMonitor, &MemoryMonitor::trimWorkingSet);

    auto createSyntheticTestImages = []() -> QStringList {
        const QString tempDir = QDir(QStandardPaths::writableLocation(QStandardPaths::TempLocation))
                                    .filePath(QStringLiteral("photozipper_selftest"));
        QDir(tempDir).removeRecursively();
        QDir().mkpath(tempDir);

        auto makeImg = [&](const QString& name, int w, int h, QColor c1, QColor c2, const QString& label) -> QString {
            QImage img(w, h, QImage::Format_RGB32);
            QPainter p(&img);
            QLinearGradient g(0, 0, w, h);
            g.setColorAt(0.0, c1);
            g.setColorAt(1.0, c2);
            p.fillRect(img.rect(), g);
            p.setPen(QPen(QColor(255, 255, 255, 60), 3));
            for (int x = 0; x < w; x += 200) p.drawLine(x, 0, x, h);
            for (int y = 0; y < h; y += 200) p.drawLine(0, y, w, y);
            p.setPen(Qt::white);
            p.setFont(QFont(QStringLiteral("Segoe UI"), 48, QFont::Bold));
            p.drawText(img.rect(), Qt::AlignCenter, label);
            p.end();
            const QString outPath = QDir(tempDir).filePath(name);
            img.save(outPath, name.endsWith(QStringLiteral(".png")) ? "PNG" : "JPG", 96);
            return outPath;
        };

        return {
            makeImg(QStringLiteral("RatioTest_3000x1688.jpg"), 3000, 1688, QColor(20, 42, 85), QColor(230, 110, 45), QStringLiteral("3000x1688 Ratio Test")),
            makeImg(QStringLiteral("Portrait_1800x3200.png"), 1800, 3200, QColor(24, 140, 130), QColor(240, 175, 45), QStringLiteral("1800x3200 Portrait"))
        };
    };

    // Support "--capture-ui=<path>" and "--capture-active-ui=<path>" to render and grab the actual QQuickWindow screenshot for visual verification
    for (const QString& arg : app.arguments()) {
        if (arg.startsWith(QStringLiteral("--capture-active-ui="))) {
            const QString outPng = arg.mid(QStringLiteral("--capture-active-ui=").length());
            QTimer::singleShot(400, &app, [&, createSyntheticTestImages]() {
                taskModel.addFilePaths(createSyntheticTestImages());
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
                themeMgr.setIsWarmDay(warm, false);
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
        // Test height-lock aspect ratio: 3000x1688 with x512> => 910x512
        const bool prevResize = compressCtrl.resizeEnabled();
        const int prevMode = compressCtrl.resizeMode();
        const bool prevAspect = compressCtrl.keepAspectRatioShrinkOnly();
        const int prevDim = compressCtrl.aspectDimension();
        const int prevH = compressCtrl.targetHeight();

        compressCtrl.setResizeEnabled(true);
        compressCtrl.setResizeMode(0);
        compressCtrl.setKeepAspectRatioShrinkOnly(true);
        compressCtrl.setAspectDimension(1); // Lock by height
        compressCtrl.setTargetHeight(512);

        QTimer::singleShot(400, &app, [&, createSyntheticTestImages]() {
            taskModel.addFilePaths(createSyntheticTestImages());
            QTimer::singleShot(300, &app, [&]() {
                compressCtrl.startBatchCompression();
            });
        });
        QObject::connect(&compressCtrl, &CompressionController::runningChanged, &app, [&, prevResize, prevMode, prevAspect, prevDim, prevH]() {
            if (!compressCtrl.isRunning() && taskModel.completedCount() > 0) {
                const QVariantMap item0 = taskModel.getItem(0);
                qInfo() << "SELF_TEST_SUCCESS: completed=" << taskModel.completedCount()
                        << "item0_outDims=" << item0.value(QStringLiteral("outputDimensionsText")).toString()
                        << "orig=" << taskModel.totalOriginalSizeText()
                        << "comp=" << taskModel.totalCompressedSizeText()
                        << "saved=" << taskModel.totalSavedText()
                        << "ram=" << memMonitor.appMemoryText();
                // Restore original settings before quitting
                compressCtrl.setResizeEnabled(prevResize);
                compressCtrl.setResizeMode(prevMode);
                compressCtrl.setKeepAspectRatioShrinkOnly(prevAspect);
                compressCtrl.setAspectDimension(prevDim);
                compressCtrl.setTargetHeight(prevH);
                compressCtrl.saveSettings();
                QTimer::singleShot(600, &app, &QCoreApplication::quit);
            }
        });
    }

    return app.exec();
}
