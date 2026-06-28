#!/usr/bin/env python3
"""
kicad_archive_project.py — Archive a KiCad 7/8/9 project for Git portability.

Copies every symbol, footprint, and 3D model the project actually uses into
a local subdirectory, then writes project-level sym-lib-table / fp-lib-table
entries that resolve via ${KIPRJMOD}.  Because the archived libraries keep
the SAME nicknames as the originals, the .kicad_sch and .kicad_pcb files
need NO modification — KiCad's project-table-wins-over-global rule does
the rest.

Usage:
    python3 kicad_archive_project.py /path/to/project
    python3 kicad_archive_project.py /path/to/project --archive-dir libs
    python3 kicad_archive_project.py /path/to/project --dry-run
"""

import argparse
import json
import os
import platform
import re
import shutil
import sys
from pathlib import Path

# ─── S-expression helpers ────────────────────────────────────────────────────

def _find_close(text, start):
    """Index of the ')' matching the '(' at *start*, handling quoted strings."""
    depth, in_str = 0, False
    for i in range(start, len(text)):
        c = text[i]
        if c == '"' and (i == 0 or text[i - 1] != '\\'):
            in_str = not in_str
        elif not in_str:
            if c == '(':
                depth += 1
            elif c == ')':
                depth -= 1
                if depth == 0:
                    return i
    return -1


def _top_level_symbols(text):
    """Yield (name, sexp_text) for top-level symbols in a .kicad_sym file.

    Top-level = depth-2 (direct child of the kicad_symbol_lib wrapper at
    depth 1).  Sub-unit blocks like  (symbol "R_0_1" …)  live at depth 3+
    and are automatically included in their parent's extracted text.
    """
    depth, in_str, i = 0, False, 0
    while i < len(text):
        c = text[i]
        if c == '"' and (i == 0 or text[i - 1] != '\\'):
            in_str = not in_str
        elif not in_str:
            if c == '(':
                depth += 1
                if depth == 2:
                    m = re.match(r'\(symbol\s+"([^"]+)"', text[i:])
                    if m:
                        end = _find_close(text, i)
                        if end != -1:
                            yield m.group(1), text[i:end + 1]
                            i = end
                            depth -= 1
            elif c == ')':
                depth -= 1
        i += 1


# ─── Path / env helpers ─────────────────────────────────────────────────────

def _expand(path_str, env):
    """Expand ${VAR} references using *env* dict."""
    return re.sub(r'\$\{(\w+)\}', lambda m: env.get(m.group(1), m.group(0)), path_str)


def _kicad_config_dir():
    """Return the newest KiCad config directory that exists, or None."""
    home = Path.home()
    syst = platform.system()
    for ver in ['9.0', '8.0', '7.0']:
        if syst == 'Linux':
            d = home / '.config' / 'kicad' / ver
        elif syst == 'Darwin':
            d = home / 'Library' / 'Preferences' / 'kicad' / ver
        else:  # Windows
            d = Path(os.environ.get('APPDATA',
                     str(home / 'AppData' / 'Roaming'))) / 'kicad' / ver
        if d.is_dir():
            return d
    return None


def _build_env(project_dir):
    """Assemble a dict of KiCad path variables from OS env + config + guesses."""
    env = dict(os.environ)
    env['KIPRJMOD'] = str(project_dir)

    # Read vars KiCad stores in kicad_common.json
    cfg = _kicad_config_dir()
    if cfg:
        common = cfg / 'kicad_common.json'
        if common.exists():
            try:
                data = json.loads(common.read_text(encoding='utf-8'))
                for k, v in data.get('environment', {}).get('vars', {}).items():
                    env.setdefault(k, v)
            except Exception:
                pass

    # Guess stock library locations
    stock = []
    if platform.system() == 'Windows':
        for v in ['9.0', '8.0', '7.0', '']:
            stock.append(Path(f'C:/Program Files/KiCad/{v}/share/kicad'.replace('//', '/')))
    else:
        stock += [Path('/usr/share/kicad'), Path('/usr/local/share/kicad')]
        if platform.system() == 'Darwin':
            stock.append(Path('/Applications/KiCad/KiCad.app/Contents/SharedSupport'))
    for base in stock:
        for v in ['9', '8', '7', '6']:
            if (base / 'symbols').is_dir():
                env.setdefault(f'KICAD{v}_SYMBOL_DIR', str(base / 'symbols'))
                env.setdefault('KICAD_SYMBOL_DIR', str(base / 'symbols'))
            if (base / 'footprints').is_dir():
                env.setdefault(f'KICAD{v}_FOOTPRINT_DIR', str(base / 'footprints'))
                env.setdefault('KICAD_FOOTPRINT_DIR', str(base / 'footprints'))
            if (base / '3dmodels').is_dir():
                env.setdefault(f'KICAD{v}_3DMODEL_DIR', str(base / '3dmodels'))
                env.setdefault('KICAD_3DMODEL_DIR', str(base / '3dmodels'))
    return env


# ─── Library table I/O ───────────────────────────────────────────────────────

_LIB_RE = re.compile(
    r'\(lib\s+\(name\s+"([^"]+)"\)\s*\(type\s+"([^"]+)"\)\s*\(uri\s+"([^"]+)"\)'
)


def _parse_lib_table(path, env):
    """Return {nickname: (raw_uri, expanded_uri, lib_type)} from a lib-table file."""
    libs = {}
    if not path or not path.exists():
        return libs
    text = path.read_text(encoding='utf-8', errors='replace')
    for m in _LIB_RE.finditer(text):
        nick, ltype, raw = m.group(1), m.group(2), m.group(3)
        libs[nick] = (raw, _expand(raw, env), ltype)
    return libs


def _merged_tables(kind, project_dir, env):
    """Merge global + project lib tables; project entries win.
    Returns {nick: (raw_uri, expanded_uri, lib_type)}.
    """
    cfg = _kicad_config_dir()
    g = _parse_lib_table((cfg / f'{kind}-lib-table') if cfg else None, env)
    p = _parse_lib_table(project_dir / f'{kind}-lib-table', env)
    return {**g, **p}


def _write_lib_table(path, kind, entries, dry_run):
    """Write a sym-lib-table or fp-lib-table.
    *entries*: list of (nickname, uri_string).
    """
    lines = [f'({kind}_lib_table\n  (version 7)\n']
    for nick, uri in entries:
        lines.append(
            f'  (lib (name "{nick}")(type "KiCad")'
            f'(uri "{uri}")(options "")(descr "Archived by kicad_archive_project"))\n'
        )
    lines.append(')\n')
    text = ''.join(lines)
    if dry_run:
        print(f'  [dry-run] Would write {path}')
        return
    if path.exists():
        bak = path.with_suffix(path.suffix + '.bak')
        shutil.copy2(path, bak)
        print(f'  ↻  Backed up {path.name} → {bak.name}')
    path.write_text(text, encoding='utf-8')
    print(f'  ✓  Wrote {path.name}')


# ─── Reference collection ───────────────────────────────────────────────────

def _collect_sym_refs(project_dir, archive_dir):
    """Return set of 'Lib:Symbol' strings from all .kicad_sch files."""
    refs = set()
    for sch in project_dir.rglob('*.kicad_sch'):
        if archive_dir in sch.parents or sch.is_relative_to(archive_dir):
            continue
        text = sch.read_text(encoding='utf-8', errors='replace')
        refs.update(m.group(1) for m in re.finditer(r'\(lib_id\s+"([^"]+)"\)', text))
    return refs


def _collect_fp_refs(project_dir, archive_dir):
    """Return set of 'Lib:Footprint' strings from schematics + PCB."""
    refs = set()
    for f in project_dir.rglob('*.kicad_sch'):
        if archive_dir in f.parents or f.is_relative_to(archive_dir):
            continue
        text = f.read_text(encoding='utf-8', errors='replace')
        for m in re.finditer(r'\(property\s+"Footprint"\s+"([^"]*)"', text):
            if ':' in m.group(1):
                refs.add(m.group(1))
    for f in project_dir.rglob('*.kicad_pcb'):
        if archive_dir in f.parents or f.is_relative_to(archive_dir):
            continue
        text = f.read_text(encoding='utf-8', errors='replace')
        for m in re.finditer(r'\(footprint\s+"([^"]+)"', text):
            if ':' in m.group(1):
                refs.add(m.group(1))
    return refs


def _split_refs(refs):
    """Split 'Lib:Name' refs into {lib_nick: {name, …}}."""
    by_lib = {}
    for ref in refs:
        if ':' not in ref:
            continue
        lib, name = ref.split(':', 1)
        by_lib.setdefault(lib, set()).add(name)
    return by_lib


# ─── Symbol archiving ───────────────────────────────────────────────────────

def _archive_symbols(sym_by_lib, sym_table, archive_dir, dry_run):
    """Copy referenced symbols into archive_dir/symbols/<Lib>.kicad_sym.
    Returns {nick: relative_uri} for entries that were archived.
    """
    out_dir = archive_dir / 'symbols'
    archived = {}

    for lib_nick, names_needed in sorted(sym_by_lib.items()):
        entry = sym_table.get(lib_nick)
        if not entry:
            print(f'  ⚠  Symbol lib "{lib_nick}" not in any lib-table — skipped')
            continue
        raw_uri, expanded, _ = entry

        # Skip libs already local to project
        if '${KIPRJMOD}' in raw_uri:
            print(f'  ─  Symbol lib "{lib_nick}" already project-local — skipped')
            continue

        src = Path(expanded)
        if not src.is_file():
            print(f'  ⚠  Symbol lib "{lib_nick}" file not found: {src}')
            continue

        src_text = src.read_text(encoding='utf-8', errors='replace')
        all_syms = dict(_top_level_symbols(src_text))

        # Resolve `extends` dependencies: if symbol A extends B, we need B too
        extras = set()
        for name in names_needed:
            block = all_syms.get(name, '')
            m = re.search(r'\(extends\s+"([^"]+)"\)', block)
            if m:
                extras.add(m.group(1))
        names_needed = names_needed | extras

        extracted = []
        for name in sorted(names_needed):
            if name in all_syms:
                extracted.append(all_syms[name])
            else:
                print(f'  ⚠  Symbol "{name}" not found in lib "{lib_nick}"')

        if not extracted:
            continue

        ver_m = re.search(r'\(version\s+(\d+)\)', src_text)
        version = ver_m.group(1) if ver_m else '20231120'
        body = '\n\t'.join(extracted)
        out_text = (f'(kicad_symbol_lib\n'
                    f'\t(version {version})\n'
                    f'\t(generator "kicad_archive_project")\n'
                    f'\t{body}\n)\n')

        dest = out_dir / f'{lib_nick}.kicad_sym'
        rel_uri = f'${{KIPRJMOD}}/{archive_dir.name}/symbols/{lib_nick}.kicad_sym'

        if dry_run:
            print(f'  [dry-run] {lib_nick}: {len(extracted)} symbols → {dest}')
        else:
            out_dir.mkdir(parents=True, exist_ok=True)
            dest.write_text(out_text, encoding='utf-8')
            print(f'  ✓  {lib_nick}: {len(extracted)} symbols → {dest.name}')

        archived[lib_nick] = rel_uri

    return archived


# ─── Footprint + 3D model archiving ─────────────────────────────────────────

def _archive_footprints(fp_by_lib, fp_table, archive_dir, env, dry_run):
    """Copy .kicad_mod files and their 3D models.
    Returns {nick: relative_uri} for entries that were archived.
    """
    fp_dir = archive_dir / 'footprints'
    model_dir = archive_dir / '3dmodels'
    archived = {}

    for lib_nick, fps_needed in sorted(fp_by_lib.items()):
        entry = fp_table.get(lib_nick)
        if not entry:
            print(f'  ⚠  Footprint lib "{lib_nick}" not in any lib-table — skipped')
            continue
        raw_uri, expanded, _ = entry

        if '${KIPRJMOD}' in raw_uri:
            print(f'  ─  Footprint lib "{lib_nick}" already project-local — skipped')
            continue

        src_pretty = Path(expanded)
        if not src_pretty.is_dir():
            print(f'  ⚠  Footprint lib "{lib_nick}" dir not found: {src_pretty}')
            continue

        dest_pretty = fp_dir / f'{lib_nick}.pretty'
        count = 0

        for fp_name in sorted(fps_needed):
            src_mod = src_pretty / f'{fp_name}.kicad_mod'
            if not src_mod.is_file():
                print(f'  ⚠  {fp_name}.kicad_mod not found in "{lib_nick}"')
                continue

            mod_text = src_mod.read_text(encoding='utf-8', errors='replace')

            # ── 3D models ──
            for mm in re.finditer(r'\(model\s+"([^"]+)"', mod_text):
                raw_model = mm.group(1)
                model_src = Path(_expand(raw_model, env))
                if not model_src.is_file():
                    # Try without env expansion (might be relative already)
                    continue

                # Preserve sub-path from the first *.3dshapes segment onward
                parts = model_src.parts
                seg_idx = next(
                    (i for i, p in enumerate(parts) if p.endswith('.3dshapes')),
                    None
                )
                rel = Path(*parts[seg_idx:]) if seg_idx is not None else Path(model_src.name)
                dest_model = model_dir / rel
                new_ref = f'${{KIPRJMOD}}/{archive_dir.name}/3dmodels/{rel.as_posix()}'

                if not dry_run:
                    dest_model.parent.mkdir(parents=True, exist_ok=True)
                    if not dest_model.exists():
                        shutil.copy2(model_src, dest_model)

                # Rewrite path inside footprint text
                mod_text = mod_text.replace(f'"{raw_model}"', f'"{new_ref}"')

            dest_mod = dest_pretty / f'{fp_name}.kicad_mod'
            if dry_run:
                print(f'  [dry-run] {lib_nick}/{fp_name}.kicad_mod')
            else:
                dest_pretty.mkdir(parents=True, exist_ok=True)
                dest_mod.write_text(mod_text, encoding='utf-8')
                count += 1

        rel_uri = f'${{KIPRJMOD}}/{archive_dir.name}/footprints/{lib_nick}.pretty'
        if count or dry_run:
            if not dry_run:
                print(f'  ✓  {lib_nick}: {count} footprints → {dest_pretty.name}')
            archived[lib_nick] = rel_uri

    return archived


# ─── Main ────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(
        description='Archive a KiCad 7/8/9 project so it is fully portable via Git.',
        epilog='The .kicad_sch and .kicad_pcb files are NOT modified — only the '
               'library tables and the new archive directory are written.',
    )
    ap.add_argument('project_dir', type=Path, help='KiCad project directory')
    ap.add_argument('--archive-dir', default='archive-libs', metavar='NAME',
                    help='Subdirectory inside project for archived libs (default: archive-libs)')
    ap.add_argument('--dry-run', action='store_true',
                    help='Print what would happen without writing anything')
    args = ap.parse_args()

    proj = args.project_dir.resolve()
    if not proj.is_dir():
        sys.exit(f'Error: {proj} is not a directory.')
    if not list(proj.glob('*.kicad_pro')):
        sys.exit(f'Error: no .kicad_pro found in {proj} — is this a KiCad project?')

    archive = proj / args.archive_dir
    env = _build_env(proj)

    print(f'\n📦  KiCad Project Archiver')
    print(f'    Project : {proj}')
    print(f'    Archive : {archive}')
    if args.dry_run:
        print(f'    Mode    : DRY RUN (no files will be written)')
    print()

    # 1 ── Resolve library tables ────────────────────────────────────────────
    sym_table = _merged_tables('sym', proj, env)
    fp_table  = _merged_tables('fp',  proj, env)
    print(f'Library tables: {len(sym_table)} symbol libs, {len(fp_table)} footprint libs\n')

    # 2 ── Collect all references from schematics + PCB ──────────────────────
    sym_refs = _collect_sym_refs(proj, archive)
    fp_refs  = _collect_fp_refs(proj, archive)
    sym_by_lib = _split_refs(sym_refs)
    fp_by_lib  = _split_refs(fp_refs)
    print(f'References found:')
    print(f'  {len(sym_refs)} symbol refs across {len(sym_by_lib)} libraries')
    print(f'  {len(fp_refs)} footprint refs across {len(fp_by_lib)} libraries\n')

    # 3 ── Archive symbols ───────────────────────────────────────────────────
    print('─── Symbols ───')
    archived_sym = _archive_symbols(sym_by_lib, sym_table, archive, args.dry_run)

    # 4 ── Archive footprints + 3D models ────────────────────────────────────
    print('\n─── Footprints & 3D Models ───')
    archived_fp = _archive_footprints(fp_by_lib, fp_table, archive, env, args.dry_run)

    # 5 ── Write project library tables ──────────────────────────────────────
    #      Include archived entries + any pre-existing project-local entries
    #      that we skipped (already had ${KIPRJMOD} paths).
    print('\n─── Library Tables ───')

    proj_sym = _parse_lib_table(proj / 'sym-lib-table', env)
    proj_fp  = _parse_lib_table(proj / 'fp-lib-table',  env)

    sym_entries = []
    for nick, uri in sorted(archived_sym.items()):
        sym_entries.append((nick, uri))
    for nick, (raw, _, _) in sorted(proj_sym.items()):
        if nick not in archived_sym and '${KIPRJMOD}' in raw:
            sym_entries.append((nick, raw))          # keep existing local entry

    fp_entries = []
    for nick, uri in sorted(archived_fp.items()):
        fp_entries.append((nick, uri))
    for nick, (raw, _, _) in sorted(proj_fp.items()):
        if nick not in archived_fp and '${KIPRJMOD}' in raw:
            fp_entries.append((nick, raw))

    _write_lib_table(proj / 'sym-lib-table', 'sym', sym_entries, args.dry_run)
    _write_lib_table(proj / 'fp-lib-table',  'fp',  fp_entries,  args.dry_run)

    # 6 ── Summary ───────────────────────────────────────────────────────────
    print(f'\n✅  Done!  {len(archived_sym)} symbol libs, {len(archived_fp)} footprint libs archived.')
    print(f'    Commit {args.archive_dir}/, sym-lib-table, and fp-lib-table to Git.')
    if not args.dry_run and (proj / 'sym-lib-table.bak').exists():
        print(f'    Original lib-tables backed up with .bak extension.')
    print()


if __name__ == '__main__':
    main()
