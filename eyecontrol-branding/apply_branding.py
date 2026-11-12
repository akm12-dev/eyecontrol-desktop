"""Apply the EyeControl branding to a RustDesk 1.5.1 source tree.

Run from the repository root after `git submodule update --init` (CI does it):
    python eyecontrol-branding/apply_branding.py

It changes only names, the built-in server and its public key. Every replacement
must match exactly once, otherwise the script stops: a new RustDesk version must
be reviewed by hand instead of being half-branded.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

APP_NAME = "EyeControl"
SERVER = "hosting.websentinelle.com"
PUBLIC_KEY = "Su9SDic3OWDbKFdJoqOiItwP+Gw2Ec6OUYIfGSf5PBo="
DESCRIPTION = "EyeControl Remote Support"
COPYRIGHT = (
    "EyeControl (c) 2026 AKM12, based on RustDesk (c) Purslane Tech Pte. Ltd., AGPL-3.0"
)

EDITS: dict[str, list[tuple[str, str]]] = {
    "libs/hbb_common/src/config.rs": [
        ('pub static ref APP_NAME: RwLock<String> = RwLock::new("RustDesk".to_owned());',
         f'pub static ref APP_NAME: RwLock<String> = RwLock::new("{APP_NAME}".to_owned());'),
        ('pub const RENDEZVOUS_SERVERS: &[&str] = &["rs-ny.rustdesk.com"];',
         f'pub const RENDEZVOUS_SERVERS: &[&str] = &["{SERVER}"];'),
        ('pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";',
         f'pub const RS_PUB_KEY: &str = "{PUBLIC_KEY}";'),
    ],
    "flutter/windows/runner/Runner.rc": [
        ('VALUE "CompanyName", "Purslane Tech Pte. Ltd." "\\0"', 'VALUE "CompanyName", "AKM12" "\\0"'),
        ('VALUE "FileDescription", "RustDesk Remote Desktop" "\\0"', f'VALUE "FileDescription", "{DESCRIPTION}" "\\0"'),
        ('VALUE "LegalCopyright", "Copyright © 2026 Purslane Tech Pte. Ltd. All rights reserved." "\\0"',
         f'VALUE "LegalCopyright", "{COPYRIGHT}" "\\0"'),
        ('VALUE "ProductName", "RustDesk" "\\0"', f'VALUE "ProductName", "{APP_NAME}" "\\0"'),
    ],
    "Cargo.toml": [
        ('LegalCopyright = "Copyright © 2026 Purslane Tech Pte. Ltd. All rights reserved."', f'LegalCopyright = "{COPYRIGHT}"'),
        ('ProductName = "RustDesk"', f'ProductName = "{APP_NAME}"'),
        ('FileDescription = "RustDesk Remote Desktop"', f'FileDescription = "{DESCRIPTION}"'),
    ],
}


def apply(path: Path, edits: list[tuple[str, str]]) -> int:
    raw = path.read_bytes()
    text = raw.decode("utf-8")
    changed = 0
    for old, new in edits:
        if new in text and old not in text:
            continue  # already applied
        count = text.count(old)
        if count != 1:
            raise SystemExit(f"{path}: expected exactly one match, found {count}: {old!r}")
        text = text.replace(old, new)
        changed += 1
    newline = "\r\n" if b"\r\n" in raw else "\n"
    if newline == "\r\n":
        text = text.replace("\r\n", "\n").replace("\n", "\r\n")
    path.write_bytes(text.encode("utf-8"))
    return changed


def main() -> int:
    for rel, edits in EDITS.items():
        path = ROOT / rel
        if not path.is_file():
            raise SystemExit(f"missing {rel} (did you init the submodules?)")
        print(f"{rel}: {apply(path, edits)} change(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
