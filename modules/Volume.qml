// Громкость. Скролл ±5%, ЛКМ → pavucontrol, ПКМ/СКМ → mute. Иконка меняется по уровню/mute.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "root:/"
import "root:/components"

Pill {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property int vol: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    // Держим свойства sink «живыми»
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    // Морфящий попап вместо тултипа
    onHoveredChanged: hovered
        ? Popouts.hoverEnter("volume", mapToItem(null, width / 2, 0).x)
        : Popouts.hoverLeave()

    onClicked: Quickshell.execDetached(["pavucontrol"])
    onRightClicked: if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
    onMiddleClicked: if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
    onWheel: (d) => {
        if (!sink || !sink.audio) return
        const step = 0.05
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (d > 0 ? step : -step)))
    }

    Icon {
        name: root.muted || root.vol === 0 ? "volumeMute"
            : (root.vol < 34 ? "volumeLow" : (root.vol < 67 ? "volumeMid" : "volumeHigh"))
        color: root.muted ? Theme.muted : Theme.sound
    }
    Text {
        text: root.muted ? "off" : (root.vol + "%")
        color: root.muted ? Theme.muted : Theme.text
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        TextMetrics { id: tm; font.family: Theme.font; font.pixelSize: Theme.fontSize; text: "100%" }
        Layout.preferredWidth: tm.width
        horizontalAlignment: Text.AlignRight
        Behavior on color { ColorAnimation { duration: Theme.med } }
    }
}
