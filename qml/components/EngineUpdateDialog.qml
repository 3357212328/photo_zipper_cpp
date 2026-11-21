import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Popup {
    id: root
    width: 680
    height: 520
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
        spacing: 14

        // Title bar
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 3
                Text {
                    text: "内嵌 ImageMagick 引擎版本管理"
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#F1F5F9"
                }
                Text {
                    text: "官方源: github.com/ImageMagick/ImageMagick · 单版本原子替换 · 自动剔除冗余命令立省 87% 体积"
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
            height: 82
            radius: 8
            color: "#2B2E33"
            border.color: "#3A3F4B"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 16

                ColumnLayout {
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
                            visible: engineManager && engineManager. memoryMonitor !== null
                            radius: 4
                            color: "#1E293B"
                            height: 20
                            width: diskTxt.implicitWidth + 12
                            Text {
                                id: diskTxt
                                anchors.centerIn: parent
                                text: "占用体积: " + (memoryMonitor ? memoryMonitor.engineSizeText : "-")
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

                Item { Layout.fillWidth: true }

                // Update to latest button
                Rectangle {
                    width: 145
                    height: 38
                    radius: 6
                    color: (engineManager && engineManager.isBusy) ? "#3B4252" : (latestMa.containsMouse ? "#A7CEFC" : "#94C1FA")
                    Text {
                        anchors.centerIn: parent
                        text: (engineManager && !engineManager.isInstalled) ? "一键安装最新版" : "更新至最新版"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 13
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

        // Quantum selection & Refresh bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "位深精度规格:"
                font.family: "Microsoft YaHei UI"
                font.pixelSize: 13
                color: "#CBD5E1"
            }

            Repeater {
                model: [
                    { code: "Q8", label: "Q8 (推荐：内存占用减半 / 速度最快)" },
                    { code: "Q16", label: "Q16 (16位高精度色深)" },
                    { code: "Q16-HDRI", label: "Q16-HDRI (浮点HDR专业级)" }
                ]
                delegate: Rectangle {
                    readonly property bool selected: engineManager && engineManager.preferredQuantum === modelData.code
                    height: 30
                    width: qTxt.implicitWidth + 20
                    radius: 6
                    color: selected ? "#2E456B" : "#2B2E33"
                    border.color: selected ? "#94C1FA" : "#3E434D"

                    Text {
                        id: qTxt
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 12
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
                height: 30
                radius: 6
                color: refMa.containsMouse ? "#363B44" : "#2B2E33"
                border.color: "#434955"
                Text {
                    anchors.centerIn: parent
                    text: (engineManager && engineManager.isFetchingReleases) ? "刷新中..." : "⟳ 刷新列表"
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 12
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
                    height: 54
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
                                text: "发布日期: " + modelData.date + "  ·  下载包大小(" + qCode + "): " + pkgSize + "  ·  内嵌精简后约 32 MB"
                                font.family: "Microsoft YaHei UI"
                                font.pixelSize: 11
                                color: "#8A919E"
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 106
                            height: 32
                            radius: 6
                            color: isCurrent ? "#2D333D" : (swMa.containsMouse ? "#466FA6" : "#375582")
                            border.color: isCurrent ? "#434A57" : "#6491CE"

                            Text {
                                anchors.centerIn: parent
                                text: isCurrent ? "已安装此版本" : "切换至此版本"
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
                        text: "取消下载"
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
