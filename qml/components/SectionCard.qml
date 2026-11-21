import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string title: ""
    property string subtitle: ""
    property alias headerRight: headerRightSlot.data
    default property alias bodyContent: contentCol.data

    color: "#2B2E33"
    radius: 10
    border.width: 1
    border.color: "#383C44"
    implicitHeight: mainLayout.implicitHeight + 32

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            visible: root.title.length > 0

            ColumnLayout {
                spacing: 2
                Text {
                    text: root.title
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 15
                    font.bold: true
                    color: "#DCE1E8"
                }
                Text {
                    visible: root.subtitle.length > 0
                    text: root.subtitle
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 11
                    color: "#8A919E"
                }
            }

            Item { Layout.fillWidth: true }

            Row {
                id: headerRightSlot
                spacing: 8
            }
        }

        ColumnLayout {
            id: contentCol
            Layout.fillWidth: true
            spacing: 12
        }
    }
}
