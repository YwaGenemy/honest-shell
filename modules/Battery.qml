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

    readonly property color batColor: crit ? Theme.critical : (warn ? Theme.warning : Theme.battery)

    // Корпус батареи + динамическая заливка уровнем + молния при зарядке
    Item {
        id: icon
        width: Theme.iconSize; height: Theme.iconSize

        Icon { name: "battery"; color: root.batColor }
        // Заливка: координаты корпуса (viewBox 1.5,5→12.5,11) в пикселях иконки
        Rectangle {
            readonly property real s: Theme.iconSize / 16
            x: 3.2 * s; y: 6.7 * s
            height: 2.6 * s
            width: Math.max(0, (9.6 * s) * root.pct / 100)
            radius: 1
            color: root.batColor
            visible: !root.charging
            Behavior on width { NumberAnimation { duration: Theme.med } }
        }
        Icon {
            name: "bolt"; color: root.batColor
            visible: root.charging
            width: Theme.iconSize * 0.62; height: Theme.iconSize * 0.62
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -Theme.iconSize * 0.06
            thickness: 2.2
        }

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
