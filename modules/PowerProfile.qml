// Профиль питания eco/performance через D-Bus (power-profiles-daemon).
// busctl используется вместо powerprofilesctl (у него в системе нет python-gobject).
// eco = "power-saver". Активный сегмент подсвечен.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "root:/"
import "root:/components"

Pill {
    id: root
    property string profile: "performance"      // "power-saver" | "balanced" | "performance"
    readonly property bool isPerf: profile === "performance"
    hpad: 8
    tooltip: "Питание: " + (isPerf ? "Performance" : (profile === "power-saver" ? "Eco" : profile))

    // Клик — переключаем на противоположный
    onClicked: setProfile(isPerf ? "power-saver" : "performance")

    // Сегмент eco
    RowLayout {
        spacing: 6
        Icon { name: "leaf"; color: root.isPerf ? Theme.muted : Theme.battery }
        // Разделитель
        Rectangle { width: 1; Layout.preferredHeight: 14; color: Theme.border }
        Icon { name: "bolt"; color: root.isPerf ? Theme.accent : Theme.muted }
    }

    // — D-Bus чтение —
    function read() { readProc.running = true }
    Process {
        id: readProc
        command: ["busctl", "get-property", "net.hadess.PowerProfiles",
                  "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles", "ActiveProfile"]
        stdout: StdioCollector {
            onStreamFinished: {
                // формат: s "performance"
                const m = ("" + text).match(/"([^"]+)"/)
                if (m) root.profile = m[1]
            }
        }
    }

    // — D-Bus запись —
    function setProfile(p) {
        root.profile = p                          // оптимистично, для мгновенного отклика
        setProc.command = ["busctl", "set-property", "net.hadess.PowerProfiles",
                           "/net/hadess/PowerProfiles", "net.hadess.PowerProfiles",
                           "ActiveProfile", "s", p]
        setProc.running = true
    }
    Process { id: setProc; onExited: root.read() }

    // Периодическая синхронизация (вдруг сменили извне)
    Timer { interval: 4000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.read() }
}
