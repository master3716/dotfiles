pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

// Keyboard layout tracking and switching for Nothing OS.
// Listens to Hyprland's socket2 activelayout event to update in real time.
Singleton {
    id: root

    property string layoutName: "English (US)"
    property string shortCode: "EN"
    readonly property bool isHebrew: shortCode === "HE"

    function updateFromText(raw: string): void {
        const str = (raw ?? "").trim();
        const lower = str.toLowerCase();
        root.layoutName = str;
        if (lower.indexOf("hebrew") >= 0 || lower.indexOf("il") >= 0) {
            root.shortCode = "HE";
        } else if (lower.indexOf("english") >= 0 || lower.indexOf("us") >= 0) {
            root.shortCode = "EN";
        } else if (lower.indexOf("arabic") >= 0 || lower.indexOf("ar") >= 0) {
            root.shortCode = "AR";
        } else if (lower.indexOf("russian") >= 0 || lower.indexOf("ru") >= 0) {
            root.shortCode = "RU";
        } else {
            root.shortCode = str.length >= 2 ? str.substring(0, 2).toUpperCase() : str.toUpperCase();
        }
    }

    function toggle(): void {
        sh.run("hyprctl switchxkblayout current next");
    }

    NProcess {
        id: sh
        function run(cmd: string): void {
            command = ["sh", "-c", cmd];
            running = true;
        }
    }

    NProcess {
        id: initQuery
        running: true
        command: ["sh", "-c", "hyprctl -j devices | jq -r '(.keyboards[] | select(.main == true) | .active_keymap) // \"\"'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim();
                if (line !== "") {
                    root.updateFromText(line);
                }
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") {
                const parts = (event.data ?? "").split(",");
                if (parts.length >= 2) {
                    root.updateFromText(parts.slice(1).join(","));
                }
            }
        }
    }
}
