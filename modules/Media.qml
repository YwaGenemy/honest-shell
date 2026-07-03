// Медиа (MPRIS): иконка + название трека. Клик — пауза/плей, СКМ — следующий.
// Hover — морфящий попап с управлением и прогрессом. Прячется, когда нет плееров.
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "root:/"
import "root:/components"

Pill {
    id: root
    readonly property var pl: {
        const list = Mpris.players.values
        return list.find(p => p.playbackState === MprisPlaybackState.Playing) ?? list[0] ?? null
    }
    readonly property bool playing: pl && pl.playbackState === MprisPlaybackState.Playing

    visible: pl !== null
    onClicked: if (pl) pl.togglePlaying()
    onMiddleClicked: if (pl && pl.canGoNext) pl.next()
    onWheel: (d) => { if (pl) (d > 0 ? pl.previous() : pl.next()) }

    onHoveredChanged: hovered
        ? Popouts.hoverEnter("media", mapToItem(null, width / 2, 0).x)
        : Popouts.hoverLeave()

    hpad: 9
    // Только нота — название трека живёт в попапе (иначе пилюля наезжает
    // на воркспейсы, когда их много)
    Icon { name: "music"; color: root.playing ? Theme.layout : Theme.muted }
}
