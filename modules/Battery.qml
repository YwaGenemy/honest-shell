// Батарея BAT1 через UPower. warning ≤30%, critical ≤15%. Зарядка — молния + мягкая пульсация.
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "root:/"
import "root:/components"

Pill {
    id: root
    readonly property var dev: UPower.displayDevice
    readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: dev && (dev.state === UPowerDeviceState.Charging
                                             || dev.state === UPowerDeviceState.FullyCharged)
    readonly property bool crit: pct <= 15 && !charging
    readonly property bool warn: pct <= 30 && !charging

    tooltip: (charging ? "Зарядка — " : "Батарея — ") + pct + "%"
    accentColor: crit ? Theme.critical : (warn ? Theme.warning : Theme.battery)

    // Иконки уровней заряда (nf-md-battery_*)
    function levelGlyph() {
        if (charging) return "󰂄"
        const buckets = ["󰂎","󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]
        return buckets[Math.min(10, Math.floor(pct / 10))]
    }

    Text {
        id: icon
        text: root.levelGlyph()
        color: root.crit ? Theme.critical : (root.warn ? Theme.warning : Theme.battery)
        font.family: Theme.font
        font.pixelSize: Theme.iconSize
        Behavior on color { ColorAnimation { duration: Theme.med } }

        // Пульсация при критическом уровне
        SequentialAnimation on opacity {
            running: root.crit
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
        }
    }
    onCritChanged: if (!crit) icon.opacity = 1
    Text {
        text: root.pct + "%"
        color: root.crit ? Theme.critical : (root.warn ? Theme.warning : Theme.text)
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        TextMetrics { id: tm; font.family: Theme.font; font.pixelSize: Theme.fontSize; text: "100%" }
        Layout.preferredWidth: tm.width
        horizontalAlignment: Text.AlignRight
        Behavior on color { ColorAnimation { duration: Theme.med } }
    }
}
