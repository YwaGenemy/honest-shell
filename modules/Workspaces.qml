// Воркспейсы 1/2/3 (persistent). Клик — переход, скролл — сосед по кругу.
// Активный «перетекает» акцентной подсветкой (анимация ширины/цвета).
import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland
import "root:/"

Item {
    id: root
    property var panelWindow
    readonly property int count: 3
    readonly property int current: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    implicitWidth: bg.implicitWidth
    implicitHeight: Theme.pillHeight

    function goto(n) {
        const w = ((n - 1 + count) % count) + 1     // цикл 1..3
        Hyprland.dispatch("workspace " + w)
    }

    // Стеклянная подложка + мягкая тень
    Rectangle {
        id: bg
        anchors.fill: parent
        implicitWidth: roww.implicitWidth + 2 * 7   // компактнее обычной пилюли: цифры прижаты к краям
        radius: Theme.pillRadius
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 0.55
            shadowVerticalOffset: 3
            autoPaddingEnabled: true
        }
    }

    Row {
        id: roww
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: root.count
            delegate: Item {
                id: cell
                required property int index
                readonly property int wsId: index + 1
                readonly property bool isActive: root.current === wsId
                width: isActive ? 28 : 24
                height: 22
                anchors.verticalCenter: parent.verticalCenter
                Behavior on width { NumberAnimation { duration: Theme.med; easing.type: Theme.easeType } }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: cell.isActive ? Theme.accentSoft
                                         : (cellMa.containsMouse ? Theme.surfaceHi : "transparent")
                    border.width: cell.isActive ? 1 : 0
                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
                    Behavior on color { ColorAnimation { duration: Theme.med } }

                    Text {
                        anchors.centerIn: parent
                        text: cell.wsId
                        color: cell.isActive ? Theme.accent : Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.bold: cell.isActive
                        Behavior on color { ColorAnimation { duration: Theme.med } }
                    }
                }
                MouseArea {
                    id: cellMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goto(cell.wsId)
                }
            }
        }
    }

    // Скролл по всей области (работает поверх клик-зон)
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (e) => root.goto(root.current + (e.angleDelta.y > 0 ? -1 : 1))
    }
}
