import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string text: ""
    property bool checked: true
    property bool switchStyle: false
    signal toggled(bool isChecked)

    implicitWidth: mainRow.implicitWidth
    implicitHeight: 26

    scale: mouseArea.pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

    RowLayout {
        id: mainRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // Mode A: Sleek Studio Toggle Switch (34x18, knob 14x14)
        Rectangle {
            visible: root.switchStyle
            Layout.preferredWidth: 34
            Layout.preferredHeight: 18
            radius: 9
            color: root.checked
                   ? (mouseArea.containsMouse ? Theme.accentHover : Theme.accent)
                   : (mouseArea.containsMouse ? Theme.cardHoverBorder : Theme.inputBorder)

            Behavior on color { ColorAnimation { duration: 150 } }

            Rectangle {
                y: 2
                x: root.checked ? 18 : 2
                width: 14
                height: 14
                radius: 7
                color: "#FFFFFF"

                Behavior on x {
                    NumberAnimation { duration: 160; easing.type: Easing.OutBack }
                }
            }
        }

        // Mode B: Crisp Vector Checkbox
        Rectangle {
            visible: !root.switchStyle
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            radius: 4.5
            color: root.checked
                   ? (mouseArea.containsMouse ? Theme.accentHover : Theme.accent)
                   : (mouseArea.containsMouse ? Theme.inputHoverBg : Theme.inputBg)
            border.width: root.checked ? 0 : 1.3
            border.color: mouseArea.containsMouse ? Theme.accent : Theme.inputBorder

            Behavior on color { ColorAnimation { duration: 130 } }
            Behavior on border.color { ColorAnimation { duration: 130 } }

            VectorIcon {
                anchors.centerIn: parent
                name: "check"
                size: 11
                strokeWidth: 2.3
                color: "#FFFFFF"
                scale: root.checked ? 1.0 : 0.2
                opacity: root.checked ? 1.0 : 0.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 110 } }
            }
        }

        Text {
            visible: root.text.length > 0
            text: root.text
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 12
            color: mouseArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
            elide: Text.ElideRight
            Behavior on color { ColorAnimation { duration: 130 } }
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
