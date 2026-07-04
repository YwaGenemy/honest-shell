// Окно панели (layer-shell, верх экрана). Создаётся по разу на монитор из shell.qml.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/components"
import "root:/modules"

PanelWindow {
    id: bar
    property var modelData
    screen: modelData

    // Явный namespace — по нему Hyprland вешает blur (см. install: layerrule blur, quickshell:bar)
    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top

    anchors { top: true; left: true; right: true }
    margins { top: Theme.barMarginTop; left: Theme.barMargin; right: Theme.barMargin }
    implicitHeight: Theme.barHeight
    color: Theme.panelBg          // прозрачный фон — стекло рисует Hyprland

    // Три зоны. Центр держим ровно по центру экрана независимо от ширины боков.
    Item {
        id: content
        anchors.fill: parent

        // Премиальное появление: ждём, пока модули наполнятся данными (трей, метрики),
        // и показываем всё одним аккордом — fade + мягкий спуск сверху. Без дёрганий.
        opacity: 0
        y: -Theme.barHeight * 0.6
        Timer {
            interval: 600; running: true
            onTriggered: { content.opacity = 1; content.y = 0 }
        }
        Behavior on opacity { NumberAnimation { duration: Theme.slow + 120; easing.type: Theme.easeType } }
        Behavior on y       { NumberAnimation { duration: Theme.slow + 120; easing.type: Theme.easeType } }

        // ЛЕВО
        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.groupGap
            LayoutSwitcher { panelWindow: bar }
            CpuUsage      { panelWindow: bar }
            GpuTemp       { panelWindow: bar }
            NetSpeed      { panelWindow: bar }
            PowerProfile  { panelWindow: bar }
            Clipboard     { panelWindow: bar }
        }

        // ЦЕНТР
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.groupGap
            Workspaces { panelWindow: bar }
        }

        // ПРАВО
        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.groupGap
            Privacy { panelWindow: bar }
            Updates { panelWindow: bar }
            Media   { panelWindow: bar }
            Tray    { panelWindow: bar }
            Volume  { panelWindow: bar }
            Battery { panelWindow: bar }
            Clock     { panelWindow: bar }
            Notes     { panelWindow: bar }
            Logout    { panelWindow: bar }
        }
    }

    // Единый морфящий попап (громкость/батарея/медиа)
    PopoutWindow { barContent: content }
}
