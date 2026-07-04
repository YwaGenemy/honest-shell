// Питание: клик — выпадающее меню ВНИЗ (блокировка / сон / перезагрузка / выключение).
// ПКМ — wlogout. Меню не распихивает соседние пины: оно в отдельном попапе.
import QtQuick
import Quickshell
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

    Icon {
        name: "power"
        color: root.open || root.hovered ? Theme.critical : Theme.muted
    }

    // Выпадающее меню под кнопкой
    PopupWindow {
        id: pop
        visible: root.open && root.panelWindow !== undefined
        grabFocus: true                              // клик мимо — закрыть
        onVisibleChanged: if (!visible) root.open = false
        color: "transparent"
        implicitWidth: card.width + 24
        implicitHeight: card.height + 20
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 8

        Rectangle {
            id: card
            x: 12; y: 4
            width: actRow.implicitWidth + 20
            height: 48
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

            Row {
                id: actRow
                anchors.centerIn: parent
                spacing: 6

                component ActBtn: Rectangle {
                    property string icon
                    property color tint: Theme.muted
                    property string label
                    property var run
                    width: 36; height: 36; radius: 9
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

                ActBtn { icon: "lock";    label: "Блокировка"; run: () => Quickshell.execDetached(["hyprlock"]) }
                ActBtn { icon: "moon";    label: "Сон";        run: () => Quickshell.execDetached(["systemctl", "suspend"]) }
                ActBtn { icon: "restart"; label: "Ребут";      run: () => Quickshell.execDetached(["systemctl", "reboot"]) }
                ActBtn { icon: "power";   label: "Выключить";  tint: Theme.critical
                         run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
            }
        }
    }
}
