#!/usr/bin/env python3
"""
Fix .mp3 and .srt references in .tscn files after files have been renamed
(accents removed, spaces stripped, special chars removed).

Usage: python fix_mp3_refs.py [project_root]
  project_root: path to the Godot project folder (default: ./project)
"""

import re
import sys
from pathlib import Path
from difflib import SequenceMatcher


# ── helpers ──────────────────────────────────────────────────────────────────

def normalize_filename(name: str) -> str:
    """Apply the same renaming logic as the bash script."""
    replacements = {
        'à':'a','á':'a','â':'a','ã':'a','ä':'a','å':'a',
        'À':'A','Á':'A','Â':'A','Ã':'A','Ä':'A','Å':'A',
        'è':'e','é':'e','ê':'e','ë':'e',
        'È':'E','É':'E','Ê':'E','Ë':'E',
        'ì':'i','í':'i','î':'i','ï':'i',
        'Ì':'I','Í':'I','Î':'I','Ï':'I',
        'ò':'o','ó':'o','ô':'o','õ':'o','ö':'o',
        'Ò':'O','Ó':'O','Ô':'O','Õ':'O','Ö':'O',
        'ù':'u','ú':'u','û':'u','ü':'u',
        'Ù':'U','Ú':'U','Û':'U','Ü':'U',
        'ý':'y','ÿ':'y','Ý':'Y',
        'ñ':'n','Ñ':'N',
        'ç':'c','Ç':'C',
        'œ':'oe','Œ':'Oe',
        'æ':'ae','Æ':'Ae',
    }
    result = []
    for ch in name:
        result.append(replacements.get(ch, ch))
    name = ''.join(result)
    name = name.replace(' ', '')
    name = re.sub(r'[^a-zA-Z0-9.\-]', '', name)
    return name


def fuzzy_score(a: str, b: str) -> float:
    return SequenceMatcher(None, a.lower(), b.lower()).ratio()


def find_renamed_file(original_res_path: str, project_root: Path, glob_ext: str) -> Path | None:
    """
    Find a renamed file on disk.
    Tries: exact path → normalized name → fuzzy match.
    glob_ext: e.g. '*.mp3' or '*.srt'
    """
    rel = original_res_path.replace('res://', '')
    original_abs = project_root / rel

    # 1. File still exists with original name
    if original_abs.exists():
        return original_abs

    # 2. Try the normalized name in the same directory
    parent = original_abs.parent
    norm_name = normalize_filename(original_abs.name)
    candidate = parent / norm_name
    if candidate.exists():
        return candidate

    # 3. Fuzzy search — find the nearest existing ancestor directory first
    search_dirs = [parent]
    if not parent.exists():
        parts = Path(rel).parts
        for i in range(len(parts), 0, -1):
            ancestor = project_root.joinpath(*parts[:i])
            if ancestor.exists():
                search_dirs = [ancestor]
                break

    best_score = 0.0
    best_path = None
    norm_stem = normalize_filename(original_abs.stem).lower()

    for search_dir in search_dirs:
        if not search_dir.is_dir():
            continue
        for f in search_dir.rglob(glob_ext):
            score = fuzzy_score(norm_stem, f.stem.lower())
            if score > best_score:
                best_score = score
                best_path = f

    if best_path and best_score >= 0.7:
        return best_path

    return None


def read_import_uid(import_file: Path) -> str | None:
    """Read the uid= field from a .import file."""
    try:
        text = import_file.read_text(encoding='utf-8')
    except Exception:
        return None
    m = re.search(r'^uid\s*=\s*"([^"]+)"', text, re.MULTILINE)
    return m.group(1) if m else None


def abs_to_res(path: Path, project_root: Path) -> str:
    """Convert absolute path to res:// path."""
    try:
        rel = path.relative_to(project_root)
        return 'res://' + rel.as_posix()
    except ValueError:
        return 'res://' + path.as_posix()


# ── collect changes ───────────────────────────────────────────────────────────

def collect_mp3_changes(matches: list, project_root: Path) -> list:
    """
    matches: list of (old_path, old_uid)
    Returns: list of (old_path, old_uid, new_res_path, new_uid, warnings)
    """
    pending = []
    for old_path, old_uid in matches:
        warn = []
        new_file = find_renamed_file(old_path, project_root, '*.mp3')
        if new_file is None:
            warn.append("renamed file not found on disk")
            pending.append((old_path, old_uid, None, None, warn))
            continue

        new_res_path = abs_to_res(new_file, project_root)
        import_file = new_file.parent / (new_file.name + '.import')

        if not import_file.exists():
            warn.append(".import file not found — uid will stay unchanged")
            new_uid = old_uid
        else:
            new_uid = read_import_uid(import_file)
            if new_uid is None:
                warn.append("could not read uid from .import — uid will stay unchanged")
                new_uid = old_uid

        if old_path == new_res_path and old_uid == new_uid:
            warn.append("nothing to change")

        pending.append((old_path, old_uid, new_res_path, new_uid, warn))
    return pending


def collect_srt_changes(matches: list, project_root: Path) -> list:
    """
    matches: list of (old_path, old_uid_or_none)
    SRT files have no .import, so uid is passed through unchanged if present.
    Returns: list of (old_path, old_uid, new_res_path, new_uid, warnings)
    """
    pending = []
    for old_path, old_uid in matches:
        warn = []
        new_file = find_renamed_file(old_path, project_root, '*.srt')
        if new_file is None:
            warn.append("renamed file not found on disk")
            pending.append((old_path, old_uid, None, None, warn))
            continue

        new_res_path = abs_to_res(new_file, project_root)

        if old_path == new_res_path:
            warn.append("nothing to change")

        # SRT has no .import — uid stays the same (no uid update needed)
        pending.append((old_path, old_uid, new_res_path, old_uid, warn))
    return pending


# ── preview & confirm ─────────────────────────────────────────────────────────

def preview_and_confirm(pending: list, label: str) -> list:
    """
    Print a preview table, ask for confirmation.
    Returns the actionable subset (possibly empty).
    Calls sys.exit(0) if the user types 'q'.
    """
    has_uid = any(old_uid is not None for _, old_uid, _, _, _ in pending)

    print(f"\n  ┌─ PREVIEW [{label}] ".ljust(64, '─') + '┐')
    for i, (old_path, old_uid, new_res_path, new_uid, warn) in enumerate(pending, 1):
        print(f"  │  [{i}/{len(pending)}]")
        print(f"  │  old path : {old_path}")
        if has_uid:
            print(f"  │  old uid  : {old_uid}")
        if new_res_path:
            path_marker = '  ' if old_path == new_res_path else '✎ '
            print(f"  │  new path : {path_marker}{new_res_path}")
            if has_uid:
                uid_marker = '  ' if old_uid == new_uid else '✎ '
                print(f"  │  new uid  : {uid_marker}{new_uid}")
        for w in warn:
            print(f"  │  ⚠  {w}")
        if i < len(pending):
            print(f"  │")
    print("  └" + '─' * 63 + '┘')
    print()

    actionable = [
        entry for entry in pending
        if entry[2] is not None  # new_res_path found
        and (
            entry[0] != entry[2]                                  # path changed
            or (entry[1] is not None and entry[1] != entry[3])   # uid changed
        )
    ]

    if not actionable:
        print(f"  → nothing to update for {label}.\n")
        return []

    while True:
        answer = input(f"  Apply {len(actionable)} {label} change(s)? [y/n/q] ").strip().lower()
        if answer in ('y', 'n', 'q'):
            break

    if answer == 'q':
        print("\nAborted by user.")
        sys.exit(0)

    if answer == 'n':
        print("  → skipped.\n")
        return []

    return actionable


def apply_changes(content: str, actionable: list, has_uid: bool) -> str:
    for old_path, old_uid, new_res_path, new_uid, _ in actionable:
        if old_path != new_res_path:
            # Replace in ext_resource tag attribute: path="old"
            content = content.replace(f'path="{old_path}"', f'path="{new_res_path}"')
            # Replace as bare string value: = "res://...srt"
            content = content.replace(f'"{old_path}"', f'"{new_res_path}"')
        if has_uid and old_uid and old_uid != new_uid:
            content = content.replace(f'"{old_uid}"', f'"{new_uid}"')
    return content


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    project_root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('./project')
    project_root = project_root.resolve()

    if not project_root.exists():
        print(f"[ERROR] Project root not found: {project_root}")
        sys.exit(1)

    print(f"Project root : {project_root}")
    print(f"Scanning for .tscn files...\n")

    # ext_resource with AudioStream type and .mp3 path — captures (path, id)
    mp3_re = re.compile(
        r'\[ext_resource\b[^\]]*\btype="AudioStream"[^\]]*\bpath="([^"]+\.mp3)"[^\]]*\bid="([^"]+)"[^\]]*\]'
    )
    # Match any ext_resource tag (full tag), then extract .srt path + id from it
    ext_resource_re = re.compile(r'\[ext_resource\b[^\]]*\]')
    srt_attr_path   = re.compile(r'\bpath="([^"]+\.srt)"')
    srt_attr_id     = re.compile(r'\bid="([^"]+)"')
    # Plain string property: any_property_name = "res://...srt"
    srt_string_re   = re.compile(r'=\s*"(res://[^"]+\.srt)"')

    tscn_files = list(project_root.rglob('*.tscn'))
    print(f"Found {len(tscn_files)} .tscn file(s)\n")

    total_replacements = 0

    for tscn_path in tscn_files:
        try:
            content = tscn_path.read_text(encoding='utf-8')
        except Exception as e:
            print(f"  [SKIP] Cannot read {tscn_path}: {e}")
            continue

        mp3_matches = mp3_re.findall(content)  # [(path, uid), ...]

        # Find SRT references:
        # 1. ext_resource tags (order-independent, to avoid double-matching)
        srt_tag_paths = set()
        srt_matches = []
        for tag in ext_resource_re.findall(content):
            m_path = srt_attr_path.search(tag)
            if not m_path:
                continue
            m_id = srt_attr_id.search(tag)
            path = m_path.group(1)
            srt_tag_paths.add(path)
            srt_matches.append((path, m_id.group(1) if m_id else None))

        # 2. Plain string properties: any_name = "res://...srt"
        #    Skip paths already captured as ext_resource (they'd be duplicates)
        for m in srt_string_re.finditer(content):
            path = m.group(1)
            if path not in srt_tag_paths:
                srt_matches.append((path, None))

        if not mp3_matches and not srt_matches:
            continue

        tscn_rel = str(tscn_path.relative_to(project_root))
        print(f"{'═' * 66}")
        print(f"[FILE] {tscn_rel}")
        print(f"       mp3 references: {len(mp3_matches)}   "
              f"srt references: {len(srt_matches)}")

        new_content = content
        file_changed = False

        # ── MP3 ──────────────────────────────────────────────────────────
        if mp3_matches:
            pending_mp3 = collect_mp3_changes(mp3_matches, project_root)
            actionable_mp3 = preview_and_confirm(pending_mp3, 'MP3')
            if actionable_mp3:
                new_content = apply_changes(new_content, actionable_mp3, has_uid=True)
                total_replacements += len(actionable_mp3)
                file_changed = True

        # ── SRT ──────────────────────────────────────────────────────────
        if srt_matches:
            pending_srt = collect_srt_changes(srt_matches, project_root)
            actionable_srt = preview_and_confirm(pending_srt, 'SRT')
            if actionable_srt:
                new_content = apply_changes(new_content, actionable_srt, has_uid=False)
                total_replacements += len(actionable_srt)
                file_changed = True

        # ── save ─────────────────────────────────────────────────────────
        if file_changed:
            tscn_path.write_text(new_content, encoding='utf-8')
            print(f"  [SAVED] {tscn_path.name}\n")
        else:
            print(f"  [NO CHANGES] {tscn_path.name}\n")

    print(f"{'═' * 66}")
    print(f"Done. {total_replacements} reference(s) updated across {len(tscn_files)} scene file(s).")


if __name__ == '__main__':
    main()