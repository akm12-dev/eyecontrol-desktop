"""Apply the EyeControl branding and design to a RustDesk 1.5.1 source tree.

Run from the repository root after `git submodule update --init` (CI does it):
    python eyecontrol-branding/apply_branding.py

What changes: product name, built-in server and key, Windows resource texts,
the colour palette (EyeControl sky blue on navy), dark theme by default, and
"RustDesk" -> "EyeControl" in the displayed translations. Every edit must match
exactly as expected, otherwise the script stops: a new RustDesk version must be
reviewed by hand instead of being half-branded. Re-running is harmless.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

APP_NAME = "EyeControl"
SERVER = "hosting.websentinelle.com"
PUBLIC_KEY = "Su9SDic3OWDbKFdJoqOiItwP+Gw2Ec6OUYIfGSf5PBo="
DESCRIPTION = "EyeControl Remote Support"
COPYRIGHT = "EyeControl (c) 2026 AKM12, based on RustDesk (c) Purslane Tech Pte. Ltd., AGPL-3.0"

# EyeControl palette (from the logo): sky blue accents on deep navy surfaces.
ACCENT = "0EA5E9"
ID_COLOR = "38BDF8"
NAVY_BG = "0B1118"
NAVY_SURFACE = "131C26"

# (old, new, expected count). count None = exactly one.
Edit = tuple[str, str, "int | None"]

EDITS: dict[str, list[Edit]] = {
    "libs/hbb_common/src/config.rs": [
        ('pub static ref APP_NAME: RwLock<String> = RwLock::new("RustDesk".to_owned());',
         f'pub static ref APP_NAME: RwLock<String> = RwLock::new("{APP_NAME}".to_owned());', None),
        ('pub const RENDEZVOUS_SERVERS: &[&str] = &["rs-ny.rustdesk.com"];',
         f'pub const RENDEZVOUS_SERVERS: &[&str] = &["{SERVER}"];', None),
        ('pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";',
         f'pub const RS_PUB_KEY: &str = "{PUBLIC_KEY}";', None),
    ],
    "flutter/windows/runner/Runner.rc": [
        ('VALUE "CompanyName", "Purslane Tech Pte. Ltd." "\\0"', 'VALUE "CompanyName", "AKM12" "\\0"', None),
        ('VALUE "FileDescription", "RustDesk Remote Desktop" "\\0"', f'VALUE "FileDescription", "{DESCRIPTION}" "\\0"', None),
        ('VALUE "LegalCopyright", "Copyright © 2026 Purslane Tech Pte. Ltd. All rights reserved." "\\0"',
         f'VALUE "LegalCopyright", "{COPYRIGHT}" "\\0"', None),
        ('VALUE "ProductName", "RustDesk" "\\0"', f'VALUE "ProductName", "{APP_NAME}" "\\0"', None),
    ],
    "Cargo.toml": [
        ('LegalCopyright = "Copyright © 2026 Purslane Tech Pte. Ltd. All rights reserved."', f'LegalCopyright = "{COPYRIGHT}"', None),
        ('ProductName = "RustDesk"', f'ProductName = "{APP_NAME}"', None),
        ('FileDescription = "RustDesk Remote Desktop"', f'FileDescription = "{DESCRIPTION}"', None),
    ],
    # Self-extracting package (the file people download)
    "libs/portable/Cargo.toml": [
        ('LegalCopyright = "Copyright © 2026 Purslane Tech Pte. Ltd. All rights reserved."', f'LegalCopyright = "{COPYRIGHT}"', None),
        ('ProductName = "RustDesk"', f'ProductName = "{APP_NAME}"', None),
        ('OriginalFilename = "rustdesk.exe"', 'OriginalFilename = "EyeControl.exe"', None),
        ('FileDescription = "RustDesk Remote Desktop"', f'FileDescription = "{DESCRIPTION}"', None),
    ],
    "flutter/lib/common.dart": [
        # palette
        ("static const Color grayBg = Color(0xFFEFEFF2);", "static const Color grayBg = Color(0xFFEDF2F7);", None),
        ("static const Color accent = Color(0xFF0071FF);", f"static const Color accent = Color(0xFF{ACCENT});", None),
        ("static const Color accent50 = Color(0x770071FF);", f"static const Color accent50 = Color(0x77{ACCENT});", None),
        ("static const Color accent80 = Color(0xAA0071FF);", f"static const Color accent80 = Color(0xAA{ACCENT});", None),
        ("static const Color idColor = Color(0xFF00B6F0);", f"static const Color idColor = Color(0xFF{ID_COLOR});", None),
        ("static const Color button = Color(0xFF2C8CFF);", f"static const Color button = Color(0xFF{ACCENT});", None),
        ("primary: Colors.blue, secondary: accent, background: grayBg),",
         "primary: accent, secondary: accent, background: grayBg),", None),
        # dark surfaces
        ("hoverColor: Color.fromARGB(255, 45, 46, 53),", "hoverColor: Color(0xFF1B2733),", None),
        ("Color(0xFF18191E)", f"Color(0xFF{NAVY_BG})", 2),
        ("Color(0xFF24252B)", f"Color(0xFF{NAVY_SURFACE})", 5),
        ("MaterialStatePropertyAll(Color(0xFF121212))", f"MaterialStatePropertyAll(Color(0xFF{NAVY_BG}))", None),
        ("""    colorScheme: ColorScheme.dark(
      primary: Colors.blue,""", """    colorScheme: ColorScheme.dark(
      primary: accent,""", None),
        ("""    border: Color(0xFF555555),
    border2: Color(0xFFE5E5E5),
    border3: Colors.white24,
    highlight: Color(0xFF3F3F3F),""", """    border: Color(0xFF2A3A4A),
    border2: Color(0xFFE5E5E5),
    border3: Colors.white24,
    highlight: Color(0xFF1E2C3A),""", None),
        # dark theme by default; "Follow system" is stored explicitly as "system"
        ("get defaultOptionTheme => isCustomClient ? 'system' : '';", "get defaultOptionTheme => 'system';", None),
        ("""      case "dark":
        return ThemeMode.dark;
      default:
        return ThemeMode.system;""", """      case "dark":
        return ThemeMode.dark;
      case "system":
        return ThemeMode.system;
      default:
        return ThemeMode.dark;""", None),
    ],
    "flutter/lib/desktop/pages/desktop_home_page.dart": [
        ("""                  Color.fromARGB(255, 226, 66, 188),
                  Color.fromARGB(255, 244, 114, 124),""", """                  Color(0xFF0369A1),
                  Color(0xFF0EA5E9),""", None),
    ],
    "flutter/lib/desktop/pages/connection_page.dart": [
        # the AKM12 server is built in: never suggest setting up a server
        ("""            offstage: !(!_svcStopped.value &&
                stateGlobal.svcStatus.value == SvcStatus.ready &&
                _svcIsUsingPublicServer.value),""", """            offstage: true,""", None),
    ],
    "flutter/lib/desktop/widgets/tabbar_widget.dart": [
        ("dividerColor: Color.fromARGB(255, 64, 64, 64),", "dividerColor: Color(0xFF1E2C3A),", None),
        ("unSelectedTabIconColor: Color.fromARGB(255, 30, 65, 98),", "unSelectedTabIconColor: Color(0xFF1E4A66),", None),
    ],
}

LANG_LINE = re.compile(r'^(\s*\("(?:[^"\\]|\\.)*",\s*")((?:[^"\\]|\\.)*)("\),?\s*)$')


def apply(path: Path, edits: list[Edit]) -> int:
    raw = path.read_bytes()
    text = raw.decode("utf-8").replace("\r\n", "\n")
    changed = 0
    for old, new, expected in edits:
        want = 1 if expected is None else expected
        count = text.count(old)
        if count == 0 and text.count(new) >= want:
            continue  # already applied
        if count != want:
            raise SystemExit(f"{path}: expected {want} match(es), found {count}: {old[:80]!r}")
        text = text.replace(old, new)
        changed += 1
    if b"\r\n" in raw:
        text = text.replace("\n", "\r\n")
    path.write_bytes(text.encode("utf-8"))
    return changed


# Texts that must keep naming RustDesk: the honest "Powered by RustDesk" credit (AGPL base).
KEEP_RUSTDESK_KEYS = ("powered_by_me",)


def rename_in_translations() -> int:
    """'RustDesk' -> 'EyeControl' in displayed texts only; keys (lookups) are never changed."""
    total = 0
    for file in sorted((ROOT / "src" / "lang").glob("*.rs")):
        if file.name == "template.rs":
            continue
        raw = file.read_bytes()
        lines = raw.decode("utf-8").split("\n")
        for i, line in enumerate(lines):
            m = LANG_LINE.match(line)
            if not m:
                continue
            if any(f'("{key}",' in m.group(1) for key in KEEP_RUSTDESK_KEYS):
                if APP_NAME in m.group(2):
                    lines[i] = m.group(1) + m.group(2).replace(APP_NAME, "RustDesk") + m.group(3)
                    total += 1
                continue
            if "RustDesk" in m.group(2) and "rustdesk.com" not in m.group(2):
                lines[i] = m.group(1) + m.group(2).replace("RustDesk", APP_NAME) + m.group(3)
                total += 1
        file.write_bytes("\n".join(lines).encode("utf-8"))
    return total


def main() -> int:
    for rel, edits in EDITS.items():
        path = ROOT / rel
        if not path.is_file():
            raise SystemExit(f"missing {rel} (did you init the submodules?)")
        print(f"{rel}: {apply(path, edits)} change(s)")
    print(f"translations: {rename_in_translations()} text(s) renamed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
