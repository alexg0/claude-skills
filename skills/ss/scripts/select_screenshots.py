#!/usr/bin/env python3
"""Select recent screenshots without printing unrelated filenames."""

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys


SUFFIXES = {".gif", ".heic", ".jpeg", ".jpg", ".png", ".webp"}
DEFAULT_PREFIXES = ("screenshot", "screen shot", "cleanshot", "shottr")


def screenshot_prefixes() -> tuple[str, ...]:
    configured = os.environ.get("SCREENSHOT_NAME_PREFIXES")
    if configured:
        return tuple(part.strip().casefold() for part in configured.split(",") if part.strip())
    return DEFAULT_PREFIXES


def has_screenshot_metadata(path: Path) -> bool:
    if sys.platform != "darwin":
        return False
    result = subprocess.run(
        ["mdls", "-raw", "-name", "kMDItemIsScreenCapture", str(path)],
        capture_output=True,
        check=False,
        text=True,
    )
    return result.returncode == 0 and result.stdout.strip() == "1"


def is_screenshot(path: Path) -> bool:
    name = path.name.casefold()
    return name.startswith(screenshot_prefixes()) or has_screenshot_metadata(path)


def screenshot_files(directory: Path) -> list[Path]:
    if not directory.is_dir():
        return []
    return [
        path
        for path in directory.iterdir()
        if path.is_file() and path.suffix.lower() in SUFFIXES and is_screenshot(path)
    ]


def configured_directory() -> Path | None:
    explicit = os.environ.get("SCREENSHOT_DIR")
    if explicit:
        return Path(explicit).expanduser()

    if sys.platform == "darwin":
        result = subprocess.run(
            ["defaults", "read", "com.apple.screencapture", "location"],
            capture_output=True,
            check=False,
            text=True,
        )
        if result.returncode == 0 and result.stdout.strip():
            return Path(result.stdout.strip()).expanduser()

    home = Path.home()
    fallbacks = [
        home / "Desktop",
        home / "Pictures" / "Screenshots",
        home / "Dropbox" / "Screenshots",
    ]
    existing = [path for path in fallbacks if path.is_dir()]
    return next((path for path in existing if screenshot_files(path)), existing[0] if existing else None)


def select(directory: Path, selector: int) -> list[Path]:
    if selector == 0:
        raise ValueError("selector cannot be zero")
    files = sorted(
        screenshot_files(directory),
        key=lambda path: (path.stat().st_mtime_ns, path.name),
        reverse=True,
    )
    if selector > 0:
        return files[:selector]
    index = -selector - 1
    return [files[index]] if index < len(files) else []


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("selector", nargs="?", type=int, default=1)
    args = parser.parse_args()

    directory = configured_directory()
    if directory is None or not directory.is_dir():
        parser.error("no screenshot directory found; set SCREENSHOT_DIR explicitly")
    try:
        selected = select(directory, args.selector)
    except ValueError as error:
        parser.error(str(error))
    print(json.dumps([str(path) for path in selected]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
