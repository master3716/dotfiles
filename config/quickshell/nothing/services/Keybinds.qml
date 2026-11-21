pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Keybindings service for Nothing OS.
// Persisted in ~/.config/nothing/config.json and written to ~/.config/hypr/binds.lua.
// Reloads Hyprland with hyprctl reload on changes.
Singleton {
    id: root

    readonly property string savePath:
        (Quickshell.env("HOME") ?? "") + "/.config/hypr/binds.lua"

    // Custom user keybinds: [{ key: "SUPER + D", command: "vesktop" }, ...]
    property var list: Config.customKeybinds ?? []

    // Built-in shortcut overrides: [{ id: "terminal", key: "SUPER + T" }, ...]
    property var overrides: Config.keybindOverrides ?? []

    readonly property var coreActions: [
        { id: "terminal",      label: "Terminal",         defaultKey: "SUPER + Return", action: 'hl.dsp.exec_cmd(terminal)' },
        { id: "launcher",      label: "App Launcher",     defaultKey: "SUPER + R",      action: 'ipc("launcher", "toggle")' },
        { id: "browser",       label: "Web Browser",      defaultKey: "SUPER + W",      action: 'hl.dsp.exec_cmd(ROOT .. "/scripts/open-default.sh web " .. browser)' },
        { id: "files",         label: "File Manager",     defaultKey: "SUPER + E",      action: 'hl.dsp.exec_cmd(fileManager)' },
        { id: "editor",        label: "Code Editor",      defaultKey: "SUPER + C",      action: 'hl.dsp.exec_cmd(codeEditor)' },
        { id: "clipboard",     label: "Clipboard",        defaultKey: "SUPER + V",      action: 'ipc("clipboard", "toggle")' },
        { id: "screenshot",    label: "Area Screenshot",  defaultKey: "SUPER + SHIFT + S", action: 'ipc("screenshot", "region")' },
        { id: "ocr",           label: "OCR Grab Text",    defaultKey: "SUPER + SHIFT + X", action: 'ipc("screenshot", "ocr")' },
        { id: "controlCentre", label: "Control Centre",   defaultKey: "SUPER + N",      action: 'ipc("bar", "toggle")' },
        { id: "displays",      label: "Display Manager",  defaultKey: "SUPER + P",      action: 'ipc("displays", "toggle")' },
        { id: "close",         label: "Close Window",     defaultKey: "SUPER + Q",      action: 'hl.dsp.window.close()' },
        { id: "fullscreen",    label: "Fullscreen",       defaultKey: "SUPER + F",      action: 'hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })' }
    ]

    function currentKeyFor(id: string, defaultKey: string): string {
        const ovs = root.overrides ?? [];
        for (let i = 0; i < ovs.length; i++) {
            if (ovs[i].id === id && ovs[i].key)
                return ovs[i].key;
        }
        return defaultKey;
    }

    function setOverride(id: string, newKey: string, defaultKey: string): void {
        const arr = (Config.keybindOverrides ?? []).slice();
        const filtered = arr.filter(x => x.id !== id);
        const val = (newKey ?? "").trim();
        if (val !== "" && val !== defaultKey) {
            filtered.push({ id: id, key: val });
        }
        Config.keybindOverrides = filtered;
        root.overrides = filtered;
        Config.save();
        root.apply();
    }

    function resetOverride(id: string): void {
        const arr = (Config.keybindOverrides ?? []).slice();
        Config.keybindOverrides = arr.filter(x => x.id !== id);
        root.overrides = Config.keybindOverrides;
        Config.save();
        root.apply();
    }

    function addCustom(key: string, command: string): bool {
        const k = (key ?? "").trim();
        const cmd = (command ?? "").trim();
        if (k === "" || cmd === "")
            return false;

        const arr = (Config.customKeybinds ?? []).slice();
        const idx = arr.findIndex(x => x.key.toLowerCase() === k.toLowerCase());
        if (idx >= 0) {
            arr[idx] = { key: k, command: cmd };
        } else {
            arr.push({ key: k, command: cmd });
        }
        Config.customKeybinds = arr;
        root.list = arr;
        Config.save();
        root.apply();
        return true;
    }

    function removeCustom(index: int): void {
        const arr = (Config.customKeybinds ?? []).slice();
        if (index >= 0 && index < arr.length) {
            arr.splice(index, 1);
            Config.customKeybinds = arr;
            root.list = arr;
            Config.save();
            root.apply();
        }
    }

    readonly property string saveText: {
        let lines = [
            "-- Written by Nothing OS Settings (Input > Keybindings)",
            "-- Rewritten whenever keybindings change in Settings.",
            ""
        ];

        // Process overrides
        const ovs = root.overrides ?? [];
        if (ovs.length > 0) {
            lines.push("-- Built-in shortcut overrides");
            for (let i = 0; i < ovs.length; i++) {
                const item = ovs[i];
                const def = root.coreActions.find(a => a.id === item.id);
                if (def && item.key) {
                    lines.push(`hl.bind("${item.key}", ${def.action})`);
                }
            }
            lines.push("");
        }

        // Process custom user binds
        const customs = root.list ?? [];
        if (customs.length > 0) {
            lines.push("-- Custom keybindings");
            for (let i = 0; i < customs.length; i++) {
                const item = customs[i];
                if (item.key && item.command) {
                    const esc = item.command.replace(/"/g, '\\"');
                    lines.push(`hl.bind("${item.key}", hl.dsp.exec_cmd("${esc}"))`);
                }
            }
            lines.push("");
        }

        return lines.join("\n");
    }

    property string error: ""

    function apply(): void {
        keeper.setText(root.saveText);
        reloaderTimer.restart();
    }

    Timer {
        id: reloaderTimer
        interval: 200
        onTriggered: {
            reloader.running = false;
            reloader.command = ["hyprctl", "reload"];
            reloader.running = true;
        }
    }

    NProcess {
        id: reloader
        label: "keybinds"
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                root.error = (t === "" || t === "ok") ? "" : t;
            }
        }
    }

    FileView {
        id: keeper
        path: root.savePath
        printErrors: false
    }

    Component.onCompleted: {
        root.list = Config.customKeybinds ?? [];
        root.overrides = Config.keybindOverrides ?? [];
    }
}
