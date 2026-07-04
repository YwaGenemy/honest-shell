pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// История буфера обмена поверх cliphist. Текст и картинки; картинки декодируются
// в кэш-файлы для превью. Восстановление — `cliphist decode <id> | wl-copy`.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string cacheDir: home + "/.cache/honest-clip"
    readonly property int limit: 50            // сколько последних записей показывать
    property bool live: false                  // авто-обновление (пока попап открыт)

    // [{ id, isImage, text, dims, thumb }]
    property var entries: []
    readonly property var images: entries.filter(e => e.isImage)
    readonly property var texts:  entries.filter(e => !e.isImage)

    function refresh() { listProc.running = true }

    // Вспышка капсулы (вызывается по IPC после скриншота) + обновление истории
    signal flashed()
    function flash() { refresh(); flashed() }

    // Слежение за буфером: wl-paste --watch печатает строку при каждом изменении.
    // Пока попап открыт (live) — обновляем список с небольшой задержкой, чтобы
    // cliphist успел сохранить новую запись.
    Timer { id: debounce; interval: 200; onTriggered: root.refresh() }
    Process {
        running: true
        command: ["wl-paste", "--watch", "echo"]
        stdout: SplitParser { onRead: if (root.live) debounce.restart() }
    }

    // Вернуть запись в буфер обмена
    function copy(id) {
        Quickshell.execDetached(["sh", "-c", "cliphist decode " + id + " | wl-copy"])
    }
    // Удалить запись из истории
    function remove(id) {
        Quickshell.execDetached(["sh", "-c",
            "cliphist list | awk -F'\\t' '$1==" + id + "' | cliphist delete"])
        // локально убрать сразу, не дожидаясь refresh
        entries = entries.filter(e => e.id !== id)
    }
    function clearAll() {
        Quickshell.execDetached(["sh", "-c", "cliphist wipe"])
        entries = []
    }

    // Собираем список: текст как есть, картинки декодируем в кэш (если ещё нет),
    // выводим разбираемый формат TYPE\tID\tDATA.
    Process {
        id: listProc
        command: ["sh", "-c",
            "mkdir -p " + root.cacheDir + "; " +
            "cliphist list | head -n " + root.limit + " | while IFS=$'\\t' read -r id rest; do " +
            "  case \"$rest\" in " +
            "    *'binary data'*png*|*'binary data'*jpeg*|*'binary data'*jpg*) " +
            "      f=" + root.cacheDir + "/$id.png; " +
            "      [ -f \"$f\" ] || cliphist decode \"$id\" > \"$f\" 2>/dev/null; " +
            "      dims=$(printf '%s' \"$rest\" | grep -oE '[0-9]+x[0-9]+' | head -1); " +
            "      printf 'IMG\\t%s\\t%s\\n' \"$id\" \"$dims\" ;; " +
            "    *) printf 'TXT\\t%s\\t%s\\n' \"$id\" \"$rest\" ;; " +
            "  esac; " +
            "done"]
        stdout: StdioCollector { onStreamFinished: {
            const out = []
            for (const line of ("" + text).split("\n")) {
                if (!line) continue
                const t = line.indexOf("\t")
                const type = line.slice(0, t)
                const rest = line.slice(t + 1)
                const t2 = rest.indexOf("\t")
                const id = parseInt(t2 < 0 ? rest : rest.slice(0, t2))
                const data = t2 < 0 ? "" : rest.slice(t2 + 1)
                if (!id) continue
                if (type === "IMG")
                    out.push({ id: id, isImage: true, text: "", dims: data,
                               thumb: "file://" + root.cacheDir + "/" + id + ".png" })
                else
                    out.push({ id: id, isImage: false, text: data, dims: "", thumb: "" })
            }
            root.entries = out
        }}
    }
}
