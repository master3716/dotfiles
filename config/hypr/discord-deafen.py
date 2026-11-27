#!/usr/bin/env python3
"""Toggle Discord/Vesktop global deafen via Vesktop IPC socket (Wayland-safe) or Hyprland sendshortcut fallback."""

import os
import socket
import subprocess
import sys
import time


def toggle_vesktop_socket() -> bool:
    rt = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    candidates = (
        os.path.join(rt, "app", "dev.vencord.Vesktop", "vesktop.sock"),
        os.path.join(rt, "vesktop.sock"),
    )
    for sock_path in candidates:
        if not os.path.exists(sock_path):
            continue
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                sock.settimeout(1.0)
                sock.connect(sock_path)
                sock.sendall(b"run-shortcut toggleDeafen\n")
                resp = sock.recv(128).decode("utf-8", errors="replace").strip()
                if resp == "ok":
                    return True
        except OSError:
            continue
    return False


def main() -> int:
    if "--test-twice" in sys.argv:
        ok1 = toggle_vesktop_socket()
        time.sleep(0.05)
        ok2 = toggle_vesktop_socket()
        print(f"vesktop_ipc_test={ok1 and ok2}")
        return 0 if (ok1 and ok2) else 1

    if toggle_vesktop_socket():
        return 0

    subprocess.run(
        [
            "hyprctl",
            "dispatch",
            "sendshortcut",
            "CTRL SHIFT, d, class:.*([Dd]iscord|[Vv]esktop).*",
        ],
        check=False,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
