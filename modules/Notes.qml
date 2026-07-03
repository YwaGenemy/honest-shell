// Заметки. Клик → ~/.config/waybar/scripts/notes.sh
import Quickshell
import QtQuick
import "root:/"
import "root:/components"

Pill {
    id: root
    tooltip: "Заметки"
    onClicked: Quickshell.execDetached(["sh", "-c", "$HOME/.config/waybar/scripts/notes.sh"])

    Text {
        text: "󰠮"
        color: Theme.layout
        font.family: Theme.font
        font.pixelSize: Theme.iconSize
    }
}
