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

    implicitWidth: 150
    implicitHeight: 52

    readonly property int boxTop: 8
    readonly property bool isFocused: textInput.activeFocus
    readonly property bool isHovered: hoverHandler.hovered

    scale: isFocused ? 1.01 : 1.0
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    HoverHandler {
        id: hoverHandler
    }

    // Outer rounded input box
    Rectangle {
        id: borderBox
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root.boxTop
        anchors.bottom: parent.bottom
        radius: 8
        color: !root.inputEnabled
               ? "#1C1F24"
               : (root.isFocused ? "#1E2430" : (root.isHovered ? "#252A34" : "#21252D"))
        border.width: root.isFocused ? 1.5 : 1
        border.color: !root.inputEnabled
                      ? "#2F343D"
                      : (root.isFocused ? "#60A5FA" : (root.isHovered ? "#525B6C" : "#3B414D"))

        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
    }

    // Floating label pill background
    Rectangle {
        x: 10
        y: 0
        width: labelItem.implicitWidth + 10
        height: 16
        radius: 4
        color: "#262A32"
    }

    Text {
        id: labelItem
        x: 15
        y: 0
        text: root.labelText
        font.family: "Microsoft YaHei UI"
        font.pixelSize: 11
        font.bold: root.isFocused
        color: !root.inputEnabled ? "#646B78" : (root.isFocused ? "#93C5FD" : "#94A3B8")
        Behavior on color { ColorAnimation { duration: 150 } }
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
        font.pixelSize: 15
        font.bold: true
        color: root.inputEnabled ? "#F1F5F9" : "#646B78"
        selectionColor: "#3B82F6"

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
        font.family: "Microsoft YaHei UI"
        font.pixelSize: 13
        color: "#565E6C"
    }
}
