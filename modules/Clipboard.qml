// Буфер обмена (cliphist). Клик — попап с историей: текст и превью картинок.
// Клик по записи — вернуть в буфер и закрыть, ПКМ — удалить из истории.
// Удобно, когда снял несколько скриншотов подряд и надо достать нужный.
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "root:/"
import "root:/components"

Pill {
    id: root
    property bool popup: false
    property bool showImages: true       // активная вкладка: картинки | текст
    active: popup
    tooltip: "Буфер обмена"

    onClicked: { popup = !popup; if (popup) Clipboard.refresh() }
    // Пока попап открыт — буфер обновляется на лету (новые скриншоты появляются сразу)
    Binding { target: Clipboard; property: "live"; value: root.popup }

    // Esc откуда угодно закрывает (мышь свободна) — единая логика для всех попапов
    onPopupChanged: root.popup ? EscClose.acquire() : EscClose.release()
    Connections { target: EscClose; function onPressed() { root.popup = false } }

    // Подскок масштаба во время вспышки (множится со scale пилюли из Pill)
    property real flashScale: 1.0
    transform: Scale {
        origin.x: root.width / 2; origin.y: root.height / 2
        xScale: root.flashScale; yScale: root.flashScale
    }

    Icon { name: "clipboard"
           color: root.popup || flashOverlay.opacity > 0.15 ? (flashOverlay.opacity > 0.15 ? "#0b0d11" : Theme.accent) : Theme.muted }

    // Расходящееся кольцо-«всплеск» позади пилюли — видно даже краем глаза.
    Rectangle {
        id: ring
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        radius: Theme.pillRadius
        color: "transparent"
        border.width: 2
        border.color: Theme.accent
        opacity: 0
        z: 9
        transform: Scale {
            origin.x: ring.width / 2; origin.y: ring.height / 2
            xScale: ring.sc; yScale: ring.sc
        }
        property real sc: 1.0
    }

    // Яркая вспышка-заливка поверх пилюли (сигнал Clipboard.flashed).
    Rectangle {
        id: flashOverlay
        parent: root
        x: 0; y: 0
        width: root.width; height: root.height
        radius: Theme.pillRadius
        opacity: 0
        z: 10
        // Живой градиент: голубой → белый → сиреневый (в тон акценту и раскладке)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#8fb7e8" }   // Theme.accent
            GradientStop { position: 0.5; color: "#eef4ff" }   // почти белый
            GradientStop { position: 1.0; color: "#d3b8f5" }   // Theme.layout
        }

        Connections {
            target: Clipboard
            function onFlashed() { flashAnim.restart(); ringAnim.restart() }
        }

        // Один мощный всплеск: резкий вход + сильный подскок + плавное затухание
        SequentialAnimation {
            id: flashAnim
            ParallelAnimation {
                NumberAnimation { target: flashOverlay; property: "opacity"; to: 1.0; duration: 45; easing.type: Easing.OutCubic }
                NumberAnimation { target: root; property: "flashScale"; to: 1.42; duration: 150; easing.type: Easing.OutBack }
            }
            ParallelAnimation {
                NumberAnimation { target: flashOverlay; property: "opacity"; to: 0.0; duration: 560; easing.type: Easing.OutCubic }
                NumberAnimation { target: root; property: "flashScale"; to: 1.0; duration: 440; easing.type: Easing.OutCubic }
            }
        }

        // Кольцо: разрастается и гаснет
        SequentialAnimation {
            id: ringAnim
            ScriptAction { script: { ring.sc = 1.0; ring.opacity = 0.9 } }
            ParallelAnimation {
                NumberAnimation { target: ring; property: "sc";      to: 2.1; duration: 520; easing.type: Easing.OutCubic }
                NumberAnimation { target: ring; property: "opacity"; to: 0.0; duration: 520; easing.type: Easing.OutCubic }
            }
        }
    }

    // Слой-окно вместо PopupWindow: keyboardFocus OnDemand + маска на карточку —
    // клики мимо карточки проходят в окна под ней (дисплей не блокируется),
    // клавиатура достаётся попапу, Esc закрывает. Клик снаружи НЕ закрывает.
    PanelWindow {
        id: pop
        visible: root.popup && root.panelWindow !== undefined
        screen: root.panelWindow ? root.panelWindow.screen : null
        color: "transparent"

        WlrLayershell.namespace: "quickshell:clipboard"
        WlrLayershell.layer: WlrLayer.Overlay
        // None — попап не трогает клавиатуру/мышь глобально; ввод только по маске
        // (карточка). Esc обрабатывается через временный глобальный бинд (см. выше).
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0

        // Только top → компоновщик центрирует по горизонтали (под воркспейсами)
        anchors { top: true }
        margins { top: 4 }
        implicitWidth: card.width + 24
        implicitHeight: card.height + 20

        // Ввод — только по карточке; остальное прозрачно для окон под попапом
        mask: Region { item: card }

        Rectangle {
            id: card
            x: 12; y: 4
            width: 760
            height: col.implicitHeight + 20
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
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 8

                // Шапка
                Item {
                    width: parent.width; height: 20
                    Text {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        text: "Буфер обмена"; color: Theme.text
                        font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true
                    }
                    Text {
                        anchors.right: clearBtn.left; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                        text: Clipboard.entries.length + " записей"
                        color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                    }
                    MouseArea {
                        id: clearBtn
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 20; height: 20; cursorShape: Qt.PointingHandCursor
                        onClicked: Clipboard.clearAll()
                        Icon { anchors.centerIn: parent; name: "trash"
                               color: clearBtn.containsMouse ? Theme.critical : Theme.muted
                               implicitWidth: 15; implicitHeight: 15 }
                    }
                }

                // Вкладки: Картинки | Текст
                Row {
                    width: parent.width
                    spacing: 8

                    component Tab: Rectangle {
                        property string label
                        property bool on: false
                        signal picked()
                        implicitWidth: tabT.implicitWidth + 20
                        implicitHeight: 24
                        radius: 8
                        color: on ? Theme.accentSoft : Qt.rgba(221/255, 228/255, 236/255, 0.05)
                        border.width: 1
                        border.color: on ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                        Text {
                            id: tabT; anchors.centerIn: parent; text: parent.label
                            color: parent.on ? Theme.accent : Theme.muted
                            font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.bold: parent.on
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.picked() }
                    }

                    Tab { label: "Картинки " + Clipboard.images.length; on: root.showImages;  onPicked: root.showImages = true }
                    Tab { label: "Текст " + Clipboard.texts.length;     on: !root.showImages; onPicked: root.showImages = false }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.border }

                // ── Картинки: широкая сетка 4-в-ряд ──
                GridView {
                    id: imgGrid
                    width: parent.width
                    visible: root.showImages
                    height: visible ? Math.min(Math.ceil(Math.max(Clipboard.images.length, 1) / 4) * 138, 300) : 0
                    clip: true
                    cellWidth: width / 4
                    cellHeight: 138
                    model: Clipboard.images
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Item {
                        id: imgCell
                        required property var modelData
                        width: GridView.view.cellWidth
                        height: GridView.view.cellHeight

                        // Перетаскивание картинки как файла в другие приложения
                        Drag.active: imgDrag.active
                        Drag.dragType: Drag.Automatic
                        Drag.supportedActions: Qt.CopyAction
                        Drag.mimeData: ({ "text/uri-list": imgCell.modelData.thumb + "\r\n" })
                        Drag.imageSource: imgCell.modelData.thumb

                        Rectangle {
                            anchors.fill: parent; anchors.margins: 4
                            radius: 10
                            color: imgHover.hovered ? Theme.accentSoft : Qt.rgba(221/255, 228/255, 236/255, 0.05)
                            border.width: 1
                            border.color: imgHover.hovered ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : "transparent"

                            Image {
                                anchors.fill: parent; anchors.margins: 6; anchors.bottomMargin: 20
                                source: imgCell.modelData.thumb
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true; cache: false
                                smooth: true
                            }
                            Text {
                                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 5
                                text: imgCell.modelData.dims
                                color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                            }
                        }

                        HoverHandler { id: imgHover; cursorShape: Qt.PointingHandCursor }
                        DragHandler { id: imgDrag; target: null; grabPermissions: PointerHandler.CanTakeOverFromAnything }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            // копирование не закрывает попап — только Esc/повторный клик
                            onSingleTapped: (ev, btn) => {
                                if (btn === Qt.RightButton) Clipboard.remove(imgCell.modelData.id)
                                else Clipboard.copy(imgCell.modelData.id)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: Clipboard.images.length === 0
                        text: "картинок нет"
                        color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                    }
                }

                // ── Текст: список ──
                ListView {
                    id: txtList
                    width: parent.width
                    visible: !root.showImages
                    height: visible ? Math.min(Math.max(Clipboard.texts.length, 1) * 54, 300) : 0
                    clip: true
                    spacing: 5
                    model: Clipboard.texts
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle {
                        id: clip
                        required property var modelData
                        width: ListView.view.width
                        height: 49
                        radius: 10
                        color: txtHover.hovered ? Theme.accentSoft : Qt.rgba(221/255, 228/255, 236/255, 0.04)

                        // Перетаскивание текста в другие приложения
                        Drag.active: txtDrag.active
                        Drag.dragType: Drag.Automatic
                        Drag.supportedActions: Qt.CopyAction
                        Drag.mimeData: ({ "text/plain": clip.modelData.text })

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 11; anchors.rightMargin: 8
                            spacing: 11
                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: "note"; color: Theme.muted; implicitWidth: 16; implicitHeight: 16
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 16 - 11 - 8
                                text: clip.modelData.text
                                color: Theme.text
                                font.family: Theme.font; font.pixelSize: Theme.fontSize
                                elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap
                            }
                        }

                        HoverHandler { id: txtHover; cursorShape: Qt.PointingHandCursor }
                        DragHandler { id: txtDrag; target: null; grabPermissions: PointerHandler.CanTakeOverFromAnything }
                        TapHandler {
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            // копирование не закрывает попап — только Esc/повторный клик
                            onSingleTapped: (ev, btn) => {
                                if (btn === Qt.RightButton) Clipboard.remove(clip.modelData.id)
                                else Clipboard.copy(clip.modelData.id)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: Clipboard.texts.length === 0
                        text: "текста нет"
                        color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                    }
                }

                Text {
                    width: parent.width
                    text: "клик — вернуть в буфер · ПКМ — удалить"
                    color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
                }
            }
        }
    }
}
