import QtQuick

Rectangle {
    id: root
    property var items: []
    property int currentIndex: 0
    property int fontPixelSize: 11
    property bool accentStyle: true
    signal activated(int index)

    implicitWidth: 220
    implicitHeight: 32
    radius: 8
    color: Theme.inputBg
    border.width: 1
    border.color: Theme.cardBorder
    clip: true

    readonly property int itemCount: Math.max(1, items.length)
    readonly property real pad: 3
    readonly property real segWidth: (width - pad * 2) / itemCount
    property bool ready: false
    property int pressedIndex: -1

    Component.onCompleted: Qt.callLater(function() { ready = true })

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    // Single GPU sliding active capsule
    Rectangle {
        id: activePill
        x: root.pad + Math.max(0, root.currentIndex) * root.segWidth
        y: root.pad
        width: root.segWidth
        height: root.height - root.pad * 2
        radius: Math.max(4, root.radius - 2)
        color: root.accentStyle ? Theme.accentSoftBg : Theme.surfaceElevated
        border.width: 1
        border.color: root.accentStyle ? Theme.accentSoftBorder : Theme.cardHoverBorder
        scale: root.pressedIndex === root.currentIndex ? 0.96 : 1.0

        Behavior on x {
            enabled: root.ready
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
        }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    Row {
        id: segRow
        x: root.pad
        y: root.pad
        width: root.width - root.pad * 2
        height: root.height - root.pad * 2
        z: 1

        Repeater {
            model: root.items
            delegate: Item {
                width: root.segWidth
                height: segRow.height
                readonly property bool isActive: index === root.currentIndex

                // Soft hover pill
                Rectangle {
                    anchors.fill: parent
                    radius: Math.max(4, root.radius - 2)
                    color: Theme.btnSecHoverBg
                    opacity: (!isActive && segMa.containsMouse) ? 0.55 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 6
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: modelData
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: root.fontPixelSize
                    font.bold: isActive
                    color: isActive
                           ? (root.accentStyle ? Theme.accentSoftText : Theme.textPrimary)
                           : (segMa.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                    scale: segMa.pressed ? 0.94 : 1.0

                    Behavior on scale {
                        NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                    }
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                MouseArea {
                    id: segMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPressed: root.pressedIndex = index
                    onReleased: root.pressedIndex = -1
                    onCanceled: root.pressedIndex = -1
                    onClicked: root.activated(index)
                }
            }
        }
    }
}
