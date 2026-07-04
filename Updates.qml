pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Проверка обновлений раз в сутки (+ при старте). Официальные репо — checkupdates
// (безопасно, без sudo, отдельная база), AUR — paru -Qua. Данные читают и пилюля,
// и попап — единый источник, без гонок.
Singleton {
    id: root

    property int  repoCount: 0
    property int  aurCount: 0
    property var  repoList: []      // ["pkg 1.0 -> 1.1", …]
    property var  aurList: []
    property bool checking: false
    readonly property int total: repoCount + aurCount

    function refresh() {
        if (checking) return
        checking = true
        repoProc.running = true
        aurProc.running = true
    }

    function _lines(out) {
        return ("" + out).split("\n").map(s => s.trim()).filter(s => s.length > 0)
    }

    // Официальные репозитории
    Process {
        id: repoProc
        // checkupdates возвращает код 2 при отсутствии обновлений — || true, чтобы не считалось ошибкой
        command: ["sh", "-c", "checkupdates 2>/dev/null || true"]
        stdout: StdioCollector { onStreamFinished: {
            root.repoList = root._lines(text)
            root.repoCount = root.repoList.length
            root.checking = false
        }}
    }

    // AUR
    Process {
        id: aurProc
        command: ["sh", "-c", "paru -Qua 2>/dev/null || true"]
        stdout: StdioCollector { onStreamFinished: {
            root.aurList = root._lines(text)
            root.aurCount = root.aurList.length
        }}
    }

    // Раз в сутки + один раз при запуске
    Timer {
        interval: 86400000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
