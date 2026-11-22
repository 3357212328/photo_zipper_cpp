import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: Theme.windowBg
    clip: true

    Behavior on color { ColorAnimation { duration: 180 } }

    property url originalUrl: ""
    property url compressedUrl: ""
    property string fileName: ""
    property string originalInfo: ""
    property string compressedInfo: ""
    property string savedPercent: ""
    property int currentIndex: -1
    property int totalCount: 0

    property real splitRatio: 0.5
    property real zoomScale: 1.0
    property real panX: 0.0
    property real panY: 0.0

    signal backRequested()
    signal prevRequested()
    signal nextRequested()

    function resetView() {
        zoomScale = 1.0
        panX = 0.0
        panY = 0.0
    }

    onOriginalUrlChanged: resetView()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ==================== TOP COMPARISON TOOLBAR (44px) ====================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: Theme.cardAltBg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                // Back to Queue Button
                Rectangle {
                    Layout.preferredHeight: 28
                    Layout.preferredWidth: backRow.implicitWidth + 18
                    radius: 7
                    color: backMa.containsMouse ? Theme.btnSecHoverBg : Theme.btnSecBg
                    border.color: backMa.containsMouse ? Theme.accent : Theme.btnSecBorder
                    scale: backMa.pressed ? 0.96 : 1.0
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 90 } }

                    RowLayout {
                        id: backRow
                        anchors.centerIn: parent
                        spacing: 6
                        VectorIcon { name: "arrow-left"; size: 13; color: Theme.textPrimary }
                        Text {
                            text: "返回队列"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }
                    MouseArea {
                        id: backMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.backRequested()
                    }
                }

                // Prev / Next Item Navigation
                RowLayout {
                    visible: root.totalCount > 0
                    spacing: 4

                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 6
                        color: prevMa.containsMouse && root.totalCount > 1 ? Theme.btnSecHoverBg : Theme.btnSecBg
                        border.color: Theme.btnSecBorder
                        opacity: root.totalCount > 1 ? 1.0 : 0.45
                        VectorIcon { anchors.centerIn: parent; name: "chevron-left"; size: 13; color: Theme.textPrimary }
                        MouseArea {
                            id: prevMa
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.totalCount > 1
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.prevRequested()
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: idxTxt.implicitWidth + 14
                        radius: 6
                        color: Theme.surfaceElevated
                        border.color: Theme.cardBorder
                        Text {
                            id: idxTxt
                            anchors.centerIn: parent
                            text: (root.currentIndex + 1) + " / " + root.totalCount
                            font.family: "Segoe UI"
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 6
                        color: nextMa.containsMouse && root.totalCount > 1 ? Theme.btnSecHoverBg : Theme.btnSecBg
                        border.color: Theme.btnSecBorder
                        opacity: root.totalCount > 1 ? 1.0 : 0.45
                        VectorIcon { anchors.centerIn: parent; name: "chevron-right"; size: 13; color: Theme.textPrimary }
                        MouseArea {
                            id: nextMa
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.totalCount > 1
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.nextRequested()
                        }
                    }
                }

                // File Name
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                    text: root.fileName.length > 0 ? root.fileName : "未选择图片"
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.textPrimary
                }

                // Original vs Compressed Badges
                Rectangle {
                    visible: root.originalUrl.toString().length > 0
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: origHdrTxt.implicitWidth + 14
                    radius: 6
                    color: Theme.btnSecBg
                    border.color: Theme.btnSecBorder
                    Text {
                        id: origHdrTxt
                        anchors.centerIn: parent
                        text: "原图 " + root.originalInfo
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        color: Theme.textSecondary
                    }
                }

                Rectangle {
                    visible: root.originalUrl.toString().length > 0
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: compHdrTxt.implicitWidth + 14
                    radius: 6
                    color: root.compressedUrl.toString().length > 0 ? Theme.successBg : Theme.btnSecBg
                    border.color: root.compressedUrl.toString().length > 0 ? Theme.successBorder : Theme.btnSecBorder
                    Text {
                        id: compHdrTxt
                        anchors.centerIn: parent
                        text: root.compressedUrl.toString().length > 0
                              ? ("压缩后 " + root.compressedInfo + " (" + root.savedPercent + ")")
                              : "尚未压缩"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        font.bold: root.compressedUrl.toString().length > 0
                        color: root.compressedUrl.toString().length > 0 ? Theme.successText : Theme.textSecondary
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

        // ==================== FULL-CANVAS ZOOM & PAN STAGE ====================
        Item {
            id: stage
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                visible: root.originalUrl.toString().length === 0
                spacing: 10

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 56
                    height: 56
                    radius: 28
                    color: Theme.surfaceElevated
                    border.color: Theme.cardBorder

                    VectorIcon {
                        anchors.centerIn: parent
                        name: "compare"
                        size: 26
                        color: Theme.textSecondary
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "前后画质对比预览"
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.textPrimary
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "请先添加图片并在队列中点击任意条目，即可在此全屏缩放对比细节"
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }
            }

            Item {
                id: previewContainer
                anchors.fill: parent
                visible: root.originalUrl.toString().length > 0
                clip: true

                // Right/Full layer: Compressed image (or Original if not yet compressed)
                Image {
                    id: rightImage
                    width: previewContainer.width
                    height: previewContainer.height
                    x: root.panX
                    y: root.panY
                    scale: root.zoomScale
                    transformOrigin: Item.Center
                    source: root.compressedUrl.toString().length > 0 ? root.compressedUrl : root.originalUrl
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                    smooth: root.zoomScale < 2.5
                    sourceSize.width: 2560
                    sourceSize.height: 2560
                }

                // Left clipped layer: Original image
                Item {
                    id: leftClip
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(0, parent.width * root.splitRatio)
                    clip: true

                    Image {
                        width: previewContainer.width
                        height: previewContainer.height
                        x: root.panX
                        y: root.panY
                        scale: root.zoomScale
                        transformOrigin: Item.Center
                        source: root.originalUrl
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                        smooth: root.zoomScale < 2.5
                        sourceSize.width: 2560
                        sourceSize.height: 2560
                    }
                }

                // Corner overlay labels (Left = 原图, Right = 压缩后)
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 14
                    radius: 6
                    color: Theme.isWarmDay ? "#EAFFFDF9" : "#D912151D"
                    border.color: Theme.cardBorder
                    height: 26
                    width: lblOrig.implicitWidth + 16
                    z: 15
                    Text {
                        id: lblOrig
                        anchors.centerIn: parent
                        text: "原图 (Original)"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    radius: 6
                    color: Theme.isWarmDay ? "#EAFFFDF9" : "#D912151D"
                    border.color: root.compressedUrl.toString().length > 0 ? Theme.successBorder : Theme.cardBorder
                    height: 26
                    width: lblComp.implicitWidth + 16
                    z: 15
                    Text {
                        id: lblComp
                        anchors.centerIn: parent
                        text: root.compressedUrl.toString().length > 0 ? "压缩后 (Compressed)" : "未压缩 (原图)"
                        font.family: "Microsoft YaHei UI"
                        font.pixelSize: 11
                        font.bold: true
                        color: root.compressedUrl.toString().length > 0 ? Theme.successText : Theme.textSecondary
                    }
                }

                // Background MouseArea: pan when zoomed > 1.01, move split line when 1.0x
                MouseArea {
                    id: canvasMa
                    anchors.fill: parent
                    z: 10
                    cursorShape: root.zoomScale > 1.01 ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.SplitHCursor
                    property real lastX: 0
                    property real lastY: 0

                    onPressed: function(mouse) {
                        lastX = mouse.x
                        lastY = mouse.y
                        if (root.zoomScale <= 1.01) {
                            root.splitRatio = Math.max(0.03, Math.min(0.97, mouse.x / width))
                        }
                    }
                    onPositionChanged: function(mouse) {
                        if (!pressed) return
                        if (root.zoomScale > 1.01) {
                            root.panX += (mouse.x - lastX)
                            root.panY += (mouse.y - lastY)
                            lastX = mouse.x
                            lastY = mouse.y
                        } else {
                            root.splitRatio = Math.max(0.03, Math.min(0.97, mouse.x / width))
                        }
                    }
                }

                WheelHandler {
                    onWheel: function(event) {
                        var factor = event.angleDelta.y > 0 ? 1.18 : (1.0 / 1.18)
                        var nextZoom = Math.max(1.0, Math.min(6.0, root.zoomScale * factor))
                        root.zoomScale = nextZoom
                        if (nextZoom <= 1.01) {
                            root.panX = 0
                            root.panY = 0
                        }
                    }
                }

                // Dedicated Draggable Split Divider Line & Knob (Always works even when zoomed in!)
                Item {
                    id: dividerHandle
                    x: previewContainer.width * root.splitRatio - width / 2
                    y: 0
                    width: 34
                    height: previewContainer.height
                    z: 20

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 2
                        height: parent.height
                        color: Theme.accent
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 34
                        height: 34
                        radius: 17
                        color: Theme.accent
                        border.width: 2
                        border.color: "#FFFFFF"
                        scale: divMa.containsMouse || divMa.pressed ? 1.1 : 1.0
                        Behavior on scale { NumberAnimation { duration: 110 } }

                        VectorIcon {
                            anchors.centerIn: parent
                            name: "compare"
                            size: 16
                            strokeWidth: 2.0
                            color: "#FFFFFF"
                        }
                    }

                    MouseArea {
                        id: divMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SplitHCursor
                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                var globalX = dividerHandle.x + mouse.x
                                root.splitRatio = Math.max(0.03, Math.min(0.97, globalX / previewContainer.width))
                            }
                        }
                    }
                }

                // Floating Bottom Zoom Toolbar
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 16
                    height: 36
                    width: zoomBarRow.implicitWidth + 20
                    radius: 18
                    color: Theme.isWarmDay ? "#F2FFFDF9" : "#E6181D28"
                    border.color: Theme.cardHoverBorder
                    z: 30

                    RowLayout {
                        id: zoomBarRow
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            Layout.preferredHeight: 24
                            Layout.preferredWidth: fitRow.implicitWidth + 12
                            radius: 12
                            color: fitMa.containsMouse ? Theme.btnSecHoverBg : Theme.btnSecBg
                            RowLayout {
                                id: fitRow
                                anchors.centerIn: parent
                                spacing: 4
                                VectorIcon { name: "maximize"; size: 11; color: Theme.textPrimary }
                                Text {
                                    text: "适应"
                                    font.family: "Microsoft YaHei UI"
                                    font.pixelSize: 11
                                    color: Theme.textPrimary
                                }
                            }
                            MouseArea {
                                id: fitMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.resetView()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            radius: 12
                            color: zOutMa.containsMouse ? Theme.btnSecHoverBg : "transparent"
                            VectorIcon { anchors.centerIn: parent; name: "zoom-out"; size: 13; color: Theme.textPrimary }
                            MouseArea {
                                id: zOutMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.zoomScale = Math.max(1.0, root.zoomScale / 1.25)
                                    if (root.zoomScale <= 1.01) { root.panX = 0; root.panY = 0 }
                                }
                            }
                        }

                        Text {
                            Layout.minimumWidth: 42
                            horizontalAlignment: Text.AlignHCenter
                            text: Math.round(root.zoomScale * 100) + "%"
                            font.family: "Segoe UI"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Rectangle {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            radius: 12
                            color: zInMa.containsMouse ? Theme.btnSecHoverBg : "transparent"
                            VectorIcon { anchors.centerIn: parent; name: "zoom-in"; size: 13; color: Theme.textPrimary }
                            MouseArea {
                                id: zInMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.zoomScale = Math.min(6.0, root.zoomScale * 1.25)
                            }
                        }

                        Rectangle { width: 1; height: 14; color: Theme.cardBorder }

                        Repeater {
                            model: [
                                { label: "100%", val: 1.0 },
                                { label: "200%", val: 2.0 },
                                { label: "400%", val: 4.0 }
                            ]
                            delegate: Rectangle {
                                readonly property bool act: Math.abs(root.zoomScale - modelData.val) < 0.08
                                Layout.preferredHeight: 22
                                Layout.preferredWidth: zLbl.implicitWidth + 12
                                radius: 11
                                color: act ? Theme.accentSoftBg : (zPresetMa.containsMouse ? Theme.btnSecHoverBg : "transparent")
                                border.color: act ? Theme.accentSoftBorder : "transparent"
                                Text {
                                    id: zLbl
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: "Segoe UI"
                                    font.pixelSize: 10
                                    font.bold: act
                                    color: act ? Theme.accentSoftText : Theme.textSecondary
                                }
                                MouseArea {
                                    id: zPresetMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.zoomScale = modelData.val
                                        if (modelData.val <= 1.01) { root.panX = 0; root.panY = 0 }
                                    }
                                }
                            }
                        }

                        Rectangle { width: 1; height: 14; color: Theme.cardBorder }

                        Text {
                            text: "滚轮缩放 · 拖动中线对比"
                            font.family: "Microsoft YaHei UI"
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }
                    }
                }
            }
        }
    }
}
