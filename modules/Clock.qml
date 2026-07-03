// Часы HH:MM. Клик → календарь на месяц: сегодня подсвечено, колесо листает
// месяцы, клик по заголовку — назад к текущему.
import QtQuick
import QtQuick.Effects
import Quickshell
import "root:/"
import "root:/components"

Pill {
    id: root
    property bool popup: false
    accentColor: Theme.accent
    active: popup

    // Смещение отображаемого месяца относительно текущего (0 = сейчас)
    property int monthOff: 0
    readonly property var shown: {
        const n = new Date(clock.date)
        return new Date(n.getFullYear(), n.getMonth() + monthOff, 1)
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    onClicked: { popup = !popup; if (popup) monthOff = 0 }

    Icon { name: "clock"; color: Theme.muted }
    Text {
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    // Попап-календарь
    PopupWindow {
        id: pop
        visible: root.popup && root.panelWindow !== undefined
        color: "transparent"
        implicitWidth: card.width + 12
        implicitHeight: card.height + 14
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 8

        Rectangle {
            id: card
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadow
                shadowBlur: 1.0
                shadowVerticalOffset: 3
                autoPaddingEnabled: true
            }
            x: 6; y: 4
            width: 250
            height: col.implicitHeight + 24
            radius: 14
            color: Theme.surfaceHi
            border.width: 1
            border.color: Theme.border

            opacity: root.popup ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Theme.easeType } }
            transform: Translate {
                y: root.popup ? 0 : -6
                Behavior on y { NumberAnimation { duration: 160; easing.type: Theme.easeType } }
            }

            // Листание месяцев колесом
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: (e) => root.monthOff += (e.angleDelta.y > 0 ? -1 : 1)
            }

            Column {
                id: col
                anchors.centerIn: parent
                width: card.width - 24
                spacing: 8

                // Заголовок: месяц + год; клик — вернуться к текущему
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.shown.toLocaleDateString(Qt.locale("ru_RU"), "MMMM yyyy")
                    color: root.monthOff === 0 ? Theme.accent : Theme.text
                    font.family: Theme.font; font.pixelSize: Theme.fontSize + 1; font.bold: true
                    font.capitalization: Font.Capitalize
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.monthOff = 0
                    }
                }

                // Дни недели
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: ["пн","вт","ср","чт","пт","сб","вс"]
                        Text {
                            required property string modelData
                            width: 30; horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: Theme.muted
                            font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                        }
                    }
                }

                // Сетка дней
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 7
                    Repeater {
                        // Кол-во пустых ячеек до 1-го числа (пн-первый) + дни месяца
                        model: {
                            const first = (root.shown.getDay() + 6) % 7
                            const days = new Date(root.shown.getFullYear(), root.shown.getMonth() + 1, 0).getDate()
                            return first + days
                        }
                        delegate: Item {
                            required property int index
                            readonly property int first: (root.shown.getDay() + 6) % 7
                            readonly property int day: index - first + 1
                            readonly property bool isToday: {
                                const n = new Date(clock.date)
                                return root.monthOff === 0 && day === n.getDate()
                            }
                            width: 30; height: 26

                            Rectangle {
                                anchors.centerIn: parent
                                width: 26; height: 24; radius: 8
                                color: parent.isToday ? Theme.accentSoft : "transparent"
                                border.width: parent.isToday ? 1 : 0
                                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.parent.day > 0 ? parent.parent.day : ""
                                    color: parent.parent.isToday ? Theme.accent : Theme.text
                                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                                    font.bold: parent.parent.isToday
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
