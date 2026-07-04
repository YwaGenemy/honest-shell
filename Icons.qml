pragma Singleton
import QtQuick

// Векторные иконки в едином штриховом стиле (viewBox 16, stroke 1.7, круглые концы).
// Слово CUR внутри разметки заменяется на цвет в Icon.qml (для заливок точек).
QtObject {
    readonly property var d: ({
        keyboard: "<rect x='1.5' y='4' width='13' height='8.5' rx='1.5'/><circle cx='4.2' cy='6.9' r='.75' fill='CUR' stroke='none'/><circle cx='6.7' cy='6.9' r='.75' fill='CUR' stroke='none'/><circle cx='9.2' cy='6.9' r='.75' fill='CUR' stroke='none'/><circle cx='11.7' cy='6.9' r='.75' fill='CUR' stroke='none'/><path d='M5 9.8h6'/>",
        cpu: "<rect x='4' y='4' width='8' height='8' rx='1.5'/><path d='M6.5 1.5v2M9.5 1.5v2M6.5 12.5v2M9.5 12.5v2M1.5 6.5h2M1.5 9.5h2M12.5 6.5h2M12.5 9.5h2'/>",
        thermo: "<path d='M8 2v7.3a2.6 2.6 0 1 1-2-.05'/><path d='M8 5h2.5M8 8h2.5'/>",
        leaf: "<path d='M13 3C7 3 3.5 6 3 12c4 .5 8-1 9.3-5.5'/><path d='M3.5 12.5C5 9 8 7 11 6.5'/>",
        bolt: "<path d='M8.7 1.5 3.8 9h2.9l-.9 5.5L10.9 7H8z'/>",
        volumeMute: "<path d='M2.5 6v4h2.8L9 13V3L5.3 6z'/><path d='M11 6.5l3 3M14 6.5l-3 3'/>",
        volumeLow: "<path d='M2.5 6v4h2.8L9 13V3L5.3 6z'/>",
        volumeMid: "<path d='M2.5 6v4h2.8L9 13V3L5.3 6z'/><path d='M11 6a3 3 0 0 1 0 4'/>",
        volumeHigh: "<path d='M2.5 6v4h2.8L9 13V3L5.3 6z'/><path d='M11 6a3 3 0 0 1 0 4'/><path d='M12.6 4.4a5.2 5.2 0 0 1 0 7.2'/>",
        battery: "<rect x='1.5' y='5' width='11' height='6' rx='1.5'/><path d='M14.5 7v2'/>",
        clock: "<circle cx='8' cy='8' r='6'/><path d='M8 5v3.2L10 10'/>",
        note: "<path d='M4 2h6.5L13 4.5V14H4z'/><path d='M6.5 6.5h4M6.5 9h4M6.5 11.5h2.5'/>",
        power: "<path d='M8 2v6'/><path d='M4.5 4a5.5 5.5 0 1 0 7 0'/>",
        bell: "<path d='M8 2.2a4 4 0 0 1 4 4c0 3 .8 4 1.5 4.6H2.5C3.2 10.2 4 9.2 4 6.2a4 4 0 0 1 4-4z'/><path d='M6.6 13a1.5 1.5 0 0 0 2.8 0'/>",
        mic: "<rect x='6' y='1.5' width='4' height='8' rx='2'/><path d='M3.5 7.5a4.5 4.5 0 0 0 9 0M8 12v2.5'/>",
        music: "<path d='M5.5 12.5V4l7-1.5V11'/><circle cx='3.8' cy='12.6' r='1.8'/><circle cx='10.8' cy='11' r='1.8'/>",
        lock: "<rect x='3.5' y='7' width='9' height='6.5' rx='1.5'/><path d='M5.5 7V5a2.5 2.5 0 0 1 5 0v2'/>",
        moon: "<path d='M13 9.5A5.5 5.5 0 0 1 6.5 3 5.5 5.5 0 1 0 13 9.5z'/>",
        restart: "<path d='M13 8a5 5 0 1 1-1.5-3.5M13 2.5v3h-3'/>",
        down: "<path d='M8 3v9M4.5 8.5 8 12l3.5-3.5'/>",
        up: "<path d='M8 13V4M4.5 7.5 8 4l3.5 3.5'/>",
        play: "<path d='M5.5 3.5v9l7-4.5z'/>",
        pause: "<path d='M5.7 3.5v9M10.3 3.5v9'/>",
        next: "<path d='M4 3.5 10 8l-6 4.5zM12 3.5v9'/>",
        prev: "<path d='M12 3.5 6 8l6 4.5zM4 3.5v9'/>",
        close: "<path d='M4.5 4.5l7 7M11.5 4.5l-7 7'/>",
        update: "<path d='M13.5 3.5v3h-3'/><path d='M13 6.2A5.2 5.2 0 1 0 13.4 10'/><path d='M8 5.2v3l2 1.3'/>",
        clipboard: "<rect x='3.5' y='3' width='9' height='11.5' rx='1.5'/><rect x='5.8' y='1.6' width='4.4' height='2.6' rx='1'/><path d='M6 7.5h4M6 10h4'/>",
        trash: "<path d='M3.5 4.5h9M6 4.5V3.2a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v1.3M5 4.5l.6 8a1 1 0 0 0 1 .95h2.8a1 1 0 0 0 1-.95l.6-8'/>",
        sliders: "<path d='M2.5 5h6.5M11.5 5h2M2.5 11h2M6.5 11h7'/><circle cx='10' cy='5' r='1.7' fill='CUR' stroke='none'/><circle cx='4.5' cy='11' r='1.7' fill='CUR' stroke='none'/>",
        plus: "<path d='M8 3.5v9M3.5 8h9'/>"
    })
}
