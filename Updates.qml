pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Обновления пакетов. Два независимых уровня:
//   1) СБОР (сеть, раз в сутки): checkupdates + paru -Qua, каждая строка тегается
//      источником (repo/aur) и складывается в кэш-файл.
//   2) ВИД (локально, мгновенно): C++-хелпер honest-updates-sort фильтрует и
//      сортирует кэш по текущим флагам. Перезапускается при клике по фильтрам —
//      сеть при этом не трогается.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string helper: home + "/.config/quickshell/helpers/honest-updates-sort"
    readonly property string dataFile: home + "/.cache/honest-updates.txt"

    // Счётчики (из сбора)
    property int  repoCount: 0
    property int  aurCount: 0
    readonly property int total: repoCount + aurCount
    property bool checking: false

    // Состояние вида (управляется кнопками в попапе)
    property string filter: "all"      // all | repo | aur
    property string sort: "name"       // name | version | source
    property string order: "asc"       // asc | desc

    // Готовый к показу список ("имя старая -> новая источник"), уже отфильтрован/отсортирован
    property var view: []

    onFilterChanged: applyView()
    onSortChanged: applyView()
    onOrderChanged: applyView()

    function refresh() {
        if (checking) return
        checking = true
        fetchProc.running = true
    }
    function applyView() { viewProc.running = true }

    function _lines(t) { return ("" + t).split("\n").map(s => s.trim()).filter(s => s.length > 0) }

    // 1) Сбор: тегируем источник и пишем кэш (tee), stdout считаем для счётчиков
    Process {
        id: fetchProc
        command: ["sh", "-c",
            "{ checkupdates 2>/dev/null | sed 's/$/ repo/'; " +
            "paru -Qua 2>/dev/null | sed 's/$/ aur/'; } | tee " + root.dataFile]
        stdout: StdioCollector { onStreamFinished: {
            const lines = root._lines(text)
            root.repoCount = lines.filter(l => l.endsWith(" repo")).length
            root.aurCount  = lines.filter(l => l.endsWith(" aur")).length
            root.checking = false
            root.applyView()
        }}
    }

    // 2) Вид: прогоняем кэш через C++-хелпер с текущими флагами.
    // Если бинарник не собран — падаем обратно на сырой кэш (cat), чтобы не пусто.
    Process {
        id: viewProc
        command: ["sh", "-c",
            root.helper + " --filter=" + root.filter + " --sort=" + root.sort +
            " --order=" + root.order + " < " + root.dataFile +
            " 2>/dev/null || cat " + root.dataFile + " 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.view = root._lines(text) }
    }

    // Раз в сутки + один раз при запуске
    Timer {
        interval: 86400000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
