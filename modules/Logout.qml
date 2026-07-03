// Выход. Клик → wlogout. Иконка краснеет на hover.
import Quickshell
import QtQuick
import "root:/"
import "root:/components"

Pill {
    id: root
    tooltip: "Выход"
    onClicked: Quickshell.execDetached(["wlogout"])

    Text {
        text: "󰐥"                       // power glyph
        color: root.hovered ? Theme.critical : Theme.muted
        font.family: Theme.font
        font.pixelSize: Theme.iconSize
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }
}
