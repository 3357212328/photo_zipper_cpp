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
               ? Theme.inputDisabledBg
               : (root.isFocused ? Theme.inputFocusBg : (root.isHovered ? Theme.inputHoverBg : Theme.inputBg))
        border.width: root.isFocused ? 1.5 : 1
        border.color: !root.inputEnabled
                      ? Theme.cardBorder
                      : (root.isFocused ? Theme.accent : (root.isHovered ? Theme.cardHoverBorder : Theme.inputBorder))

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    // Floating label pill background
    Rectangle {
        x: 10
        y: 0
        width: labelItem.implicitWidth + 10
        height: 16
        radius: 4
        color: Theme.cardBg
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Text {
        id: labelItem
        x: 15
        y: 0
        text: root.labelText
        font.family: "Microsoft YaHei UI"
        font.pixelSize: 11
        font.bold: root.isFocused
        color: !root.inputEnabled ? Theme.textMuted : (root.isFocused ? Theme.accent : Theme.textSecondary)
        Behavior on color { ColorAnimation { duration: 140 } }
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
        color: root.inputEnabled ? Theme.textPrimary : Theme.textMuted
        selectionColor: Theme.accent

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
        color: Theme.textMuted
    }
}
