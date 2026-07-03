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

    // Непрерывные группы занятых воркспейсов: [{start, end}, …] (id, 1-based)
    readonly property var occRuns: {
        const runs = [];
        let start = -1;
        for (let i = 1; i <= count; i++) {
            if (occupied[i] === true && start < 0) start = i;
            if (occupied[i] !== true && start > 0) { runs.push({ start: start, end: i - 1 }); start = -1; }
        }
        if (start > 0) runs.push({ start: start, end: count });
        return runs;
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
            shadowBlur: 0.55
            shadowVerticalOffset: 3
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
        // Непрерывную группу занятых рисуем ОДНОЙ капсулой: отдельные прямоугольники
        // на дробном масштабе монитора дают волосяные щели на стыках.
        Repeater {
            model: root.occRuns
            delegate: Rectangle {
                required property var modelData
                x: (modelData.start - 1) * root.cellW
                width: (modelData.end - modelData.start + 1) * root.cellW
                height: root.cellH
                radius: height / 2
                color: Qt.rgba(221/255, 228/255, 236/255, 0.13)
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

                x: index * root.cellW
                width: root.cellW; height: root.cellH

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
