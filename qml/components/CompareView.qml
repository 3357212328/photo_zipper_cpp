import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: Theme.cardAltBg
    clip: true

    Behavior on color { ColorAnimation { duration: 180 } }

    property url originalUrl: ""
    property url compressedUrl: ""
    property string fileName: ""
    property string originalInfo: ""
    property string compressedInfo: ""
    property string savedPercent: ""
    property real splitRatio: 0.5

    // Top 1px hairline border
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.headerBorder
    }

    // Empty state
    ColumnLayout {
        anchors.centerIn: parent
        visible: root.originalUrl.toString().length === 0
        spacing: 8

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 44
            height: 44
            radius: 22
            color: Theme.surfaceElevated
            border.color: Theme.cardBorder

            VectorIcon {
                anchors.centerIn: parent
                name: "compare"
                size: 22
                color: Theme.textSecondary
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "前后画质对比预览"
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 13
            font.bold: true
            color: Theme.textPrimary
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "在上方队列点击任意图片，即可在此滑动对比原图与压缩后画质细节"
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 11
            color: Theme.textSecondary
        }
    }

    Item {
        id: previewContainer
        anchors.fill: parent
        anchors.margins: 12
        visible: root.originalUrl.toString().length > 0

        // Recessed preview stage
        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.inputBg
            border.color: Theme.cardBorder
        }

        // Right/Full layer: Compressed image (or Original if not yet compressed)
        Image {
            id: rightImage
            anchors.fill: parent
            anchors.margins: 1
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
            anchors.margins: 1
            width: Math.max(0, (parent.width - 2) * root.splitRatio)
            clip: true

            Image {
                width: previewContainer.width - 2
                height: previewContainer.height - 2
                source: root.originalUrl
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                sourceSize.width: 1280
                sourceSize.height: 800
            }
        }

        // Split divider line & circular knob
        Rectangle {
            id: splitLine
            x: parent.width * root.splitRatio - width / 2
            y: 1
            width: 2
            height: parent.height - 2
            color: Theme.accent

            Rectangle {
                anchors.centerIn: parent
                width: 32
                height: 32
                radius: 16
                color: Theme.accent
                border.width: 2
                border.color: "#FFFFFF"
                scale: cmpMa.containsMouse || cmpMa.pressed ? 1.1 : 1.0
                Behavior on scale { NumberAnimation { duration: 120 } }

                VectorIcon {
                    anchors.centerIn: parent
                    name: "compare"
                    size: 15
                    strokeWidth: 2.0
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
            color: Theme.isWarmDay ? "#ECFFFDF9" : "#D911141B"
            border.color: Theme.cardBorder
            height: 24
            width: origLabel.implicitWidth + 16

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
            color: Theme.isWarmDay ? "#ECFFFDF9" : "#D911141B"
            border.color: root.compressedUrl.toString().length > 0 ? Theme.successBorder : Theme.cardBorder
            height: 24
            width: compLabel.implicitWidth + 16

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
            id: cmpMa
            anchors.fill: parent
            hoverEnabled: true
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
