#!/usr/bin/env python3
"""
Scan a KiCad project directory for LCSC part numbers and download
symbols/footprints/3D models via easyeda2kicad.

Searches .kicad_sch and .kicad_pcb files for properties named "LCSC Part"
(or common variants) and runs:
    easyeda2kicad --full --lcsc_id=<part>
for each unique part found.
"""

import argparse
import os
import re
import subprocess
import sys
import time
from pathlib import Path

# Seconds to wait between downloads to avoid rate-limiting (403s)
DEFAULT_DELAY = 5

# Matches: (property "LCSC Part" "C7501247" ...)
# Also catches common field name variants like "LCSC", "LCSC Part #", "LCSC_Part"
LCSC_PROPERTY_RE = re.compile(
    r'\(\s*property\s+"(?:LCSC[ _]?Part(?:\s*#)?|LCSC)"\s+"(C\d+)"',
    re.IGNORECASE,
)

# Fallback: bare LCSC part number pattern in any quoted string (less precise)
LCSC_BARE_RE = re.compile(r'"(C\d{4,})"')

KICAD_EXTENSIONS = {".kicad_sch", ".kicad_pcb"}
LIB_EXTENSIONS = {".kicad_sym", ".kicad_mod"}


def get_default_easyeda_lib_dir() -> Path:
    """Return the default easyeda2kicad library directory for the current OS."""
    if sys.platform == "win32":
        # C:/Users/<username>/Documents/Kicad/easyeda2kicad/
        docs = Path.home() / "Documents" / "Kicad" / "easyeda2kicad"
    else:
        # Linux/macOS: ~/Documents/Kicad/easyeda2kicad/
        docs = Path.home() / "Documents" / "Kicad" / "easyeda2kicad"
    return docs


def find_existing_parts(search_dirs: list[Path]) -> set[str]:
    """Scan library files (.kicad_sym, .kicad_mod) for LCSC parts already downloaded."""
    found: set[str] = set()
    seen_files: set[Path] = set()
    for d in search_dirs:
        if not d.is_dir():
            continue
        for root, _dirs, filenames in os.walk(d):
            for name in filenames:
                p = Path(root) / name
                if p.suffix in LIB_EXTENSIONS and p not in seen_files:
                    seen_files.add(p)
                    try:
                        text = p.read_text(encoding="utf-8", errors="replace")
                    except OSError:
                        continue
                    # easyeda2kicad stores LCSC IDs in property fields and symbol names
                    found.update(re.findall(r'C\d{4,}', text))
    return found


def find_kicad_files(project_dir: Path) -> list[Path]:
    """Recursively find all .kicad_sch and .kicad_pcb files."""
    files = []
    for root, _dirs, filenames in os.walk(project_dir):
        for name in filenames:
            if Path(name).suffix in KICAD_EXTENSIONS:
                files.append(Path(root) / name)
    return sorted(files)


def extract_lcsc_parts(filepath: Path) -> set[str]:
    """Extract LCSC part numbers from a single KiCad file."""
    text = filepath.read_text(encoding="utf-8", errors="replace")
    return set(LCSC_PROPERTY_RE.findall(text))


def run_easyeda2kicad(part_id: str, output_dir: str | None, dry_run: bool) -> bool:
    """Download a single LCSC part. Returns True on success."""
    cmd = ["easyeda2kicad", "--full", f"--lcsc_id={part_id}"]
    if output_dir:
        cmd.append(f"--output={output_dir}")

    if dry_run:
        print(f"  [dry-run] {' '.join(cmd)}")
        return True

    print(f"  Running: {' '.join(cmd)}")
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        if result.returncode != 0:
            print(f"  WARNING: easyeda2kicad failed for {part_id}")
            if result.stderr.strip():
                print(f"    stderr: {result.stderr.strip()}")
            return False
        return True
    except FileNotFoundError:
        print("  ERROR: easyeda2kicad not found. Install it with:")
        print("    pip install easyeda2kicad")
        sys.exit(1)
    except subprocess.TimeoutExpired:
        print(f"  WARNING: Timed out downloading {part_id}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Scan a KiCad project for LCSC parts and download them via easyeda2kicad.",
    )
    parser.add_argument(
        "project_dir",
        nargs="?",
        default=".",
        help="Path to the KiCad project directory (default: current directory)",
    )
    parser.add_argument(
        "--output", "-o",
        default=None,
        help="Output directory for easyeda2kicad (passed as --output=DIR)",
    )
    parser.add_argument(
        "--dry-run", "-n",
        action="store_true",
        help="Show what would be downloaded without actually running easyeda2kicad",
    )
    parser.add_argument(
        "--delay", "-d",
        type=float,
        default=DEFAULT_DELAY,
        help=f"Seconds to wait between downloads to avoid rate-limiting (default: {DEFAULT_DELAY})",
    )
    parser.add_argument(
        "--lib-dir",
        action="append",
        default=None,
        help="Additional directory to scan for existing library files (can be repeated; "
             "always checks ~/Documents/Kicad/easyeda2kicad/ by default)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Download all parts even if they already exist in libraries",
    )
    args = parser.parse_args()

    project_dir = Path(args.project_dir).resolve()
    if not project_dir.is_dir():
        print(f"Error: '{project_dir}' is not a directory.", file=sys.stderr)
        sys.exit(1)

    # Find files
    kicad_files = find_kicad_files(project_dir)
    if not kicad_files:
        print(f"No .kicad_sch or .kicad_pcb files found in {project_dir}")
        sys.exit(0)

    print(f"Scanning {len(kicad_files)} KiCad file(s) in {project_dir}\n")

    # Collect parts with their source files for reporting
    all_parts: dict[str, list[str]] = {}
    for f in kicad_files:
        parts = extract_lcsc_parts(f)
        rel = f.relative_to(project_dir)
        for p in parts:
            all_parts.setdefault(p, []).append(str(rel))

    if not all_parts:
        print("No LCSC part numbers found.")
        sys.exit(0)

    # Report
    print(f"Found {len(all_parts)} unique LCSC part(s):\n")
    for part_id in sorted(all_parts):
        sources = ", ".join(all_parts[part_id])
        print(f"  {part_id}  (in {sources})")

    # Check which parts already exist in libraries
    if not args.force:
        lib_dirs = [Path(d).resolve() for d in args.lib_dir] if args.lib_dir else []
        # Always check the default easyeda2kicad library location
        default_lib = get_default_easyeda_lib_dir()
        lib_dirs.append(default_lib)
        # Also check the project dir and output dir
        lib_dirs.append(project_dir)
        if args.output:
            lib_dirs.append(Path(args.output).resolve())
            lib_dirs.append(Path(args.output).resolve().parent)

        print(f"\nChecking for already-downloaded parts...")
        print(f"  Default library: {default_lib}")
        if not default_lib.is_dir():
            print(f"  (directory does not exist yet)")
        existing = find_existing_parts(lib_dirs)
        already = {p for p in all_parts if p in existing}
        if already:
            print(f"  Skipping {len(already)} part(s) already in libraries:")
            for part_id in sorted(already):
                print(f"    {part_id}")
            for p in already:
                del all_parts[p]
        else:
            print("  None found in existing libraries.")

    if not all_parts:
        print("\nAll parts already downloaded. Use --force to re-download.")
        sys.exit(0)

    # Download
    print(f"\nDownloading {len(all_parts)} part(s)...")
    sorted_parts = sorted(all_parts)
    ok, fail = 0, 0
    for i, part_id in enumerate(sorted_parts):
        if i > 0 and not args.dry_run:
            print(f"  Waiting {args.delay}s before next download...")
            time.sleep(args.delay)
        if run_easyeda2kicad(part_id, args.output, args.dry_run):
            ok += 1
        else:
            fail += 1

    print(f"\nDone. {ok} succeeded, {fail} failed out of {ok + fail} parts.")


if __name__ == "__main__":
    main()
