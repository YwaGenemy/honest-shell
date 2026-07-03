// Единое морфящее окно попапов (паттерн caelestia, упрощённый).
// Одно PopupWindow на всю ширину панели; внутри — карточка, которая анимированно
// меняет x/размер и перетекает между содержимым (громкость/батарея/медиа).
// Клики мимо карточки проходят насквозь (mask), hover на карточке держит её открытой.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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
    // Порядок морфа: погасить старый контент → карточка ПУСТОЙ доезжает и меняет
    // размер → новый контент проявляется уже на финальном месте. Если проявлять
    // во время движения, выглядит как «спавн мимо + доравнивание».
    SequentialAnimation {
        id: swapAnim
        NumberAnimation { target: cload; property: "opacity"; to: 0; duration: 70; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects }
        ScriptAction { script: win.shownName = Popouts.name }
        PauseAnimation { duration: Theme.decelDur - 60 }   // карточка едет пустой
        NumberAnimation { target: cload; property: "opacity"; to: 1; duration: 140; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects }
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
        // Морф: без перелёта (decel) — иначе карточка «доравнивается» после прыжка
        Behavior on x      { enabled: Popouts.shown; NumberAnimation { duration: Theme.decelDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decel } }
        Behavior on width  { enabled: Popouts.shown; NumberAnimation { duration: Theme.decelDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decel } }
        Behavior on height { enabled: Popouts.shown; NumberAnimation { duration: Theme.decelDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decel } }
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
                           : win.shownName === "media" ? mediaC
                           : win.shownName === "cpu" ? cpuC
                           : win.shownName === "gpu" ? gpuC
                           : win.shownName === "net" ? netC : null
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

            // Слайдер (высокая зона клика — легко попасть)
            Item {
                id: slider
                Layout.fillWidth: true
                height: 26
                Rectangle {   // дорожка
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 5; radius: 2.5
                    color: Qt.rgba(221/255, 228/255, 236/255, 0.15)
                }
                Rectangle {   // заполнение
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * Math.min(1, vol); height: 5; radius: 2.5
                    color: Theme.sound
                }
                Rectangle {   // ручка
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.min(1, vol) * (parent.width - width)
                    width: 15; height: 15; radius: 7.5
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

    // ── CPU ──
    Component {
        id: cpuC
        ColumnLayout {
            property string la: "…"
            property string cores: ""
            spacing: 6
            implicitWidth: 205

            Process { id: laP; command: ["cat", "/proc/loadavg"]
                stdout: StdioCollector { onStreamFinished: la = ("" + text).trim().split(" ").slice(0, 3).join("  ·  ") } }
            Process { id: ncP; command: ["nproc"]
                stdout: StdioCollector { onStreamFinished: cores = ("" + text).trim() } }
            Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: { laP.running = true; if (cores === "") ncP.running = true } }

            Text { text: "Процессор"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true }
            Text { text: "Load: " + la; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
            Text { text: "Ядер: " + (cores || "…"); color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
        }
    }

    // ── GPU ──
    Component {
        id: gpuC
        ColumnLayout {
            property int temp: 0
            property int busy: 0
            spacing: 6
            implicitWidth: 205

            Process { id: tP; command: ["sh", "-c", "cat /sys/devices/pci0000:00/0000:00:08.1/0000:03:00.0/hwmon/hwmon*/temp1_input"]
                stdout: StdioCollector { onStreamFinished: { const v = parseInt(("" + text).trim()); if (!isNaN(v)) temp = Math.round(v / 1000) } } }
            Process { id: bP; command: ["sh", "-c", "cat /sys/devices/pci0000:00/0000:00:08.1/0000:03:00.0/gpu_busy_percent 2>/dev/null || echo -1"]
                stdout: StdioCollector { onStreamFinished: { const v = parseInt(("" + text).trim()); if (!isNaN(v)) busy = v } } }
            Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: { tP.running = true; bP.running = true } }

            Text { text: "Видеокарта (amdgpu)"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true }
            Text { text: "Температура: " + temp + "°C"; color: temp >= 70 ? Theme.warning : Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
            Text { visible: busy >= 0; text: "Загрузка: " + busy + "%"; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
        }
    }

    // ── Сеть ──
    Component {
        id: netC
        ColumnLayout {
            property string iface: "…"
            property string totals: "…"
            spacing: 6
            implicitWidth: 230

            Process { id: iP; command: ["sh", "-c", "ip -o -4 route get 1.1.1.1 2>/dev/null | awk '{print $5\"  ·  \"$7}'"]
                stdout: StdioCollector { onStreamFinished: iface = ("" + text).trim() || "нет соединения" } }
            Process { id: tP2; command: ["sh", "-c", "awk -F'[: ]+' 'NR>2 && $2!=\"lo\" {rx+=$3; tx+=$11} END {printf \"%.1f GB  ↑ %.1f GB\", rx/1073741824, tx/1073741824}' /proc/net/dev"]
                stdout: StdioCollector { onStreamFinished: totals = ("" + text).trim() } }
            Component.onCompleted: { iP.running = true; tP2.running = true }

            Text { text: "Сеть"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true }
            Text { text: iface; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
            Text { text: "С загрузки: ↓ " + totals; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
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

            // ВАЖНО: все строки всегда занимают место (opacity вместо visible),
            // иначе при смене трека карточка меняет высоту, курсор оказывается
            // за её пределами и попап закрывается.
            Text {
                Layout.fillWidth: true
                text: pl ? (pl.trackTitle || "Без названия") : "Ничего не играет"
                color: Theme.text; elide: Text.ElideRight
                font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true
            }
            Text {
                Layout.fillWidth: true
                text: (pl ? (pl.trackArtist || "") : "") || " "
                color: Theme.muted; elide: Text.ElideRight
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
            }

            // Прогресс
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                opacity: pl && (pl.length ?? 0) > 0 ? 1 : 0.25
                Text { text: fmt(pos); color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
                Item {
                    Layout.fillWidth: true; height: 4
                    Rectangle { anchors.fill: parent; radius: 2; color: Qt.rgba(221/255, 228/255, 236/255, 0.15) }
                    Rectangle {
                        width: parent.width * (pl && (pl.length ?? 0) > 0 ? Math.min(1, pos / pl.length) : 0)
                        height: parent.height; radius: 2; color: Theme.accent
                    }
                }
                Text { text: pl && (pl.length ?? 0) > 0 ? fmt(pl.length) : "-:--"; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 2 }
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
