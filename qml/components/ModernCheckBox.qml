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

    scale: mouseArea.pressed ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

    RowLayout {
        id: mainRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // Mode A: Modern Animated Toggle Switch (when switchStyle == true)
        Rectangle {
            visible: root.switchStyle
            Layout.preferredWidth: 38
            Layout.preferredHeight: 20
            radius: 10
            color: root.checked
                   ? (mouseArea.containsMouse ? "#60A5FA" : "#3B82F6")
                   : (mouseArea.containsMouse ? "#475569" : "#334155")
            border.width: 1
            border.color: root.checked ? "#93C5FD" : "#475569"

            Behavior on color { ColorAnimation { duration: 180 } }

            Rectangle {
                y: 2
                x: root.checked ? 20 : 2
                width: 16
                height: 16
                radius: 8
                color: "#FFFFFF"

                Behavior on x {
                    NumberAnimation { duration: 180; easing.type: Easing.OutBack }
                }
            }
        }

        // Mode B: Animated Modern Checkbox (default)
        Rectangle {
            visible: !root.switchStyle
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            radius: 5
            color: root.checked
                   ? (mouseArea.containsMouse ? "#60A5FA" : "#3B82F6")
                   : (mouseArea.containsMouse ? "#2B313D" : "#1E222A")
            border.width: root.checked ? 0 : 1.5
            border.color: mouseArea.containsMouse ? "#60A5FA" : "#525B6C"

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Canvas {
                id: checkCanvas
                anchors.fill: parent
                scale: root.checked ? 1.0 : 0.2
                opacity: root.checked ? 1.0 : 0.0
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                Behavior on opacity { NumberAnimation { duration: 130 } }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = "#FFFFFF";
                    ctx.lineWidth = 2.0;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.beginPath();
                    ctx.moveTo(4.0, 9.2);
                    ctx.lineTo(7.5, 12.8);
                    ctx.lineTo(14.0, 5.4);
                    ctx.stroke();
                }
            }
        }

        Text {
            text: root.text
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 13
            color: mouseArea.containsMouse ? "#F8FAFC" : "#CBD5E1"
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
