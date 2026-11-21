import QtQuick

Item {
    id: root
    property string text: ""
    property bool checked: true
    property string tooltipText: ""
    signal toggled(bool isChecked)

    implicitWidth: row.implicitWidth
    implicitHeight: 28

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 9

        Rectangle {
            id: box
            width: 18
            height: 18
            radius: 3
            anchors.verticalCenter: parent.verticalCenter
            color: root.checked ? "#94C1FA" : "transparent"
            border.width: root.checked ? 0 : 1.5
            border.color: mouseArea.containsMouse ? "#94C1FA" : "#68707E"

            Behavior on color { ColorAnimation { duration: 120 } }

            Canvas {
                id: checkCanvas
                anchors.fill: parent
                visible: root.checked
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = "#11161F";
                    ctx.lineWidth = 2.0;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.beginPath();
                    ctx.moveTo(3.8, 9.2);
                    ctx.lineTo(7.4, 13.0);
                    ctx.lineTo(14.3, 5.2);
                    ctx.stroke();
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 14
            color: "#D8DDE6"
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
