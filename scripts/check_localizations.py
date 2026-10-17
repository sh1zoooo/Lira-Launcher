#!/usr/bin/env python3
"""Validate the shipped Russian catalogue and literal native localization references."""
from collections import Counter
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
TOKEN = re.compile(r'\s+|/\*.*?\*/|//[^\n]*|"(?:\\.|[^"\\])*"|[=;]', re.S)
FORMAT = re.compile(r'%(?:(\d+)\$)?[-+ #0]*\d*(?:\.\d+)?(hh|ll|[hljztL])?([@diuoxXfFeEgGaAcCsSpn%])')


def read_catalog(path):
    text = path.read_text(encoding='utf-8-sig')
    tokens = []
    offset = 0
    while offset < len(text):
        match = TOKEN.match(text, offset)
        if not match:
            line = text.count('\n', 0, offset) + 1
            raise ValueError(f'{path.relative_to(ROOT)}:{line}: invalid .strings syntax')
        token = match.group()
        if token[0] == '"' or token in ('=', ';'):
            tokens.append(token)
        offset = match.end()
    result = {}
    for index in range(0, len(tokens), 4):
        entry = tokens[index:index + 4]
        if len(entry) != 4 or entry[1] != '=' or entry[3] != ';':
            raise ValueError(f'{path}: expected "key" = "value"; near {entry}')
        key, value = entry[0][1:-1], entry[2][1:-1]
        if key in result:
            raise ValueError(f'{path}: duplicate key {key}')
        result[key] = value
    return result


def formats(value):
    """Compare printf argument indices and types; ignore literal %% and prose."""
    args = []
    next_index = 1
    for position, length, kind in FORMAT.findall(value):
        if kind == '%':
            continue
        index = int(position) if position else next_index
        args.append((index, length, kind))
        if not position:
            next_index += 1
    return sorted(args)


def main():
    base = ROOT / 'Natives/resources'
    en = read_catalog(base / 'en.lproj/Localizable.strings')
    ru = read_catalog(base / 'ru.lproj/Localizable.strings')
    errors = []
    for key, source in en.items():
        if key not in ru:
            errors.append(f'Missing Russian key: {key}')
        elif formats(source) != formats(ru[key]):
            errors.append(f'Format arguments differ: {key}: {formats(source)} != {formats(ru[key])}')
        elif re.search('[\u4e00-\u9fff]', ru[key]):
            errors.append(f'Untranslated Chinese in Russian value: {key}')
    refs = set()
    for path in (ROOT / 'Natives').rglob('*'):
        if path.suffix not in ('.m', '.h') or any(p in ('external', 'resources', 'build') for p in path.parts):
            continue
        source = path.read_text(errors='replace')
        # Skip comments, but preserve string literals including URLs.
        source = re.sub(r'/\*.*?\*/|//[^\n]*|@?"(?:\\.|[^"\\])*"',
                        lambda m: '' if m[0].startswith('/') else m[0], source, flags=re.S)
        refs.update(re.findall(r'localize\(@"((?:\\.|[^"\\])*)"', source))
    for key in sorted(refs - ru.keys()):
        errors.append(f'Referenced native key missing Russian translation: {key}')
    if errors:
        print('\n'.join(errors), file=sys.stderr)
        return 1
    print(f'OK: {len(ru)} Russian keys; English parity, printf arguments, syntax, and {len(refs)} native references checked.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
