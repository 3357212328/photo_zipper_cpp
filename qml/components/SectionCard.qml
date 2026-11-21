import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string title: ""
    property string subtitle: ""
    property alias headerRight: headerRightSlot.data
    default property alias bodyContent: contentCol.data

    color: "#262A32"
    radius: 12
    border.width: 1
    border.color: hoverHandler.hovered ? "#424A59" : "#343944"
    implicitHeight: mainLayout.implicitHeight + 28

    Behavior on border.color { ColorAnimation { duration: 180 } }

    HoverHandler {
        id: hoverHandler
    }

    ColumnLayout {
        id: mainLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            visible: root.title.length > 0
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.title
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 14
                    font.bold: true
                    color: "#F1F5F9"
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: root.subtitle.length > 0
                    text: root.subtitle
                    font.family: "Microsoft YaHei UI"
                    font.pixelSize: 11
                    color: "#8A94A6"
                }
            }

            RowLayout {
                id: headerRightSlot
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
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
