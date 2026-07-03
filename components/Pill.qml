// Базовый «модуль-пилюля»: стеклянная поверхность, hover-подсветка, лёгкий подъём,
// мягкая тень, состояние active (акцентный фон) и встроенный тултип снизу.
// Контент (иконки/текст) кладётся детьми — они лягут в центрированный ряд.
//
// ВАЖНО про структуру: default-свойство перенаправлено в row.data, поэтому каркас
// (фон, зона клика, тултип) вынесен в ИМЕНОВАННЫЕ свойства с явным parent — иначе
// эти элементы попали бы внутрь контент-ряда.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "root:/"

Item {
    id: root

    // Публичное API
    property var    panelWindow                 // окно панели — нужно для тултипа
    property bool   active: false               // активное состояние → акцентный фон
    property color  accentColor: Theme.accent   // цвет рамки/подсветки в active
    property string tooltip: ""                 // текст тултипа (пусто = нет)
    property real   hpad: Theme.pillPadH
    property alias  hovered: ma.containsMouse

    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal wheel(int delta)                     // delta>0 — вверх/от себя

    // Контент субклассов уходит СЮДА (в центрированный ряд)
    default property alias content: row.data

    implicitWidth:  row.implicitWidth + hpad * 2
    implicitHeight: Theme.pillHeight

    // Лёгкий «подъём» на hover
    scale: ma.containsMouse ? 1.035 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Theme.easeType } }

    // — Каркас (именованные свойства, чтобы не попасть в content) —

    // Стеклянная поверхность + мягкая тень
    readonly property Rectangle _bg: Rectangle {
        id: bg
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        z: 0
        radius: Theme.pillRadius
        color: root.active ? Theme.accentSoft
                           : (ma.containsMouse ? Theme.surfaceHi : Theme.surface)
        border.width: 1
        border.color: root.active ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)
                                   : (ma.containsMouse ? Theme.borderHi : Theme.border)
        Behavior on color        { ColorAnimation { duration: Theme.med; easing.type: Theme.easeType } }
        Behavior on border.color { ColorAnimation { duration: Theme.med; easing.type: Theme.easeType } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 2
            autoPaddingEnabled: true
        }
    }

    // Контейнер контента
    readonly property RowLayout _row: RowLayout {
        id: row
        parent: root
        z: 1
        spacing: Theme.gap
        x: (root.width - width) / 2
        y: (root.height - height) / 2
    }

    // Зона ввода (поверх всего)
    readonly property MouseArea _ma: MouseArea {
        id: ma
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        z: 2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (e) => {
            // Клик отменяет тултип — иначе он всплывает поверх открытого попапа
            tipTimer.stop(); root._showTip = false
            if (e.button === Qt.LeftButton) root.clicked()
            else if (e.button === Qt.RightButton) root.rightClicked()
            else if (e.button === Qt.MiddleButton) root.middleClicked()
        }
        onWheel: (e) => root.wheel(e.angleDelta.y)
    }

    // — Тултип —
    property bool _showTip: false
    readonly property Timer tipTimer: Timer {
        interval: 450
        onTriggered: root._showTip = true
    }
    onHoveredChanged: {
        if (hovered && tooltip.length > 0) tipTimer.restart()
        else { tipTimer.stop(); root._showTip = false }
    }

    readonly property PopupWindow tip: PopupWindow {
        visible: root._showTip && root.tooltip.length > 0 && root.panelWindow !== undefined
        color: "transparent"
        implicitWidth: tipBg.implicitWidth
        implicitHeight: tipBg.implicitHeight

        // Якорим попап прямо к пилюле: нижняя грань, рост вниз (штатный способ Quickshell 0.3)
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6

        Rectangle {
            id: tipBg
            implicitWidth: tipText.implicitWidth + 20
            implicitHeight: tipText.implicitHeight + 12
            radius: 9
            color: Theme.surfaceHi
            border.width: 1
            border.color: Theme.border
            Text {
                id: tipText
                anchors.centerIn: parent
                text: root.tooltip
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }
        }
    }
}
