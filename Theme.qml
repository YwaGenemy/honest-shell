pragma Singleton
import QtQuick

// Единая тема: цвета, шрифты, ритм отступов, тайминги анимаций.
// Всё оформление тянется отсюда — меняешь тут, меняется везде.
QtObject {
    // — Поверхности —
    readonly property color panelBg:    "transparent"                 // фон панели прозрачный (blur даёт Hyprland)
    readonly property color surface:    Qt.rgba(16/255, 18/255, 22/255, 0.88)   // пилюля-модуль
    readonly property color surfaceHi:  Qt.rgba(28/255, 32/255, 38/255, 0.94)   // hover-подсветка
    readonly property color border:     Qt.rgba(221/255, 228/255, 236/255, 0.12)
    readonly property color borderHi:   Qt.rgba(221/255, 228/255, 236/255, 0.22)

    // — Текст —
    readonly property color text:    "#e9eef5"
    readonly property color muted:   "#9ca8b6"

    // — Акценты (характер: спокойный, стеклянный) —
    readonly property color accent:      "#8fb7e8"
    readonly property color accentSoft:  Qt.rgba(143/255, 183/255, 232/255, 0.18) // активный фон
    readonly property color layout:      "#d3b8f5"   // раскладка
    readonly property color sound:       "#a8cbe8"   // звук
    readonly property color battery:     "#acd8b6"   // батарея ок
    readonly property color warning:     "#e8c46b"
    readonly property color critical:    "#e88484"

    // — Тени —
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.55)

    // — Шрифты —
    readonly property string font:      "CaskaydiaCove Nerd Font"
    readonly property int    fontSize:  13
    readonly property int    iconSize:  15

    // — Геометрия / ритм —
    readonly property int barHeight:    34
    readonly property int barMargin:    8      // горизонтальный отступ панели от краёв экрана
    readonly property int barMarginTop: 0      // прижато: визуальный зазор сверху = зазору до окон (2px, gaps_out 0)
    readonly property int pillHeight:   30
    readonly property int pillRadius:   11
    readonly property int pillPadH:     12     // горизонтальный внутренний отступ пилюли
    readonly property int gap:          7      // зазор между модулями в группе
    readonly property int groupGap:     8      // зазор между пилюлями-соседями

    // — Тайминги (микроанимации) —
    readonly property int  fast:   130
    readonly property int  med:    220
    readonly property int  slow:   360
    // Мягкое «дорогое» ускорение
    readonly property var  ease:      [0.22, 1, 0.36, 1, 1, 1]   // cubic out-expo-ish (для Behavior easing.bezierCurve)
    readonly property int  easeType:  Easing.OutCubic

    // — Кривые Material 3 Expressive (BezierSpline) —
    // spatial: для движения/размеров, с лёгким overshoot («перелетает» и возвращается)
    // effects: для opacity/цвета, без overshoot
    readonly property list<real> spatial:      [0.30, 1.45, 0.30, 1.00, 1, 1]
    readonly property list<real> spatialFast:  [0.35, 2.10, 0.22, 0.90, 1, 1]
    readonly property list<real> effects:      [0.34, 0.80, 0.34, 1.00, 1, 1]
    readonly property int spatialDur:     520
    readonly property int spatialFastDur: 290
    readonly property int effectsDur:     200
    // decel: быстрое затухание без перелёта — для морфа попапов и разъезжающихся пилюль
    readonly property list<real> decel:   [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property int decelDur:       300
}
