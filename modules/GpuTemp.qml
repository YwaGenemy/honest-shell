// Температура GPU °C. Путь через glob по PCI-адресу (amdgpu) — устойчив к перенумерации hwmon.
// ВАЖНО: у тебя amdgpu = hwmon6 (hwmon5 = Wi-Fi), поэтому берём hwmon* по стабильному PCI-пути.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "root:/"
import "root:/components"

Pill {
    id: root
    property int temp: 0
    tooltip: "GPU: " + temp + "°C"

    Icon { name: "thermo"; color: root.temp >= 85 ? Theme.critical : (root.temp >= 70 ? Theme.warning : Theme.muted) }
    Text {
        text: root.temp + "°"
        color: root.temp >= 85 ? Theme.critical : Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        TextMetrics { id: tm; font.family: Theme.font; font.pixelSize: Theme.fontSize; text: "100°" }
        Layout.preferredWidth: tm.width
        horizontalAlignment: Text.AlignRight
        Behavior on color { ColorAnimation { duration: Theme.med } }
    }

    Process {
        id: proc
        command: ["sh", "-c", "cat /sys/devices/pci0000:00/0000:00:08.1/0000:03:00.0/hwmon/hwmon*/temp1_input"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(("" + text).trim().split("\n")[0])
                if (!isNaN(v)) root.temp = Math.round(v / 1000)
            }
        }
    }
    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
