# -*- coding: utf-8 -*-
"""Вынести многострочное тело из Попытка (обёртка статистики) в хелпер Выполнить<ИмяКоманды>."""
import re
import os
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))


def extract_try_body(text, start_pos):
    """Тело Попытка до Исключение (внешний уровень), с учётом вложенных Попытка/КонецПопытки."""
    i = start_pos
    depth = 1
    body_start = i
    while i < len(text):
        line_end = text.find('\n', i)
        if line_end == -1:
            line_end = len(text)
        line = text[i:line_end]
        stripped = line.strip()
        if stripped == 'Попытка':
            depth += 1
        elif stripped == 'КонецПопытки' or stripped == 'КонецПопытки;':
            depth -= 1
        elif depth == 1 and stripped.startswith('Исключение'):
            return text[body_start:i], i
        i = line_end + 1 if line_end < len(text) else len(text)
    return None, None


def dedent_body(body, extra_tab=False):
    lines = body.split('\n')
    if lines and not lines[-1].strip():
        lines = lines[:-1]
    if not lines:
        return ''
    min_indent = min(
        len(re.match(r'^(\s*)', ln).group(1))
        for ln in lines
        if ln.strip()
    )
    result = []
    for ln in lines:
        if ln.strip():
            result.append(ln[min_indent:] if len(ln) >= min_indent else ln)
        else:
            result.append('')
    body_text = '\n'.join(result)
    if extra_tab:
        body_text = '\n'.join(('\t' + ln if ln else '') for ln in body_text.split('\n'))
    return body_text


def process_file(path, dry_run=False):
    with open(path, encoding='utf-8-sig') as f:
        text = f.read()
    original = text
    text = text.replace('\r\n', '\n')
    changes = []

    pattern = re.compile(
        r'(ПараметрыСессии\w*\s*=\s*ЗарегистрироватьНовуюСессию\("([^"]+)"\);\s*\n\s*Попытка\s*\n)',
        re.MULTILINE,
    )

    offset = 0
    while True:
        m = pattern.search(text, offset)
        if not m:
            break
        cmd_name = m.group(2)
        try_start = m.end()
        body, after_try = extract_try_body(text, try_start)
        if body is None:
            offset = m.end()
            continue

        body_lines = [ln for ln in body.split('\n') if ln.strip()]
        if len(body_lines) <= 1:
            offset = after_try
            continue

        # уже один вызов хелпера?
        stripped = body.strip()
        if re.match(r'^Выполнить\w+\([^)]*\);\s*$', stripped, re.DOTALL):
            offset = after_try
            continue

        helper_name = f'Выполнить{cmd_name}'
        if re.search(rf'Процедура\s+{helper_name}\s*\(', text):
            offset = after_try
            continue

        # параметры вызова: если в теле есть ПараметрыСессии — передаём
        needs_session = 'ПараметрыСессии' in body
        # доп. параметры из сигнатуры команды — ищем процедуру с именем cmd_name
        proc_m = re.search(
            rf'Процедура\s+{re.escape(cmd_name)}\(([^)]*)\)',
            text[: m.start()],
        )
        extra_args = []
        if proc_m:
            params = [p.strip() for p in proc_m.group(1).split(',') if p.strip()]
            for p in params:
                if p != 'Команда' and p != 'ПараметрыСессии':
                    extra_args.append(p)

        call_args = []
        if needs_session or True:
            call_args.append('ПараметрыСессии')
        for p in extra_args:
            if p not in call_args:
                call_args.append(p)
        if proc_m and 'Команда' in proc_m.group(1) and 'Команда' not in call_args:
            call_args.append('Команда')

        call_line = f'\t\t{helper_name}({", ".join(call_args)});'

        helper_params = ['ПараметрыСессии']
        if proc_m and 'Команда' in proc_m.group(1):
            if 'Команда' not in helper_params:
                helper_params.append('Команда')
        for p in extra_args:
            if p not in helper_params:
                helper_params.append(p)

        helper_body = dedent_body(body, extra_tab=True)
        helper_block = (
            f'\n&НаКлиенте\n'
            f'Процедура {helper_name}({", ".join(helper_params)})\n\n'
            f'{helper_body}\n\n'
            f'КонецПроцедуры\n'
        )

        exc_m = re.match(
            r'(\s*Исключение[\s\S]*?КонецПопытки;\s*\n\s*ЗарегистрироватьОкончаниеСессии\([^)]*\);)',
            text[after_try:],
        )
        if not exc_m:
            offset = after_try
            continue

        new_block = m.group(1) + call_line + '\n' + exc_m.group(1)
        replace_end = after_try + exc_m.end()
        # вставка хелпера перед #Область Статистика
        insert_pos = text.find('#Область СтатистикаРаботыВнутреннихМеханизмов')
        if insert_pos == -1:
            insert_pos = len(text)

        text = text[: m.start()] + new_block + text[replace_end:]
        text = text[:insert_pos] + helper_block + text[insert_pos:]

        changes.append(cmd_name)
        offset = m.start() + len(new_block)

    if changes and not dry_run:
        out = original.replace('\r\n', '\n')
        if '\r\n' in original:
            text = text.replace('\n', '\r\n')
        with open(path, 'w', encoding='utf-8-sig', newline='') as f:
            f.write(text)

    return changes


def main():
    dry = '--dry' in sys.argv
    total_files = 0
    total_changes = 0
    log_path = os.path.join(ROOT, 'fix_try_log.txt')
    with open(log_path, 'w', encoding='utf-8') as log:
        for dirpath, _, files in os.walk(ROOT):
            for fn in files:
                if fn != 'Module.bsl':
                    continue
                if 'Ext\\Form' not in dirpath and 'Ext/Form' not in dirpath:
                    continue
                path = os.path.join(dirpath, fn)
                if 'fix_try' in path or 'ошибки_' in path:
                    continue
                with open(path, encoding='utf-8-sig') as f:
                    if 'ЗарегистрироватьНовуюСессию' not in f.read():
                        continue
                try:
                    ch = process_file(path, dry_run=dry)
                except Exception as e:
                    log.write(f'ERROR {path}: {e}\n')
                    continue
                if ch:
                    total_files += 1
                    total_changes += len(ch)
                    log.write(f'{path}: {", ".join(ch)}\n')
    print(f'files={total_files} changes={total_changes} dry={dry} log={log_path}')


if __name__ == '__main__':
    main()
