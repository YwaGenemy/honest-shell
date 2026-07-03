// Единое морфящее окно попапов (паттерн caelestia, упрощённый).
// Одно PopupWindow на всю ширину панели; внутри — карточка, которая анимированно
// меняет x/размер и перетекает между содержимым (громкость/батарея/медиа).
// Клики мимо карточки проходят насквозь (mask), hover на карточке держит её открытой.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import "root:/"

PopupWindow {
    id: win
    required property Item barContent

    // Имя, которое сейчас отрисовано (отстаёт от Popouts.name на время кроссфейда)
    property string shownName: ""

    visible: Popouts.shown || card.opacity > 0.01
    color: "transparent"
    anchor.item: barContent
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 4
    implicitWidth: barContent.width
    implicitHeight: 300

    // Ввод — только по карточке
    mask: Region { item: card }

    // Кроссфейд контента при переключении между модулями
    Connections {
        target: Popouts
        function onNameChanged() {
            if (Popouts.name === "") return
            if (win.shownName === "") { win.shownName = Popouts.name; return }  // первое открытие — без фейда
            if (Popouts.name !== win.shownName) swapAnim.restart()
        }
    }
    SequentialAnimation {
        id: swapAnim
        NumberAnimation { target: cload; property: "opacity"; to: 0; duration: 90; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects }
        ScriptAction { script: win.shownName = Popouts.name }
        NumberAnimation { target: cload; property: "opacity"; to: 1; duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects }
    }

    // Нарисованная тень
    Rectangle {
        x: card.x - 1; y: card.y + 2
        width: card.width + 2; height: card.height + 2
        radius: card.radius + 1
        color: Theme.shadow
        opacity: card.opacity * 0.6
    }

    Rectangle {
        id: card
        readonly property real pad: 16
        width: (cload.item ? cload.item.implicitWidth : 200) + pad * 2
        height: (cload.item ? cload.item.implicitHeight : 60) + pad * 2
        x: Math.max(8, Math.min(Popouts.anchorX - width / 2, win.implicitWidth - width - 8))
        y: 0
        radius: 14
        color: Theme.surfaceHi
        border.width: 1
        border.color: Theme.border

        opacity: Popouts.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
        // Морф: позиция и размер перетекают
        Behavior on x      { enabled: Popouts.shown; NumberAnimation { duration: 340; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        Behavior on width  { enabled: Popouts.shown; NumberAnimation { duration: 340; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        Behavior on height { enabled: Popouts.shown; NumberAnimation { duration: 340; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
        transform: Translate {
            y: Popouts.shown ? 0 : -6
            Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
        }

        HoverHandler {
            onHoveredChanged: hovered ? Popouts.holdOpen() : Popouts.hoverLeave()
        }

        Loader {
            id: cload
            x: card.pad; y: card.pad
            sourceComponent: win.shownName === "volume" ? volumeC
                           : win.shownName === "battery" ? batteryC
                           : win.shownName === "media" ? mediaC : null
        }
    }

    // ── Громкость ──
    Component {
        id: volumeC
        ColumnLayout {
            readonly property var sink: Pipewire.defaultAudioSink
            readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
            spacing: 10
            implicitWidth: 230

            PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

            Text { text: "Громкость"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true }

            // Слайдер
            Item {
                id: slider
                Layout.fillWidth: true
                height: 16
                Rectangle {   // дорожка
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 4; radius: 2
                    color: Qt.rgba(221/255, 228/255, 236/255, 0.15)
                }
                Rectangle {   // заполнение
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * Math.min(1, vol); height: 4; radius: 2
                    color: Theme.sound
                }
                Rectangle {   // ручка
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.min(1, vol) * (parent.width - width)
                    width: 12; height: 12; radius: 6
                    color: Theme.text
                }
                MouseArea {
                    anchors.fill: parent
                    onPressed: (e) => setV(e.x)
                    onPositionChanged: (e) => { if (pressed) setV(e.x) }
                    function setV(px) {
                        if (!sink || !sink.audio) return
                        sink.audio.muted = false
                        sink.audio.volume = Math.max(0, Math.min(1, px / width))
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: sink ? (sink.description || sink.name || "") : ""
                    color: Theme.muted; elide: Text.ElideRight
                    font.family: Theme.font; font.pixelSize: Theme.fontSize - 2
                }
                Text {
                    text: Math.round(vol * 100) + "%"
                    color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
                }
            }
        }
    }

    // ── Батарея ──
    Component {
        id: batteryC
        ColumnLayout {
            readonly property var dev: UPower.displayDevice
            readonly property bool charging: dev && (dev.state === UPowerDeviceState.Charging
                                                     || dev.state === UPowerDeviceState.FullyCharged)
            readonly property int secs: dev ? Math.round(charging ? dev.timeToFull : dev.timeToEmpty) : 0
            spacing: 6
            implicitWidth: 215

            function fmtTime(s) {
                const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60)
                return h > 0 ? ("≈ " + h + " ч " + m + " м") : ("≈ " + m + " мин")
            }

            Text {
                text: "Батарея — " + (dev ? Math.round(dev.percentage * 100) : 0) + "%"
                color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true
            }
            Text {
                text: charging ? (dev && dev.state === UPowerDeviceState.FullyCharged ? "Заряжена полностью" : "Заряжается")
                               : "Разряжается"
                color: charging ? Theme.battery : Theme.muted
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            }
            Text {
                visible: secs > 60
                text: (charging ? "До полной: " : "Осталось: ") + fmtTime(secs)
                color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            }
            Text {
                visible: dev && (dev.changeRate ?? 0) > 0.1
                text: "Мощность: " + (dev ? dev.changeRate.toFixed(1) : 0) + " Вт"
                color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            }
        }
    }

    // ── Медиа (MPRIS) ──
    Component {
        id: mediaC
        ColumnLayout {
            readonly property var pl: {
                const list = Mpris.players.values
                return list.find(p => p.playbackState === MprisPlaybackState.Playing) ?? list[0] ?? null
            }
            property real pos: 0
            spacing: 8
            implicitWidth: 250

            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: pos = pl ? pl.position : 0
            }
            function fmt(s) {
                s = Math.max(0, Math.round(s))
                return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
            }

            Text {
                Layout.fillWidth: true
                text: pl ? (pl.trackTitle || "Без названия") : "Ничего не играет"
                color: Theme.text; elide: Text.ElideRight
                font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true
            }
            Text {
                Layout.fillWidth: true
                visible: pl && (pl.trackArtist || "") !== ""
                text: pl ? (pl.trackArtist || "") : ""
                color: Theme.muted; elide: Text.ElideRight
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            }

            // Прогресс
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: pl && (pl.length ?? 0) > 0
                Text { text: fmt(pos); color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                Item {
                    Layout.fillWidth: true; height: 4
                    Rectangle { anchors.fill: parent; radius: 2; color: Qt.rgba(221/255, 228/255, 236/255, 0.15) }
                    Rectangle {
                        width: parent.width * (pl && pl.length > 0 ? Math.min(1, pos / pl.length) : 0)
                        height: parent.height; radius: 2; color: Theme.accent
                    }
                }
                Text { text: pl ? fmt(pl.length) : ""; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
            }

            // Управление
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 18
                MouseArea {
                    width: 22; height: 22; cursorShape: Qt.PointingHandCursor
                    onClicked: if (pl) pl.previous()
                    Icon { anchors.centerIn: parent; name: "prev"; color: pl && pl.canGoPrevious ? Theme.text : Theme.muted }
                }
                MouseArea {
                    width: 26; height: 26; cursorShape: Qt.PointingHandCursor
                    onClicked: if (pl) pl.togglePlaying()
                    Icon {
                        anchors.centerIn: parent
                        name: pl && pl.playbackState === MprisPlaybackState.Playing ? "pause" : "play"
                        color: Theme.accent; width: 18; height: 18
                    }
                }
                MouseArea {
                    width: 22; height: 22; cursorShape: Qt.PointingHandCursor
                    onClicked: if (pl) pl.next()
                    Icon { anchors.centerIn: parent; name: "next"; color: pl && pl.canGoNext ? Theme.text : Theme.muted }
                }
            }
        }
    }
}
