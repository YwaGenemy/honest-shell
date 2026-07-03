// Точка входа Quickshell. Запускается: `quickshell` (или `qs`).
// Меню трея рендерим сами (TrayMenu) — режим QApplication не нужен.
import Quickshell
import "root:/"

ShellRoot {
    // По одной панели на каждый монитор.
    Variants {
        model: Quickshell.screens
        Bar {}
    }
}
