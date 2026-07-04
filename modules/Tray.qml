// System tray. Иконки появляются с лёгким fade+scale. ЛКМ/ПКМ — стеклянное меню (если есть), скролл — прокрутка.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import "root:/"
import "root:/components"

Item {
    id: root
    property var panelWindow

    // До полной инициализации (стартовое наполнение трея) анимации ширины выключены —
    // иначе панель «дёргается» вправо при запуске.
    property bool ready: false
    Timer { interval: 900; running: true; onTriggered: root.ready = true }

    // Счётчик обновляем по сигналу valuesChanged — биндинг на .values.length
    // не реактивен к асинхронному добавлению элементов трея (важно при чистом старте,
    // когда апплеты регистрируются уже ПОСЛЕ создания панели).
    property int count: 0
    function _sync() { count = SystemTray.items.values.length }
    Component.onCompleted: _sync()
    Connections { target: SystemTray.items; function onValuesChanged() { root._sync() } }
    // Подстраховка от гонки: апплеты трея иногда регистрируются позже, а сигнал
    // valuesChanged до live-инстанса не всегда долетает — синхронизируем и по таймеру.
    Timer { interval: 1500; running: true; repeat: true; onTriggered: root._sync() }

    visible: count > 0
    implicitWidth: visible ? bg.implicitWidth : 0
    implicitHeight: Theme.pillHeight
    Behavior on implicitWidth {
        enabled: root.ready
        NumberAnimation { duration: Theme.med; easing.type: Theme.easeType }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        implicitWidth: roww.implicitWidth + 2 * Theme.pillPadH
        radius: Theme.pillRadius
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowColor: Theme.shadow
            shadowBlur: 1.0; shadowVerticalOffset: 2; autoPaddingEnabled: true
        }
    }

    Row {
        id: roww
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: entry
                required property var modelData
                width: 18; height: 18
                anchors.verticalCenter: parent.verticalCenter

                // появление (после старта — мгновенно, без прыжка)
                opacity: 0; scale: 0.6
                Component.onCompleted: { opacity = 1; scale = 1 }
                Behavior on opacity { enabled: root.ready; NumberAnimation { duration: Theme.med } }
                Behavior on scale   { enabled: root.ready; NumberAnimation { duration: Theme.med; easing.type: Theme.easeType } }

                Image {
                    anchors.fill: parent
                    source: entry.modelData.icon
                    sourceSize.width: 18; sourceSize.height: 18
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: hov.containsMouse ? 1.0 : 0.85
                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                }

                MouseArea {
                    id: hov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: (e) => {
                        const m = entry.modelData
                        if (e.button === Qt.LeftButton) {
                            // Есть меню (Wi-Fi/BT/USB) — показываем его; иначе основное действие
                            if (m.hasMenu) menu.shown = !menu.shown
                            else m.activate()
                        } else if (e.button === Qt.MiddleButton) {
                            m.secondaryActivate()
                        } else if (e.button === Qt.RightButton && m.hasMenu) {
                            menu.shown = !menu.shown
                        }
                    }
                    onWheel: (e) => entry.modelData.scroll(e.angleDelta.y, false)
                }

                // Стеклянное меню в стиле панели
                TrayMenu {
                    id: menu
                    menuHandle: entry.modelData.menu
                    anchorItem: entry
                }
            }
        }
    }
}
