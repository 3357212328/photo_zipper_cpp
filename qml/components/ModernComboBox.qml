import QtQuick
import QtQuick.Controls.Basic

ComboBox {
    id: control
    implicitHeight: 36
    implicitWidth: 160
    font.family: "Microsoft YaHei UI"
    font.pixelSize: 13

    delegate: ItemDelegate {
        width: control.width
        height: 34
        contentItem: Text {
            text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
            color: highlighted ? "#FFFFFF" : "#D4D9E2"
            font: control.font
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: 10
        }
        background: Rectangle {
            color: highlighted ? "#3B64A8" : "transparent"
            radius: 4
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

        Connections {
            target: control
            function onPressedChanged() { canvas.requestPaint(); }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = "#A0A7B2";
            ctx.lineWidth = 1.6;
            ctx.beginPath();
            ctx.moveTo(1, 1);
            ctx.lineTo(5, 5);
            ctx.lineTo(9, 1);
            ctx.stroke();
        }
    }

    contentItem: Text {
        leftPadding: 12
        rightPadding: control.indicator.width + control.spacing
        text: control.displayText
        font: control.font
        color: "#E6EAF0"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 140
        implicitHeight: 36
        color: control.down ? "#23262B" : "#25282D"
        border.color: control.visualFocus ? "#94C1FA" : "#454A54"
        border.width: 1
        radius: 6
    }

    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: contentItem.implicitHeight + 8
        padding: 4

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            color: "#22252A"
            border.color: "#454A54"
            border.width: 1
            radius: 6
        }
    }
}
