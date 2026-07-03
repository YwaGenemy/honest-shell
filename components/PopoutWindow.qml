// Единое морфящее окно попапов (паттерн caelestia, упрощённый).
// Одно PopupWindow на всю ширину панели; внутри — карточка, которая анимированно
// меняет x/размер и перетекает между содержимым (громкость/батарея/медиа).
// Клики мимо карточки проходят насквозь (mask), hover на карточке держит её открытой.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import "root:/"

PopupWindow {
    id: win
    required property Item barContent

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

    // ── Морф без Behavior-ов ──
    // x зависит от width; если геометрию анимировать Behavior-ами, цель x
    // пересчитывается каждый кадр движения width и анимация перезапускается
    // 60 раз/с — получается «прыжок + доравнивание». Поэтому: новый контент
    // грузится в скрытый Loader, его размер известен сразу, и карточка едет
    // к финальным значениям ОДНОЙ ParallelAnimation с кроссфейдом.
    property bool useA: true

    function compFor(n) {
        return n === "volume" ? volumeC
             : n === "battery" ? batteryC
             : n === "media" ? mediaC
             : n === "cpu" ? cpuC
             : n === "gpu" ? gpuC
             : n === "net" ? netC : null
    }

    function morph() {
        const nm = Popouts.name
        if (nm === "") return
        const incoming = useA ? lb : la      // скрытый лоадер
        const outgoing = useA ? la : lb
        incoming.sourceComponent = compFor(nm)
        const w = (incoming.item ? incoming.item.implicitWidth : 200) + card.pad * 2
        const h = (incoming.item ? incoming.item.implicitHeight : 60) + card.pad * 2
        const tx = Math.max(8, Math.min(Popouts.anchorX - w / 2, win.implicitWidth - w - 8))

        useA = !useA                          // opacity-биндинги лоадеров сделают кроссфейд
        if (card.opacity < 0.5) {             // свежее открытие — ставим без анимации
            morphAnim.stop()
            card.x = tx; card.width = w; card.height = h
        } else {
            xA.to = tx; wA.to = w; hA.to = h
            morphAnim.restart()
        }
    }

    Connections {
        target: Popouts
        function onNameChanged() { win.morph() }
    }

    ParallelAnimation {
        id: morphAnim
        NumberAnimation { id: xA; target: card; property: "x";      duration: Theme.decelDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decel }
        NumberAnimation { id: wA; target: card; property: "width";  duration: Theme.decelDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decel }
        NumberAnimation { id: hA; target: card; property: "height"; duration: Theme.decelDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.decel }
    }

    Rectangle {
        id: card
        readonly property real pad: 16

        // Настоящая мягкая тень (шейдер уже прогрет пилюлями при старте)
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 3
            autoPaddingEnabled: true
        }
        // Геометрия управляется ТОЛЬКО morph()/morphAnim — биндингов нет
        width: 200
        height: 60
        y: 0
        radius: 14
        color: Theme.surfaceHi
        border.width: 1
        border.color: Theme.border

        opacity: Popouts.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
        transform: Translate {
            y: Popouts.shown ? 0 : -6
            Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
        }

        HoverHandler {
            onHoveredChanged: hovered ? Popouts.holdOpen() : Popouts.hoverLeave()
        }

        // Два лоадера: front виден, back с новым контентом — кроссфейд сменой useA
        Loader {
            id: la
            x: card.pad; y: card.pad
            opacity: win.useA ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
        }
        Loader {
            id: lb
            x: card.pad; y: card.pad
            opacity: win.useA ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
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
