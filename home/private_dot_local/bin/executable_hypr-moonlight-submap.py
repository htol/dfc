#!/usr/bin/env python3
"""Switch the Hyprland submap to "stream" while a Moonlight window has focus.

Listens on the Hyprland event socket and runs `hyprctl submap stream/reset`
on focus changes. Exit the submap manually with SUPER+Escape (bound in
hyprland.conf) if it ever gets stuck.
"""

import json
import os
import re
import socket
import subprocess
import time

MOONLIGHT_CLASS = re.compile(r"^com\.moonlight_stream\.Moonlight$")
DEBUG = bool(os.environ.get("MOONLIGHT_SUBMAP_DEBUG"))


def debug(msg: str) -> None:
    if DEBUG:
        with open("/tmp/hypr-moonlight-submap.log", "a") as f:
            f.write(f"{time.time():.3f} {msg}\n")


def hyprctl(*args: str) -> None:
    subprocess.run(
        ["hyprctl", "dispatch", *args],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )


def connect() -> socket.socket:
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sock_path = os.path.join(
        runtime, "hypr", os.environ["HYPRLAND_INSTANCE_SIGNATURE"], ".socket2.sock"
    )
    for _ in range(30):
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(sock_path)
            return s
        except OSError:
            time.sleep(1)
    raise RuntimeError(f"cannot connect to {sock_path}")


def current_class() -> str:
    """Return the class of the currently focused window, or "" if none."""
    try:
        out = subprocess.run(
            ["hyprctl", "-j", "activewindow"],
            capture_output=True,
            text=True,
            check=False,
            timeout=5,
        ).stdout
        return json.loads(out).get("class", "") if out.strip() else ""
    except (OSError, ValueError):
        return ""


def set_submap(window_class: str) -> None:
    action = "stream" if MOONLIGHT_CLASS.match(window_class) else "reset"
    debug(f"{window_class!r} -> {action}")
    hyprctl("submap", action)


def main() -> None:
    s = connect()
    set_submap(current_class())
    s.settimeout(None)
    buf = b""
    while True:
        chunk = s.recv(4096)
        if not chunk:
            return
        buf += chunk
        while b"\n" in buf:
            line, buf = buf.split(b"\n", 1)
            event = line.decode("utf-8", "replace")
            if not event.startswith("activewindow>>"):
                continue
            window_class = event.split(">>", 1)[1].split(",", 1)[0]
            set_submap(window_class)


if __name__ == "__main__":
    main()
