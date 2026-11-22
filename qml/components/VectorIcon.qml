import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property string name: ""
    property real size: 16
    property color color: Theme.textPrimary
    property real strokeWidth: 1.8

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    function pathFor(iconName) {
        switch (iconName) {
        case "plus":         return "M12 5 V19 M5 12 H19"
        case "folder":       return "M3 7 C3 5.9 3.9 5 5 5 H9.5 L11.5 7.5 H19 C20.1 7.5 21 8.4 21 9.5 V18 C21 19.1 20.1 20 19 20 H5 C3.9 20 3 19.1 3 18 Z"
        case "sparkles":     return "M12 3 L13.8 8.2 L19 10 L13.8 11.8 L12 17 L10.2 11.8 L5 10 L10.2 8.2 Z M19 15 L19.8 17.2 L22 18 L19.8 18.8 L19 21 L18.2 18.8 L16 18 L18.2 17.2 Z"
        case "eye":          return "M2 12 C4.5 7.5 8 5.5 12 5.5 C16 5.5 19.5 7.5 22 12 C19.5 16.5 16 18.5 12 18.5 C8 18.5 4.5 16.5 2 12 Z M12 9 A3 3 0 1 0 12 15 A3 3 0 1 0 12 9"
        case "trash":        return "M4 7 H20 M10 11 V17 M14 11 V17 M5 7 L6 19 C6 20.1 6.9 21 8 21 H16 C17.1 21 18 20.1 18 19 L19 7 M9 7 V4 C9 3.4 9.4 3 10 3 H14 C14.6 3 15 3.4 15 4 V7"
        case "sun":          return "M12 8 A4 4 0 1 0 12 16 A4 4 0 1 0 12 8 M12 2 V4 M12 20 V22 M4.9 4.9 L6.3 6.3 M17.7 17.7 L19.1 19.1 M2 12 H4 M20 12 H22 M4.9 19.1 L6.3 17.7 M17.7 6.3 L19.1 4.9"
        case "moon":         return "M20.5 14.5 A8.5 8.5 0 1 1 9.5 3.5 A6.8 6.8 0 0 0 20.5 14.5 Z"
        case "sliders":      return "M4 6 H20 M4 12 H20 M4 18 H20 M9 4 V8 M15 10 V14 M11 16 V20"
        case "droplet":      return "M12 2.5 C12 2.5 5.5 10 5.5 14.5 A6.5 6.5 0 0 0 18.5 14.5 C18.5 10 12 2.5 12 2.5 Z"
        case "output":       return "M12 3 V14 M7.5 9.5 L12 14 L16.5 9.5 M4 16 V19 C4 20.1 4.9 21 6 21 H18 C19.1 21 20 20.1 20 19 V16"
        case "upload":       return "M12 16 V5 M7.5 9.5 L12 5 L16.5 9.5 M4 16 V19 C4 20.1 4.9 21 6 21 H18 C19.1 21 20 20.1 20 19 V16"
        case "check":        return "M5 12.5 L9.5 17 L19 7.5"
        case "x":            return "M6 6 L18 18 M18 6 L6 18"
        case "chevron-down": return "M6 9 L12 15 L18 9"
        case "refresh":      return "M20 12 A8 8 0 1 1 17.6 6.3 M20 4 V9 H15"
        case "cloud":        return "M6.5 19 H17.5 C19.7 19 21.5 17.2 21.5 15 C21.5 13 20 11.3 18 11.1 C17.4 7.7 14.5 5 11 5 C7.5 5 4.7 7.6 4.2 11 C2.9 11.6 2 13 2 14.6 C2 17 4 19 6.5 19 Z"
        case "package":      return "M12 2.5 L20.5 7.2 V16.8 L12 21.5 L3.5 16.8 V7.2 Z M12 21.5 V12 M20.5 7.2 L12 12 L3.5 7.2"
        case "zap":          return "M13 2 L4 14 H11 L10 22 L20 10 H13 Z"
        case "stop":         return "M6 6 H18 V18 H6 Z"
        case "folder-open":  return "M3 8 C3 6.9 3.9 6 5 6 H9.5 L11.5 8.5 H19 C20.1 8.5 21 9.4 21 10.5 L19.5 18.5 C19.3 19.4 18.5 20 17.6 20 H5 C3.9 20 3 19.1 3 18 Z"
        case "compare":      return "M12 3 V21 M8 8 L4 12 L8 16 M16 8 L20 12 L16 16"
        case "terminal":     return "M4 17 L10 11 L4 5 M12 19 H20"
        case "cpu":          return "M7 7 H17 V17 H7 Z M9 3 V7 M15 3 V7 M9 17 V21 M15 17 V21 M3 9 H7 M3 15 H7 M17 9 H21 M17 15 H21"
        default:             return ""
        }
    }

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        transform: Scale {
            xScale: root.size / 24.0
            yScale: root.size / 24.0
        }

        ShapePath {
            strokeColor: root.color
            fillColor: "transparent"
            strokeWidth: root.strokeWidth
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: root.pathFor(root.name)
            }
        }
    }
}
