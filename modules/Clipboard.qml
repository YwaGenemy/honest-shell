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

                Rectangle { width: parent.width; height: 1; color: Theme.border }

                // Список истории
                ListView {
                    width: parent.width
                    height: Math.min(Math.max(Clipboard.entries.length, 1) * 54, 460)
                    clip: true
                    spacing: 5
                    model: Clipboard.entries
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
                            anchors.leftMargin: 9; anchors.rightMargin: 8
                            spacing: 11

                            // Превью: картинка или иконка типа
                            Item {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 60; height: 40
                                Image {
                                    visible: clip.modelData.isImage
                                    anchors.fill: parent
                                    source: clip.modelData.thumb
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true; cache: false
                                }
                                Icon {
                                    visible: !clip.modelData.isImage
                                    anchors.centerIn: parent; name: "note"
                                    color: Theme.muted; implicitWidth: 18; implicitHeight: 18
                                }
                            }

                            // Текст / описание картинки
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 60 - 11 - 8
                                text: clip.modelData.isImage
                                      ? ("Картинка  " + clip.modelData.dims)
                                      : clip.modelData.text
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
                                if (e.button === Qt.RightButton) {
                                    Clipboard.remove(clip.modelData.id)
                                } else {
                                    Clipboard.copy(clip.modelData.id)
                                    root.popup = false
                                }
                            }
                        }
                    }

                    // Пусто
                    Text {
                        anchors.centerIn: parent
                        visible: Clipboard.entries.length === 0
                        text: "история пуста"
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
