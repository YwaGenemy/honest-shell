pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Непрерывный опрос системы (CPU/GPU) в одном месте. Попапы просто читают
// готовые живые значения — никаких Process на каждое наведение, никаких гонок
// и обрезанных данных при пересоздании компонентов морфящего попапа.
Singleton {
    id: root

    // — CPU —
    property string cpuModel: "…"
    property int    cpuCores: 0        // физические
    property int    cpuThreads: 0
    property int    cpuUsage: 0        // общая загрузка, %
    property var    cpuPerCore: []     // загрузка по потокам, [%]
    property real   cpuFreq: 0         // средняя частота, МГц
    property int    cpuTemp: 0         // °C
    property string loadAvg: "…"

    // — GPU (amdgpu) —
    readonly property string gpuPath: "/sys/devices/pci0000:00/0000:00:08.1/0000:03:00.0"
    property int  gpuTemp: 0           // °C
    property int  gpuBusy: 0           // %
    property real gpuVramUsed: 0       // МБ — выделенная (carveout из BIOS)
    property real gpuVramTotal: 0      // МБ
    property real gpuGttUsed: 0        // МБ — подкачка из ОЗУ (GTT)
    property real gpuGttTotal: 0       // МБ
    property real gpuFreq: 0           // МГц (sclk)
    property real gpuVolt: 0           // В

    // Прошлые значения /proc/stat для дельт
    property var _prevTotal: ({})
    property var _prevIdle: ({})

    function _parseStat(out) {
        const lines = ("" + out).split("\n")
        const per = []
        let overall = 0
        const nt = {}, ni = {}
        for (const line of lines) {
            if (!line.startsWith("cpu")) continue
            const f = line.trim().split(/\s+/)
            const key = f[0]                       // "cpu" | "cpu0" | "cpu1" …
            let total = 0
            for (let i = 1; i < f.length; i++) total += parseInt(f[i]) || 0
            const idle = (parseInt(f[4]) || 0) + (parseInt(f[5]) || 0)
            const dt = total - (root._prevTotal[key] ?? total)
            const di = idle - (root._prevIdle[key] ?? idle)
            const use = dt > 0 ? Math.max(0, Math.min(100, Math.round(100 * (1 - di / dt)))) : 0
            nt[key] = total; ni[key] = idle
            if (key === "cpu") overall = use
            else per.push(use)
        }
        root._prevTotal = nt; root._prevIdle = ni
        root.cpuUsage = overall
        root.cpuPerCore = per
    }

    // /proc/stat — общая + по-ядерная загрузка
    Process {
        id: statP
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector { onStreamFinished: root._parseStat(text) }
    }

    // Бандл: loadavg, средняя частота, температуры, GPU-метрики — одним заходом
    Process {
        id: bundleP
        command: ["sh", "-c",
            "echo LOAD $(cut -d' ' -f1-3 /proc/loadavg);" +
            "echo FREQ $(awk '/cpu MHz/{s+=$4;n++} END{if(n)printf \"%.0f\",s/n}' /proc/cpuinfo);" +
            "echo CTMP $(cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -1);" +
            "for h in /sys/class/hwmon/*/name; do read n <\"$h\"; [ \"$n\" = k10temp ] && cat \"${h%name}temp1_input\"; done | head -1 | sed 's/^/CTMP2 /';" +
            "G=/sys/devices/pci0000:00/0000:00:08.1/0000:03:00.0;" +
            "echo GTMP $(cat $G/hwmon/hwmon*/temp1_input 2>/dev/null);" +
            "echo GBSY $(cat $G/gpu_busy_percent 2>/dev/null);" +
            "echo GVU $(cat $G/mem_info_vram_used 2>/dev/null);" +
            "echo GVT $(cat $G/mem_info_vram_total 2>/dev/null);" +
            "echo GGU $(cat $G/mem_info_gtt_used 2>/dev/null);" +
            "echo GGT $(cat $G/mem_info_gtt_total 2>/dev/null);" +
            "echo GFRQ $(cat $G/hwmon/hwmon*/freq1_input 2>/dev/null);" +
            "echo GVLT $(cat $G/hwmon/hwmon*/in0_input 2>/dev/null)"]
        stdout: StdioCollector { onStreamFinished: {
            for (const line of ("" + text).split("\n")) {
                const p = line.split(/\s+/)
                const v = p[1]
                switch (p[0]) {
                case "LOAD": root.loadAvg = p.slice(1, 4).join("  ·  "); break
                case "FREQ": if (v) root.cpuFreq = parseInt(v); break
                case "CTMP2": if (v) root.cpuTemp = Math.round(parseInt(v) / 1000); break
                case "GTMP": if (v) root.gpuTemp = Math.round(parseInt(v) / 1000); break
                case "GBSY": if (v) root.gpuBusy = parseInt(v); break
                case "GVU": if (v) root.gpuVramUsed = parseInt(v) / 1048576; break
                case "GVT": if (v) root.gpuVramTotal = parseInt(v) / 1048576; break
                case "GGU": if (v) root.gpuGttUsed = parseInt(v) / 1048576; break
                case "GGT": if (v) root.gpuGttTotal = parseInt(v) / 1048576; break
                case "GFRQ": if (v) root.gpuFreq = parseInt(v) / 1e6; break
                case "GVLT": if (v) root.gpuVolt = parseInt(v) / 1000; break
                }
            }
        }}
    }

    // Статика — один раз
    Process {
        running: true
        command: ["sh", "-c",
            "echo MODEL $(grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //; s/ with .*//; s/(R)//g; s/(TM)//g');" +
            "echo CORES $(grep -m1 'cpu cores' /proc/cpuinfo | grep -o '[0-9]*');" +
            "echo THREADS $(grep -c ^processor /proc/cpuinfo)"]
        stdout: StdioCollector { onStreamFinished: {
            for (const line of ("" + text).split("\n")) {
                const i = line.indexOf(" ")
                const k = line.slice(0, i), v = line.slice(i + 1).trim()
                if (k === "MODEL") root.cpuModel = v
                else if (k === "CORES") root.cpuCores = parseInt(v) || 0
                else if (k === "THREADS") root.cpuThreads = parseInt(v) || 0
            }
        }}
    }

    Timer {
        interval: 2000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { statP.running = true; bundleP.running = true }
    }
}
