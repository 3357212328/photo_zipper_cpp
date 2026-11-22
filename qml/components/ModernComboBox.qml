import QtQuick
import QtQuick.Controls.Basic

ComboBox {
    id: control
    implicitHeight: 36
    implicitWidth: 150
    font.family: "Microsoft YaHei UI"
    font.pixelSize: 12

    HoverHandler {
        id: hoverHandler
    }

    delegate: ItemDelegate {
        width: control.width - 8
        height: 32
        contentItem: Text {
            text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
            color: highlighted ? "#FFFFFF" : Theme.textPrimary
            font: control.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: 10
        }
        background: Rectangle {
            color: highlighted ? Theme.accent : "transparent"
            radius: 6
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        highlighted: control.highlightedIndex === index
    }

    // Pure GPU Text Indicator (Zero Canvas Overhead)
    indicator: Text {
        x: control.width - width - 12
        y: control.topPadding + (control.availableHeight - height) / 2
        text: "▾"
        font.pixelSize: 13
        color: hoverHandler.hovered ? Theme.accent : Theme.textSecondary
        rotation: control.popup.visible ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    contentItem: Text {
        leftPadding: 12
        rightPadding: control.indicator.width + control.spacing + 8
        text: control.displayText
        font: control.font
        color: Theme.textPrimary
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 140
        implicitHeight: 36
        color: control.down ? Theme.inputBg : (hoverHandler.hovered ? Theme.inputHoverBg : Theme.inputBg)
        border.color: control.popup.visible ? Theme.accent : (hoverHandler.hovered ? Theme.cardHoverBorder : Theme.inputBorder)
        border.width: 1
        radius: 8

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: contentItem.implicitHeight + 8
        padding: 4

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 140; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: 140; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 100 }
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            spacing: 2
            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            color: Theme.popupBg
            border.color: Theme.cardHoverBorder
            border.width: 1
            radius: 8
        }
    }
}
