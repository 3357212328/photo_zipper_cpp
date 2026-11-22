import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: root
    color: Theme.cardAltBg
    radius: 12
    border.width: 1
    border.color: Theme.cardBorder
    clip: true

    Behavior on color { ColorAnimation { duration: 180 } }
    Behavior on border.color { ColorAnimation { duration: 180 } }

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
        spacing: 8

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "🖼️ 前后画质对比预览"
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 15
            font.bold: true
            color: Theme.textPrimary
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "在上方列表点击任意图片，即可在此实时滑动对比「原图 vs 压缩后」细节"
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 12
            color: Theme.textSecondary
        }
    }

    Item {
        id: previewContainer
        anchors.fill: parent
        anchors.margins: 8
        visible: root.originalUrl.toString().length > 0

        // Pure GPU Backdrop (Zero Canvas CPU loop lag during window resize/move)
        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.inputBg
        }

        // Right/Full layer: Compressed image (or Original if not yet compressed)
        Image {
            id: rightImage
            anchors.fill: parent
            source: root.compressedUrl.toString().length > 0 ? root.compressedUrl : root.originalUrl
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            sourceSize.width: 1280
            sourceSize.height: 800
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
                sourceSize.width: 1280
                sourceSize.height: 800
            }
        }

        // Split divider line
        Rectangle {
            id: splitLine
            x: parent.width * root.splitRatio - width / 2
            y: 0
            width: 2
            height: parent.height
            color: Theme.accent

            Rectangle {
                anchors.centerIn: parent
                width: 30
                height: 30
                radius: 15
                color: Theme.accent
                border.width: 2
                border.color: "#FFFFFF"

                Text {
                    anchors.centerIn: parent
                    text: "◀▶"
                    font.pixelSize: 9
                    font.bold: true
                    color: "#FFFFFF"
                }
            }
        }

        // Top badges
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 10
            radius: 6
            color: Theme.isWarmDay ? "#E6FFFDF9" : "#CC16181D"
            border.color: Theme.cardBorder
            height: 26
            width: origLabel.implicitWidth + 18

            Text {
                id: origLabel
                anchors.centerIn: parent
                text: "原图  " + root.originalInfo
                font.family: "Microsoft YaHei UI"
                font.pixelSize: 11
                font.bold: true
                color: Theme.textPrimary
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            radius: 6
            color: Theme.isWarmDay ? "#E6FFFDF9" : "#CC16181D"
            border.color: root.compressedUrl.toString().length > 0 ? Theme.successBorder : Theme.cardBorder
            height: 26
            width: compLabel.implicitWidth + 18

            Text {
                id: compLabel
                anchors.centerIn: parent
                text: root.compressedUrl.toString().length > 0
                      ? ("压缩后  " + root.compressedInfo + " (" + root.savedPercent + ")")
                      : "尚未压缩 (展示原图)"
                font.family: "Microsoft YaHei UI"
                font.pixelSize: 11
                font.bold: true
                color: root.compressedUrl.toString().length > 0 ? Theme.successText : Theme.textSecondary
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
