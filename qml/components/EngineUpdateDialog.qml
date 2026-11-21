import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Dialogs

Popup {
    id: root
    width: 720
    height: 580
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
        color: "#AA0E1013"
    }

    background: Rectangle {
        color: "#22252A"
        radius: 12
        border.width: 1
        border.color: "#434955"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // Title bar
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 3
                Text {
                    text: "内嵌 ImageMagick 引擎版本管理 (在线 & 本地双模式)"
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#F1F5F9"
                }
                Text {
                    text: "支持从 GitHub 官方源在线更新，或直接导入本地压缩包/文件夹 · 严格单版本原子替换"
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 12
                    color: "#94A3B8"
                }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 30
                height: 30
                radius: 6
                color: closeMa.containsMouse ? "#383E4A" : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 15
                    color: "#CBD5E1"
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
            height: 80
            radius: 8
            color: "#2B2E33"
            border.color: "#3A3F4B"

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
                            width: 10
                            height: 10
                            radius: 5
                            color: (engineManager && engineManager.isInstalled) ? "#4ADE80" : "#F87171"
                        }
                        Text {
                            text: "当前内嵌版本: " + (engineManager ? engineManager.currentVersion : "-")
                                  + " (" + (engineManager ? engineManager.currentQuantum : "-") + ")"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#E2E8F0"
                        }
                        Rectangle {
                            radius: 4
                            color: "#1E293B"
                            height: 20
                            width: diskTxt.implicitWidth + 12
                            Text {
                                id: diskTxt
                                anchors.centerIn: parent
                                text: "引擎体积: " + (memoryMonitor ? memoryMonitor.engineSizeText : "-")
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                color: "#94C1FA"
                            }
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: "支持模块: " + (engineManager ? engineManager.currentFeatures : "-")
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        color: "#8A919E"
                    }
                }

                // Online Update to latest button
                Rectangle {
                    width: 142
                    height: 36
                    radius: 6
                    color: (engineManager && engineManager.isBusy) ? "#3B4252" : (latestMa.containsMouse ? "#A7CEFC" : "#94C1FA")
                    Text {
                        anchors.centerIn: parent
                        text: (engineManager && !engineManager.isInstalled) ? "☁ 在线安装最新版" : "☁ 在线更新最新版"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#11161F"
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
            height: 54
            radius: 8
            color: "#252932"
            border.color: "#3B4354"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "📦 本地离线更新 / 切换特定版本"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#E2E8F0"
                    }
                    Text {
                        text: "选择本地已下载的官方便携包 (.7z/.zip) 或解压目录，自动瘦身并清除旧版"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        color: "#8A919E"
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 136
                    height: 32
                    radius: 6
                    color: locPkgMa.containsMouse ? "#3D4657" : "#313744"
                    border.color: "#52607A"
                    Text {
                        anchors.centerIn: parent
                        text: "📄 选择本地压缩包"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 12
                        color: "#E2E8F0"
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
                    width: 136
                    height: 32
                    radius: 6
                    color: locDirMa.containsMouse ? "#3D4657" : "#313744"
                    border.color: "#52607A"
                    Text {
                        anchors.centerIn: parent
                        text: "📁 选择本地文件夹"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 12
                        color: "#E2E8F0"
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
            spacing: 10

            Text {
                text: "在线下载位深规格:"
                font.family: "Microsoft YaHei UI"
                font.pixelSize: 12
                color: "#CBD5E1"
            }

            Repeater {
                model: [
                    { code: "Q8", label: "Q8 (推荐：最省内存 / 速度最快)" },
                    { code: "Q16", label: "Q16 (16位高色深)" },
                    { code: "Q16-HDRI", label: "Q16-HDRI (浮点HDR)" }
                ]
                delegate: Rectangle {
                    readonly property bool selected: engineManager && engineManager.preferredQuantum === modelData.code
                    height: 28
                    width: qTxt.implicitWidth + 18
                    radius: 6
                    color: selected ? "#2E456B" : "#2B2E33"
                    border.color: selected ? "#94C1FA" : "#3E434D"

                    Text {
                        id: qTxt
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        color: selected ? "#E6F0FF" : "#A0A7B2"
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
                width: 96
                height: 28
                radius: 6
                color: refMa.containsMouse ? "#363B44" : "#2B2E33"
                border.color: "#434955"
                Text {
                    anchors.centerIn: parent
                    text: (engineManager && engineManager.isFetchingReleases) ? "刷新中..." : "⟳ 刷新在线源"
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 11
                    color: "#CBD5E1"
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
            color: "#1B1D21"
            radius: 8
            border.color: "#33373F"
            clip: true

            ListView {
                id: releaseListView
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6
                model: engineManager ? engineManager.availableReleases : []
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    width: releaseListView.width - 12
                    height: 52
                    radius: 6
                    readonly property bool isCurrent: engineManager
                                                      && engineManager.currentVersion === modelData.tag
                                                      && engineManager.currentQuantum === engineManager.preferredQuantum
                    color: isCurrent ? "#22324C" : "#26292E"
                    border.color: isCurrent ? "#5B89C8" : "#333740"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        ColumnLayout {
                            spacing: 2
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "ImageMagick " + modelData.tag
                                    font.family: "Segoe UI"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#F1F5F9"
                                }
                                Rectangle {
                                    visible: index === 0
                                    radius: 4
                                    color: "#1E3A8A"
                                    height: 18
                                    width: 44
                                    Text {
                                        anchors.centerIn: parent
                                        text: "最新"
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 10
                                        color: "#93C5FD"
                                    }
                                }
                                Rectangle {
                                    visible: isCurrent
                                    radius: 4
                                    color: "#14532D"
                                    height: 18
                                    width: 58
                                    Text {
                                        anchors.centerIn: parent
                                        text: "当前使用"
                                        font.family: "Microsoft YaHei UI"
                                        font.pixelSize: 10
                                        color: "#86EFAC"
                                    }
                                }
                            }
                            Text {
                                readonly property string qCode: engineManager ? engineManager.preferredQuantum : "Q8"
                                readonly property string pkgSize: (modelData.sizes && modelData.sizes[qCode]) ? modelData.sizes[qCode] : "~11.6 MB"
                                text: "发布日期: " + modelData.date + "  ·  下载包(" + qCode + "): " + pkgSize + "  ·  内嵌精简后约 32.6 MB"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                color: "#8A919E"
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 110
                            height: 30
                            radius: 6
                            color: isCurrent ? "#2D333D" : (swMa.containsMouse ? "#466FA6" : "#375582")
                            border.color: isCurrent ? "#434A57" : "#6491CE"

                            Text {
                                anchors.centerIn: parent
                                text: isCurrent ? "当前已安装" : "在线切换此版"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 12
                                color: isCurrent ? "#7A8290" : "#FFFFFF"
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
                    color: "#94C1FA"
                }

                Rectangle {
                    visible: engineManager && engineManager.isBusy
                    width: 68
                    height: 24
                    radius: 4
                    color: "#7F1D1D"
                    Text {
                        anchors.centerIn: parent
                        text: "取消操作"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        color: "#FCA5A5"
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
                height: 6
                radius: 3
                color: "#1B1D21"
                visible: engineManager && engineManager.isBusy

                Rectangle {
                    width: parent.width * (engineManager ? engineManager.downloadProgress : 0)
                    height: parent.height
                    radius: 3
                    color: "#94C1FA"
                }
            }
        }
    }
}
