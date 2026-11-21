import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import "components"

ApplicationWindow {
    id: window
    width: 1280
    height: 840
    minimumWidth: 1020
    minimumHeight: 680
    visible: true
    title: "PhotoZipper C++ · 现代高性能图片压缩工作站 (Powered by ImageMagick)"
    color: "#1E2024"

    property int selectedTaskIndex: -1
    property string toastText: ""
    property bool toastError: false

    function refreshSelectedPreview() {
        if (selectedTaskIndex < 0 || selectedTaskIndex >= taskModel.totalCount) {
            compareView.originalUrl = ""
            compareView.compressedUrl = ""
            compareView.originalInfo = ""
            compareView.compressedInfo = ""
            compareView.savedPercent = ""
            return
        }
        var info = taskModel.getItem(selectedTaskIndex)
        compareView.originalUrl = info.fileUrl || ""
        compareView.compressedUrl = info.outputUrl || ""
        compareView.fileName = info.fileName || ""
        compareView.originalInfo = (info.dimensionsText || "") + " · " + (info.originalSizeText || "")
        compareView.compressedInfo = (info.outputDimensionsText !== "-" ? (info.outputDimensionsText + " · ") : "") + (info.compressedSizeText || "")
        compareView.savedPercent = info.savedPercentText || ""
    }

    function showToast(msg, isErr) {
        window.toastText = msg
        window.toastError = isErr
        toastTimer.restart()
    }

    Timer {
        id: toastTimer
        interval: 4200
        onTriggered: window.toastText = ""
    }

    Connections {
        target: compressCtrl
        function onToastMessage(message, isError) {
            window.showToast(message, isError)
        }
        function onItemFinished(row) {
            if (row === window.selectedTaskIndex) {
                window.refreshSelectedPreview()
            }
        }
    }

    Connections {
        target: taskModel
        function onItemAdded(count) {
            if (window.selectedTaskIndex < 0 && taskModel.totalCount > 0) {
                window.selectedTaskIndex = 0
                window.refreshSelectedPreview()
            }
        }
    }

    Connections {
        target: engineMgr
        function onEngineChanged() {
            memMonitor.refreshDiskSizes(engineMgr.engineDirectory)
        }
        function onInstallationFinished(success, message) {
            memMonitor.refreshDiskSizes(engineMgr.engineDirectory)
            window.showToast(message, !success)
        }
    }

    Component.onCompleted: {
        memMonitor.refreshDiskSizes(engineMgr.engineDirectory)
    }

    // Dialogs
    FileDialog {
        id: addFilesDialog
        title: "选择要压缩的图片"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["图片文件 (*.jpg *.jpeg *.png *.webp *.avif *.jxl *.bmp *.tif *.tiff *.gif *.heic *.ico)", "所有文件 (*.*)"]
        onAccepted: taskModel.addUrls(selectedFiles)
    }

    FolderDialog {
        id: addFolderDialog
        title: "选择图片文件夹（自动递归扫描）"
        onAccepted: taskModel.addUrls([selectedFolder])
    }

    FolderDialog {
        id: customOutputFolderDialog
        title: "选择输出保存目录"
        onAccepted: compressCtrl.customOutputDir = selectedFolder.toString()
    }

    EngineUpdateDialog {
        id: engineDialog
        anchors.centerIn: Overlay.overlay
        engineManager: engineMgr
        memoryMonitor: memMonitor
    }

    // Full-window drag & drop support
    DropArea {
        id: globalDropArea
        anchors.fill: parent
        onDropped: function(drop) {
            if (drop.hasUrls) {
                taskModel.addUrls(drop.urls)
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ==================== TOP HEADER BAR ====================
        Rectangle {
            Layout.fillWidth: true
            height: 58
            color: "#17191C"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 14

                // Brand Logo
                Rectangle {
                    width: 36
                    height: 36
                    radius: 8
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#94C1FA" }
                        GradientStop { position: 1.0; color: "#4E82D4" }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "PZ"
                        font.family: "Segoe UI"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#10141D"
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "PhotoZipper C++"
                        font.family: "Segoe UI"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#F1F5F9"
                    }
                    Text {
                        text: "Qt Quick 6.8 · 内嵌 ImageMagick 高性能图像压缩引擎"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        color: "#8A919E"
                    }
                }

                Item { Layout.fillWidth: true }

                // Resource & Memory Monitor Pill
                Rectangle {
                    height: 34
                    width: resRow.implicitWidth + 24
                    radius: 17
                    color: "#23262C"
                    border.color: "#343942"

                    RowLayout {
                        id: resRow
                        anchors.centerIn: parent
                        spacing: 14

                        Text {
                            text: "🧠 运行内存: " + memMonitor.appMemoryText
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            color: "#A5F3FC"
                        }
                        Rectangle { width: 1; height: 14; color: "#3A3F4B" }
                        Text {
                            text: "📦 主程序: " + memMonitor.appBinarySizeText + " · 引擎: " + memMonitor.engineSizeText
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            color: "#CBD5E1"
                        }
                    }
                }

                // Embedded ImageMagick Status & Version Switcher Button
                Rectangle {
                    height: 36
                    width: engBtnRow.implicitWidth + 24
                    radius: 8
                    color: engMa.containsMouse ? "#2F3642" : "#262A32"
                    border.color: engineMgr.isInstalled ? "#4E74A6" : "#E11D48"

                    RowLayout {
                        id: engBtnRow
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: engineMgr.isInstalled ? "#4ADE80" : "#FB7185"
                        }
                        Text {
                            text: engineMgr.isInstalled
                                  ? ("ImageMagick " + engineMgr.currentVersion + " (" + engineMgr.currentQuantum + ")")
                                  : "未安装引擎 (点击一键内嵌)"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#E2E8F0"
                        }
                        Rectangle {
                            radius: 4
                            color: "#375582"
                            height: 20
                            width: 62
                            Text {
                                anchors.centerIn: parent
                                text: "引擎管理"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                color: "#FFFFFF"
                            }
                        }
                    }

                    MouseArea {
                        id: engMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: engineDialog.open()
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#2B2F37"
            }
        }

        // ==================== MAIN WORKSPACE ====================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16
            spacing: 16

            // ---------- LEFT PANE: Batch Queue + Before/After Split Preview ----------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // Action Toolbar
                Rectangle {
                    Layout.fillWidth: true
                    height: 50
                    radius: 10
                    color: "#26292E"
                    border.color: "#343842"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        // Add Files Button
                        Rectangle {
                            height: 34
                            width: 104
                            radius: 6
                            color: addFileMa.containsMouse ? "#A5CDFC" : "#94C1FA"
                            Text {
                                anchors.centerIn: parent
                                text: "＋ 添加图片"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#10151E"
                            }
                            MouseArea {
                                id: addFileMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: addFilesDialog.open()
                            }
                        }

                        // Add Folder Button
                        Rectangle {
                            height: 34
                            width: 112
                            radius: 6
                            color: addDirMa.containsMouse ? "#383D47" : "#2F333B"
                            border.color: "#454B57"
                            Text {
                                anchors.centerIn: parent
                                text: "📁 添加文件夹"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 12
                                color: "#E2E8F0"
                            }
                            MouseArea {
                                id: addDirMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: addFolderDialog.open()
                            }
                        }

                        // Generate Sample Test Images Button
                        Rectangle {
                            height: 34
                            width: 122
                            radius: 6
                            color: sampleMa.containsMouse ? "#383D47" : "#2F333B"
                            border.color: "#454B57"
                            Text {
                                anchors.centerIn: parent
                                text: "✨ 导入测试样张"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 12
                                color: "#94C1FA"
                            }
                            MouseArea {
                                id: sampleMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: compressCtrl.generateSampleImages()
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Summary statistics pill
                        Text {
                            visible: taskModel.totalCount > 0
                            text: "共 " + taskModel.totalCount + " 张 · 原总计 " + taskModel.totalOriginalSizeText
                                  + " → 压缩后 " + taskModel.totalCompressedSizeText
                                  + " (已省 " + taskModel.totalSavedText + ")"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            color: "#86EFAC"
                        }

                        // Clear Completed
                        Rectangle {
                            visible: taskModel.completedCount > 0
                            height: 30
                            width: 84
                            radius: 6
                            color: clrDoneMa.containsMouse ? "#383D47" : "transparent"
                            border.color: "#454B57"
                            Text {
                                anchors.centerIn: parent
                                text: "清理已完成"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                color: "#CBD5E1"
                            }
                            MouseArea {
                                id: clrDoneMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    taskModel.clearCompleted()
                                    window.selectedTaskIndex = taskModel.totalCount > 0 ? 0 : -1
                                    window.refreshSelectedPreview()
                                }
                            }
                        }

                        // Clear All
                        Rectangle {
                            visible: taskModel.totalCount > 0
                            height: 30
                            width: 72
                            radius: 6
                            color: clrAllMa.containsMouse ? "#4C1D24" : "transparent"
                            border.color: "#573239"
                            Text {
                                anchors.centerIn: parent
                                text: "清空列表"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                color: "#FDA4AF"
                            }
                            MouseArea {
                                id: clrAllMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    taskModel.clearAll()
                                    window.selectedTaskIndex = -1
                                    window.refreshSelectedPreview()
                                }
                            }
                        }
                    }
                }

                // Task Queue List Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 330
                    color: "#23262B"
                    radius: 10
                    border.color: globalDropArea.containsDrag ? "#94C1FA" : "#343842"
                    border.width: globalDropArea.containsDrag ? 2 : 1
                    clip: true

                    // Empty Dropzone prompt
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: taskModel.totalCount === 0
                        spacing: 12

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 68
                            height: 68
                            radius: 34
                            color: "#2C3038"
                            border.color: "#434956"
                            Text {
                                anchors.centerIn: parent
                                text: "📥"
                                font.pixelSize: 30
                            }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "拖拽图片或整个文件夹到这里"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#E2E8F0"
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "支持 JPG / PNG / WebP / AVIF / JXL / HEIC / TIFF / BMP / GIF 等全格式批量处理"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            color: "#8A919E"
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12
                            Rectangle {
                                width: 132
                                height: 36
                                radius: 6
                                color: "#94C1FA"
                                Text {
                                    anchors.centerIn: parent
                                    text: "选择本地图片"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#11161F"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: addFilesDialog.open()
                                }
                            }
                            Rectangle {
                                width: 156
                                height: 36
                                radius: 6
                                color: "#2F343D"
                                border.color: "#4B5362"
                                Text {
                                    anchors.centerIn: parent
                                    text: "✨ 一键生成测试样张"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 13
                                    color: "#E2E8F0"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: compressCtrl.generateSampleImages()
                                }
                            }
                        }
                    }

                    ListView {
                        id: taskListView
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6
                        visible: taskModel.totalCount > 0
                        model: taskModel
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle {
                            width: taskListView.width - 10
                            height: 62
                            radius: 8
                            readonly property bool isSelected: index === window.selectedTaskIndex
                            color: isSelected ? "#2D384B" : (rowMa.containsMouse ? "#2B2F37" : "#282B31")
                            border.color: isSelected ? "#6E9EE0" : "#353942"

                            MouseArea {
                                id: rowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.selectedTaskIndex = index
                                    window.refreshSelectedPreview()
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 12
                                spacing: 12

                                // Low-memory thumbnail (capped at 96x96 sourceSize)
                                Rectangle {
                                    width: 46
                                    height: 46
                                    radius: 6
                                    color: "#1B1D21"
                                    border.color: "#3D424D"
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 2
                                        source: model.fileUrl
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                        sourceSize.width: 96
                                        sourceSize.height: 96
                                    }
                                }

                                // File name & dimensions
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3
                                    RowLayout {
                                        spacing: 6
                                        Rectangle {
                                            radius: 4
                                            color: "#363C48"
                                            height: 18
                                            width: fmtTxt.implicitWidth + 10
                                            Text {
                                                id: fmtTxt
                                                anchors.centerIn: parent
                                                text: model.format
                                                font.family: "Segoe UI"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: "#94C1FA"
                                            }
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            elide: Text.ElideMiddle
                                            text: model.fileName
                                            font.family: "Microsoft YaHei UI"
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: "#F1F5F9"
                                        }
                                    }
                                    Text {
                                        text: "原尺寸: " + model.dimensionsText
                                              + (model.outputDimensionsText !== "-" ? ("  →  新尺寸: " + model.outputDimensionsText) : "")
                                              + (model.elapsedMs > 0 ? ("  ·  耗时 " + model.elapsedMs + " ms") : "")
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 11
                                        color: "#8E96A4"
                                    }
                                }

                                // Size before -> after
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignRight
                                    spacing: 2
                                    Text {
                                        Layout.alignment: Qt.AlignRight
                                        text: model.originalSizeText + (model.compressedSize > 0 ? (" → " + model.compressedSizeText) : "")
                                        font.family: "Segoe UI"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: "#E2E8F0"
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignRight
                                        text: model.savedPercentText !== "-" ? ("体积变化: " + model.savedPercentText) : "等待处理"
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 11
                                        color: model.savedPositive ? "#4ADE80" : "#94A3B8"
                                    }
                                }

                                // Status badge
                                Rectangle {
                                    width: 68
                                    height: 26
                                    radius: 6
                                    color: model.status === "已完成" ? "#14532D"
                                         : (model.status === "处理中" ? "#1E3A8A"
                                         : (model.status === "失败" ? "#7F1D1D" : "#32363F"))

                                    Text {
                                        anchors.centerIn: parent
                                        text: model.status
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: model.status === "已完成" ? "#86EFAC"
                                             : (model.status === "处理中" ? "#93C5FD"
                                             : (model.status === "失败" ? "#FCA5A5" : "#CBD5E1"))
                                    }
                                }

                                // Open output folder button
                                Rectangle {
                                    visible: model.outputPath.length > 0
                                    width: 28
                                    height: 28
                                    radius: 6
                                    color: locMa.containsMouse ? "#3E4552" : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "📂"
                                        font.pixelSize: 13
                                    }
                                    MouseArea {
                                        id: locMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: compressCtrl.openFileInExplorer(model.outputPath)
                                    }
                                }

                                // Remove button
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 6
                                    color: delMa.containsMouse ? "#4C1D24" : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.pixelSize: 12
                                        color: "#94A3B8"
                                    }
                                    MouseArea {
                                        id: delMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            taskModel.removeAt(index)
                                            if (window.selectedTaskIndex >= taskModel.totalCount) {
                                                window.selectedTaskIndex = taskModel.totalCount - 1
                                            }
                                            window.refreshSelectedPreview()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Interactive Before/After Split View Comparison
                CompareView {
                    id: compareView
                    Layout.fillWidth: true
                    Layout.preferredHeight: 245
                }
            }

            // ---------- RIGHT PANE: Settings & Compression Controls ----------
            ColumnLayout {
                Layout.preferredWidth: 420
                Layout.maximumWidth: 420
                Layout.fillHeight: true
                spacing: 12

                // Quick Preset Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 46
                    radius: 10
                    color: "#26292E"
                    border.color: "#343842"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "⚡ 快捷预设"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#DCE1E8"
                        }

                        ModernComboBox {
                            Layout.fillWidth: true
                            model: [
                                "均衡瘦身 (5120×1080 仅缩小 + 82%)",
                                "Web 极速优化 (转 WebP + 1080P)",
                                "摄影高清归档 (原尺寸 + 92% 4:4:4)",
                                "严格体积锁定 (≤ 200 KB 目标大小)",
                                "纯无损极限瘦身 (零画质损失去冗余)"
                            ]
                            onActivated: function(idx) {
                                compressCtrl.applyPreset(idx)
                            }
                        }
                    }
                }

                // Scrollable Settings Cards
                ScrollView {
                    id: settingsScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        width: settingsScroll.availableWidth
                        spacing: 12

                        // ==================== 1. 尺寸调整 (1:1 Restored from User Screenshot + Extensions) ====================
                        SectionCard {
                            Layout.fillWidth: true
                            title: "尺寸调整"
                            headerRight: [
                                ModernCheckBox {
                                    text: "启用"
                                    checked: compressCtrl.resizeEnabled
                                    onToggled: function(c) { compressCtrl.resizeEnabled = c }
                                }
                            ]

                            // Exact Width (px) and Height (px) floating label inputs from screenshot
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 24
                                opacity: compressCtrl.resizeEnabled ? 1.0 : 0.45

                                FloatingInput {
                                    Layout.fillWidth: true
                                    labelText: compressCtrl.resizeMode === 1 ? "缩放比例 (%)" : "宽度 (px)"
                                    text: compressCtrl.resizeMode === 1
                                          ? compressCtrl.resizePercentage.toString()
                                          : (compressCtrl.targetWidth > 0 ? compressCtrl.targetWidth.toString() : "")
                                    placeholderText: "不限"
                                    inputEnabled: compressCtrl.resizeEnabled
                                    validator: IntValidator { bottom: 1; top: 99999 }
                                    onEditingCompleted: function(val) {
                                        var num = parseInt(val)
                                        if (compressCtrl.resizeMode === 1) {
                                            compressCtrl.resizePercentage = isNaN(num) ? 100 : num
                                        } else {
                                            compressCtrl.targetWidth = isNaN(num) ? 0 : num
                                        }
                                    }
                                }

                                FloatingInput {
                                    Layout.fillWidth: true
                                    visible: compressCtrl.resizeMode === 0
                                    labelText: "高度 (px)"
                                    text: compressCtrl.targetHeight > 0 ? compressCtrl.targetHeight.toString() : ""
                                    placeholderText: "不限"
                                    inputEnabled: compressCtrl.resizeEnabled
                                    validator: IntValidator { bottom: 1; top: 99999 }
                                    onEditingCompleted: function(val) {
                                        var num = parseInt(val)
                                        compressCtrl.targetHeight = isNaN(num) ? 0 : num
                                    }
                                }
                            }

                            // Screenshot checkbox: 保持宽高比 (仅缩小)
                            ModernCheckBox {
                                visible: compressCtrl.resizeMode === 0
                                enabled: compressCtrl.resizeEnabled
                                opacity: compressCtrl.resizeEnabled ? 1.0 : 0.45
                                text: "保持宽高比 (仅缩小)"
                                checked: compressCtrl.keepAspectRatioShrinkOnly
                                onToggled: function(c) { compressCtrl.keepAspectRatioShrinkOnly = c }
                            }

                            // Additional resize mode & resampling filter options
                            RowLayout {
                                Layout.fillWidth: true
                                enabled: compressCtrl.resizeEnabled
                                opacity: compressCtrl.resizeEnabled ? 1.0 : 0.45
                                spacing: 8

                                Text {
                                    text: "缩放模式:"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 12
                                    color: "#94A3B8"
                                }
                                ModernComboBox {
                                    Layout.fillWidth: true
                                    currentIndex: compressCtrl.resizeMode
                                    model: ["指定宽高 (px)", "按百分比缩放 (%)", "限制最长边 (px)"]
                                    onActivated: function(idx) { compressCtrl.resizeMode = idx }
                                }
                                Text {
                                    text: "算法:"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 12
                                    color: "#94A3B8"
                                }
                                ModernComboBox {
                                    Layout.preferredWidth: 118
                                    currentIndex: compressCtrl.filterType
                                    model: ["Lanczos", "Mitchell", "Catrom", "Triangle"]
                                    onActivated: function(idx) { compressCtrl.filterType = idx }
                                }
                            }
                        }

                        // ==================== 2. 压缩质量与智能体积控制 ====================
                        SectionCard {
                            Layout.fillWidth: true
                            title: "压缩与编码策略"
                            headerRight: [
                                ModernCheckBox {
                                    text: "纯无损模式"
                                    checked: compressCtrl.losslessMode
                                    onToggled: function(c) { compressCtrl.losslessMode = c }
                                }
                            ]

                            // Quality Slider
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                enabled: !compressCtrl.losslessMode
                                opacity: compressCtrl.losslessMode ? 0.45 : 1.0

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "压缩质量 (Quality)"
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 13
                                        color: "#CBD5E1"
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: compressCtrl.quality + "%"
                                        font.family: "Segoe UI"
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: "#94C1FA"
                                    }
                                }

                                Slider {
                                    id: qSlider
                                    Layout.fillWidth: true
                                    from: 10
                                    to: 100
                                    stepSize: 1
                                    value: compressCtrl.quality
                                    onMoved: compressCtrl.quality = Math.round(value)

                                    background: Rectangle {
                                        x: qSlider.leftPadding
                                        y: qSlider.topPadding + qSlider.availableHeight / 2 - height / 2
                                        width: qSlider.availableWidth
                                        height: 6
                                        radius: 3
                                        color: "#1B1D21"

                                        Rectangle {
                                            width: qSlider.visualPosition * parent.width
                                            height: parent.height
                                            color: "#94C1FA"
                                            radius: 3
                                        }
                                    }

                                    handle: Rectangle {
                                        x: qSlider.leftPadding + qSlider.visualPosition * (qSlider.availableWidth - width)
                                        y: qSlider.topPadding + qSlider.availableHeight / 2 - height / 2
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: qSlider.pressed ? "#FFFFFF" : "#94C1FA"
                                        border.color: "#15181E"
                                        border.width: 2
                                    }
                                }
                            }

                            // Target File Size Lock (目标体积锁定)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                ModernCheckBox {
                                    text: "锁定最大文件体积 ≤"
                                    checked: compressCtrl.targetSizeEnabled
                                    onToggled: function(c) { compressCtrl.targetSizeEnabled = c }
                                }

                                FloatingInput {
                                    Layout.fillWidth: true
                                    labelText: "目标上限 (KB)"
                                    text: compressCtrl.targetMaxKB.toString()
                                    inputEnabled: compressCtrl.targetSizeEnabled
                                    validator: IntValidator { bottom: 5; top: 50000 }
                                    onEditingCompleted: function(val) {
                                        var n = parseInt(val)
                                        if (!isNaN(n) && n > 0) compressCtrl.targetMaxKB = n
                                    }
                                }
                            }

                            // Format Conversion & Chroma Subsampling
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: "输出格式:"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 12
                                    color: "#94A3B8"
                                }
                                ModernComboBox {
                                    Layout.fillWidth: true
                                    model: ["保持原格式", "JPEG (.jpg)", "WebP (.webp)", "AVIF (.avif)", "PNG (.png)", "JPEG XL (.jxl)"]
                                    onActivated: function(idx) {
                                        var fmts = ["original", "jpg", "webp", "avif", "png", "jxl"]
                                        compressCtrl.outputFormat = fmts[idx]
                                    }
                                }

                                Text {
                                    text: "色度采样:"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 12
                                    color: "#94A3B8"
                                }
                                ModernComboBox {
                                    Layout.preferredWidth: 122
                                    currentIndex: compressCtrl.chromaSubsampling
                                    model: ["自动采样", "4:2:0 (高压缩)", "4:4:4 (色彩无损)"]
                                    onActivated: function(idx) { compressCtrl.chromaSubsampling = idx }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16
                                ModernCheckBox {
                                    text: "渐进式 JPEG 加载"
                                    checked: compressCtrl.progressiveJpeg
                                    onToggled: function(c) { compressCtrl.progressiveJpeg = c }
                                }
                                ModernCheckBox {
                                    text: "若压缩后变大则自动保留原图"
                                    checked: compressCtrl.skipIfLarger
                                    onToggled: function(c) { compressCtrl.skipIfLarger = c }
                                }
                            }
                        }

                        // ==================== 3. 元数据隐私、画质增强与水印 ====================
                        SectionCard {
                            Layout.fillWidth: true
                            title: "隐私清理、画质增强与水印"

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 8
                                columnSpacing: 12

                                ModernCheckBox {
                                    text: "剥离 EXIF/GPS 隐私信息"
                                    checked: compressCtrl.stripMetadata
                                    onToggled: function(c) { compressCtrl.stripMetadata = c }
                                }
                                ModernCheckBox {
                                    text: "EXIF 自动旋转回正"
                                    checked: compressCtrl.autoOrient
                                    onToggled: function(c) { compressCtrl.autoOrient = c }
                                }
                                ModernCheckBox {
                                    text: "统一转换为 sRGB 色域"
                                    checked: compressCtrl.convertToSRGB
                                    onToggled: function(c) { compressCtrl.convertToSRGB = c }
                                }
                                ModernCheckBox {
                                    text: "缩放后自适应锐化补偿"
                                    checked: compressCtrl.sharpenAfterResize
                                    onToggled: function(c) { compressCtrl.sharpenAfterResize = c }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Text {
                                    text: "色彩滤镜:"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 12
                                    color: "#94A3B8"
                                }
                                ModernComboBox {
                                    Layout.fillWidth: true
                                    currentIndex: compressCtrl.colorFilter
                                    model: ["无滤镜 (保持原色)", "黑白质感灰度 (Gray)", "自动色阶与对比度增强", "复古暖调怀旧 (Sepia)"]
                                    onActivated: function(idx) { compressCtrl.colorFilter = idx }
                                }
                            }

                            // Watermark controls
                            ModernCheckBox {
                                text: "添加防盗文字水印 (ImageMagick 矢量渲染)"
                                checked: compressCtrl.watermarkEnabled
                                onToggled: function(c) { compressCtrl.watermarkEnabled = c }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: compressCtrl.watermarkEnabled
                                spacing: 10

                                FloatingInput {
                                    Layout.fillWidth: true
                                    labelText: "水印文字"
                                    text: compressCtrl.watermarkText
                                    onEditingCompleted: function(v) { compressCtrl.watermarkText = v }
                                }

                                ModernComboBox {
                                    Layout.preferredWidth: 106
                                    currentIndex: compressCtrl.watermarkPosition
                                    model: ["右下角", "左下角", "右上角", "左上角", "画面居中"]
                                    onActivated: function(idx) { compressCtrl.watermarkPosition = idx }
                                }
                            }
                        }

                        // ==================== 4. 输出路径与并发控制 ====================
                        SectionCard {
                            Layout.fillWidth: true
                            title: "输出目录与并发控制"

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Text {
                                    text: "保存位置:"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 12
                                    color: "#94A3B8"
                                }
                                ModernComboBox {
                                    Layout.fillWidth: true
                                    currentIndex: compressCtrl.outputDirMode
                                    model: ["原图同级 compressed 子文件夹", "指定自定义输出目录", "直接覆盖原文件"]
                                    onActivated: function(idx) { compressCtrl.outputDirMode = idx }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: compressCtrl.outputDirMode === 1
                                spacing: 8
                                FloatingInput {
                                    Layout.fillWidth: true
                                    labelText: "自定义输出路径"
                                    text: compressCtrl.customOutputDir
                                    placeholderText: "请选择文件夹..."
                                    onEditingCompleted: function(v) { compressCtrl.customOutputDir = v }
                                }
                                Rectangle {
                                    width: 68
                                    height: 44
                                    radius: 6
                                    color: "#363B44"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "浏览..."
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 12
                                        color: "#E2E8F0"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: customOutputFolderDialog.open()
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: compressCtrl.outputDirMode !== 2
                                spacing: 12

                                FloatingInput {
                                    Layout.fillWidth: true
                                    labelText: "文件名前缀"
                                    text: compressCtrl.filePrefix
                                    placeholderText: "无"
                                    onEditingCompleted: function(v) { compressCtrl.filePrefix = v }
                                }
                                FloatingInput {
                                    Layout.fillWidth: true
                                    labelText: "文件名后缀"
                                    text: compressCtrl.fileSuffix
                                    placeholderText: "_min"
                                    onEditingCompleted: function(v) { compressCtrl.fileSuffix = v }
                                }
                            }

                            // Live ImageMagick CLI command preview box
                            Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                radius: 6
                                color: "#1B1D21"
                                border.color: "#333740"

                                Text {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: compressCtrl.commandPreview
                                    font.family: "Consolas"
                                    font.pixelSize: 10
                                    color: "#94A3B8"
                                    wrapMode: Text.WrapAnywhere
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                // ==================== START / STOP BATCH BUTTON ====================
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: 10
                    color: compressCtrl.isRunning
                           ? "#991B1B"
                           : (startMa.containsMouse ? "#A7CEFC" : "#94C1FA")

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        Text {
                            text: compressCtrl.isRunning
                                  ? ("⏹ 停止压缩 (" + Math.round(compressCtrl.batchProgress * 100) + "%)")
                                  : ("🚀 开始批量压缩 (" + taskModel.totalCount + " 张图片)")
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 16
                            font.bold: true
                            color: compressCtrl.isRunning ? "#FFFFFF" : "#10151E"
                        }
                    }

                    MouseArea {
                        id: startMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (compressCtrl.isRunning) {
                                compressCtrl.cancelBatchCompression()
                            } else {
                                compressCtrl.startBatchCompression()
                            }
                        }
                    }
                }
            }
        }
    }

    // Floating Toast Banner
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        visible: window.toastText.length > 0
        height: 40
        width: toastLbl.implicitWidth + 36
        radius: 20
        color: window.toastError ? "#991B1B" : "#1E3A5F"
        border.color: window.toastError ? "#F87171" : "#94C1FA"

        Text {
            id: toastLbl
            anchors.centerIn: parent
            text: window.toastText
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 13
            color: "#F8FAFC"
        }
    }
}
