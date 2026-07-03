// Штриховая SVG-иконка (генерируется data-URI, цвет — параметром).
// Единый стиль всей панели: stroke 1.7, скруглённые концы, viewBox 16.
//
// ВАЖНО: корень — Item с фиксированным implicitSize, а не сам Image.
// У Image implicitWidth следует за sourceSize; если sourceSize зависит от width,
// RowLayout входит в бесконечный цикл увеличения (width→sourceSize→implicitWidth→width…),
// который выжигает CPU. Item разрывает эту связь.
import QtQuick
import "root:/"

Item {
    id: root
    property string name
    property color color: Theme.muted
    property real thickness: 1.7

    implicitWidth: Theme.iconSize
    implicitHeight: Theme.iconSize

    readonly property string _rgb:
        "rgb(" + Math.round(color.r * 255) + "," + Math.round(color.g * 255) + "," + Math.round(color.b * 255) + ")"

    Image {
        anchors.fill: parent
        // Фиксированный размер рендера (не зависит от геометрии — без циклов)
        sourceSize: Qt.size(Theme.iconSize * 3, Theme.iconSize * 3)
        fillMode: Image.PreserveAspectFit
        opacity: root.color.a
        source: "data:image/svg+xml;utf8," + encodeURIComponent(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='none' stroke='" + root._rgb
            + "' stroke-width='" + root.thickness + "' stroke-linecap='round' stroke-linejoin='round'>"
            + (Icons.d[root.name] ?? "").replace(/CUR/g, root._rgb) + "</svg>")
    }

    Behavior on color { ColorAnimation { duration: Theme.med } }
}
