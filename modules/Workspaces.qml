// Воркспейсы 1/2/3 (persistent). Клик — переход, скролл — сосед по кругу.
// Активный индикатор — скользящая пилюля-«резинка»: передний край едет быстрее
// заднего (разные кривые), при переключении она растягивается и догоняет себя.
// Занятые воркспейсы подсвечены фоном; соседние занятые сливаются в одну капсулу.
import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland
import "root:/"

Item {
    id: root
    property var panelWindow
    readonly property int current: Math.max(1, Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1)

    // Геометрия ячеек: без зазора, чтобы занятые могли сливаться
    readonly property real cellW: 26
    readonly property real cellH: 22

    // Какие воркспейсы заняты окнами (id → bool), обновляется от событий Hyprland
    readonly property var occupied: {
        const o = {};
        for (const ws of Hyprland.workspaces.values)
            o[ws.id] = (ws.lastIpcObject?.windows ?? 0) > 0;
        return o;
    }

    // Число окон на воркспейсе (id → count)
    readonly property var winCounts: {
        const o = {};
        for (const ws of Hyprland.workspaces.values)
            o[ws.id] = ws.lastIpcObject?.windows ?? 0;
        return o;
    }

    // «Температура» по времени фокуса: нейтральный → акцент → янтарь
    function heatColor(t) {
        const mix = (a, b, k) => Qt.rgba(a.r + (b.r - a.r) * k, a.g + (b.g - a.g) * k, a.b + (b.b - a.b) * k, 1);
        const base = Qt.color("#dde4ec");
        if (t < 0.5) return mix(base, Theme.accent, t * 2);
        return mix(Theme.accent, Qt.color(Theme.warning), (t - 0.5) * 2);
    }

    // Минимум 3 ячейки; дальше панель растёт под текущий/занятые воркспейсы (4, 5, …)
    readonly property int count: {
        let m = 3;
        for (const ws of Hyprland.workspaces.values)
            if (ws.id > m && (ws.lastIpcObject?.windows ?? 0) > 0) m = ws.id;
        return Math.max(m, current);
    }

    // Quickshell сам не перечитывает список воркспейсов и счётчики окон —
    // без этого «тихое» создание окна на 5+ не появляется на панели.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["openwindow", "closewindow", "movewindow", "createworkspace",
                 "destroyworkspace", "workspace"].includes(event.name))
                Hyprland.refreshWorkspaces()
        }
    }

    implicitWidth: bg.implicitWidth
    implicitHeight: Theme.pillHeight

    function goto(n) {
        const w = ((n - 1 + count) % count) + 1     // цикл 1..3
        Hyprland.dispatch("workspace " + w)
    }

    // Стеклянная подложка + мягкая тень
    Rectangle {
        id: bg
        anchors.fill: parent
        implicitWidth: cells.width + 2 * 7
        radius: Theme.pillRadius
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 1.0
            shadowVerticalOffset: 2
            autoPaddingEnabled: true
        }
    }

    Item {
        id: cells
        anchors.centerIn: parent
        width: root.cellW * root.count
        height: root.cellH
        // Появление/уход ячеек 4+ — плавное расширение пилюли
        Behavior on width { NumberAnimation { duration: Theme.spatialDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }

        // — Слой 1: фон занятых воркспейсов —
        // Ячейки рисуются НЕПРОЗРАЧНЫМИ с нахлёстом 1px на стыках внутри общего слоя
        // (layer.enabled), а полупрозрачность применяется к слою целиком. Так нет ни
        // волосяных щелей на дробном масштабе, ни яркой полосы от нахлёста, и при этом
        // каждая ячейка анимируется отдельно — склейка соседей плавная.
        Item {
            id: occLayer
            anchors.fill: parent
            layer.enabled: true
            opacity: 0.13

            Repeater {
                model: root.count
                delegate: Rectangle {
                    id: occ
                    required property int index
                    readonly property bool isOcc: root.occupied[index + 1] === true
                    readonly property bool prevOcc: root.occupied[index] === true       // сосед слева (ws id = index)
                    readonly property bool nextOcc: root.occupied[index + 2] === true   // сосед справа

                    x: index * root.cellW - (prevOcc ? 1 : 0)
                    width: root.cellW + (prevOcc ? 1 : 0) + (nextOcc ? 1 : 0)
                    height: root.cellH
                    // Капсула нейтральная: занятость + плотность по числу окон.
                    // Жар показывает отдельная полоска под цифрой (слой 3).
                    color: "#dde4ec"
                    opacity: isOcc ? (0.7 + 0.3 * Math.min(root.winCounts[index + 1] ?? 0, 4) / 4) : 0

                    readonly property real r: height / 2
                    topLeftRadius:     prevOcc ? 0 : r
                    bottomLeftRadius:  prevOcc ? 0 : r
                    topRightRadius:    nextOcc ? 0 : r
                    bottomRightRadius: nextOcc ? 0 : r

                    Behavior on opacity        { NumberAnimation { duration: Theme.effectsDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
                    Behavior on topLeftRadius  { NumberAnimation { duration: Theme.effectsDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
                    Behavior on topRightRadius { NumberAnimation { duration: Theme.effectsDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
                    Behavior on bottomLeftRadius  { NumberAnimation { duration: Theme.effectsDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
                    Behavior on bottomRightRadius { NumberAnimation { duration: Theme.effectsDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
                }
            }
        }

        // — Слой 2: активная пилюля-«резинка» —
        // Два края едут к одной цели с разной скоростью → растяжение и догон.
        Item {
            id: indicator
            readonly property real target: (root.current - 1) * root.cellW
            property real edgeFast: target
            property real edgeSlow: target

            Behavior on edgeFast { NumberAnimation { duration: Theme.spatialFastDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatialFast } }
            Behavior on edgeSlow { NumberAnimation { duration: Theme.spatialDur;     easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }

            Rectangle {
                x: Math.min(indicator.edgeFast, indicator.edgeSlow)
                width: Math.abs(indicator.edgeFast - indicator.edgeSlow) + root.cellW
                height: root.cellH
                radius: height / 2
                color: Theme.accentSoft
                border.width: 1
                border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
            }
        }

        // — Слой 3: цифры + клик-зоны —
        Repeater {
            model: root.count
            delegate: Item {
                id: cell
                required property int index
                readonly property int wsId: index + 1
                readonly property bool isActive: root.current === wsId
                // Корень — быстрый видимый старт (2 мин фокуса уже заметны).
                // heat?.[…] — на первом кадре reload хранилище ещё не восстановлено.
                readonly property real heat: Math.sqrt(Math.min(1, (WsUsage.heat?.[wsId] ?? 0) / WsUsage.fullScale))

                x: index * root.cellW
                width: root.cellW; height: root.cellH

                // «Тлеющий след»: полоска важности под цифрой. Растёт и теплеет
                // с временем фокуса, видна и на активной ячейке (рисуется поверх пилюли).
                // Появление — «разжигание»: растягивается из центра с мягким перелётом + fade.
                Rectangle {
                    id: heatBar
                    readonly property bool lit: cell.heat > 0.02

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    width: 6 + 10 * cell.heat
                    height: 2.5
                    radius: 1.25
                    color: root.heatColor(0.25 + 0.75 * cell.heat)   // от голубого сразу, к янтарю

                    opacity: lit ? 0.7 + 0.3 * cell.heat : 0
                    visible: opacity > 0.01
                    transform: Scale {
                        origin.x: heatBar.width / 2
                        xScale: heatBar.lit ? 1 : 0.15
                        Behavior on xScale { NumberAnimation { duration: Theme.spatialDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.spatial } }
                    }

                    Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
                    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
                    Behavior on color { ColorAnimation { duration: 600 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: cell.wsId
                    color: cell.isActive ? Theme.accent
                         : (root.occupied[cell.wsId] === true ? Theme.text
                         : (cellMa.containsMouse ? Theme.text : Theme.muted))
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: cell.isActive
                    Behavior on color { ColorAnimation { duration: Theme.effectsDur; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.effects } }
                }
                MouseArea {
                    id: cellMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goto(cell.wsId)
                }
            }
        }
    }

    // Скролл по всей области (работает поверх клик-зон)
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (e) => root.goto(root.current + (e.angleDelta.y > 0 ? -1 : 1))
    }
}
