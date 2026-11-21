import QtQuick
import QtQuick.Controls.Basic

Item {
    id: root
    property string labelText: "宽度 (px)"
    property string text: "5120"
    property string placeholderText: ""
    property bool inputEnabled: true
    property var validator: null
    signal editingCompleted(string newValue)

    implicitWidth: 165
    implicitHeight: 54

    // Top offset for floating label
    readonly property int boxTop: 8

    // Main outer rounded border box
    Rectangle {
        id: borderBox
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root.boxTop
        anchors.bottom: parent.bottom
        radius: 6
        color: "transparent"
        border.width: textInput.activeFocus ? 1.5 : 1
        border.color: !root.inputEnabled
                      ? "#3E434C"
                      : (textInput.activeFocus ? "#111317" : "#4A505A")

        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    // Mask behind floating label so top border breaks cleanly around the label text
    Rectangle {
        x: 10
        y: 0
        width: labelItem.implicitWidth + 8
        height: 16
        color: "#2B2E33"
    }

    Text {
        id: labelItem
        x: 14
        y: 0
        text: root.labelText
        font.family: "Microsoft YaHei UI"
        font.pixelSize: 12
        color: !root.inputEnabled ? "#7C828D" : (textInput.activeFocus ? "#DCE1E8" : "#A0A7B2")
    }

    TextInput {
        id: textInput
        anchors.left: borderBox.left
        anchors.right: borderBox.right
        anchors.top: borderBox.top
        anchors.bottom: borderBox.bottom
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        enabled: root.inputEnabled
        text: root.text
        validator: root.validator
        selectByMouse: true
        clip: true
        font.family: "Segoe UI"
        font.pixelSize: 16
        color: root.inputEnabled ? "#E6EAF0" : "#777D88"
        selectionColor: "#4A72B8"

        onTextEdited: {
            root.text = textInput.text
            root.editingCompleted(textInput.text)
        }
        onEditingFinished: {
            root.text = textInput.text
            root.editingCompleted(textInput.text)
        }
    }

    Text {
        anchors.left: textInput.left
        anchors.verticalCenter: textInput.verticalCenter
        visible: textInput.text.length === 0 && root.placeholderText.length > 0
        text: root.placeholderText
        font.family: "Segoe UI"
        font.pixelSize: 15
        color: "#636975"
    }
}
