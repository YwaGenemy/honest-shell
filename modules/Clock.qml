// Часы HH:MM. Клик → попап с полной датой (русская локаль), с плавным появлением.
import QtQuick
import Quickshell
import "root:/"
import "root:/components"

Pill {
    id: root
    property bool popup: false
    accentColor: Theme.accent
    active: popup

    SystemClock { id: clock; precision: SystemClock.Minutes }

    onClicked: popup = !popup

    Text {
        text: "󰥔"                      // clock glyph
        color: Theme.muted
        font.family: Theme.font
        font.pixelSize: Theme.iconSize
    }
    Text {
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    // Попап с датой
    PopupWindow {
        id: pop
        visible: root.popup && root.panelWindow !== undefined
        color: "transparent"
        implicitWidth: card.width + 12    // запас под тень и слайд
        implicitHeight: card.height + 14
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 8

        // Нарисованная тень (мгновенная, без шейдеров — не дёргает первый кадр)
        Rectangle {
            x: card.x - 1; y: card.y + 2
            width: card.width + 2; height: card.height + 2
            radius: card.radius + 1
            color: Theme.shadow
            opacity: card.opacity * 0.6
        }

        Rectangle {
            id: card
            x: 6; y: 4
            width: 240; height: 96
            radius: 14
            color: Theme.surfaceHi
            border.width: 1
            border.color: Theme.border

            // появление: fade + мягкий слайд (без scale — он рвётся на свежем окне)
            opacity: root.popup ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Theme.easeType } }
            transform: Translate {
                y: root.popup ? 0 : -6
                Behavior on y { NumberAnimation { duration: 160; easing.type: Theme.easeType } }
            }

            Column {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clock.date.toLocaleDateString(Qt.locale("ru_RU"), "dddd")
                    color: Theme.accent
                    font.family: Theme.font; font.pixelSize: Theme.fontSize + 1
                    font.capitalization: Font.Capitalize
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: clock.date.toLocaleDateString(Qt.locale("ru_RU"), "d MMMM yyyy")
                    color: Theme.text
                    font.family: Theme.font; font.pixelSize: Theme.fontSize + 4; font.bold: true
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Theme.muted
                    font.family: Theme.font; font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}
