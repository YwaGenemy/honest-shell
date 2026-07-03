// Загрузка CPU % — по дельте /proc/stat. Цвет плавно уходит в warning при высокой нагрузке.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "root:/"
import "root:/components"

Pill {
    id: root
    property int  usage: 0
    property real _prevTotal: 0
    property real _prevIdle: 0
    tooltip: "CPU: " + usage + "%"

    Text {
        text: String.fromCodePoint(0xF0EFB)   // nf-md-cpu-64-bit
        color: Theme.accent
        font.family: Theme.font
        font.pixelSize: Theme.iconSize
    }
    Text {
        text: root.usage + "%"
        color: root.usage >= 85 ? Theme.warning : Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        // фиксированная ширина под "100%" — пилюля не «дышит» при смене цифр
        TextMetrics { id: tm; font.family: Theme.font; font.pixelSize: Theme.fontSize; text: "100%" }
        Layout.preferredWidth: tm.width
        horizontalAlignment: Text.AlignRight
        Behavior on color { ColorAnimation { duration: Theme.med } }
    }

    function parse(out) {
        const line = ("" + out).split("\n")[0].trim().split(/\s+/)
        // cpu user nice system idle iowait irq softirq steal ...
        let total = 0
        for (let i = 1; i < line.length; i++) total += parseInt(line[i]) || 0
        const idle = (parseInt(line[4]) || 0) + (parseInt(line[5]) || 0)
        const dt = total - root._prevTotal
        const di = idle - root._prevIdle
        if (dt > 0 && root._prevTotal > 0)
            root.usage = Math.max(0, Math.min(100, Math.round(100 * (1 - di / dt))))
        root._prevTotal = total
        root._prevIdle = idle
    }

    Process {
        id: proc
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Timer {
        interval: 1500; running: true; repeat: true; triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
