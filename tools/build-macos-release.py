#!/usr/bin/env python3
"""Package the existing v1.0.0 pet with the Mac installer (no external tools)."""
import json
from pathlib import Path
import stat
import zipfile

ROOT = Path(__file__).resolve().parent.parent
FILES = (
    "install.command", "install.sh", "docs/INSTALL-MACOS.md", "README.md",
    "pet/pet.json", "pet/spritesheet.webp", "preview.html",
    "LICENSE", "ASSET-NOTICE.md", "CREDITS.md",
    "docs/contact-sheet.png", "docs/all-states.gif", "docs/look-loop.gif",
)
ARCHIVE = "codex-yier-yellow-bag-pet-v1.0.0-macos.zip"
PREFIX = "codex-yier-yellow-bag-pet-v1.0.0-macos"


def build():
    manifest = json.loads((ROOT / "pet/pet.json").read_text(encoding="utf-8"))
    assert manifest["id"] == "yier-yellow-bag"
    assert manifest["spriteVersionNumber"] == 2
    assert manifest["spritesheetPath"] == "spritesheet.webp"
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    destination = dist / ARCHIVE
    with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as archive:
        for name in FILES:
            path = ROOT / name
            if path.is_symlink() or not path.is_file():
                raise ValueError(f"Missing regular package file: {name}")
            data = path.read_bytes()
            executable = name in ("install.command", "install.sh")
            if executable:
                data = data.replace(b"\r\n", b"\n")
                if not data.startswith(b"#!/bin/bash\n"):
                    raise ValueError(f"Invalid executable header: {name}")
            info = zipfile.ZipInfo(f"{PREFIX}/{name}")
            info.create_system = 3
            info.external_attr = (stat.S_IFREG | (0o755 if executable else 0o644)) << 16
            archive.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED)
    print(f"Built {destination.name}: {len(FILES)} files, {destination.stat().st_size:,} bytes")
    return destination


if __name__ == "__main__":
    build()
