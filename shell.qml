// Точка входа Quickshell. Запускается: `quickshell` (или `qs`).
// Меню трея рендерим сами (TrayMenu) — режим QApplication не нужен.
import Quickshell
import Quickshell.Io
import "root:/"

ShellRoot {
    // По одной панели на каждый монитор.
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // IPC: `qs ipc call clipboard flash` — вызывается скриптом скриншота.
    // Один обработчик на весь шелл (не в per-monitor модуле).
    IpcHandler {
        target: "clipboard"
        function flash(): void { Clipboard.flash() }
    }
}
