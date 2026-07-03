// Кастомное стеклянное меню для элементов трея.
// Данные берём из родного DBus-меню (QsMenuOpener), вид — полностью наш:
// тёмное стекло, hover-подсветка, чекбоксы, сепараторы, подменю раскрываются инлайн.
import QtQuick
import Quickshell
import "root:/"

PopupWindow {
    id: root
    property var menuHandle          // SystemTrayItem.menu
    property Item anchorItem         // иконка, под которой открываемся
    property bool shown: false

    visible: shown
    onVisibleChanged: if (!visible) shown = false   // закрытие извне (потеря фокуса)
    grabFocus: true   // клик мимо меню — закрыть
    color: "transparent"

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 8

    implicitWidth: card.width + 24    // запас под тень
    implicitHeight: card.height + 24

    QsMenuOpener { id: opener; menu: root.menuHandle }

    // «Нарисованная» тень вместо MultiEffect: рисуется мгновенно, без компиляции
    // шейдера на первом открытии (из-за неё и был рывок стилей).
    Rectangle {
        x: card.x - 1; y: card.y + 2
        width: card.width + 2; height: card.height + 2
        radius: card.radius + 1
        color: Theme.shadow
        opacity: card.opacity * 0.6
    }

    Rectangle {
        id: card
        x: 12; y: 6
        width: 310
        height: list.implicitHeight + 12
        radius: 13
        color: Theme.surfaceHi
        border.width: 1
        border.color: Theme.border

        // Появление: fade + мягкий слайд сверху (scale на свежем окне дёргается)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Theme.easeType } }
        transform: Translate {
            y: root.shown ? 0 : -6
            Behavior on y { NumberAnimation { duration: 160; easing.type: Theme.easeType } }
        }

        Column {
            id: list
            anchors.centerIn: parent
            width: card.width - 12

            Repeater {
                model: opener.children
                delegate: MenuItemView {
                    required property var modelData
                    entry: modelData
                    menuRoot: root
                    width: list.width
                }
            }
        }
    }

    // Один пункт меню (+ инлайн-подменю при раскрытии)
    component MenuItemView: Column {
        id: item
        property var entry
        property var menuRoot
        property bool expanded: false

        // Сепаратор
        Rectangle {
            visible: item.entry.isSeparator
            width: parent.width - 16; height: 1
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.border
        }
        Item { visible: item.entry.isSeparator; width: 1; height: 5 }

        // Обычный пункт
        Rectangle {
            visible: !item.entry.isSeparator
            width: parent.width
            height: 32
            radius: 8
            color: mia.containsMouse && item.entry.enabled ? Theme.accentSoft : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.fast } }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                spacing: 8

                // Чекбокс / радио
                Text {
                    visible: item.entry.buttonType !== 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: item.entry.checkState === Qt.Checked ? "󰄲" : "󰄱"
                    color: item.entry.checkState === Qt.Checked ? Theme.accent : Theme.muted
                    font.family: Theme.font; font.pixelSize: Theme.iconSize
                }
                // Иконка пункта (если есть)
                Image {
                    visible: item.entry.icon !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    source: item.entry.icon
                    sourceSize.width: 16; sourceSize.height: 16
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - (item.entry.hasChildren ? 26 : 0)
                            - (item.entry.buttonType !== 0 ? 26 : 0)
                            - (item.entry.icon !== "" ? 24 : 0)
                    text: item.entry.text.replace(/_/g, "")
                    color: item.entry.enabled ? Theme.text : Theme.muted
                    font.family: Theme.font; font.pixelSize: Theme.fontSize
                    elide: Text.ElideRight
                }
            }
            // Стрелка подменю
            Text {
                visible: item.entry.hasChildren
                anchors.right: parent.right; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: item.expanded ? "󰅃" : "󰅂"
                color: Theme.muted
                font.family: Theme.font; font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: mia
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: item.entry.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (!item.entry.enabled) return
                    if (item.entry.hasChildren) item.expanded = !item.expanded
                    else { item.entry.triggered(); item.menuRoot.shown = false }
                }
            }
        }

        // Инлайн-подменю (один уровень; раскрытие вниз, с отступом)
        Column {
            visible: item.expanded && item.entry.hasChildren
            width: parent.width
            leftPadding: 14

            QsMenuOpener { id: subOpener; menu: item.expanded ? item.entry : null }
            Repeater {
                model: subOpener.children
                delegate: SubItemView {
                    required property var modelData
                    entry: modelData
                    menuRoot: item.menuRoot
                    width: item.width - 14
                }
            }
        }
    }

    // Пункт подменю (без дальнейшей вложенности)
    component SubItemView: Rectangle {
        id: sub
        property var entry
        property var menuRoot
        height: entry.isSeparator ? 7 : 30
        radius: 8
        color: sma.containsMouse && entry.enabled && !entry.isSeparator ? Theme.accentSoft : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }

        Rectangle {
            visible: sub.entry.isSeparator
            anchors.centerIn: parent
            width: parent.width - 16; height: 1
            color: Theme.border
        }
        Row {
            visible: !sub.entry.isSeparator
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left; anchors.leftMargin: 10
            anchors.right: parent.right; anchors.rightMargin: 10
            spacing: 8
            Text {
                visible: sub.entry.buttonType !== 0
                anchors.verticalCenter: parent.verticalCenter
                text: sub.entry.checkState === Qt.Checked ? "󰄲" : "󰄱"
                color: sub.entry.checkState === Qt.Checked ? Theme.accent : Theme.muted
                font.family: Theme.font; font.pixelSize: Theme.iconSize
            }
            Image {
                visible: sub.entry.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                source: sub.entry.icon
                sourceSize.width: 16; sourceSize.height: 16
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - (sub.entry.buttonType !== 0 ? 26 : 0)
                        - (sub.entry.icon !== "" ? 24 : 0)
                text: sub.entry.text.replace(/_/g, "")
                color: sub.entry.enabled ? Theme.text : Theme.muted
                font.family: Theme.font; font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }
        }
        MouseArea {
            id: sma
            anchors.fill: parent
            hoverEnabled: true
            enabled: !sub.entry.isSeparator
            cursorShape: sub.entry.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (sub.entry.enabled) { sub.entry.triggered(); sub.menuRoot.shown = false }
        }
    }
}
