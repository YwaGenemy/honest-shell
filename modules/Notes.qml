// Заметки прямо в панели: клик — попап с полем ввода, автосохранение в файл.
// Без запуска nvim. Файл тот же, что раньше (waybar-notes.txt) — старые заметки на месте.
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "root:/"
import "root:/components"

Pill {
    id: root
    property bool popup: false
    active: popup
    tooltip: "Заметки"

    onClicked: popup = !popup

    Icon { name: "note"; color: root.popup ? Theme.accent : Theme.layout }

    // Файл заметок (совместим со старым скриптом — заметки не теряются)
    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/share/waybar-notes.txt"
        blockLoading: true          // text() возвращает содержимое сразу
        atomicWrites: true
    }
    // Автосохранение с задержкой, чтобы не писать на каждую букву
    Timer { id: saveT; interval: 500; onTriggered: file.setText(area.text) }

    // Esc откуда угодно закрывает — единая логика попапов
    Connections { target: EscClose; function onPressed() { root.popup = false } }
    onPopupChanged: {
        if (popup) {
            area.text = file.text()
            area.forceActiveFocus()
            EscClose.acquire()
        } else {
            file.setText(area.text)        // финальное сохранение
            EscClose.release()
        }
    }

    PanelWindow {
        id: pop
        visible: root.popup && root.panelWindow !== undefined
        screen: root.panelWindow ? root.panelWindow.screen : null
        color: "transparent"

        WlrLayershell.namespace: "quickshell:notes"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand   // нужен ввод текста
        exclusiveZone: 0

        // Под кнопкой заметок (правая зона) — прижато к правому краю
        anchors { top: true; right: true }
        margins {
            top: Theme.barMarginTop + Theme.barHeight + 4
            right: Theme.barMargin
        }
        implicitWidth: card.width + 24
        implicitHeight: card.height + 20

        mask: Region { item: card }

        Rectangle {
            id: card
            x: 12; y: 4
            width: 420
            height: 340
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

            Column {
                anchors { fill: parent; margins: 14 }
                spacing: 8

                // Шапка
                Item {
                    width: parent.width; height: 20
                    Text {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        text: "Заметки"; color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true
                    }
                    Text {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        text: saveT.running ? "сохраняю…" : "сохранено"
                        color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.border }

                // Поле ввода
                ScrollView {
                    width: parent.width
                    height: parent.height - 20 - 8 - 1 - 8 - 16 - 8
                    clip: true

                    TextArea {
                        id: area
                        wrapMode: TextArea.Wrap
                        selectByMouse: true
                        persistentSelection: true
                        placeholderText: "Пиши заметку… сохраняется само"
                        color: Theme.text
                        placeholderTextColor: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        background: null
                        onTextChanged: saveT.restart()
                        Keys.onEscapePressed: root.popup = false
                    }
                }

                Text {
                    width: parent.width
                    text: "Esc — закрыть · сохраняется автоматически"
                    color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                }
            }
        }
    }
}
