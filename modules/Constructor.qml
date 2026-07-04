// Конструктор панели: клик — попап, где меняешь состав панели без кода.
// По зонам (Лево/Центр/Право) — активные модули с ‹ › (порядок) и × (убрать).
// Снизу — доступные модули с кнопками Л/Ц/П (добавить в зону). Всё в BarConfig.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/components"

Pill {
    id: root
    property bool popup: false
    active: popup
    tooltip: "Конструктор панели"

    onClicked: popup = !popup

    Icon { name: "sliders"; color: root.popup ? Theme.accent : Theme.muted }

    // Esc откуда угодно закрывает — единая логика попапов
    onPopupChanged: root.popup ? EscClose.acquire() : EscClose.release()
    Connections { target: EscClose; function onPressed() { root.popup = false } }

    PanelWindow {
        id: pop
        visible: root.popup && root.panelWindow !== undefined
        screen: root.panelWindow ? root.panelWindow.screen : null
        color: "transparent"

        WlrLayershell.namespace: "quickshell:constructor"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0

        anchors { top: true; right: true }
        margins { top: Theme.barMarginTop + Theme.barHeight + 4; right: Theme.barMargin }
        implicitWidth: card.width + 24
        implicitHeight: card.height + 20
        mask: Region { item: card }

        Rectangle {
            id: card
            x: 12; y: 4
            width: 470
            height: col.implicitHeight + 28
            radius: 14
            color: Theme.surfaceHi
            border.width: 1
            border.color: Theme.border
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true; shadowColor: Theme.shadow
                shadowBlur: 1.0; shadowVerticalOffset: 3; autoPaddingEnabled: true
            }

            opacity: root.popup ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
            transform: Translate {
                y: root.popup ? 0 : -6
                Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
            }

            // — Чип активного модуля: ‹ имя › × —
            component ActiveChip: Rectangle {
                property string mid
                implicitHeight: 26
                implicitWidth: chipRow.implicitWidth + 12
                radius: 8
                color: Qt.rgba(143/255, 183/255, 232/255, 0.14)
                border.width: 1
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 5
                    MouseArea {
                        width: 14; height: 20; anchors.verticalCenter: parent.verticalCenter
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BarConfig.shift(parent.parent.mid, -1)
                        Text { anchors.centerIn: parent; text: "‹"; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize + 2 }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: BarConfig.names[parent.parent.mid] ?? parent.parent.mid
                        color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                    }
                    MouseArea {
                        width: 14; height: 20; anchors.verticalCenter: parent.verticalCenter
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BarConfig.shift(parent.parent.mid, 1)
                        Text { anchors.centerIn: parent; text: "›"; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize + 2 }
                    }
                    // × убрать (конструктор не даём удалить — иначе не вернуть)
                    MouseArea {
                        width: 16; height: 20; anchors.verticalCenter: parent.verticalCenter
                        visible: parent.parent.mid !== "settings"
                        cursorShape: Qt.PointingHandCursor
                        onClicked: BarConfig.remove(parent.parent.mid)
                        Icon { anchors.centerIn: parent; name: "close"; color: Theme.critical; implicitWidth: 11; implicitHeight: 11 }
                    }
                }
            }

            // — Строка зоны: подпись + чипы —
            component ZoneRow: RowLayout {
                property string label
                property var ids
                Layout.fillWidth: true
                spacing: 8
                Text {
                    Layout.preferredWidth: 44
                    text: parent.label; color: Theme.muted
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: parent.parent.ids
                        delegate: ActiveChip { required property var modelData; mid: modelData }
                    }
                }
            }

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 10

                Text { text: "Конструктор панели"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                ZoneRow { label: "Лево";   ids: BarConfig.left }
                ZoneRow { label: "Центр";  ids: BarConfig.center }
                ZoneRow { label: "Право";  ids: BarConfig.right }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                Text {
                    text: BarConfig.available.length > 0 ? "Доступные — добавить в зону:" : "Все модули на панели"
                    color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: BarConfig.available
                        delegate: Rectangle {
                            required property var modelData
                            implicitHeight: 26
                            implicitWidth: availRow.implicitWidth + 12
                            radius: 8
                            color: Qt.rgba(221/255, 228/255, 236/255, 0.05)
                            border.width: 1; border.color: Theme.border

                            Row {
                                id: availRow
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: BarConfig.names[parent.parent.modelData] ?? parent.parent.modelData
                                    color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                                }
                                // Кнопки зоны: Л / Ц / П
                                Repeater {
                                    model: [["Л", "left"], ["Ц", "center"], ["П", "right"]]
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: 18; height: 20; radius: 5
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: zma.containsMouse ? Theme.accentSoft : "transparent"
                                        Text {
                                            anchors.centerIn: parent; text: parent.modelData[0]
                                            color: zma.containsMouse ? Theme.accent : Theme.muted
                                            font.family: Theme.font; font.pixelSize: Theme.fontSize - 2; font.bold: true
                                        }
                                        MouseArea {
                                            id: zma; anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: BarConfig.add(availRow.parent.modelData, parent.modelData[1])
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "‹ › — порядок · × — убрать · Esc — закрыть"
                    color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                }
            }
        }
    }
}
