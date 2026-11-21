import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import "components"

ApplicationWindow {
    id: window
    width: 1280
    height: 820
    minimumWidth: 1060
    minimumHeight: 680
    visible: true
    title: "PhotoZipper C++ · 现代高性能图片压缩工作站 (Powered by ImageMagick)"
    color: "#16181D"

    property int selectedTaskIndex: -1
    property int activeSettingsTab: 0   // 0=尺寸与压缩, 1=画质与水印, 2=输出与命令
    property bool showComparePanel: false
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
        interval: 4000
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

    // Global drag & drop
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

        // ==================== 1. TOP NAVIGATION HEADER (Strictly Fixed 56px Height) ====================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            Layout.minimumHeight: 56
            Layout.maximumHeight: 56
            color: "#111318"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 12

                // Brand App Icon (Explicitly constrained to 34x34 so it NEVER inflates the layout)
                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 8
                    color: "transparent"

                    Image {
                        anchors.fill: parent
                        source: "qrc:/icons/app_icon.png"
                        sourceSize.width: 36
                        sourceSize.height: 36
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "PhotoZipper C++"
                        font.family: "Segoe UI"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#F8FAFC"
                    }
                    Text {
                        text: "Qt Quick 6.8 · 内嵌单版本 ImageMagick 高性能图像压缩工作站"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        color: "#64748B"
                    }
                }

                Item { Layout.fillWidth: true }

                // Live Memory & Binary Footprint Pill
                Rectangle {
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: resRow.implicitWidth + 22
                    radius: 16
                    color: "#1A1E26"
                    border.color: "#2A303C"

                    RowLayout {
                        id: resRow
                        anchors.centerIn: parent
                        spacing: 12

                        RowLayout {
                            spacing: 5
                            Rectangle { width: 6; height: 6; radius: 3; color: "#38BDF8" }
                            Text {
                                text: "内存: " + memMonitor.appMemoryText
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                color: "#BAE6FD"
                            }
                        }
                        Rectangle { width: 1; height: 12; color: "#2E3543" }
                        Text {
                            text: "主程序: " + memMonitor.appBinarySizeText + " · 引擎: " + memMonitor.engineSizeText
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 11
                            color: "#94A3B8"
                        }
                    }
                }

                // Embedded ImageMagick Version & Manager Button
                Rectangle {
                    id: engineHeaderBtn
                    Layout.preferredHeight: 34
                    Layout.preferredWidth: engBtnRow.implicitWidth + 22
                    radius: 8
                    color: engMa.containsMouse ? "#252C38" : "#1C2029"
                    border.color: engineMgr.isInstalled ? (engMa.containsMouse ? "#60A5FA" : "#384761") : "#F43F5E"
                    scale: engMa.pressed ? 0.96 : 1.0

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 110 } }

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
                                  : "未安装引擎"
                            font.family: "Segoe UI"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#E2E8F0"
                        }
                        Rectangle {
                            radius: 5
                            color: "#2563EB"
                            Layout.preferredHeight: 20
                            Layout.preferredWidth: 64
                            Text {
                                anchors.centerIn: parent
                                text: "引擎管理"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                font.bold: true
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
                color: "#222630"
            }
        }

        // ==================== 2. MAIN WORKSPACE ====================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 14
            spacing: 14

            // ---------- LEFT WORKSPACE: Toolbar + Queue List + Animated Collapsible Preview ----------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                // Top Action Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    Layout.minimumHeight: 48
                    Layout.maximumHeight: 48
                    radius: 10
                    color: "#1E222A"
                    border.color: "#2C323E"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        // Add Files Button
                        Rectangle {
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: 102
                            radius: 7
                            color: addFileMa.containsMouse ? "#60A5FA" : "#3B82F6"
                            scale: addFileMa.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: "＋ 添加图片"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 12
                                font.bold: true
                                color: "#FFFFFF"
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
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: 110
                            radius: 7
                            color: addDirMa.containsMouse ? "#2E3543" : "#252A34"
                            border.color: addDirMa.containsMouse ? "#4E596F" : "#373E4C"
                            scale: addDirMa.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

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
                            Layout.preferredHeight: 32
                            Layout.preferredWidth: 118
                            radius: 7
                            color: sampleMa.containsMouse ? "#2E3543" : "#252A34"
                            border.color: sampleMa.containsMouse ? "#60A5FA" : "#373E4C"
                            scale: sampleMa.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: "✨ 导入测试样张"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 12
                                color: "#93C5FD"
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
                        Rectangle {
                            visible: taskModel.totalCount > 0
                            Layout.preferredHeight: 28
                            Layout.preferredWidth: statRow.implicitWidth + 18
                            radius: 14
                            color: "#15241D"
                            border.color: "#234733"

                            RowLayout {
                                id: statRow
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "共 " + taskModel.totalCount + " 张 · " + taskModel.totalOriginalSizeText
                                          + " → " + taskModel.totalCompressedSizeText
                                          + " (省 " + taskModel.totalSavedText + ")"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 11
                                    color: "#86EFAC"
                                }
                            }
                        }

                        // Toggle Split Preview Button
                        Rectangle {
                            Layout.preferredHeight: 30
                            Layout.preferredWidth: 96
                            radius: 7
                            color: window.showComparePanel
                                   ? "#1E3A8A"
                                   : (cmpToggleMa.containsMouse ? "#2E3543" : "#252A34")
                            border.color: window.showComparePanel ? "#60A5FA" : "#373E4C"
                            scale: cmpToggleMa.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: window.showComparePanel ? "👁 收起对比" : "👁 画质对比"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                font.bold: window.showComparePanel
                                color: window.showComparePanel ? "#93C5FD" : "#CBD5E1"
                            }
                            MouseArea {
                                id: cmpToggleMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: window.showComparePanel = !window.showComparePanel
                            }
                        }

                        // Clear All
                        Rectangle {
                            visible: taskModel.totalCount > 0
                            Layout.preferredHeight: 30
                            Layout.preferredWidth: 68
                            radius: 7
                            color: clrAllMa.containsMouse ? "#4C1D24" : "#252A34"
                            border.color: clrAllMa.containsMouse ? "#F43F5E" : "#373E4C"
                            scale: clrAllMa.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Text {
                                anchors.centerIn: parent
                                text: "清空"
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
                                    window.showComparePanel = false
                                    window.refreshSelectedPreview()
                                }
                            }
                        }
                    }
                }

                // Task Queue Area
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#1B1E25"
                    radius: 12
                    border.color: globalDropArea.containsDrag ? "#60A5FA" : "#2A303C"
                    border.width: globalDropArea.containsDrag ? 2 : 1
                    clip: true

                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    // Empty Dropzone State with Breathing Pulse Animation
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: taskModel.totalCount === 0
                        opacity: visible ? 1.0 : 0.0
                        spacing: 14

                        Behavior on opacity { NumberAnimation { duration: 220 } }

                        Rectangle {
                            id: dropCircle
                            Layout.alignment: Qt.AlignHCenter
                            width: 76
                            height: 76
                            radius: 38
                            color: "#222731"
                            border.color: "#3B82F6"
                            border.width: 1.5

                            SequentialAnimation on scale {
                                loops: Animation.Infinite
                                running: taskModel.totalCount === 0
                                NumberAnimation { from: 1.0; to: 1.06; duration: 1600; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.06; to: 1.0; duration: 1600; easing.type: Easing.InOutSine }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "📥"
                                font.pixelSize: 32
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "拖拽图片或文件夹到这里开始压缩"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 17
                            font.bold: true
                            color: "#F1F5F9"
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "支持 JPG / PNG / WebP / AVIF / JXL / HEIC / TIFF / BMP 等全格式高并发处理"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            color: "#64748B"
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 136
                                Layout.preferredHeight: 38
                                radius: 8
                                color: emptyAddMa.containsMouse ? "#60A5FA" : "#3B82F6"
                                scale: emptyAddMa.pressed ? 0.96 : 1.0
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "＋ 选择本地图片"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#FFFFFF"
                                }
                                MouseArea {
                                    id: emptyAddMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: addFilesDialog.open()
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 158
                                Layout.preferredHeight: 38
                                radius: 8
                                color: emptySampleMa.containsMouse ? "#2C3342" : "#232833"
                                border.color: emptySampleMa.containsMouse ? "#60A5FA" : "#3A4252"
                                scale: emptySampleMa.pressed ? 0.96 : 1.0
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "✨ 一键生成测试样张"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 13
                                    color: "#E2E8F0"
                                }
                                MouseArea {
                                    id: emptySampleMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: compressCtrl.generateSampleImages()
                                }
                            }
                        }
                    }

                    // Animated Task ListView
                    ListView {
                        id: taskListView
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        visible: taskModel.totalCount > 0
                        model: taskModel
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        add: Transition {
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                                NumberAnimation { property: "y"; from: 20; duration: 220; easing.type: Easing.OutCubic }
                            }
                        }
                        remove: Transition {
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; to: 0; duration: 160 }
                                NumberAnimation { property: "scale"; to: 0.92; duration: 160 }
                            }
                        }
                        displaced: Transition {
                            NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic }
                        }

                        delegate: Rectangle {
                            width: taskListView.width - 8
                            height: 64
                            radius: 10
                            readonly property bool isSelected: index === window.selectedTaskIndex
                            color: isSelected ? "#233047" : (rowMa.containsMouse ? "#242A35" : "#20242D")
                            border.color: isSelected ? "#3B82F6" : (rowMa.containsMouse ? "#384152" : "#2B303C")
                            border.width: isSelected ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            MouseArea {
                                id: rowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.selectedTaskIndex = index
                                    window.showComparePanel = true
                                    window.refreshSelectedPreview()
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                // Low-memory thumbnail
                                Rectangle {
                                    Layout.preferredWidth: 46
                                    Layout.preferredHeight: 46
                                    radius: 7
                                    color: "#14171D"
                                    border.color: "#333A48"
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
                                    spacing: 4
                                    RowLayout {
                                        spacing: 8
                                        Rectangle {
                                            radius: 4
                                            color: "#1E3A8A"
                                            Layout.preferredHeight: 18
                                            Layout.preferredWidth: fmtTxt.implicitWidth + 10
                                            Text {
                                                id: fmtTxt
                                                anchors.centerIn: parent
                                                text: model.format
                                                font.family: "Segoe UI"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: "#93C5FD"
                                            }
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            elide: Text.ElideMiddle
                                            text: model.fileName
                                            font.family: "Microsoft YaHei UI"
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: "#F8FAFC"
                                        }
                                    }
                                    Text {
                                        text: "分辨率: " + model.dimensionsText
                                              + (model.outputDimensionsText !== "-" ? ("  →  " + model.outputDimensionsText) : "")
                                              + (model.elapsedMs > 0 ? ("  ·  " + model.elapsedMs + " ms") : "")
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 11
                                        color: "#8A94A6"
                                    }
                                }

                                // Size before -> after
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignRight
                                    spacing: 3
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
                                        text: model.savedPercentText !== "-" ? ("节省 " + model.savedPercentText) : "就绪"
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 11
                                        font.bold: model.savedPositive
                                        color: model.savedPositive ? "#4ADE80" : "#64748B"
                                    }
                                }

                                // Status badge
                                Rectangle {
                                    Layout.preferredWidth: 66
                                    Layout.preferredHeight: 26
                                    radius: 6
                                    color: model.status === "已完成" ? "#14532D"
                                         : (model.status === "处理中" ? "#1E3A8A"
                                         : (model.status === "失败" ? "#7F1D1D" : "#2A303C"))
                                    Behavior on color { ColorAnimation { duration: 180 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: model.status
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: model.status === "已完成" ? "#86EFAC"
                                             : (model.status === "处理中" ? "#93C5FD"
                                             : (model.status === "失败" ? "#FCA5A5" : "#94A3B8"))
                                    }
                                }

                                // Open output folder button
                                Rectangle {
                                    visible: model.outputPath.length > 0
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 6
                                    color: locMa.containsMouse ? "#333C4D" : "transparent"
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
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    radius: 6
                                    color: delMa.containsMouse ? "#4C1D24" : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.pixelSize: 12
                                        color: delMa.containsMouse ? "#FDA4AF" : "#64748B"
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

                // Smoothly Animated Collapsible Before/After Split View
                CompareView {
                    id: compareView
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.showComparePanel ? 250 : 0
                    Layout.maximumHeight: window.showComparePanel ? 250 : 0
                    opacity: window.showComparePanel ? 1.0 : 0.0
                    visible: Layout.preferredHeight > 2

                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                }
            }

            // ---------- RIGHT PANE: Clean Tabbed Settings Architecture (Zero Clutter) ----------
            ColumnLayout {
                Layout.preferredWidth: 420
                Layout.minimumWidth: 420
                Layout.maximumWidth: 420
                Layout.fillHeight: true
                spacing: 10

                // Quick Preset Selector Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    Layout.minimumHeight: 48
                    Layout.maximumHeight: 48
                    radius: 10
                    color: "#1E222A"
                    border.color: "#2C323E"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "⚡ 预设方案"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#93C5FD"
                        }

                        ModernComboBox {
                            Layout.fillWidth: true
                            model: [
                                "均衡瘦身 (5120×1080 仅缩小 + 82%)",
                                "Web 极速优化 (转 WebP + 1080P)",
                                "摄影高清归档 (原尺寸 + 92% 4:4:4)",
                                "严格体积锁定 (≤ 200 KB 目标上限)",
                                "纯无损极限瘦身 (零画质损失去冗余)"
                            ]
                            onActivated: function(idx) {
                                compressCtrl.applyPreset(idx)
                            }
                        }
                    }
                }

                // Segmented Animated Tab Bar (3 Clean Tabs instead of a messy wall of cards!)
                Rectangle {
                    id: tabBarContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    Layout.minimumHeight: 40
                    Layout.maximumHeight: 40
                    radius: 10
                    color: "#181B22"
                    border.color: "#282D38"

                    readonly property real tabWidth: (width - 8) / 3

                    // Sliding active pill indicator
                    Rectangle {
                        x: 4 + window.activeSettingsTab * tabBarContainer.tabWidth
                        y: 4
                        width: tabBarContainer.tabWidth
                        height: parent.height - 8
                        radius: 7
                        color: "#2563EB"

                        Behavior on x {
                            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 0

                        Repeater {
                            model: ["📐 尺寸与压缩", "🎨 画质与水印", "📂 输出设置"]
                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 12
                                    font.bold: window.activeSettingsTab === index
                                    color: window.activeSettingsTab === index ? "#FFFFFF" : "#94A3B8"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: window.activeSettingsTab = index
                                }
                            }
                        }
                    }
                }

                // Tab Content Container (Animated Cross-Fade & Slide)
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // ==================== TAB 0: 尺寸与压缩 (Core Resize & Compression) ====================
                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 12
                        visible: opacity > 0.01
                        opacity: window.activeSettingsTab === 0 ? 1.0 : 0.0
                        transform: Translate {
                            x: window.activeSettingsTab === 0 ? 0 : -18
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        // Card 1: 尺寸调整
                        SectionCard {
                            Layout.fillWidth: true
                            title: "尺寸调整"
                            subtitle: "按指定宽高边界或比例智能缩放"
                            headerRight: [
                                ModernCheckBox {
                                    text: "启用"
                                    switchStyle: true
                                    checked: compressCtrl.resizeEnabled
                                    onToggled: function(c) { compressCtrl.resizeEnabled = c }
                                }
                            ]

                            // Quick Resolution Chips
                            RowLayout {
                                Layout.fillWidth: true
                                enabled: compressCtrl.resizeEnabled
                                opacity: compressCtrl.resizeEnabled ? 1.0 : 0.4
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                spacing: 6

                                Repeater {
                                    model: [
                                        { label: "5K超宽", w: 5120, h: 1080 },
                                        { label: "4K UHD", w: 3840, h: 2160 },
                                        { label: "2K QHD", w: 2560, h: 1440 },
                                        { label: "1080P", w: 1920, h: 1080 },
                                        { label: "720P", w: 1280, h: 720 }
                                    ]
                                    delegate: Rectangle {
                                        readonly property bool active: compressCtrl.resizeMode === 0
                                                                       && compressCtrl.targetWidth === modelData.w
                                                                       && compressCtrl.targetHeight === modelData.h
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 26
                                        radius: 6
                                        color: active ? "#1E3A8A" : (chipMa.containsMouse ? "#2D3340" : "#1E222A")
                                        border.color: active ? "#60A5FA" : "#353B48"
                                        scale: chipMa.pressed ? 0.94 : 1.0
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                        Behavior on scale { NumberAnimation { duration: 100 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: "Microsoft YaHei UI"
                                            font.pixelSize: 11
                                            font.bold: active
                                            color: active ? "#93C5FD" : "#94A3B8"
                                        }
                                        MouseArea {
                                            id: chipMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                compressCtrl.resizeMode = 0
                                                compressCtrl.targetWidth = modelData.w
                                                compressCtrl.targetHeight = modelData.h
                                            }
                                        }
                                    }
                                }
                            }

                            // Width & Height Floating Inputs
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                opacity: compressCtrl.resizeEnabled ? 1.0 : 0.4
                                Behavior on opacity { NumberAnimation { duration: 150 } }

                                FloatingInput {
                                    Layout.fillWidth: true
                                    labelText: compressCtrl.resizeMode === 1
                                               ? "缩放比例 (%)"
                                               : (compressCtrl.resizeMode === 2 ? "最长边上限 (px)" : "宽度 (px)")
                                    text: compressCtrl.resizeMode === 1
                                          ? compressCtrl.resizePercentage.toString()
                                          : (compressCtrl.targetWidth > 0 ? compressCtrl.targetWidth.toString() : "")
                                    placeholderText: "不限制"
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

                                Text {
                                    visible: compressCtrl.resizeMode === 0
                                    text: "×"
                                    font.family: "Segoe UI"
                                    font.pixelSize: 16
                                    color: "#64748B"
                                    Layout.topMargin: 8
                                }

                                FloatingInput {
                                    Layout.fillWidth: true
                                    visible: compressCtrl.resizeMode === 0
                                    labelText: "高度 (px)"
                                    text: compressCtrl.targetHeight > 0 ? compressCtrl.targetHeight.toString() : ""
                                    placeholderText: "不限制"
                                    inputEnabled: compressCtrl.resizeEnabled
                                    validator: IntValidator { bottom: 1; top: 99999 }
                                    onEditingCompleted: function(val) {
                                        var num = parseInt(val)
                                        compressCtrl.targetHeight = isNaN(num) ? 0 : num
                                    }
                                }
                            }

                            ModernCheckBox {
                                visible: compressCtrl.resizeMode === 0
                                enabled: compressCtrl.resizeEnabled
                                opacity: compressCtrl.resizeEnabled ? 1.0 : 0.4
                                text: "保持宽高比 (仅缩小)"
                                checked: compressCtrl.keepAspectRatioShrinkOnly
                                onToggled: function(c) { compressCtrl.keepAspectRatioShrinkOnly = c }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                enabled: compressCtrl.resizeEnabled
                                opacity: compressCtrl.resizeEnabled ? 1.0 : 0.4
                                spacing: 8

                                ModernComboBox {
                                    Layout.fillWidth: true
                                    currentIndex: compressCtrl.resizeMode
                                    model: ["按宽高边界 (px)", "按百分比缩放 (%)", "限制最长边 (px)"]
                                    onActivated: function(idx) { compressCtrl.resizeMode = idx }
                                }
                                ModernComboBox {
                                    Layout.preferredWidth: 130
                                    currentIndex: compressCtrl.filterType
                                    model: ["Lanczos 滤波", "Mitchell 滤波", "Catrom 滤波", "Triangle 滤波"]
                                    onActivated: function(idx) { compressCtrl.filterType = idx }
                                }
                            }
                        }

                        // Card 2: 压缩与编码策略
                        SectionCard {
                            Layout.fillWidth: true
                            title: "压缩与编码策略"
                            subtitle: "画质平衡、目标体积锁定与格式转换"
                            headerRight: [
                                ModernCheckBox {
                                    text: "无损模式"
                                    switchStyle: true
                                    checked: compressCtrl.losslessMode
                                    onToggled: function(c) { compressCtrl.losslessMode = c }
                                }
                            ]

                            // Quality Slider
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                enabled: !compressCtrl.losslessMode
                                opacity: compressCtrl.losslessMode ? 0.4 : 1.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "压缩质量 (Quality)"
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 12
                                        color: "#CBD5E1"
                                    }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        radius: 5
                                        color: "#1E3A8A"
                                        Layout.preferredWidth: 46
                                        Layout.preferredHeight: 22
                                        Text {
                                            anchors.centerIn: parent
                                            text: compressCtrl.quality + "%"
                                            font.family: "Segoe UI"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: "#93C5FD"
                                        }
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
                                        color: "#181B22"

                                        Rectangle {
                                            width: qSlider.visualPosition * parent.width
                                            height: parent.height
                                            color: "#3B82F6"
                                            radius: 3
                                        }
                                    }

                                    handle: Rectangle {
                                        x: qSlider.leftPadding + qSlider.visualPosition * (qSlider.availableWidth - width)
                                        y: qSlider.topPadding + qSlider.availableHeight / 2 - height / 2
                                        width: 18
                                        height: 18
                                        radius: 9
                                        scale: qSlider.pressed ? 1.2 : 1.0
                                        color: qSlider.pressed ? "#FFFFFF" : "#60A5FA"
                                        border.color: "#1E3A8A"
                                        border.width: 2
                                        Behavior on scale { NumberAnimation { duration: 120 } }
                                    }
                                }
                            }

                            // Target File Size Lock
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                ModernCheckBox {
                                    text: "锁定最大体积 ≤"
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
                                spacing: 8

                                ModernComboBox {
                                    Layout.fillWidth: true
                                    model: ["保持原格式", "转 JPEG (.jpg)", "转 WebP (.webp)", "转 AVIF (.avif)", "转 PNG (.png)", "转 JPEG XL (.jxl)"]
                                    onActivated: function(idx) {
                                        var fmts = ["original", "jpg", "webp", "avif", "png", "jxl"]
                                        compressCtrl.outputFormat = fmts[idx]
                                    }
                                }

                                ModernComboBox {
                                    Layout.preferredWidth: 145
                                    currentIndex: compressCtrl.chromaSubsampling
                                    model: ["色度: 自动采样", "色度: 4:2:0 高压缩", "色度: 4:4:4 无损色"]
                                    onActivated: function(idx) { compressCtrl.chromaSubsampling = idx }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 14
                                ModernCheckBox {
                                    text: "渐进式 JPEG"
                                    checked: compressCtrl.progressiveJpeg
                                    onToggled: function(c) { compressCtrl.progressiveJpeg = c }
                                }
                                ModernCheckBox {
                                    text: "防反向变大保护"
                                    checked: compressCtrl.skipIfLarger
                                    onToggled: function(c) { compressCtrl.skipIfLarger = c }
                                }
                            }
                        }
                    }

                    // ==================== TAB 1: 画质与水印 (Privacy, Enhancement & Watermark) ====================
                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 12
                        visible: opacity > 0.01
                        opacity: window.activeSettingsTab === 1 ? 1.0 : 0.0
                        transform: Translate {
                            x: window.activeSettingsTab === 1 ? 0 : 18
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        SectionCard {
                            Layout.fillWidth: true
                            title: "元数据隐私与色彩管理"
                            subtitle: "清理拍摄定位隐私并标准化色彩空间"

                            ModernCheckBox {
                                text: "剥离 EXIF / GPS / XMP 隐私元数据 (-strip)"
                                checked: compressCtrl.stripMetadata
                                onToggled: function(c) { compressCtrl.stripMetadata = c }
                            }
                            ModernCheckBox {
                                text: "剥离前根据 EXIF 自动旋转回正方向 (-auto-orient)"
                                checked: compressCtrl.autoOrient
                                onToggled: function(c) { compressCtrl.autoOrient = c }
                            }
                            ModernCheckBox {
                                text: "统一转换为标准 sRGB 网页色域 (-colorspace sRGB)"
                                checked: compressCtrl.convertToSRGB
                                onToggled: function(c) { compressCtrl.convertToSRGB = c }
                            }
                        }

                        SectionCard {
                            Layout.fillWidth: true
                            title: "画质增强与防盗水印"
                            subtitle: "由 ImageMagick 在同一次流水线中完成矢量合成"

                            ModernCheckBox {
                                text: "缩放后自适应 Unsharp 锐化补偿（提升缩略图清晰度）"
                                checked: compressCtrl.sharpenAfterResize
                                onToggled: function(c) { compressCtrl.sharpenAfterResize = c }
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

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#323844" }

                            ModernCheckBox {
                                text: "叠加文字防盗水印"
                                switchStyle: true
                                checked: compressCtrl.watermarkEnabled
                                onToggled: function(c) { compressCtrl.watermarkEnabled = c }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                enabled: compressCtrl.watermarkEnabled
                                opacity: compressCtrl.watermarkEnabled ? 1.0 : 0.4
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                spacing: 10

                                FloatingInput {
                                    Layout.fillWidth: true
                                    labelText: "水印内容"
                                    text: compressCtrl.watermarkText
                                    inputEnabled: compressCtrl.watermarkEnabled
                                    onEditingCompleted: function(v) { compressCtrl.watermarkText = v }
                                }

                                ModernComboBox {
                                    Layout.preferredWidth: 112
                                    currentIndex: compressCtrl.watermarkPosition
                                    model: ["右下角", "左下角", "右上角", "左上角", "画面居中"]
                                    onActivated: function(idx) { compressCtrl.watermarkPosition = idx }
                                }
                            }
                        }
                    }

                    // ==================== TAB 2: 输出设置 (Output Path, Naming & CLI Preview) ====================
                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 12
                        visible: opacity > 0.01
                        opacity: window.activeSettingsTab === 2 ? 1.0 : 0.0
                        transform: Translate {
                            x: window.activeSettingsTab === 2 ? 0 : 18
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        SectionCard {
                            Layout.fillWidth: true
                            title: "输出目录与重命名规则"
                            subtitle: "配置压缩后文件的存放位置与前后缀"

                            ModernComboBox {
                                Layout.fillWidth: true
                                currentIndex: compressCtrl.outputDirMode
                                model: ["保存在原图同级 compressed 子文件夹", "保存到自定义输出目录", "直接覆盖原图片文件"]
                                onActivated: function(idx) { compressCtrl.outputDirMode = idx }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: compressCtrl.outputDirMode === 1
                                spacing: 8
                                FloatingInput {
                                    Layout.fillWidth: true
                                    labelText: "自定义输出路径"
                                    text: compressCtrl.customOutputDir
                                    placeholderText: "点击右侧浏览选择文件夹..."
                                    onEditingCompleted: function(v) { compressCtrl.customOutputDir = v }
                                }
                                Rectangle {
                                    Layout.preferredWidth: 72
                                    Layout.preferredHeight: 44
                                    Layout.topMargin: 8
                                    radius: 8
                                    color: browseMa.containsMouse ? "#384152" : "#2D3340"
                                    border.color: "#475569"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "浏览..."
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 12
                                        color: "#E2E8F0"
                                    }
                                    MouseArea {
                                        id: browseMa
                                        anchors.fill: parent
                                        hoverEnabled: true
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
                                    placeholderText: "无前缀"
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
                        }

                        SectionCard {
                            Layout.fillWidth: true
                            title: "实时 ImageMagick 引擎指令预览"
                            subtitle: "底层内嵌进程池实际执行的受控沙箱参数"

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: 8
                                color: "#14171D"
                                border.color: "#2B313E"

                                Text {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    text: compressCtrl.commandPreview
                                    font.family: "Consolas"
                                    font.pixelSize: 11
                                    color: "#93C5FD"
                                    wrapMode: Text.WrapAnywhere
                                }
                            }
                        }
                    }
                }

                // ==================== Primary Start / Stop CTA Button ====================
                Rectangle {
                    id: startBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    Layout.minimumHeight: 50
                    Layout.maximumHeight: 50
                    radius: 10
                    scale: startMa.pressed ? 0.97 : 1.0
                    color: compressCtrl.isRunning
                           ? "#DC2626"
                           : (startMa.containsMouse ? "#60A5FA" : "#3B82F6")

                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    // Progress bar overlay while running
                    Rectangle {
                        visible: compressCtrl.isRunning
                        width: parent.width * compressCtrl.batchProgress
                        height: parent.height
                        radius: 10
                        color: "#33FFFFFF"
                        Behavior on width { NumberAnimation { duration: 150 } }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10
                        Text {
                            text: compressCtrl.isRunning
                                  ? ("⏹ 停止批量压缩 (" + Math.round(compressCtrl.batchProgress * 100) + "%)")
                                  : ("🚀 开始批量压缩 (" + taskModel.totalCount + " 张图片)")
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 15
                            font.bold: true
                            color: "#FFFFFF"
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

    // Animated Floating Toast Notification
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: window.toastText.length > 0 ? 26 : 6
        opacity: window.toastText.length > 0 ? 1.0 : 0.0
        visible: opacity > 0.01
        height: 40
        width: toastLbl.implicitWidth + 36
        radius: 20
        color: window.toastError ? "#991B1B" : "#1E3A8A"
        border.color: window.toastError ? "#F87171" : "#60A5FA"

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

        Text {
            id: toastLbl
            anchors.centerIn: parent
            text: window.toastText
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 13
            font.bold: true
            color: "#F8FAFC"
        }
    }
}
