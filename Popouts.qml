pragma Singleton
import QtQuick

// Состояние единого морфящего попапа. Модули по hover зовут hoverEnter/hoverLeave,
// окно (PopoutWindow) слушает name/anchorX и перетекает между содержимым.
QtObject {
    id: root

    property string name: ""      // "volume" | "battery" | "media" | ""
    property real anchorX: 0      // центр модуля в координатах окна панели
    readonly property bool shown: name !== ""

    property string _pendingName: ""
    property real _pendingX: 0

    readonly property Timer _openT: Timer {
        interval: 230
        onTriggered: { root.name = root._pendingName; root.anchorX = root._pendingX }
    }
    readonly property Timer _closeT: Timer {
        interval: 320
        onTriggered: root.name = ""
    }

    function hoverEnter(n, x) {
        _closeT.stop()
        _pendingName = n; _pendingX = x
        if (shown) { name = n; anchorX = x }   // уже открыт → морф без задержки
        else _openT.restart()
    }
    function hoverLeave() { _openT.stop(); _closeT.restart() }
    function holdOpen() { _closeT.stop() }     // курсор перешёл на сам попап
    function close() { _openT.stop(); _closeT.stop(); name = "" }
}
