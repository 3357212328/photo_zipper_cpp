import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string text: ""
    property bool checked: true
    property bool switchStyle: false
    signal toggled(bool isChecked)

    implicitWidth: mainRow.implicitWidth
    implicitHeight: 30

    scale: mouseArea.pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

    RowLayout {
        id: mainRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // Mode A: Modern Animated Toggle Switch
        Rectangle {
            visible: root.switchStyle
            Layout.preferredWidth: 38
            Layout.preferredHeight: 20
            radius: 10
            color: root.checked
                   ? (mouseArea.containsMouse ? Theme.accentHover : Theme.accent)
                   : (mouseArea.containsMouse ? Theme.cardHoverBorder : Theme.inputBorder)
            border.width: 1
            border.color: root.checked ? Theme.accent : Theme.cardBorder

            Behavior on color { ColorAnimation { duration: 160 } }

            Rectangle {
                y: 2
                x: root.checked ? 20 : 2
                width: 16
                height: 16
                radius: 8
                color: "#FFFFFF"

                Behavior on x {
                    NumberAnimation { duration: 160; easing.type: Easing.OutBack }
                }
            }
        }

        // Mode B: Pure GPU Animated Checkbox (Zero Canvas Overhead)
        Rectangle {
            visible: !root.switchStyle
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            radius: 5
            color: root.checked
                   ? (mouseArea.containsMouse ? Theme.accentHover : Theme.accent)
                   : (mouseArea.containsMouse ? Theme.inputHoverBg : Theme.inputBg)
            border.width: root.checked ? 0 : 1.5
            border.color: mouseArea.containsMouse ? Theme.accent : Theme.inputBorder

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            Text {
                anchors.centerIn: parent
                text: "✓"
                font.family: "Segoe UI"
                font.pixelSize: 12
                font.bold: true
                color: "#FFFFFF"
                scale: root.checked ? 1.0 : 0.2
                opacity: root.checked ? 1.0 : 0.0
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }

        Text {
            text: root.text
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 13
            color: mouseArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: 140 } }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}
