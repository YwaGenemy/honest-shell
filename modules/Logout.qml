// Питание: клик по ⏻ разворачивает действия прямо в пилюле
// (блокировка / сон / перезагрузка / выключение). ПКМ — wlogout, как раньше.
// Сворачивается через 2с после ухода курсора.
import QtQuick
import Quickshell
import "root:/"
import "root:/components"

Item {
    id: root
    property var panelWindow
    property bool open: false

    implicitWidth: bg.width
    implicitHeight: Theme.pillHeight

    Timer { id: hideT; interval: 2000; onTriggered: root.open = false }

    Rectangle {
        id: bg
        width: row.implicitWidth + 24
        height: Theme.pillHeight
        radius: Theme.pillRadius
        color: powerMa.containsMouse || root.open ? Theme.surfaceHi : Theme.surface
        border.width: 1
        border.color: powerMa.containsMouse || root.open ? Theme.borderHi : Theme.border
        Behavior on width { NumberAnimation { duration: 340; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        Behavior on color { ColorAnimation { duration: Theme.med } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            // Разворачивающиеся действия (слева от кнопки питания)
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: root.open ? acts.implicitWidth : 0
                height: Theme.pillHeight
                clip: true
                Behavior on width { NumberAnimation { duration: 340; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }

                Row {
                    id: acts
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    opacity: root.open ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    component ActBtn: MouseArea {
                        id: btn
                        property string icon
                        property color tint: Theme.muted
                        property var run
                        width: 24; height: 24
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: hideT.stop()
                        onExited: if (root.open) hideT.restart()
                        onClicked: { root.open = false; btn.run() }
                        Rectangle {
                            anchors.fill: parent; radius: 7
                            color: btn.containsMouse ? Theme.accentSoft : "transparent"
                        }
                        Icon {
                            anchors.centerIn: parent
                            name: btn.icon
                            color: btn.containsMouse && btn.tint === Theme.muted ? Theme.text : btn.tint
                            implicitWidth: 14; implicitHeight: 14
                        }
                    }

                    ActBtn { icon: "lock";    run: () => Quickshell.execDetached(["hyprlock"]) }
                    ActBtn { icon: "moon";    run: () => Quickshell.execDetached(["systemctl", "suspend"]) }
                    ActBtn { icon: "restart"; run: () => Quickshell.execDetached(["systemctl", "reboot"]) }
                    ActBtn { icon: "power"; tint: Theme.critical
                             run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
                }
            }

            // Кнопка питания
            MouseArea {
                id: powerMa
                anchors.verticalCenter: parent.verticalCenter
                width: 22; height: 22
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onEntered: hideT.stop()
                onExited: if (root.open) hideT.restart()
                onClicked: (e) => {
                    if (e.button === Qt.RightButton) Quickshell.execDetached(["wlogout"])
                    else root.open = !root.open
                }
                Icon {
                    anchors.centerIn: parent
                    name: "power"
                    color: powerMa.containsMouse || root.open ? Theme.critical : Theme.muted
                }
            }
        }
    }
}
