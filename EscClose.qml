pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Единая логика «Esc закрывает попап» для всех открываемых капсул.
// Пока открыт хотя бы один попап — вешаем ГЛОБАЛЬНЫЙ бинд Escape (мышь свободна,
// попапы не захватывают ввод). Нажатие Esc → сигнал pressed() → каждый открытый
// попап закрывается сам. Рефсчёт: бинд снимается, когда закрылся последний.
Singleton {
    id: root
    signal pressed()
    property int _open: 0

    function acquire() {
        _open++
        if (_open === 1)
            Quickshell.execDetached(["hyprctl", "keyword", "bind", ",escape,global,quickshell:escClose"])
    }
    function release() {
        _open = Math.max(0, _open - 1)
        if (_open === 0)
            Quickshell.execDetached(["hyprctl", "keyword", "unbind", ",escape"])
    }

    GlobalShortcut {
        name: "escClose"
        description: "Закрыть попап панели"
        onPressed: root.pressed()
    }
}
