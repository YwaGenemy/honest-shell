pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Учёт «важности» воркспейсов: раз в 5с текущему начисляется тик фокуса,
// все остывают с полураспадом ≈ 1 час. Жар переживает hot-reload конфига
// (PersistentProperties), но не рестарт процесса quickshell.
Singleton {
    id: root

    PersistentProperties {
        id: store
        reloadableId: "wsUsageHeat"
        property var heat: ({})
    }

    readonly property var heat: store.heat

    // Сколько тиков = «раскалён»: 360 тиков ≈ 30 мин чистого фокуса
    readonly property real fullScale: 360

    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: {
            const h = {};
            for (const k in store.heat) {
                const v = store.heat[k] * 0.999;     // полураспад ≈ 58 мин
                if (v > 0.05) h[k] = v;
            }
            const cur = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0;
            if (cur > 0) h[cur] = (h[cur] ?? 0) + 1;
            store.heat = h;
        }
    }

    // 0..1 с извлечением корня: быстрый видимый старт, плавное насыщение.
    // ~2 мин фокуса → 0.25 (полоска уже читается), ~8 мин → 0.5, ~30 мин → 1.0
    function intensity(id) {
        return Math.sqrt(Math.min(1, (store.heat[id] ?? 0) / fullScale));
    }
}
