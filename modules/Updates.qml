// Значок обновлений: появляется, только когда есть что обновлять. Число — общее
// (репо + AUR). Клик — kitty с `paru -Syu`, СКМ — перепроверить сейчас.
// Hover — попап с разбивкой и списком пакетов.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/"
import "root:/components"

Pill {
    id: root
    visible: Updates.total > 0
    accentColor: Theme.warning

    onClicked: Quickshell.execDetached(["kitty", "--hold", "paru", "-Syu"])
    onMiddleClicked: Updates.refresh()

    onHoveredChanged: hovered
        ? Popouts.hoverEnter("updates", mapToItem(null, width / 2, 0).x)
        : Popouts.hoverLeave()

    Icon { name: "update"; color: Theme.warning }
    Text {
        text: Updates.total
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.bold: true
    }
}
