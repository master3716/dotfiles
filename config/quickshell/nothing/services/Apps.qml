pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// Resolve applications via the system's .desktop files.
// That is what gives real icons and names, rather than guessed
// Nerd Font codepoints.
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications?.values ?? []

    readonly property var visible: root.all
        .filter(e => !e.noDisplay)
        .sort((x, y) => x.name.localeCompare(y.name))

    // Returns a DesktopEntry for a .desktop id or a Hyprland window class.
    // byId("zen") rarely suffices: the real icon is often `zen-browser`,
    // and the class only matches StartupWMClass.
    function entry(id: string): var {
        if (!id)
            return null;
        const tries = [id, id.toLowerCase()];
        for (let i = 0; i < tries.length; i++) {
            const e = DesktopEntries.byId(tries[i]);
            if (e)
                return e;
        }
        // Hyprland class vs StartupWMClass / .desktop id, before
        // heuristicLookup which can glue "zen" to a grey theme icon.
        const lower = id.toLowerCase();
        const all = root.all;
        for (let i = 0; i < all.length; i++) {
            const e = all[i];
            const wm = (e.startupClass ?? "").toLowerCase();
            const eid = (e.id ?? "").toLowerCase();
            if (wm === lower || eid === lower)
                return e;
        }
        for (let i = 0; i < tries.length; i++) {
            const e = DesktopEntries.heuristicLookup(tries[i]);
            if (e)
                return e;
        }
        return null;
    }

    // Hyprland class -> .desktop icon name. Without this, iconPath("zen")
    // finds nothing (the icon is named zen-browser / app.zen_browser.zen).
    readonly property var iconAliases: ({
        zen: "app.zen_browser.zen",
        "zen-browser": "app.zen_browser.zen",
        "app.zen_browser.zen": "zen-browser",
        helium: "helium-browser",
        "helium-browser": "helium-browser",
        dolphin: "org.kde.dolphin",
        "org.kde.dolphin": "org.kde.dolphin",
        files: "org.gnome.Nautilus",
        nautilus: "org.gnome.Nautilus",
        "org.gnome.nautilus": "system-file-manager",
        spotify: "com.spotify.Client",
        "spotify-client": "com.spotify.Client",
        "com.spotify.client": "spotify",
        vesktop: "dev.vencord.Vesktop",
        "dev.vencord.vesktop": "vesktop",
        zapzap: "com.rtosta.zapzap",
        "com.rtosta.zapzap": "whatsapp",
        stremio: "com.stremio.Stremio",
        "com.stremio.stremio": "stremio",
        ghostty: "com.mitchellh.ghostty",
        "com.mitchellh.ghostty": "utilities-terminal",
        cursor: "co.anysphere.cursor",
        "co.anysphere.cursor": "co.anysphere.cursor",
    })

    // Direct filesystem icon index populated once at startup so Flatpak, Snap,
    // hicolor, Yaru, Papirus, and Adwaita icons resolve even if Qt's icon
    // theme plugin skips them.
    property var diskIconMap: ({})

    function _iconScore(p: string): int {
        let s = 0;
        if (p.indexOf("/apps/") >= 0 || p.indexOf("/pixmaps/") >= 0)
            s += 100;
        if (p.endsWith(".svg"))
            s += 50;
        else if (p.indexOf("/scalable/") >= 0 || p.indexOf("/256x256/") >= 0 || p.indexOf("/128x128/") >= 0)
            s += 40;
        else if (p.indexOf("/96x96/") >= 0 || p.indexOf("/64x64/") >= 0 || p.indexOf("/48x48/") >= 0)
            s += 30;
        else if (p.indexOf("/32x32/") >= 0)
            s += 15;
        if (p.indexOf("symbolic") >= 0 || p.indexOf("/16x16/") >= 0 || p.indexOf("/22x22/") >= 0 || p.indexOf("/24x24/") >= 0)
            s -= 80;
        return s;
    }

    Process {
        id: iconScanProc
        running: true
        command: [
            "sh", "-c",
            "find \"$HOME/.local/share/icons\" \"$HOME/.local/share/flatpak/exports/share/icons\" /var/lib/flatpak/exports/share/icons /usr/share/icons/Papirus-Dark /usr/share/icons/Papirus /usr/share/icons/Qogir-Dark /usr/share/icons/breeze-dark /usr/share/icons/Yaru /usr/share/icons/Adwaita /usr/share/icons/hicolor /usr/share/pixmaps /var/lib/snapd/desktop/icons -maxdepth 6 \\( -type f -o -type l \\) \\( -name '*.svg' -o -name '*.png' -o -name '*.xpm' \\) 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const best = {};
                const bestScore = {};
                for (let i = 0; i < lines.length; i++) {
                    const p = lines[i].trim();
                    if (!p)
                        continue;
                    const slash = p.lastIndexOf("/");
                    if (slash < 0)
                        continue;
                    const fname = p.slice(slash + 1);
                    const dot = fname.lastIndexOf(".");
                    if (dot <= 0)
                        continue;
                    const stem = fname.slice(0, dot);
                    const sc = root._iconScore(p);
                    const keys = [stem, stem.toLowerCase()];
                    for (let k = 0; k < keys.length; k++) {
                        const key = keys[k];
                        if (bestScore[key] === undefined || sc > bestScore[key]) {
                            bestScore[key] = sc;
                            best[key] = "file://" + p;
                        }
                    }
                }
                root.diskIconMap = best;
            }
        }
    }

    function iconNames(id: string): var {
        const names = [];
        const seen = {};
        const add = n => {
            if (!n)
                return;
            const s = String(n);
            if (seen[s])
                return;
            seen[s] = true;
            names.push(s);
        };
        const e = root.entry(id);
        add(e?.icon);
        add(id);
        if (id)
            add(id.toLowerCase());
        add(root.iconAliases[(id ?? "").toLowerCase()]);
        return names;
    }

    function toImageUrl(p: string): string {
        if (!p)
            return "";
        if (p.includes("://") || p.startsWith("qrc:"))
            return p;
        if (p.startsWith("/"))
            return "file://" + p;
        return p;
    }

    // URLs to try in order. iconPath(..., true) often skips
    // hicolor/pixmaps: known paths are then added, without listing
    // missing files (each Image failure pollutes the log).
    function iconCandidates(id: string): var {
        const names = root.iconNames(id);
        const urls = [];
        const seen = {};
        const addUrl = u => {
            if (!u || seen[u])
                return;
            seen[u] = true;
            urls.push(u);
        };
        for (let i = 0; i < names.length; i++) {
            const n = names[i];
            if (n.startsWith("/") || n.includes("://")) {
                addUrl(root.toImageUrl(n));
                continue;
            }
            if (Quickshell.hasThemeIcon(n))
                addUrl(root.toImageUrl(Quickshell.iconPath(n)));
            const disk = root.diskIconMap[n] ?? root.diskIconMap[n.toLowerCase()];
            if (disk)
                addUrl(disk);
            const known = root.knownIconFiles[n];
            if (known) {
                for (let j = 0; j < known.length; j++)
                    addUrl(known[j]);
            }
        }
        return urls;
    }

    // Real paths as a last resort (the Qogir catalogue is tried first).
    readonly property var knownIconFiles: ({
        "zen-browser": [
            "file:///usr/share/icons/Qogir-Dark/scalable/apps/zen.svg",
            "file:///opt/zen-browser-bin/browser/chrome/icons/default/default48.png",
            "file:///usr/share/icons/hicolor/48x48/apps/zen-browser.png"
        ],
        "helium-browser": [
            "file:///usr/share/icons/hicolor/256x256/apps/helium-browser.png",
            "file:///usr/share/pixmaps/helium-browser.png"
        ],
        kitty: [
            "file:///usr/share/icons/Qogir-Dark/scalable/apps/kitty.svg",
            "file://" + Quickshell.shellPath("assets/icons/kitty.png")
        ],
        vesktop: [
            "file://" + (Quickshell.env("HOME") ?? "") + "/.local/share/icons/hicolor/scalable/apps/dev.vencord.Vesktop.svg",
            "file:///usr/share/icons/Qogir-Dark/scalable/apps/vesktop.svg",
            "file:///usr/share/icons/hicolor/scalable/apps/vesktop.svg"
        ],
        "dev.vencord.vesktop": [
            "file://" + (Quickshell.env("HOME") ?? "") + "/.local/share/icons/hicolor/scalable/apps/dev.vencord.Vesktop.svg",
            "file:///usr/share/icons/Qogir-Dark/scalable/apps/vesktop.svg",
            "file:///usr/share/icons/hicolor/scalable/apps/vesktop.svg"
        ],
        "spotify-client": [
            "file:///usr/share/icons/Qogir-Dark/scalable/apps/spotify.svg"
        ],
        spotify: [
            "file:///usr/share/icons/Qogir-Dark/scalable/apps/spotify.svg"
        ],
        "co.anysphere.cursor": [
            "file:///usr/share/pixmaps/co.anysphere.cursor.png"
        ],
        cursor: [
            "file:///usr/share/pixmaps/co.anysphere.cursor.png"
        ],
        // AUR-only, so Qogir/breeze-dark never carry it. hasThemeIcon()
        // does not walk down to hicolor for these, even though the icon
        // is really there: same story as zen-browser and helium-browser.
        "burpsuite-pro": [
            "file:///usr/share/icons/hicolor/scalable/apps/burpsuite-pro.svg",
            "file:///usr/share/icons/hicolor/128x128/apps/burpsuite-pro.png"
        ]
    })

    function iconFor(id: string): string {
        const c = root.iconCandidates(id);
        return c.length > 0 ? c[0] : "";
    }

    function nameFor(id: string): string {
        return root.entry(id)?.name ?? id;
    }

    // SNI tray: the id is often chrome_status_icon_1; the tooltip names the app.
    function trayKey(item: var): string {
        if (!item)
            return "";
        const id = String(item.id ?? "").toLowerCase();
        const title = String(item.title ?? "").toLowerCase();
        const tip = String(item.tooltipTitle ?? "").toLowerCase();
        const blob = `${id} ${title} ${tip}`;
        if (blob.indexOf("spotify") >= 0)
            return "spotify";
        if (blob.indexOf("vesktop") >= 0 || blob.indexOf("discord") >= 0)
            return "vesktop";
        if (blob.indexOf("cursor") >= 0)
            return "cursor";
        if (id && id.indexOf("chrome_status") < 0 && id.indexOf(":") < 0)
            return id;
        return title || tip;
    }

    // Expected Hyprland class for this app (used by the dock indicator dot).
    function classFor(id: string): string {
        const e = root.entry(id);
        return (e?.startupClass || e?.id || id).toLowerCase();
    }

    function launch(id: string): void {
        const e = root.entry(id);
        if (e) e.execute();
    }

    function search(query: string): var {
        const q = query.trim().toLowerCase();
        if (q === "") return root.visible;
        return root.visible.filter(e =>
            e.name.toLowerCase().includes(q)
            || (e.genericName ?? "").toLowerCase().includes(q)
            || (e.comment ?? "").toLowerCase().includes(q)
            || (e.id ?? "").toLowerCase().includes(q));
    }
}
