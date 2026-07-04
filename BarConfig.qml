pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Раскладка панели: какие модули в какой зоне и в каком порядке.
// Правится из конструктора (шестерёнка), сохраняется в bar-layout.json,
// переживает перезапуск. Bar.qml строит зоны из этих массивов.
Singleton {
    id: root
    readonly property string file: Quickshell.env("HOME") + "/.config/quickshell/bar-layout.json"

    // Порядок модулей по зонам (значения по умолчанию — текущая панель)
    property var left:   ["layout", "cpu", "gpu", "net", "power", "clipboard"]
    property var center: ["workspaces"]
    property var right:  ["privacy", "updates", "media", "tray", "volume", "battery", "clock", "notes", "logout", "settings"]

    // Все известные модули: id → русское имя (порядок = порядок в «Доступных»)
    readonly property var names: ({
        "layout": "Раскладка", "cpu": "CPU", "gpu": "GPU", "net": "Сеть",
        "power": "Профиль питания", "clipboard": "Буфер", "workspaces": "Воркспейсы",
        "privacy": "Микрофон", "updates": "Обновления", "media": "Медиа", "tray": "Трей",
        "volume": "Громкость", "battery": "Батарея", "clock": "Часы", "notes": "Заметки",
        "logout": "Выключение", "settings": "Конструктор"
    })
    readonly property var allIds: Object.keys(names)

    function zoneOf(id) {
        if (left.includes(id)) return "left"
        if (center.includes(id)) return "center"
        if (right.includes(id)) return "right"
        return ""
    }
    // Модули, которых сейчас нет ни в одной зоне
    readonly property var available: allIds.filter(id => zoneOf(id) === "")

    function _rm(arr, id) { return arr.filter(x => x !== id) }
    function _stripAll(id) { left = _rm(left, id); center = _rm(center, id); right = _rm(right, id) }

    function remove(id) { _stripAll(id); save() }
    function add(id, zone) {
        _stripAll(id)                               // сначала убрать из прежней зоны
        if (zone === "left") left = left.concat([id])
        else if (zone === "center") center = center.concat([id])
        else right = right.concat([id])
        save()
    }
    // Сдвиг внутри зоны (delta ±1) — для перестановки порядка
    function shift(id, delta) {
        const z = zoneOf(id); if (!z) return
        const arr = (z === "left" ? left : z === "center" ? center : right).slice()
        const i = arr.indexOf(id), j = i + delta
        if (j < 0 || j >= arr.length) return
        arr[i] = arr[j]; arr[j] = id
        if (z === "left") left = arr; else if (z === "center") center = arr; else right = arr
        save()
    }

    // — Сохранение / загрузка —
    FileView { id: store; path: root.file; blockLoading: true; atomicWrites: true }

    function save() {
        store.setText(JSON.stringify({ left: root.left, center: root.center, right: root.right }, null, 2))
    }
    function load() {
        try {
            const t = store.text()
            if (!t || t.length < 2) return
            const d = JSON.parse(t)
            if (Array.isArray(d.left)) left = d.left
            if (Array.isArray(d.center)) center = d.center
            if (Array.isArray(d.right)) right = d.right
        } catch (e) {}
    }
    Component.onCompleted: load()
}
