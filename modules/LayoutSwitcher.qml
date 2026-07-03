// Раскладка EN/RU. Клик → переключение. Состояние ловим из событий Hyprland (activelayout).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "root:/"
import "root:/components"

Pill {
    id: root
    property string kb: "at-translated-set-2-keyboard"
    property bool isRu: false
    tooltip: isRu ? "Раскладка: Русская" : "Layout: English"

    onClicked: Hyprland.dispatch("switchxkblayout " + kb + " next")

    Text {
        text: String.fromCodePoint(0xF030C)   // nf-md-keyboard
        color: Theme.layout
        font.family: Theme.font
        font.pixelSize: Theme.iconSize
    }
    Text {
        text: root.isRu ? "RU" : "EN"
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    function apply(name) {
        root.isRu = /rus/i.test(name)
    }

    // Реакция на события раскладки в реальном времени
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") {
                // data: "<keyboard>,<LayoutName>"
                const parts = ("" + event.data).split(",")
                root.apply(parts[parts.length - 1])
            }
        }
    }

    // Начальное состояние
    Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    for (const k of d.keyboards) {
                        if (k.name === root.kb || k.main) { root.apply(k.active_keymap); break }
                    }
                } catch (e) {}
            }
        }
    }
}
