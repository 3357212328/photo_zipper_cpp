import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string prefixText: ""
    property string suffixText: ""
    property string text: ""
    property string placeholderText: ""
    property bool inputEnabled: true
    property var validator: null
    signal editingCompleted(string newValue)

    implicitWidth: 140
    implicitHeight: 36
    radius: 8
    color: !inputEnabled
           ? Theme.inputDisabledBg
           : (textInput.activeFocus ? Theme.inputFocusBg : (hoverHandler.hovered ? Theme.inputHoverBg : Theme.inputBg))
    border.width: textInput.activeFocus ? 1.5 : 1
    border.color: !inputEnabled
                  ? Theme.cardBorder
                  : (textInput.activeFocus ? Theme.accent : (hoverHandler.hovered ? Theme.cardHoverBorder : Theme.inputBorder))

    Behavior on color { ColorAnimation { duration: 130 } }
    Behavior on border.color { ColorAnimation { duration: 130 } }

    HoverHandler {
        id: hoverHandler
    }

    onInputEnabledChanged: {
        if (!inputEnabled && textInput.activeFocus) {
            textInput.focus = false
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6

        Text {
            visible: root.prefixText.length > 0
            text: root.prefixText
            font.family: "Microsoft YaHei UI"
            font.pixelSize: 11
            font.bold: true
            color: !root.inputEnabled ? Theme.textMuted : (textInput.activeFocus ? Theme.accent : Theme.textSecondary)
            Behavior on color { ColorAnimation { duration: 130 } }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextInput {
                id: textInput
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                enabled: root.inputEnabled
                readOnly: !root.inputEnabled
                text: root.text
                validator: root.validator
                selectByMouse: true
                clip: true
                font.family: "Segoe UI"
                font.pixelSize: 13
                font.bold: true
                color: root.inputEnabled ? Theme.textPrimary : Theme.textMuted
                selectionColor: Theme.accent

                onTextEdited: {
                    root.editingCompleted(textInput.text)
                }
                onEditingFinished: {
                    root.editingCompleted(textInput.text)
                }
            }

            Text {
                anchors.left: textInput.left
                anchors.verticalCenter: textInput.verticalCenter
                visible: textInput.text.length === 0 && root.placeholderText.length > 0
                text: root.placeholderText
                font.family: "Microsoft YaHei UI"
                font.pixelSize: 12
                color: Theme.textMuted
            }
        }

        Text {
            visible: root.suffixText.length > 0
            text: root.suffixText
            font.family: "Segoe UI"
            font.pixelSize: 11
            color: Theme.textMuted
        }
    }
}
