// Скорость сети ↓/↑ — дельта rx/tx по /proc/net/dev (все интерфейсы кроме lo).
// Ширина зафиксирована метриками, чтобы панель не «дышала».
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "root:/"
import "root:/components"

Pill {
    id: root
    property real down: 0
    property real up: 0
    property real _prevRx: 0
    property real _prevTx: 0
    property real _prevTs: 0
    tooltip: "Сеть: приём / отдача"

    function parse(out) {
        let rx = 0, tx = 0
        for (const line of ("" + out).split("\n")) {
            if (!line.includes(":")) continue
            const f = line.trim().split(/[:\s]+/)
            if (f.length < 10 || f[0] === "lo") continue
            rx += parseInt(f[1]) || 0
            tx += parseInt(f[9]) || 0
        }
        const now = Date.now() / 1000
        if (root._prevTs > 0) {
            const dt = Math.max(0.5, now - root._prevTs)
            root.down = Math.max(0, (rx - root._prevRx) / dt)
            root.up   = Math.max(0, (tx - root._prevTx) / dt)
        }
        root._prevRx = rx; root._prevTx = tx; root._prevTs = now
    }
    function fmt(b) {
        return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s"
                            : Math.round(b / 1024) + " KB/s"
    }

    Icon { name: "down"; color: Theme.battery; implicitWidth: 12; implicitHeight: 12 }
    Text {
        text: root.fmt(root.down)
        color: Theme.text
        font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
        TextMetrics { id: tmd; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; text: "99.9 MB/s" }
        Layout.preferredWidth: tmd.width
        horizontalAlignment: Text.AlignRight
    }
    Icon { name: "up"; color: Theme.warning; implicitWidth: 12; implicitHeight: 12 }
    Text {
        text: root.fmt(root.up)
        color: Theme.muted
        font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
        TextMetrics { id: tmu; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; text: "999 KB/s" }
        Layout.preferredWidth: tmu.width
        horizontalAlignment: Text.AlignRight
    }

    Process {
        id: proc
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
