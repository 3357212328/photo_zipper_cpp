import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Shapes
import "components"

ApplicationWindow {
    id: window
    width: 1280
    height: 820
    minimumWidth: 1080
    minimumHeight: 680
    visible: true
    title: "PhotoZipper C++"
    color: Theme.windowBg

    Behavior on color { ColorAnimation { duration: 180 } }

    property int selectedTaskIndex: -1
    property int activeSettingsTab: compressCtrl.activeSettingsTab
    property int activePresetIndex: compressCtrl.activePresetIndex
    property bool showComparePanel: false
    property string toastText: ""
    property bool toastError: false

    function openEngineDialog() {
        engineDialog.open()
    }
    function setWarmDayTheme(val) {
        Theme.setIsWarmDay(val, false)
    }

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

        // ==================== 1. UNIFIED STUDIO TOP BAR (52px) ====================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            Layout.minimumHeight: 52
            Layout.maximumHeight: 52
            color: Theme.headerBg
            Behavior on color { ColorAnimation { duration: 180 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10

                // Brand Icon + Title + Version Badge
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 6
                    color: "transparent"

                    Image {
                        anchors.fill: parent
                        source: "qrc:/icons/app_icon.png"
                        sourceSize.width: 28
                        sourceSize.height: 28
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                Text {
                    text: "PhotoZipper"
                    font.family: "Segoe UI"
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.textPrimary
                }

                Rectangle {
                    Layout.preferredHeight: 18
                    Layout.preferredWidth: 34
                    radius: 4
                    color: Theme.accentSoftBg
                    border.color: Theme.accentSoftBorder
                    Text {
                        anchors.centerIn: parent
                        text: "v1.0"
                        font.family: "Segoe UI"
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.accentSoftText
                    }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 18; color: Theme.headerBorder; Layout.leftMargin: 4; Layout.rightMargin: 4 }

                // Primary Add Files CTA
                Rectangle {
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: addFileRow.implicitWidth + 22
                    radius: 8
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: addFileMa.containsMouse ? Theme.accentHover : Theme.accent }
                        GradientStop { position: 1.0; color: Theme.accentEnd }
                    }
                    scale: addFileMa.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

                    RowLayout {
                        id: addFileRow
                        anchors.centerIn: parent
                        spacing: 6
                        VectorIcon { name: "plus"; size: 13; strokeWidth: 2.2; color: "#FFFFFF" }
                        Text {
                            text: "添加图片"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#FFFFFF"
                        }
                    }
                    MouseArea {
                        id: addFileMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addFilesDialog.open()
                    }
                }

                // Secondary Button: Add Folder (High-Contrast)
                Rectangle {
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: addDirRow.implicitWidth + 20
                    radius: 8
                    color: addDirMa.containsMouse ? Theme.btnSecHoverBg : Theme.btnSecBg
                    border.color: addDirMa.containsMouse ? Theme.cardHoverBorder : Theme.btnSecBorder
                    scale: addDirMa.pressed ? 0.96 : 1.0
                    Behavior on color { ColorAnimation { duration: 130 } }
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

                    RowLayout {
                        id: addDirRow
                        anchors.centerIn: parent
                        spacing: 6
                        VectorIcon { name: "folder"; size: 14; color: Theme.textPrimary }
                        Text {
                            text: "添加文件夹"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }
                    MouseArea {
                        id: addDirMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: addFolderDialog.open()
                    }
                }

                // Toggle Full-Canvas Compare View Pill (High-Contrast)
                Rectangle {
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: cmpRow.implicitWidth + 20
                    radius: 8
                    color: window.showComparePanel
                           ? Theme.accentSoftBg
                           : (cmpToggleMa.containsMouse ? Theme.btnSecHoverBg : Theme.btnSecBg)
                    border.color: window.showComparePanel ? Theme.accentSoftBorder : (cmpToggleMa.containsMouse ? Theme.cardHoverBorder : Theme.btnSecBorder)
                    scale: cmpToggleMa.pressed ? 0.96 : 1.0
                    Behavior on color { ColorAnimation { duration: 130 } }
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

                    RowLayout {
                        id: cmpRow
                        anchors.centerIn: parent
                        spacing: 6
                        VectorIcon { name: "eye"; size: 14; color: window.showComparePanel ? Theme.accentSoftText : Theme.textPrimary }
                        Text {
                            text: window.showComparePanel ? "返回队列" : "画质对比"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            font.bold: true
                            color: window.showComparePanel ? Theme.accentSoftText : Theme.textPrimary
                        }
                    }
                    MouseArea {
                        id: cmpToggleMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!window.showComparePanel && window.selectedTaskIndex < 0 && taskModel.totalCount > 0) {
                                window.selectedTaskIndex = 0
                            }
                            window.showComparePanel = !window.showComparePanel
                            window.refreshSelectedPreview()
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Compact Telemetry Chip
                Rectangle {
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: resRow.implicitWidth + 18
                    radius: 14
                    color: Theme.surfaceElevated
                    border.color: Theme.cardBorder

                    RowLayout {
                        id: resRow
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle { width: 6; height: 6; radius: 3; color: Theme.accent }
                        Text {
                            Layout.minimumWidth: 78
                            text: "内存 " + memMonitor.appMemoryText
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 11
                            color: Theme.textPrimary
                        }
                        Rectangle { width: 1; height: 11; color: Theme.cardBorder }
                        Text {
                            text: "引擎 " + memMonitor.engineSizeText
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 11
                            color: Theme.textSecondary
                        }
                    }
                }

                // Theme Switcher Pill
                Rectangle {
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: themeRow.implicitWidth + 18
                    radius: 8
                    color: themeMa.containsMouse ? Theme.btnSecHoverBg : Theme.btnSecBg
                    border.color: themeMa.containsMouse ? Theme.accent : Theme.btnSecBorder
                    scale: themeMa.pressed ? 0.96 : 1.0
                    Behavior on color { ColorAnimation { duration: 130 } }
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

                    RowLayout {
                        id: themeRow
                        anchors.centerIn: parent
                        spacing: 6
                        VectorIcon {
                            name: Theme.isWarmDay ? "sun" : "moon"
                            size: 13
                            color: Theme.isWarmDay ? Theme.accent : Theme.accentSoftText
                        }
                        Text {
                            text: Theme.isWarmDay ? "暖阳" : "夜间"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }
                    MouseArea {
                        id: themeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Theme.toggle()
                    }
                }

                // Embedded ImageMagick Engine Pill
                Rectangle {
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: engBtnRow.implicitWidth + 18
                    radius: 8
                    color: engMa.containsMouse ? Theme.btnSecHoverBg : Theme.btnSecBg
                    border.color: engineMgr.isInstalled ? (engMa.containsMouse ? Theme.accent : Theme.btnSecBorder) : Theme.dangerBorder
                    scale: engMa.pressed ? 0.96 : 1.0
                    Behavior on color { ColorAnimation { duration: 130 } }
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

                    RowLayout {
                        id: engBtnRow
                        anchors.centerIn: parent
                        spacing: 7
                        Rectangle {
                            width: 7
                            height: 7
                            radius: 3.5
                            color: engineMgr.isInstalled ? "#22C55E" : "#EF4444"
                        }
                        Text {
                            text: engineMgr.isInstalled
                                  ? ("ImageMagick " + engineMgr.currentVersion + " (" + engineMgr.currentQuantum + ")")
                                  : "未安装引擎"
                            font.family: "Segoe UI"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Rectangle {
                            Layout.preferredHeight: 18
                            Layout.preferredWidth: 36
                            radius: 4
                            color: Theme.accentSoftBg
                            Text {
                                anchors.centerIn: parent
                                text: "管理"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.accentSoftText
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
                color: Theme.headerBorder
            }
        }

        // ==================== 2. EDGE-TO-EDGE SPLIT WORKSPACE ====================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ---------- LEFT MAIN CANVAS (Queue View <-> Full-Canvas Compare View) ----------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    visible: !window.showComparePanel

                // Active Queue Summary Bar (only shown when queue has items)
                Rectangle {
                    visible: taskModel.totalCount > 0
                    z: 5
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    color: Theme.cardAltBg

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 10

                        Text {
                            text: "任务队列 (" + taskModel.totalCount + ")"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Rectangle {
                            Layout.preferredHeight: 22
                            Layout.preferredWidth: sumTxt.implicitWidth + 16
                            radius: 11
                            color: Theme.successBg
                            border.color: Theme.successBorder
                            Text {
                                id: sumTxt
                                anchors.centerIn: parent
                                text: taskModel.totalOriginalSizeText + " → " + taskModel.totalCompressedSizeText + " · 已节省 " + taskModel.totalSavedText
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.successText
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            visible: taskModel.completedCount > 0
                            Layout.preferredHeight: 26
                            Layout.preferredWidth: clrDoneRow.implicitWidth + 16
                            radius: 6
                            color: clrDoneMa.containsMouse ? Theme.btnSecHoverBg : Theme.btnSecBg
                            border.color: Theme.btnSecBorder
                            RowLayout {
                                id: clrDoneRow
                                anchors.centerIn: parent
                                spacing: 5
                                VectorIcon { name: "check"; size: 12; color: Theme.textSecondary }
                                Text {
                                    text: "清理已完成"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 11
                                    color: Theme.textSecondary
                                }
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

                        Rectangle {
                            Layout.preferredHeight: 26
                            Layout.preferredWidth: clrAllRow.implicitWidth + 16
                            radius: 6
                            color: clrAllMa.containsMouse ? Theme.dangerBg : Theme.btnSecBg
                            border.color: clrAllMa.containsMouse ? Theme.dangerBorder : Theme.btnSecBorder
                            RowLayout {
                                id: clrAllRow
                                anchors.centerIn: parent
                                spacing: 5
                                VectorIcon { name: "trash"; size: 12; color: Theme.dangerText }
                                Text {
                                    text: "清空"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 11
                                    color: Theme.dangerText
                                }
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

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.headerBorder
                    }
                }

                // Queue Body / Empty Dropzone
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // Centered Modern Dashed-Border Dropzone
                    Item {
                        id: dropzoneBox
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 64, 520)
                        height: 320
                        visible: taskModel.totalCount === 0

                        // Crisp Dashed Rounded Rectangle via QtQuick.Shapes
                        Shape {
                            anchors.fill: parent
                            antialiasing: true
                            ShapePath {
                                strokeColor: globalDropArea.containsDrag ? Theme.accent : Theme.cardHoverBorder
                                strokeWidth: globalDropArea.containsDrag ? 2 : 1.4
                                strokeStyle: ShapePath.DashLine
                                dashPattern: [6, 5]
                                fillColor: globalDropArea.containsDrag ? Theme.accentSoftBg : Theme.cardAltBg
                                PathRectangle {
                                    x: 1; y: 1
                                    width: dropzoneBox.width - 2
                                    height: dropzoneBox.height - 2
                                    radius: 16
                                }
                            }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - 48
                            spacing: 14

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 62
                                height: 62
                                radius: 31
                                color: Theme.accentSoftBg
                                border.color: Theme.accentSoftBorder
                                scale: globalDropArea.containsDrag ? 1.1 : 1.0
                                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

                                VectorIcon {
                                    anchors.centerIn: parent
                                    name: "upload"
                                    size: 26
                                    strokeWidth: 2.0
                                    color: Theme.accentSoftText
                                }
                            }

                            ColumnLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 5
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "拖拽图片或文件夹至此"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 17
                                    font.bold: true
                                    color: Theme.textPrimary
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "内置 ImageMagick 原生引擎高效压缩，轻量级界面低内存运行"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 12
                                    color: Theme.textSecondary
                                }
                            }

                            // Supported Format Chips
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 6
                                Repeater {
                                    model: ["JPG", "PNG", "WebP", "AVIF", "JXL", "HEIC", "TIFF"]
                                    delegate: Rectangle {
                                        Layout.preferredHeight: 20
                                        Layout.preferredWidth: fmtChip.implicitWidth + 12
                                        radius: 4
                                        color: Theme.surfaceElevated
                                        border.color: Theme.cardBorder
                                        Text {
                                            id: fmtChip
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.family: "Segoe UI"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: Theme.textSecondary
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 4
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 136
                                    Layout.preferredHeight: 36
                                    radius: 8
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: emptyAddMa.containsMouse ? Theme.accentHover : Theme.accent }
                                        GradientStop { position: 1.0; color: Theme.accentEnd }
                                    }
                                    scale: emptyAddMa.pressed ? 0.96 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        VectorIcon { name: "plus"; size: 13; strokeWidth: 2.2; color: "#FFFFFF" }
                                        Text {
                                            text: "选择本地图片"
                                            font.family: "Microsoft YaHei UI"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: "#FFFFFF"
                                        }
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
                                    Layout.preferredWidth: 136
                                    Layout.preferredHeight: 36
                                    radius: 8
                                    color: emptyFolderMa.containsMouse ? Theme.btnSecHoverBg : Theme.btnSecBg
                                    border.color: emptyFolderMa.containsMouse ? Theme.accent : Theme.btnSecBorder
                                    scale: emptyFolderMa.pressed ? 0.96 : 1.0
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        VectorIcon { name: "folder"; size: 13; color: Theme.textPrimary }
                                        Text {
                                            text: "添加文件夹"
                                            font.family: "Microsoft YaHei UI"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Theme.textPrimary
                                        }
                                    }
                                    MouseArea {
                                        id: emptyFolderMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: addFolderDialog.open()
                                    }
                                }
                            }
                        }
                    }

                    // Active Task ListView
                    ListView {
                        id: taskListView
                        anchors.fill: parent
                        topMargin: 14
                        bottomMargin: 14
                        leftMargin: 14
                        rightMargin: 14
                        clip: true
                        spacing: 8
                        visible: taskModel.totalCount > 0
                        model: taskModel
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        add: Transition {
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 170; easing.type: Easing.OutCubic }
                                NumberAnimation { property: "y"; from: 14; duration: 170; easing.type: Easing.OutCubic }
                            }
                        }
                        remove: Transition {
                            ParallelAnimation {
                                NumberAnimation { property: "opacity"; to: 0; duration: 130 }
                                NumberAnimation { property: "scale"; to: 0.95; duration: 130 }
                            }
                        }

                        delegate: Rectangle {
                            width: taskListView.width - taskListView.leftMargin - taskListView.rightMargin - 8
                            height: 64
                            radius: 10
                            readonly property bool isSelected: index === window.selectedTaskIndex
                            color: isSelected ? Theme.rowSelectedBg : (rowMa.containsMouse ? Theme.rowHoverBg : Theme.rowBg)
                            border.color: isSelected ? Theme.accent : (rowMa.containsMouse ? Theme.cardHoverBorder : Theme.cardBorder)
                            border.width: isSelected ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: 120 } }

                            MouseArea {
                                id: rowMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    window.selectedTaskIndex = index
                                    window.refreshSelectedPreview()
                                }
                                onDoubleClicked: {
                                    window.selectedTaskIndex = index
                                    window.refreshSelectedPreview()
                                    window.showComparePanel = true
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                // Low-memory thumbnail
                                Rectangle {
                                    Layout.preferredWidth: 44
                                    Layout.preferredHeight: 44
                                    radius: 7
                                    color: Theme.inputBg
                                    border.color: Theme.cardBorder
                                    clip: true

                                    Text {
                                        anchors.centerIn: parent
                                        visible: thumbImg.status !== Image.Ready
                                        text: model.format
                                        font.family: "Segoe UI"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.textMuted
                                    }

                                    Image {
                                        id: thumbImg
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        property bool useOutputFallback: false
                                        readonly property url outUrl: model.outputUrl
                                        onOutUrlChanged: {
                                            if (status === Image.Error && outUrl.toString().length > 0) {
                                                useOutputFallback = true
                                            }
                                        }
                                        source: (useOutputFallback && outUrl.toString().length > 0) ? outUrl : model.fileUrl
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                        sourceSize.width: 96
                                        sourceSize.height: 96
                                        onStatusChanged: {
                                            if (status === Image.Error && !useOutputFallback && outUrl.toString().length > 0) {
                                                useOutputFallback = true
                                            }
                                        }
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
                                            color: Theme.accentSoftBg
                                            border.color: Theme.accentSoftBorder
                                            Layout.preferredHeight: 18
                                            Layout.preferredWidth: fmtTxt.implicitWidth + 10
                                            Text {
                                                id: fmtTxt
                                                anchors.centerIn: parent
                                                text: model.format
                                                font.family: "Segoe UI"
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: Theme.accentSoftText
                                            }
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            elide: Text.ElideMiddle
                                            text: model.fileName
                                            font.family: "Microsoft YaHei UI"
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: Theme.textPrimary
                                        }
                                    }
                                    Text {
                                        text: model.dimensionsText
                                              + (model.outputDimensionsText !== "-" ? ("  →  " + model.outputDimensionsText) : "")
                                              + (model.elapsedMs > 0 ? ("  ·  " + model.elapsedMs + " ms") : "")
                                        font.family: "Segoe UI"
                                        font.pixelSize: 11
                                        color: Theme.textSecondary
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
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Theme.textPrimary
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignRight
                                        Layout.maximumWidth: 210
                                        elide: Text.ElideRight
                                        text: model.status === "失败"
                                              ? (model.errorMessage.length > 0 ? model.errorMessage : "压缩失败")
                                              : (model.status === "处理中"
                                                 ? "正在压缩..."
                                                 : (model.status === "已取消"
                                                    ? "已取消"
                                                    : (model.savedPercentText !== "-" ? ("节省 " + model.savedPercentText) : "等待压缩")))
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 11
                                        font.bold: model.savedPositive
                                        color: model.status === "失败" ? Theme.dangerText
                                             : (model.status === "处理中" ? Theme.accentSoftText
                                             : (model.savedPositive ? Theme.successText : Theme.textMuted))
                                    }
                                }

                                // Status badge
                                Rectangle {
                                    Layout.preferredWidth: 62
                                    Layout.preferredHeight: 24
                                    radius: 6
                                    color: model.status === "已完成" ? Theme.successBg
                                         : (model.status === "处理中" ? Theme.accentSoftBg
                                         : (model.status === "失败" ? Theme.dangerBg : Theme.btnSecBg))
                                    border.color: model.status === "已完成" ? Theme.successBorder
                                                : (model.status === "处理中" ? Theme.accentSoftBorder
                                                : (model.status === "失败" ? Theme.dangerBorder : Theme.btnSecBorder))

                                    Text {
                                        anchors.centerIn: parent
                                        text: model.status
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: model.status === "已完成" ? Theme.successText
                                             : (model.status === "处理中" ? Theme.accentSoftText
                                             : (model.status === "失败" ? Theme.dangerText : Theme.textSecondary))
                                    }

                                    MouseArea {
                                        id: statusTipMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.NoButton
                                    }

                                    ToolTip.visible: statusTipMa.containsMouse && model.errorMessage.length > 0
                                    ToolTip.text: model.errorMessage
                                }

                                // Compare this item button
                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 6
                                    color: cmpItemMa.containsMouse ? Theme.accentSoftBg : "transparent"
                                    VectorIcon {
                                        anchors.centerIn: parent
                                        name: "eye"
                                        size: 14
                                        color: cmpItemMa.containsMouse ? Theme.accentSoftText : Theme.textSecondary
                                    }
                                    MouseArea {
                                        id: cmpItemMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            window.selectedTaskIndex = index
                                            window.refreshSelectedPreview()
                                            window.showComparePanel = true
                                        }
                                    }
                                }

                                // Open output folder button
                                Rectangle {
                                    visible: model.outputPath.length > 0
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 6
                                    color: locMa.containsMouse ? Theme.btnSecHoverBg : "transparent"
                                    VectorIcon {
                                        anchors.centerIn: parent
                                        name: "folder-open"
                                        size: 14
                                        color: locMa.containsMouse ? Theme.textPrimary : Theme.textSecondary
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
                                    color: delMa.containsMouse ? Theme.dangerBg : "transparent"
                                    VectorIcon {
                                        anchors.centerIn: parent
                                        name: "x"
                                        size: 13
                                        color: delMa.containsMouse ? Theme.dangerText : Theme.textMuted
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

                } // End Queue ColumnLayout

                // Full-Canvas Before/After Compare Studio
                CompareView {
                    id: compareView
                    anchors.fill: parent
                    visible: opacity > 0.01
                    opacity: window.showComparePanel ? 1.0 : 0.0
                    currentIndex: window.selectedTaskIndex
                    totalCount: taskModel.totalCount

                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    onBackRequested: window.showComparePanel = false
                    onPrevRequested: {
                        if (taskModel.totalCount > 1) {
                            window.selectedTaskIndex = (window.selectedTaskIndex - 1 + taskModel.totalCount) % taskModel.totalCount
                            window.refreshSelectedPreview()
                        }
                    }
                    onNextRequested: {
                        if (taskModel.totalCount > 1) {
                            window.selectedTaskIndex = (window.selectedTaskIndex + 1) % taskModel.totalCount
                            window.refreshSelectedPreview()
                        }
                    }
                }
            }

            // Vertical 1px Hairline Separator
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.headerBorder
            }

            // ---------- RIGHT INSPECTOR SIDEBAR (392px, Studio Pro Hairline Sections) ----------
            Rectangle {
                Layout.preferredWidth: 392
                Layout.minimumWidth: 392
                Layout.maximumWidth: 392
                Layout.fillHeight: true
                color: Theme.sidebarBg
                Behavior on color { ColorAnimation { duration: 180 } }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Segmented Tab Bar Header
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54

                        Rectangle {
                            id: tabBarContainer
                            anchors.fill: parent
                            anchors.margins: 10
                            radius: 9
                            color: Theme.inputBg
                            border.color: Theme.cardBorder

                            readonly property real tabWidth: (width - 6) / 3
                            property bool ready: false
                            property int pressedTab: -1
                            Component.onCompleted: Qt.callLater(function() { ready = true })

                            // Sliding elevated pill indicator
                            Rectangle {
                                x: 3 + window.activeSettingsTab * tabBarContainer.tabWidth
                                y: 3
                                width: tabBarContainer.tabWidth
                                height: parent.height - 6
                                radius: 7
                                color: Theme.surfaceElevated
                                border.color: Theme.cardHoverBorder
                                scale: tabBarContainer.pressedTab === window.activeSettingsTab ? 0.96 : 1.0

                                Behavior on x {
                                    enabled: tabBarContainer.ready
                                    NumberAnimation { duration: 210; easing.type: Easing.OutCubic }
                                }
                                Behavior on scale {
                                    NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 3
                                spacing: 0

                                Repeater {
                                    model: [
                                        { icon: "sliders", label: "核心压缩" },
                                        { icon: "droplet", label: "增强水印" },
                                        { icon: "output",  label: "导出设置" }
                                    ]
                                    delegate: Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 5
                                            scale: tabMa.pressed ? 0.94 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                                            VectorIcon {
                                                name: modelData.icon
                                                size: 13
                                                color: window.activeSettingsTab === index ? Theme.accent : Theme.textSecondary
                                            }
                                            Text {
                                                text: modelData.label
                                                font.family: "Microsoft YaHei UI"
                                                font.pixelSize: 12
                                                font.bold: window.activeSettingsTab === index
                                                color: window.activeSettingsTab === index ? Theme.textPrimary : Theme.textSecondary
                                                Behavior on color { ColorAnimation { duration: 130 } }
                                            }
                                        }

                                        MouseArea {
                                            id: tabMa
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onPressed: tabBarContainer.pressedTab = index
                                            onReleased: tabBarContainer.pressedTab = -1
                                            onCanceled: tabBarContainer.pressedTab = -1
                                            onClicked: compressCtrl.activeSettingsTab = index
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Theme.headerBorder
                        }
                    }

                    // Tab Body Area (Scroll-free, hairline-separated studio sections)
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        // ==================== TAB 0: 核心压缩 ====================
                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 14
                            visible: opacity > 0.01
                            opacity: window.activeSettingsTab === 0 ? 1.0 : 0.0
                            transform: Translate {
                                x: window.activeSettingsTab === 0 ? 0 : -12
                                Behavior on x { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
                            }
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            // 1. 快捷预设 (Sliding SegmentedControl)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 7

                                Text {
                                    text: "快捷预设"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.textSecondary
                                }

                                SegmentedControl {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    items: ["均衡", "WebP", "高清", "限体积", "无损"]
                                    currentIndex: window.activePresetIndex
                                    onActivated: function(idx) {
                                        compressCtrl.applyPreset(idx)
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardBorder }

                            // 2. 尺寸调整
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "尺寸调整"
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.textPrimary
                                    }
                                    Item { Layout.fillWidth: true }
                                    ModernCheckBox {
                                        text: "启用"
                                        switchStyle: true
                                        checked: compressCtrl.resizeEnabled
                                        onToggled: function(c) { compressCtrl.resizeEnabled = c }
                                    }
                                }

                                // Side-by-side CompactInput (W / H) with Single-Axis Aspect Lock
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    opacity: compressCtrl.resizeEnabled ? 1.0 : 0.4

                                    CompactInput {
                                        readonly property bool wEnabled: compressCtrl.resizeEnabled
                                                                       && (compressCtrl.resizeMode === 1 || !compressCtrl.keepAspectRatioShrinkOnly || compressCtrl.aspectDimension === 0)
                                        Layout.fillWidth: true
                                        prefixText: compressCtrl.resizeMode === 1 ? "比例" : "W"
                                        suffixText: compressCtrl.resizeMode === 1 ? "%" : "px"
                                        text: compressCtrl.resizeMode === 1
                                              ? compressCtrl.resizePercentage.toString()
                                              : ((!wEnabled && compressCtrl.keepAspectRatioShrinkOnly)
                                                 ? ""
                                                 : (compressCtrl.targetWidth > 0 ? compressCtrl.targetWidth.toString() : ""))
                                        placeholderText: (!wEnabled && compressCtrl.keepAspectRatioShrinkOnly) ? "按比例自动" : "不限"
                                        inputEnabled: wEnabled
                                        opacity: wEnabled ? 1.0 : 0.45
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

                                    CompactInput {
                                        readonly property bool hEnabled: compressCtrl.resizeEnabled
                                                                       && (!compressCtrl.keepAspectRatioShrinkOnly || compressCtrl.aspectDimension === 1)
                                        Layout.fillWidth: true
                                        visible: compressCtrl.resizeMode === 0
                                        prefixText: "H"
                                        suffixText: "px"
                                        text: (!hEnabled && compressCtrl.keepAspectRatioShrinkOnly)
                                              ? ""
                                              : (compressCtrl.targetHeight > 0 ? compressCtrl.targetHeight.toString() : "")
                                        placeholderText: (!hEnabled && compressCtrl.keepAspectRatioShrinkOnly) ? "按比例自动" : "不限"
                                        inputEnabled: hEnabled
                                        opacity: hEnabled ? 1.0 : 0.45
                                        validator: IntValidator { bottom: 1; top: 99999 }
                                        onEditingCompleted: function(val) {
                                            var num = parseInt(val)
                                            compressCtrl.targetHeight = isNaN(num) ? 0 : num
                                        }
                                    }
                                }

                                // Keep aspect ratio + single-axis selector (按宽度 / 按高度)
                                RowLayout {
                                    visible: compressCtrl.resizeMode === 0
                                    Layout.fillWidth: true
                                    enabled: compressCtrl.resizeEnabled
                                    opacity: compressCtrl.resizeEnabled ? 1.0 : 0.4
                                    spacing: 8

                                    ModernCheckBox {
                                        text: "保持宽高比 (仅缩小)"
                                        checked: compressCtrl.keepAspectRatioShrinkOnly
                                        onToggled: function(c) { compressCtrl.keepAspectRatioShrinkOnly = c }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Lock Axis Segmented Pill (按宽度 | 按高度)
                                    SegmentedControl {
                                        visible: compressCtrl.keepAspectRatioShrinkOnly
                                        Layout.preferredWidth: 118
                                        Layout.preferredHeight: 26
                                        fontPixelSize: 10
                                        items: ["按宽度", "按高度"]
                                        currentIndex: compressCtrl.aspectDimension
                                        onActivated: function(idx) { compressCtrl.aspectDimension = idx }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    enabled: compressCtrl.resizeEnabled
                                    opacity: compressCtrl.resizeEnabled ? 1.0 : 0.4
                                    spacing: 6

                                    // 2-pill Resize Mode (按宽高 | 按比例)
                                    SegmentedControl {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 32
                                        accentStyle: false
                                        items: ["按宽高", "按比例"]
                                        currentIndex: compressCtrl.resizeMode
                                        onActivated: function(idx) { compressCtrl.resizeMode = idx }
                                    }

                                    ModernComboBox {
                                        Layout.preferredWidth: 116
                                        Layout.preferredHeight: 32
                                        currentIndex: compressCtrl.filterType
                                        model: ["Lanczos", "Mitchell", "Catrom", "Triangle"]
                                        onActivated: function(idx) { compressCtrl.filterType = idx }
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardBorder }

                            // 3. 压缩与格式
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "压缩与格式"
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.textPrimary
                                    }
                                    Item { Layout.fillWidth: true }
                                    ModernCheckBox {
                                        text: "无损模式"
                                        switchStyle: true
                                        checked: compressCtrl.losslessMode
                                        onToggled: function(c) { compressCtrl.losslessMode = c }
                                    }
                                }

                                // Quality Slider + Smart Tier Badge
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    enabled: !compressCtrl.losslessMode
                                    opacity: compressCtrl.losslessMode ? 0.4 : 1.0

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "压缩质量"
                                            font.family: "Microsoft YaHei UI"
                                            font.pixelSize: 12
                                            color: Theme.textSecondary
                                        }
                                        Text {
                                            text: compressCtrl.quality >= 88 ? "· 高画质" : (compressCtrl.quality >= 75 ? "· 均衡推荐" : "· 极限瘦身")
                                            font.family: "Microsoft YaHei UI"
                                            font.pixelSize: 11
                                            color: Theme.textMuted
                                        }
                                        Item { Layout.fillWidth: true }
                                        Rectangle {
                                            radius: 5
                                            color: Theme.accentSoftBg
                                            border.color: Theme.accentSoftBorder
                                            Layout.preferredWidth: 44
                                            Layout.preferredHeight: 20
                                            Text {
                                                anchors.centerIn: parent
                                                text: compressCtrl.quality + "%"
                                                font.family: "Segoe UI"
                                                font.pixelSize: 11
                                                font.bold: true
                                                color: Theme.accentSoftText
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
                                            height: 5
                                            radius: 2.5
                                            color: Theme.inputBorder

                                            Rectangle {
                                                width: qSlider.visualPosition * parent.width
                                                height: parent.height
                                                radius: 2.5
                                                gradient: Gradient {
                                                    orientation: Gradient.Horizontal
                                                    GradientStop { position: 0.0; color: Theme.accent }
                                                    GradientStop { position: 1.0; color: Theme.accentEnd }
                                                }
                                            }
                                        }

                                        handle: Rectangle {
                                            x: qSlider.leftPadding + qSlider.visualPosition * (qSlider.availableWidth - width)
                                            y: qSlider.topPadding + qSlider.availableHeight / 2 - height / 2
                                            width: 16
                                            height: 16
                                            radius: 8
                                            scale: qSlider.pressed ? 1.18 : 1.0
                                            color: "#FFFFFF"
                                            border.color: Theme.accent
                                            border.width: 2.5
                                            Behavior on scale { NumberAnimation { duration: 90 } }
                                        }
                                    }
                                }

                                // 6-Pill Output Format Selector (Sliding SegmentedControl)
                                SegmentedControl {
                                    readonly property var formatCodes: ["original", "jpg", "webp", "avif", "png", "jxl"]
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    items: ["原格式", "JPG", "WebP", "AVIF", "PNG", "JXL"]
                                    currentIndex: Math.max(0, formatCodes.indexOf(compressCtrl.outputFormat))
                                    onActivated: function(idx) {
                                        compressCtrl.outputFormat = formatCodes[idx]
                                    }
                                }

                                // Target Size Lock Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    ModernCheckBox {
                                        text: "锁定最大体积"
                                        checked: compressCtrl.targetSizeEnabled
                                        onToggled: function(c) { compressCtrl.targetSizeEnabled = c }
                                    }

                                    CompactInput {
                                        Layout.fillWidth: true
                                        prefixText: "≤"
                                        suffixText: "KB"
                                        text: compressCtrl.targetMaxKB.toString()
                                        inputEnabled: compressCtrl.targetSizeEnabled
                                        validator: IntValidator { bottom: 5; top: 50000 }
                                        onEditingCompleted: function(val) {
                                            var n = parseInt(val)
                                            if (!isNaN(n) && n > 0) compressCtrl.targetMaxKB = n
                                        }
                                    }
                                }

                                // Bottom Options Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    ModernCheckBox {
                                        text: "渐进式"
                                        checked: compressCtrl.progressiveJpeg
                                        onToggled: function(c) { compressCtrl.progressiveJpeg = c }
                                    }
                                    ModernCheckBox {
                                        text: "防变大"
                                        checked: compressCtrl.skipIfLarger
                                        onToggled: function(c) { compressCtrl.skipIfLarger = c }
                                    }
                                    Item { Layout.fillWidth: true }
                                    ModernComboBox {
                                        Layout.preferredWidth: 124
                                        Layout.preferredHeight: 30
                                        currentIndex: compressCtrl.chromaSubsampling
                                        model: ["色度: 自动", "色度: 4:2:0", "色度: 4:4:4"]
                                        onActivated: function(idx) { compressCtrl.chromaSubsampling = idx }
                                    }
                                }
                            }
                        }

                        // ==================== TAB 1: 增强水印 ====================
                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 14
                            visible: opacity > 0.01
                            opacity: window.activeSettingsTab === 1 ? 1.0 : 0.0
                            transform: Translate {
                                x: window.activeSettingsTab === 1 ? 0 : 12
                                Behavior on x { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
                            }
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: "隐私清理与色彩管理"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.textPrimary
                                }
                                ModernCheckBox {
                                    text: "剥离 EXIF / GPS / XMP 隐私元数据 (-strip)"
                                    checked: compressCtrl.stripMetadata
                                    onToggled: function(c) { compressCtrl.stripMetadata = c }
                                }
                                ModernCheckBox {
                                    text: "剥离前根据 EXIF 自动旋转回正方向"
                                    checked: compressCtrl.autoOrient
                                    onToggled: function(c) { compressCtrl.autoOrient = c }
                                }
                                ModernCheckBox {
                                    text: "统一转换为标准 sRGB 网页色域"
                                    checked: compressCtrl.convertToSRGB
                                    onToggled: function(c) { compressCtrl.convertToSRGB = c }
                                }
                                ModernCheckBox {
                                    text: "缩放后自适应 Unsharp 锐化补偿"
                                    checked: compressCtrl.sharpenAfterResize
                                    onToggled: function(c) { compressCtrl.sharpenAfterResize = c }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardBorder }

                            // 4-Pill Color Filter
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: "色彩滤镜"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.textPrimary
                                }
                                SegmentedControl {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    items: ["原色", "黑白灰度", "自动增强", "复古怀旧"]
                                    currentIndex: compressCtrl.colorFilter
                                    onActivated: function(idx) { compressCtrl.colorFilter = idx }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardBorder }

                            // Watermark Section
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "防盗文字水印"
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.textPrimary
                                    }
                                    Item { Layout.fillWidth: true }
                                    ModernCheckBox {
                                        text: "启用"
                                        switchStyle: true
                                        checked: compressCtrl.watermarkEnabled
                                        onToggled: function(c) { compressCtrl.watermarkEnabled = c }
                                    }
                                }

                                CompactInput {
                                    Layout.fillWidth: true
                                    prefixText: "水印"
                                    text: compressCtrl.watermarkText
                                    placeholderText: "输入水印文本..."
                                    inputEnabled: compressCtrl.watermarkEnabled
                                    opacity: compressCtrl.watermarkEnabled ? 1.0 : 0.4
                                    onEditingCompleted: function(v) { compressCtrl.watermarkText = v }
                                }

                                SegmentedControl {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    enabled: compressCtrl.watermarkEnabled
                                    opacity: compressCtrl.watermarkEnabled ? 1.0 : 0.4
                                    items: ["右下", "左下", "右上", "左上", "居中"]
                                    currentIndex: compressCtrl.watermarkPosition
                                    onActivated: function(idx) { compressCtrl.watermarkPosition = idx }
                                }
                            }
                        }

                        // ==================== TAB 2: 导出设置 ====================
                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 16
                            spacing: 14
                            visible: opacity > 0.01
                            opacity: window.activeSettingsTab === 2 ? 1.0 : 0.0
                            transform: Translate {
                                x: window.activeSettingsTab === 2 ? 0 : 12
                                Behavior on x { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
                            }
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Text {
                                    text: "保存位置"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.textPrimary
                                }

                                SegmentedControl {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    items: ["compressed目录", "自定义目录", "覆盖原图"]
                                    currentIndex: compressCtrl.outputDirMode
                                    onActivated: function(idx) { compressCtrl.outputDirMode = idx }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: compressCtrl.outputDirMode === 1
                                    spacing: 8
                                    CompactInput {
                                        Layout.fillWidth: true
                                        prefixText: "路径"
                                        text: compressCtrl.customOutputDir
                                        placeholderText: "选择保存文件夹..."
                                        onEditingCompleted: function(v) { compressCtrl.customOutputDir = v }
                                    }
                                    Rectangle {
                                        Layout.preferredWidth: 66
                                        Layout.preferredHeight: 36
                                        radius: 8
                                        color: browseMa.containsMouse ? Theme.btnSecHoverBg : Theme.btnSecBg
                                        border.color: Theme.btnSecBorder
                                        Text {
                                            anchors.centerIn: parent
                                            text: "浏览"
                                            font.family: "Microsoft YaHei UI"
                                            font.pixelSize: 12
                                            color: Theme.textPrimary
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
                                    spacing: 8
                                    CompactInput {
                                        Layout.fillWidth: true
                                        prefixText: "前缀"
                                        text: compressCtrl.filePrefix
                                        placeholderText: "无"
                                        onEditingCompleted: function(v) { compressCtrl.filePrefix = v }
                                    }
                                    CompactInput {
                                        Layout.fillWidth: true
                                        prefixText: "后缀"
                                        text: compressCtrl.fileSuffix
                                        placeholderText: "_min"
                                        onEditingCompleted: function(v) { compressCtrl.fileSuffix = v }
                                    }
                                }
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.cardBorder }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                RowLayout {
                                    spacing: 6
                                    VectorIcon { name: "terminal"; size: 13; color: Theme.accent }
                                    Text {
                                        text: "ImageMagick 实时指令预览"
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Theme.textPrimary
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 110
                                    radius: 8
                                    color: Theme.inputBg
                                    border.color: Theme.cardBorder

                                    Text {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        text: compressCtrl.commandPreview
                                        font.family: "Consolas"
                                        font.pixelSize: 11
                                        color: Theme.accentSoftText
                                        wrapMode: Text.WrapAnywhere
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Docked Action Footer
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 74

                        Rectangle {
                            anchors.top: parent.top
                            width: parent.width
                            height: 1
                            color: Theme.headerBorder
                        }

                        Rectangle {
                            id: startBtn
                            anchors.fill: parent
                            anchors.margins: 14
                            radius: 10
                            scale: startMa.pressed ? 0.97 : 1.0
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0.0
                                    color: compressCtrl.isRunning
                                           ? "#DC2626"
                                           : (startMa.containsMouse ? Theme.accentHover : Theme.accent)
                                }
                                GradientStop {
                                    position: 1.0
                                    color: compressCtrl.isRunning ? "#EF4444" : Theme.accentEnd
                                }
                            }

                            Rectangle {
                                visible: compressCtrl.isRunning
                                width: parent.width * compressCtrl.batchProgress
                                height: parent.height
                                radius: 10
                                color: "#33FFFFFF"
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                VectorIcon {
                                    name: compressCtrl.isRunning ? "stop" : "zap"
                                    size: 16
                                    strokeWidth: 2.0
                                    color: "#FFFFFF"
                                }
                                Text {
                                    text: compressCtrl.isRunning
                                          ? ("停止批量压缩 (" + Math.round(compressCtrl.batchProgress * 100) + "%)")
                                          : ("开始批量压缩 (" + taskModel.totalCount + " 张图片)")
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 14
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
        }
    }

    // Animated Floating Toast Notification
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: window.toastText.length > 0 ? (window.showComparePanel ? 68 : 26) : 6
        opacity: window.toastText.length > 0 ? 1.0 : 0.0
        visible: opacity > 0.01
        height: 38
        width: toastLbl.implicitWidth + 36
        radius: 19
        color: window.toastError ? Theme.dangerBg : Theme.accent
        border.color: window.toastError ? Theme.dangerBorder : Theme.accentEnd

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

        Text {
            id: toastLbl
            anchors.centerIn: parent
            text: window.toastText
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 12
            font.bold: true
            color: window.toastError ? Theme.dangerText : "#FFFFFF"
        }
    }
}
