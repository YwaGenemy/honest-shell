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

    // Фиксированная ширина контента по типу — ColumnLayout сам считает ширину
    // от детей, и она «плавает» с приходом асинхронных данных; задаём явно.
    readonly property var _cw: ({ volume: 230, battery: 215, media: 250, cpu: 250, gpu: 245, net: 235 })

    function morph() {
        const nm = Popouts.name
        if (nm === "") return
        const incoming = useA ? lb : la      // скрытый лоадер
        const outgoing = useA ? la : lb
        incoming.sourceComponent = compFor(nm)
        const cw = _cw[nm] ?? 220
        if (incoming.item) incoming.item.width = cw   // фиксируем ширину контента
        const w = cw + card.pad * 2
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

    // Строка «метка : значение»
    component InfoRow: RowLayout {
        property string k
        property string v
        property color vc: Theme.text
        Layout.fillWidth: true
        spacing: 8
        Text { text: k; color: Theme.muted; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
        Item { Layout.fillWidth: true }
        Text { text: v; color: vc; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1
               font.bold: true; horizontalAlignment: Text.AlignRight }
    }

    // ── CPU ──
    Component {
        id: cpuC
        ColumnLayout {
            spacing: 7
            implicitWidth: 250

            Text { text: SysInfo.cpuModel; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }

            // Сетка мини-баров по потокам
            GridLayout {
                Layout.fillWidth: true
                columns: 8
                rowSpacing: 3
                columnSpacing: 3
                Repeater {
                    model: SysInfo.cpuPerCore
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 16
                        radius: 3
                        color: Qt.rgba(221/255, 228/255, 236/255, 0.08)
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: parent.height * Math.min(1, parent.modelData / 100)
                            radius: 3
                            color: parent.modelData >= 85 ? Theme.warning : Theme.accent
                            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            InfoRow { k: "Загрузка"; v: SysInfo.cpuUsage + "%"; vc: SysInfo.cpuUsage >= 85 ? Theme.warning : Theme.text }
            InfoRow { k: "Ядра / потоки"; v: SysInfo.cpuCores + " / " + SysInfo.cpuThreads }
            InfoRow { k: "Частота"; v: (SysInfo.cpuFreq / 1000).toFixed(2) + " ГГц" }
            InfoRow { k: "Температура"; v: SysInfo.cpuTemp + " °C"; vc: SysInfo.cpuTemp >= 80 ? Theme.critical : SysInfo.cpuTemp >= 65 ? Theme.warning : Theme.text }
            InfoRow { k: "Load avg"; v: SysInfo.loadAvg }
        }
    }

    // ── GPU ──
    Component {
        id: gpuC
        ColumnLayout {
            spacing: 7
            implicitWidth: 245
            readonly property real vramFrac: SysInfo.gpuVramTotal > 0 ? SysInfo.gpuVramUsed / SysInfo.gpuVramTotal : 0
            readonly property real gttFrac: SysInfo.gpuGttTotal > 0 ? SysInfo.gpuGttUsed / SysInfo.gpuGttTotal : 0

            // Мини-полоса памяти (переиспользуется для VRAM и GTT)
            component MemBar: Item {
                property real frac: 0
                property color fill: Theme.layout
                Layout.fillWidth: true; implicitHeight: 5
                Rectangle { anchors.fill: parent; radius: 2.5; color: Qt.rgba(221/255, 228/255, 236/255, 0.1) }
                Rectangle {
                    width: parent.width * Math.min(1, parent.frac); height: parent.height; radius: 2.5
                    color: parent.frac >= 0.9 ? Theme.warning : parent.fill
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                }
            }

            Text { text: "Radeon (5700U)"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true }

            // Полоса загрузки GPU
            Item {
                Layout.fillWidth: true; height: 6
                Rectangle { anchors.fill: parent; radius: 3; color: Qt.rgba(221/255, 228/255, 236/255, 0.1) }
                Rectangle {
                    width: parent.width * Math.min(1, SysInfo.gpuBusy / 100); height: parent.height; radius: 3
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                }
            }
            InfoRow { k: "Загрузка"; v: SysInfo.gpuBusy + "%" }
            InfoRow { k: "Температура"; v: SysInfo.gpuTemp + " °C"; vc: SysInfo.gpuTemp >= 85 ? Theme.critical : SysInfo.gpuTemp >= 70 ? Theme.warning : Theme.text }
            InfoRow { k: "Частота"; v: Math.round(SysInfo.gpuFreq) + " МГц" }
            InfoRow { k: "Напряжение"; v: SysInfo.gpuVolt.toFixed(3) + " В" }

            // Выделенная видеопамять (carveout из BIOS)
            InfoRow { k: "VRAM (своя)"; v: Math.round(SysInfo.gpuVramUsed) + " / " + Math.round(SysInfo.gpuVramTotal) + " МБ" }
            MemBar { frac: parent.vramFrac; fill: Theme.layout }
            // Подкачка из ОЗУ (GTT)
            InfoRow { k: "GTT (из ОЗУ)"; v: (SysInfo.gpuGttUsed / 1024).toFixed(1) + " / " + (SysInfo.gpuGttTotal / 1024).toFixed(1) + " ГБ" }
            MemBar { frac: parent.gttFrac; fill: Theme.accent }
        }
    }

    // ── Сеть ──
    Component {
        id: netC
        ColumnLayout {
            property string iface: "…"
            property real rxBytes: 0
            property real txBytes: 0
            spacing: 7
            implicitWidth: 235

            // Адаптивные единицы: КБ → МБ → ГБ → ТБ
            function human(b) {
                if (b >= 1099511627776) return (b / 1099511627776).toFixed(2) + " ТБ"
                if (b >= 1073741824)   return (b / 1073741824).toFixed(2) + " ГБ"
                if (b >= 1048576)      return (b / 1048576).toFixed(0) + " МБ"
                return (b / 1024).toFixed(0) + " КБ"
            }

            Process { id: iP; command: ["sh", "-c", "ip -o -4 route get 1.1.1.1 2>/dev/null | awk '{print $5\" \"$7}'"]
                stdout: StdioCollector { onStreamFinished: iface = ("" + text).trim() || "нет соединения" } }
            Process { id: tP2; command: ["sh", "-c", "awk 'NR>2{gsub(/^ +/,\"\"); split($0,a,/[: ]+/); if(a[1]!=\"lo\"){rx+=a[2]; tx+=a[10]}} END{printf \"%d|%d\", rx, tx}' /proc/net/dev"]
                stdout: StdioCollector { onStreamFinished: {
                    const p = ("" + text).trim().split("|")
                    rxBytes = parseFloat(p[0]) || 0
                    txBytes = parseFloat(p[1]) || 0
                } } }
            Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: { iP.running = true; tP2.running = true } }

            Text { text: "Сеть"; color: Theme.text; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true }
            InfoRow { k: "Интерфейс"; v: (iface + " ").split(" ")[0] }
            InfoRow { k: "IP"; v: (iface + "  ").split(" ")[1] || "—" }
            InfoRow { k: "Принято ↓"; v: parent.human(parent.rxBytes) }
            InfoRow { k: "Отдано ↑"; v: parent.human(parent.txBytes) }
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
