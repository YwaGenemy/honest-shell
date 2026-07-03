// Индикатор приватности: появляется, только когда кто-то слушает микрофон
// (pactl source-outputs). Пульсирующая точка + имя приложения.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "root:/"
import "root:/components"

Pill {
    id: root
    property var apps: []
    visible: apps.length > 0
    accentColor: Theme.critical
    tooltip: "Микрофон используется"

    function parse(out) {
        try {
            const list = JSON.parse("" + out)
            const names = []
            for (const so of list) {
                const n = so.properties?.["application.name"]
                    ?? so.properties?.["application.process.binary"] ?? "app"
                if (!names.includes(n)) names.push(n)
            }
            root.apps = names
        } catch (e) { root.apps = [] }
    }

    // Пульсирующая точка
    Rectangle {
        width: 7; height: 7; radius: 3.5
        color: Theme.critical
        SequentialAnimation on opacity {
            running: root.visible
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0;  duration: 800; easing.type: Easing.InOutSine }
        }
    }
    Icon { name: "mic"; color: Theme.critical }
    Text {
        text: root.apps.join(", ")
        color: Theme.text
        font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
        elide: Text.ElideRight
        Layout.maximumWidth: 120
    }

    Process {
        id: proc
        command: ["sh", "-c", "pactl -f json list source-outputs 2>/dev/null || echo []"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Timer {
        interval: 3000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
