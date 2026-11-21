import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: root
    color: "#1B1D21"
    radius: 10
    border.width: 1
    border.color: "#33373F"
    clip: true

    property url originalUrl: ""
    property url compressedUrl: ""
    property string fileName: ""
    property string originalInfo: ""
    property string compressedInfo: ""
    property string savedPercent: ""
    property real splitRatio: 0.5

    // Empty state
    ColumnLayout {
        anchors.centerIn: parent
        visible: root.originalUrl.toString().length === 0
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "🖼️ 前后画质对比预览"
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 16
            font.bold: true
            color: "#A0A7B2"
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "在上方列表点击任意图片，即可在此实时滑动对比「原图 vs 压缩后」细节"
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 12
            color: "#6B7280"
        }
    }

    Item {
        id: previewContainer
        anchors.fill: parent
        anchors.margins: 8
        visible: root.originalUrl.toString().length > 0

        // Checkered background for transparent PNG/WebP
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                var sz = 14;
                for (var y = 0; y < height; y += sz) {
                    for (var x = 0; x < width; x += sz) {
                        ctx.fillStyle = ((Math.floor(x / sz) + Math.floor(y / sz)) % 2 === 0) ? "#22252A" : "#1D2024";
                        ctx.fillRect(x, y, sz, sz);
                    }
                }
            }
        }

        // Right/Full layer: Compressed image (or Original if not yet compressed)
        Image {
            id: rightImage
            anchors.fill: parent
            source: root.compressedUrl.toString().length > 0 ? root.compressedUrl : root.originalUrl
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            // Cap texture resolution to keep GPU/RAM memory strictly low
            sourceSize.width: 1400
            sourceSize.height: 1000
        }

        // Left clipped layer: Original image
        Item {
            id: leftClip
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * root.splitRatio
            clip: true

            Image {
                width: previewContainer.width
                height: previewContainer.height
                source: root.originalUrl
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                sourceSize.width: 1400
                sourceSize.height: 1000
            }
        }

        // Split divider line
        Rectangle {
            id: splitLine
            x: parent.width * root.splitRatio - width / 2
            y: 0
            width: 2
            height: parent.height
            color: "#94C1FA"

            Rectangle {
                anchors.centerIn: parent
                width: 32
                height: 32
                radius: 16
                color: "#94C1FA"
                border.width: 2
                border.color: "#14171C"

                Text {
                    anchors.centerIn: parent
                    text: "◀▶"
                    font.pixelSize: 10
                    font.bold: true
                    color: "#11151C"
                }
            }
        }

        // Top badges
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 10
            radius: 6
            color: "#CC16181D"
            border.color: "#445063"
            height: 28
            width: origLabel.implicitWidth + 20

            Text {
                id: origLabel
                anchors.centerIn: parent
                text: "原图  " + root.originalInfo
                font.family: "Microsoft YaHei UI"
                font.pixelSize: 12
                color: "#E2E8F0"
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            radius: 6
            color: "#CC16181D"
            border.color: root.compressedUrl.toString().length > 0 ? "#4D7C5D" : "#445063"
            height: 28
            width: compLabel.implicitWidth + 20

            Text {
                id: compLabel
                anchors.centerIn: parent
                text: root.compressedUrl.toString().length > 0
                      ? ("压缩后  " + root.compressedInfo + " (" + root.savedPercent + ")")
                      : "尚未压缩 (展示原图)"
                font.family: "Microsoft YaHei UI"
                font.pixelSize: 12
                color: root.compressedUrl.toString().length > 0 ? "#86EFAC" : "#94A3B8"
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SplitHCursor
            onPressed: function(mouse) {
                root.splitRatio = Math.max(0.05, Math.min(0.95, mouse.x / width))
            }
            onPositionChanged: function(mouse) {
                if (pressed) {
                    root.splitRatio = Math.max(0.05, Math.min(0.95, mouse.x / width))
                }
            }
        }
    }
}
