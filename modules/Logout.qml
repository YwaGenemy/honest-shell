// Питание: клик — выпадающее меню ВНИЗ (блокировка / сон / перезагрузка / выключение).
// ПКМ — wlogout. Меню не распихивает соседние пины: оно в отдельном попапе.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/components"

Pill {
    id: root
    property bool open: false
    active: open
    accentColor: Theme.critical
    tooltip: "Питание"

    onClicked: open = !open
    onRightClicked: Quickshell.execDetached(["wlogout"])
    // Esc откуда угодно закрывает — единая логика попапов
    onOpenChanged: root.open ? EscClose.acquire() : EscClose.release()
    Connections { target: EscClose; function onPressed() { root.open = false } }

    // При открытии — крестик (⏻ живёт только в меню, не дублируется)
    Icon {
        name: root.open ? "close" : "power"
        color: root.open || root.hovered ? Theme.critical : Theme.muted
    }

    // Выпадающее меню — слой-окно, привязанное к правому краю (там же правый край
    // пилюли). Так меню встаёт ТОЧНО под кнопкой ⏻, не уезжает вбок.
    PanelWindow {
        id: pop
        visible: root.open && root.panelWindow !== undefined
        screen: root.panelWindow ? root.panelWindow.screen : null
        color: "transparent"

        WlrLayershell.namespace: "quickshell:powermenu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0

        anchors { top: true; right: true }
        // margin.right = barMargin − 12: карточка (с 12px тени слева/справа) правым
        // краем совпадёт с правым краем пилюли.
        // Панель резервирует свою высоту (exclusive zone), поэтому отсчёт top уже
        // идёт от НИЗА панели — нужен только маленький зазор, без barHeight.
        margins {
            top: 4
            right: Theme.barMargin - 12
        }
        implicitWidth: card.width + 24
        implicitHeight: card.height + 20
        mask: Region { item: card }

        // Узкая капсула, раскрывающаяся ВНИЗ столбцом действий
        Rectangle {
            id: card
            x: 12; y: 4
            width: 40
            height: actCol.implicitHeight + 12
            radius: 13
            color: Theme.surfaceHi
            border.width: 1
            border.color: Theme.border

            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
            transform: Translate {
                y: root.open ? 0 : -6
                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
            }

            Column {
                id: actCol
                anchors.horizontalCenter: parent.horizontalCenter
                y: 6
                spacing: 4

                component ActBtn: Rectangle {
                    property string icon
                    property color tint: Theme.muted
                    property var run
                    width: 32; height: 32; radius: 9
                    color: bma.containsMouse ? Theme.accentSoft : Qt.rgba(221/255, 228/255, 236/255, 0.04)
                    Icon {
                        anchors.centerIn: parent
                        name: parent.icon
                        color: bma.containsMouse ? (parent.tint === Theme.muted ? Theme.text : parent.tint) : parent.tint
                        implicitWidth: 17; implicitHeight: 17
                    }
                    MouseArea {
                        id: bma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.open = false; parent.run() }
                    }
                }

                // Порядок сверху вниз: выключение (у капсулы) → ребут → сон → блокировка
                ActBtn { icon: "power";   tint: Theme.critical
                         run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
                ActBtn { icon: "restart"; run: () => Quickshell.execDetached(["systemctl", "reboot"]) }
                ActBtn { icon: "moon";    run: () => Quickshell.execDetached(["systemctl", "suspend"]) }
                ActBtn { icon: "lock";    run: () => Quickshell.execDetached(["hyprlock"]) }
            }
        }
    }
}
