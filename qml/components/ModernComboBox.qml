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
            color: highlighted ? "#FFFFFF" : "#CBD5E1"
            font: control.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: 10
        }
        background: Rectangle {
            color: highlighted ? "#2563EB" : "transparent"
            radius: 6
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        highlighted: control.highlightedIndex === index
    }

    indicator: Canvas {
        id: canvas
        x: control.width - width - 12
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 10
        height: 6
        contextType: "2d"
        rotation: control.popup.visible ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = hoverHandler.hovered ? "#93C5FD" : "#94A3B8";
            ctx.lineWidth = 1.6;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";
            ctx.beginPath();
            ctx.moveTo(1, 1);
            ctx.lineTo(5, 5);
            ctx.lineTo(9, 1);
            ctx.stroke();
        }
    }

    contentItem: Text {
        leftPadding: 12
        rightPadding: control.indicator.width + control.spacing + 8
        text: control.displayText
        font: control.font
        color: "#F1F5F9"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 140
        implicitHeight: 36
        color: control.down ? "#1C2028" : (hoverHandler.hovered ? "#2A303C" : "#21252D")
        border.color: control.popup.visible ? "#60A5FA" : (hoverHandler.hovered ? "#4E5768" : "#383E4A")
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
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 110 }
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
            color: "#1E222A"
            border.color: "#475569"
            border.width: 1
            radius: 8
        }
    }
}
