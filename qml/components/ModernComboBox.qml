import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ComboBox {
    id: control
    implicitHeight: 34
    implicitWidth: 140
    font.family: "Microsoft YaHei UI"
    font.pixelSize: 12

    HoverHandler {
        id: hoverHandler
    }

    delegate: ItemDelegate {
        width: ListView.view ? ListView.view.width : (control.width - 8)
        height: 32
        padding: 0
        z: 2
        highlighted: control.highlightedIndex === index

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        background: Item {}

        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
                color: highlighted ? Theme.accentSoftText : Theme.textPrimary
                font.family: control.font.family
                font.pixelSize: control.font.pixelSize
                font.bold: highlighted || control.currentIndex === index
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            VectorIcon {
                visible: control.currentIndex === index
                name: "check"
                size: 12
                strokeWidth: 2.2
                color: Theme.accent
            }
        }
    }

    indicator: VectorIcon {
        x: control.width - width - 10
        y: control.topPadding + (control.availableHeight - height) / 2
        name: "chevron-down"
        size: 13
        strokeWidth: 1.8
        color: hoverHandler.hovered ? Theme.accent : Theme.textSecondary
        rotation: control.popup.visible ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 130 } }
    }

    contentItem: Text {
        leftPadding: 10
        rightPadding: control.indicator.width + control.spacing + 6
        text: control.displayText
        font: control.font
        color: Theme.textPrimary
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 130
        implicitHeight: 34
        color: control.down ? Theme.inputBg : (hoverHandler.hovered ? Theme.inputHoverBg : Theme.inputBg)
        border.color: control.popup.visible ? Theme.accent : (hoverHandler.hovered ? Theme.cardHoverBorder : Theme.inputBorder)
        border.width: 1
        radius: 8

        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on border.color { ColorAnimation { duration: 130 } }
    }

    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: contentItem.implicitHeight + 8
        padding: 4

        onOpened: listView.animateHighlight = true
        onAboutToHide: listView.animateHighlight = false

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 140; easing.type: Easing.OutCubic }
                NumberAnimation { property: "y"; from: control.height - 2; to: control.height + 4; duration: 140; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 100 }
        }

        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            highlightFollowsCurrentItem: false
            spacing: 2
            ScrollIndicator.vertical: ScrollIndicator { }

            property bool animateHighlight: false

            highlight: Rectangle {
                y: listView.currentItem ? listView.currentItem.y : 0
                width: listView.width
                height: listView.currentItem ? listView.currentItem.height : 32
                radius: 6
                z: 0
                visible: listView.currentIndex >= 0
                color: Theme.accentSoftBg
                border.width: 1
                border.color: Theme.accentSoftBorder

                Behavior on y {
                    enabled: listView.animateHighlight
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
            }
        }

        background: Rectangle {
            color: Theme.popupBg
            border.color: Theme.cardHoverBorder
            border.width: 1
            radius: 8
        }
    }
}
