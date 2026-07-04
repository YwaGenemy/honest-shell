// Буфер обмена (cliphist). Клик — попап с историей: текст и превью картинок.
// Клик по записи — вернуть в буфер и закрыть, ПКМ — удалить из истории.
// Удобно, когда снял несколько скриншотов подряд и надо достать нужный.
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import "root:/"
import "root:/components"

Pill {
    id: root
    property bool popup: false
    property bool showImages: true       // активная вкладка: картинки | текст
    active: popup
    tooltip: "Буфер обмена"

    onClicked: { popup = !popup; if (popup) Clipboard.refresh() }

    Icon { name: "clipboard"; color: root.popup ? Theme.accent : Theme.muted }

    PopupWindow {
        id: pop
        visible: root.popup && root.panelWindow !== undefined
        color: "transparent"
        grabFocus: true
        onVisibleChanged: if (!visible) root.popup = false   // клик мимо — закрыть
        implicitWidth: card.width + 24
        implicitHeight: card.height + 20
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 8

        Rectangle {
            id: card
            x: 12; y: 4
            width: 400
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

                // ── Картинки: крупная сетка 2-в-ряд ──
                GridView {
                    width: parent.width
                    visible: root.showImages
                    height: visible ? Math.min(Math.ceil(Math.max(Clipboard.images.length, 1) / 2) * 130, 470) : 0
                    clip: true
                    cellWidth: width / 2
                    cellHeight: 130
                    model: Clipboard.images
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Item {
                        id: imgCell
                        required property var modelData
                        width: GridView.view.cellWidth
                        height: GridView.view.cellHeight

                        Rectangle {
                            anchors.fill: parent; anchors.margins: 4
                            radius: 10
                            color: imgMa.containsMouse ? Theme.accentSoft : Qt.rgba(221/255, 228/255, 236/255, 0.05)
                            border.width: 1
                            border.color: imgMa.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : "transparent"

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
                            MouseArea {
                                id: imgMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (e) => {
                                    if (e.button === Qt.RightButton) Clipboard.remove(imgCell.modelData.id)
                                    else { Clipboard.copy(imgCell.modelData.id); root.popup = false }
                                }
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
                    width: parent.width
                    visible: !root.showImages
                    height: visible ? Math.min(Math.max(Clipboard.texts.length, 1) * 54, 470) : 0
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
                        color: itemMa.containsMouse ? Theme.accentSoft : Qt.rgba(221/255, 228/255, 236/255, 0.04)

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
                        MouseArea {
                            id: itemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (e) => {
                                if (e.button === Qt.RightButton) Clipboard.remove(clip.modelData.id)
                                else { Clipboard.copy(clip.modelData.id); root.popup = false }
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
