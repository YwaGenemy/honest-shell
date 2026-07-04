// Окно панели (layer-shell, верх экрана). Создаётся по разу на монитор из shell.qml.
// Три зоны строятся ДАННЫМИ из BarConfig (Repeater по id-модулей) — состав меняется
// из конструктора без правки кода.
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

    // id-модуля → Component. Здесь bar в области видимости, поэтому panelWindow: bar.
    Component { id: c_layout;     LayoutSwitcher { panelWindow: bar } }
    Component { id: c_cpu;        CpuUsage       { panelWindow: bar } }
    Component { id: c_gpu;        GpuTemp        { panelWindow: bar } }
    Component { id: c_net;        NetSpeed       { panelWindow: bar } }
    Component { id: c_power;      PowerProfile   { panelWindow: bar } }
    Component { id: c_clipboard;  Clipboard      { panelWindow: bar } }
    Component { id: c_workspaces; Workspaces     { panelWindow: bar } }
    Component { id: c_privacy;    Privacy        { panelWindow: bar } }
    Component { id: c_updates;    Updates        { panelWindow: bar } }
    Component { id: c_media;      Media          { panelWindow: bar } }
    Component { id: c_tray;       Tray           { panelWindow: bar } }
    Component { id: c_volume;     Volume         { panelWindow: bar } }
    Component { id: c_battery;    Battery        { panelWindow: bar } }
    Component { id: c_clock;      Clock          { panelWindow: bar } }
    Component { id: c_notes;      Notes          { panelWindow: bar } }
    Component { id: c_logout;     Logout         { panelWindow: bar } }
    Component { id: c_settings;   Constructor    { panelWindow: bar } }

    function compFor(id) {
        return ({
            "layout": c_layout, "cpu": c_cpu, "gpu": c_gpu, "net": c_net, "power": c_power,
            "clipboard": c_clipboard, "workspaces": c_workspaces, "privacy": c_privacy,
            "updates": c_updates, "media": c_media, "tray": c_tray, "volume": c_volume,
            "battery": c_battery, "clock": c_clock, "notes": c_notes, "logout": c_logout,
            "settings": c_settings
        })[id] ?? null
    }

    // Делегат зоны: Loader по id; невидимый модуль (Privacy/Updates/Media при пустоте)
    // сворачивается в лейауте вместе с Loader.
    component ZoneItem: Loader {
        required property var modelData
        sourceComponent: bar.compFor(modelData)
        visible: item ? item.visible : true
    }

    Item {
        id: content
        anchors.fill: parent

        // Премиальное появление: fade + мягкий спуск сверху одним аккордом.
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
            Repeater { model: BarConfig.left; delegate: ZoneItem {} }
        }

        // ЦЕНТР
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.groupGap
            Repeater { model: BarConfig.center; delegate: ZoneItem {} }
        }

        // ПРАВО
        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.groupGap
            Repeater { model: BarConfig.right; delegate: ZoneItem {} }
        }
    }

    // Единый морфящий попап (громкость/батарея/медиа/…)
    PopoutWindow { barContent: content }
}
