pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Учёт «важности» воркспейсов: раз в 5с текущему начисляется тик фокуса,
// все остывают с полураспадом ≈ 1 час. Данные живут в рамках сессии.
QtObject {
    id: root

    // id воркспейса → накопленный «жар» (в тиках, с остыванием)
    property var heat: ({})

    readonly property Timer _tick: Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: {
            const h = {};
            for (const k in root.heat) {
                const v = root.heat[k] * 0.999;      // полураспад ≈ 58 мин
                if (v > 0.05) h[k] = v;
            }
            const cur = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0;
            if (cur > 0) h[cur] = (h[cur] ?? 0) + 1;
            root.heat = h;
        }
    }

    // 0..1: 0 — холодный, 1 — ≈50 минут недавнего фокуса
    function intensity(id) {
        return Math.min(1, (heat[id] ?? 0) / 600);
    }
}
