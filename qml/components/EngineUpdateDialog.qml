import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs

Popup {
    id: root
    width: 720
    height: 580
    padding: 0
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property var engineManager: null
    property var memoryMonitor: null

    onOpened: {
        if (engineManager && engineManager.availableReleases.length === 0) {
            engineManager.fetchReleases(20)
        }
    }

    FileDialog {
        id: localArchiveDialog
        title: "选择本地 ImageMagick 官方便携压缩包 (.7z / .zip / .tar.xz)"
        fileMode: FileDialog.OpenFile
        nameFilters: [
            "ImageMagick 便携包 (*.7z *.zip *.tar.xz *.tar.gz)",
            "所有文件 (*.*)"
        ]
        onAccepted: {
            if (engineManager) {
                engineManager.installFromLocalArchive(selectedFile)
            }
        }
    }

    FolderDialog {
        id: localFolderDialog
        title: "选择本地包含 magick.exe 的 ImageMagick 目录"
        onAccepted: {
            if (engineManager) {
                engineManager.installFromLocalDirectory(selectedFolder)
            }
        }
    }

    Overlay.modal: Rectangle {
        color: Theme.isWarmDay ? "#66241C16" : "#BA090B10"
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 170; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 190; easing.type: Easing.OutBack }
        }
    }
    exit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.96; duration: 120; easing.type: Easing.InCubic }
        }
    }

    background: Rectangle {
        color: Theme.sidebarBg
        radius: 14
        border.width: 1
        border.color: Theme.cardHoverBorder
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 14

        // Title bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 9
                color: Theme.accentSoftBg
                border.color: Theme.accentSoftBorder

                VectorIcon {
                    anchors.centerIn: parent
                    name: "cpu"
                    size: 18
                    color: Theme.accentSoftText
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "内嵌 ImageMagick 引擎版本管理"
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.textPrimary
                }
                Text {
                    text: "支持从 GitHub 官方源在线更新或导入本地压缩包/目录 · 严格单版本原子替换"
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 11
                    color: Theme.textSecondary
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                radius: 8
                color: closeMa.containsMouse ? Theme.dangerBg : Theme.btnSecBg
                border.color: closeMa.containsMouse ? Theme.dangerBorder : Theme.btnSecBorder
                Behavior on color { ColorAnimation { duration: 130 } }

                VectorIcon {
                    anchors.centerIn: parent
                    name: "x"
                    size: 14
                    color: closeMa.containsMouse ? Theme.dangerText : Theme.textSecondary
                }
                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }

        // Current engine status card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 74
            radius: 10
            color: Theme.cardBg
            border.color: Theme.cardBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        spacing: 8
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: (engineManager && engineManager.isInstalled) ? "#22C55E" : "#EF4444"
                        }
                        Text {
                            text: "当前内嵌版本: " + (engineManager ? engineManager.currentVersion : "-")
                                  + " (" + (engineManager ? engineManager.currentQuantum : "-") + ")"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Rectangle {
                            radius: 5
                            color: Theme.accentSoftBg
                            border.color: Theme.accentSoftBorder
                            Layout.preferredHeight: 20
                            Layout.preferredWidth: diskTxt.implicitWidth + 14
                            Text {
                                id: diskTxt
                                anchors.centerIn: parent
                                text: "引擎体积: " + (memoryMonitor ? memoryMonitor.engineSizeText : "-")
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.accentSoftText
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: "支持模块: " + (engineManager ? engineManager.currentFeatures : "-")
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }
                }

                // Online Update to latest button
                Rectangle {
                    Layout.preferredWidth: 144
                    Layout.preferredHeight: 36
                    radius: 8
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: (engineManager && engineManager.isBusy) ? Theme.btnSecBg : (latestMa.containsMouse ? Theme.accentHover : Theme.accent) }
                        GradientStop { position: 1.0; color: (engineManager && engineManager.isBusy) ? Theme.btnSecBg : Theme.accentEnd }
                    }
                    scale: latestMa.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        VectorIcon {
                            name: "cloud"
                            size: 14
                            color: "#FFFFFF"
                        }
                        Text {
                            text: (engineManager && !engineManager.isInstalled) ? "在线安装最新版" : "在线更新最新版"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#FFFFFF"
                        }
                    }
                    MouseArea {
                        id: latestMa
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: engineManager && !engineManager.isBusy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: engineManager.installLatestVersion()
                    }
                }
            }
        }

        // Local Offline Update / Import Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            radius: 10
            color: Theme.cardBg
            border.color: Theme.cardBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: "本地离线更新 / 切换特定版本"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.textPrimary
                    }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: "选择本地官方便携包 (.7z/.zip) 或解压目录，自动瘦身并清除旧版"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        color: Theme.textSecondary
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 126
                    Layout.minimumWidth: 126
                    Layout.maximumWidth: 126
                    Layout.preferredHeight: 34
                    radius: 8
                    color: locPkgMa.containsMouse ? Theme.btnSecHoverBg : Theme.btnSecBg
                    border.color: locPkgMa.containsMouse ? Theme.accent : Theme.btnSecBorder
                    scale: locPkgMa.pressed ? 0.96 : 1.0
                    Behavior on color { ColorAnimation { duration: 130 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        VectorIcon { name: "package"; size: 13; color: Theme.textPrimary }
                        Text {
                            text: "本地压缩包"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            color: Theme.textPrimary
                        }
                    }
                    MouseArea {
                        id: locPkgMa
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: engineManager && !engineManager.isBusy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: localArchiveDialog.open()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 126
                    Layout.minimumWidth: 126
                    Layout.maximumWidth: 126
                    Layout.preferredHeight: 34
                    radius: 8
                    color: locDirMa.containsMouse ? Theme.btnSecHoverBg : Theme.btnSecBg
                    border.color: locDirMa.containsMouse ? Theme.accent : Theme.btnSecBorder
                    scale: locDirMa.pressed ? 0.96 : 1.0
                    Behavior on color { ColorAnimation { duration: 130 } }
                    Behavior on scale { NumberAnimation { duration: 100 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        VectorIcon { name: "folder"; size: 13; color: Theme.textPrimary }
                        Text {
                            text: "本地文件夹"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            color: Theme.textPrimary
                        }
                    }
                    MouseArea {
                        id: locDirMa
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: engineManager && !engineManager.isBusy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: localFolderDialog.open()
                    }
                }
            }
        }

        // Quantum selection & Refresh bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "位深精度:"
                font.family: "Microsoft YaHei UI"
                font.pixelSize: 12
                color: Theme.textSecondary
            }

            Repeater {
                model: [
                    { code: "Q8", label: "Q8 (推荐 · 省内存)" },
                    { code: "Q16", label: "Q16 (高色深)" },
                    { code: "Q16-HDRI", label: "Q16-HDRI (浮点)" }
                ]
                delegate: Rectangle {
                    readonly property bool selected: engineManager && engineManager.preferredQuantum === modelData.code
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: qTxt.implicitWidth + 18
                    radius: 6
                    color: selected ? Theme.accentSoftBg : Theme.btnSecBg
                    border.color: selected ? Theme.accentSoftBorder : Theme.btnSecBorder
                    Behavior on color { ColorAnimation { duration: 130 } }

                    Text {
                        id: qTxt
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        font.bold: selected
                        color: selected ? Theme.accentSoftText : Theme.textSecondary
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (engineManager) engineManager.preferredQuantum = modelData.code
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 104
                Layout.preferredHeight: 28
                radius: 6
                color: refMa.containsMouse ? Theme.btnSecHoverBg : Theme.btnSecBg
                border.color: Theme.btnSecBorder
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 5
                    VectorIcon { name: "refresh"; size: 12; color: Theme.textPrimary }
                    Text {
                        text: (engineManager && engineManager.isFetchingReleases) ? "刷新中..." : "刷新在线源"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        color: Theme.textPrimary
                    }
                }
                MouseArea {
                    id: refMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: engineManager && !engineManager.isFetchingReleases
                    onClicked: engineManager.fetchReleases(25)
                }
            }
        }

        // Releases list
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.inputBg
            radius: 10
            border.color: Theme.cardBorder
            clip: true

            ListView {
                id: releaseListView
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6
                model: engineManager ? engineManager.availableReleases : []
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    width: releaseListView.width - 10
                    height: 52
                    radius: 8
                    readonly property bool isCurrent: engineManager
                                                      && engineManager.currentVersion === modelData.tag
                                                      && engineManager.currentQuantum === engineManager.preferredQuantum
                    color: isCurrent ? Theme.rowSelectedBg : Theme.rowBg
                    border.color: isCurrent ? Theme.accentSoftBorder : Theme.cardBorder

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "ImageMagick " + modelData.tag
                                    font.family: "Segoe UI"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.textPrimary
                                }
                                Rectangle {
                                    visible: index === 0
                                    radius: 4
                                    color: Theme.accentSoftBg
                                    border.color: Theme.accentSoftBorder
                                    Layout.preferredHeight: 18
                                    Layout.preferredWidth: 38
                                    Text {
                                        anchors.centerIn: parent
                                        text: "最新"
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.accentSoftText
                                    }
                                }
                                Rectangle {
                                    visible: isCurrent
                                    radius: 4
                                    color: Theme.successBg
                                    border.color: Theme.successBorder
                                    Layout.preferredHeight: 18
                                    Layout.preferredWidth: 54
                                    Text {
                                        anchors.centerIn: parent
                                        text: "当前使用"
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.successText
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                readonly property string qCode: engineManager ? engineManager.preferredQuantum : "Q8"
                                readonly property string pkgSize: (modelData.sizes && modelData.sizes[qCode]) ? modelData.sizes[qCode] : "~11.6 MB"
                                text: "发布日期: " + modelData.date + "  ·  下载包(" + qCode + "): " + pkgSize + "  ·  精简后约 32.6 MB"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                color: Theme.textSecondary
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 106
                            Layout.preferredHeight: 30
                            radius: 7
                            color: isCurrent ? Theme.btnSecBg : (swMa.containsMouse ? Theme.accentHover : Theme.accent)
                            border.color: isCurrent ? Theme.btnSecBorder : Theme.accent
                            scale: swMa.pressed ? 0.96 : 1.0
                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: isCurrent ? "当前已安装" : "切换至此版本"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                font.bold: !isCurrent
                                color: isCurrent ? Theme.textMuted : "#FFFFFF"
                            }
                            MouseArea {
                                id: swMa
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !isCurrent && engineManager && !engineManager.isBusy
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    engineManager.installVersion(modelData.tag, engineManager.preferredQuantum)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Progress & Status Footer
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: engineManager ? engineManager.statusMessage : ""
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.accent
                }

                Rectangle {
                    visible: engineManager && engineManager.isBusy
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 24
                    radius: 5
                    color: Theme.dangerBg
                    border.color: Theme.dangerBorder
                    Text {
                        anchors.centerIn: parent
                        text: "取消操作"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        color: Theme.dangerText
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: engineManager.cancelDownload()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Theme.inputBg
                visible: engineManager && engineManager.isBusy

                Rectangle {
                    width: parent.width * (engineManager ? engineManager.downloadProgress : 0)
                    height: parent.height
                    radius: 3
                    color: Theme.accent
                }
            }
        }
    }
}
