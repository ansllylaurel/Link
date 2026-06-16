# -*- coding: utf-8 -*-
"""
Глубокий аудит модулей:
- Какие серверные методы вызываются из командных обёрток
- Есть ли в них ошибки без ДобавитьТекстОшибки
- Какой процент уже покрыт
"""

import re
from pathlib import Path
from collections import defaultdict

ROOT = Path(r"C:\Users\DETarasov\Documents\Link\Статистика работы механизмов\Конфигурация\DataProcessors")
REPORT = ROOT.parent / "audit_deep.txt"

# Паттерн для разбора метода: аннотация + заголовок + тело
RE_METHOD = re.compile(
    r'(&(?:НаСервере(?:БезКонтекста)?|НаКлиенте(?:НаСервереБезКонтекста)?|НаКлиентеНаСервереБезКонтекста))\s*\n'
    r'\s*(Процедура|Функция)\s+(\w+)\s*\(([^)]*)\)',
    re.IGNORECASE
)

def find_methods(text):
    """Возвращает список методов с их позициями."""
    methods = []
    for m in RE_METHOD.finditer(text):
        annotation = m.group(1)
        kind       = m.group(2)
        name       = m.group(3)
        params     = m.group(4)
        start      = m.start()
        methods.append({
            'annotation': annotation,
            'kind':       kind,
            'name':       name,
            'params':     params,
            'header_start': start,
            'header_end':   m.end(),
        })

    # Найти конец каждого метода
    for i, meth in enumerate(methods):
        end_kw = 'КонецПроцедуры' if meth['kind'].lower() == 'процедура' else 'КонецФункции'
        search_from = meth['header_end']
        pos = text.lower().find(end_kw.lower(), search_from)
        meth['body_end'] = pos + len(end_kw) if pos != -1 else len(text)
        meth['body'] = text[meth['header_end']:meth['body_end']]

    return methods


def is_server(meth):
    ann = meth['annotation'].lower()
    return 'насервере' in ann


def is_client(meth):
    ann = meth['annotation'].lower()
    return 'наклиенте' in ann and 'насервере' not in ann


def has_params_sessii(meth):
    return 'ПараметрыСессии' in meth['params']


def has_soobshchit_without_dobavit(body):
    """Находит СообщитьПользователю без предшествующего ДобавитьТекстОшибки."""
    results = []
    for m in re.finditer(r'ОбщегоНазначенияКлиентСервер\.СообщитьПользователю\(', body):
        # Проверим строку перед этим вызовом (в пределах 2 строк)
        pre = body[:m.start()]
        pre_lines = pre.split('\n')
        # Последние 2 строки перед этой
        context = '\n'.join(pre_lines[-3:])
        if 'ДобавитьТекстОшибки' not in context:
            # Найдём аргумент (простой случай — до закрывающей скобки на той же строке)
            rest = body[m.start():]
            line_end = rest.find('\n')
            call_line = rest[:line_end] if line_end != -1 else rest[:100]
            results.append(call_line.strip())
    return results


def has_exception_without_dobavit(body):
    """Находит блоки Исключение без ДобавитьТекстОшибки."""
    count = 0
    for m in re.finditer(r'\bИсключение\b', body):
        # Найдём конец блока исключения
        exc_start = m.end()
        end_try = body.find('КонецПопытки', exc_start)
        exc_body = body[exc_start:end_try] if end_try != -1 else body[exc_start:exc_start+200]
        if 'ДобавитьТекстОшибки' not in exc_body:
            count += 1
    return count


def calls_in_body(body, method_names):
    """Находит вызовы известных методов в теле."""
    called = []
    for name in method_names:
        if re.search(r'\b' + re.escape(name) + r'\s*\(', body):
            called.append(name)
    return called


def analyze_module(path: Path):
    text = path.read_text(encoding='utf-8-sig')
    if '#Область СтатистикаРаботыВнутреннихМеханизмов' not in text:
        return None

    methods = find_methods(text)
    method_map = {m['name']: m for m in methods}
    method_names = set(method_map.keys())

    # Найти командные обёртки (содержат ЗарегистрироватьНовуюСессию)
    wrappers = [m for m in methods if 'ЗарегистрироватьНовуюСессию' in m['body']]

    issues = []

    for wrapper in wrappers:
        # Найдём серверные методы, вызываемые из обёртки
        called_from_wrapper = calls_in_body(wrapper['body'], method_names)

        for callee_name in called_from_wrapper:
            callee = method_map.get(callee_name)
            if callee is None:
                continue
            # Только серверные методы (не клиентские утилиты)
            if not is_server(callee):
                # Это клиентский метод - тоже проверим
                pass

            # Проверим наличие проблем
            soob = has_soobshchit_without_dobavit(callee['body'])
            exc  = has_exception_without_dobavit(callee['body'])
            has_ps = has_params_sessii(callee)

            if soob or exc:
                issues.append({
                    'wrapper':  wrapper['name'],
                    'callee':   callee_name,
                    'annotation': callee['annotation'],
                    'has_ps':   has_ps,
                    'soob':     soob,
                    'exc':      exc,
                })

            # Рекурсия 1 уровень: методы вызванные из callee
            if has_ps:  # только если уже получает параметр — дальнейшее Threading возможно
                sub_called = calls_in_body(callee['body'], method_names)
                for sub_name in sub_called:
                    sub = method_map.get(sub_name)
                    if sub is None or sub['name'] in {w['name'] for w in wrappers}:
                        continue
                    s_soob = has_soobshchit_without_dobavit(sub['body'])
                    s_exc  = has_exception_without_dobavit(sub['body'])
                    s_has_ps = has_params_sessii(sub)
                    if s_soob or s_exc:
                        issues.append({
                            'wrapper':   wrapper['name'],
                            'callee':    f"  └→ {sub_name}",
                            'annotation': sub['annotation'],
                            'has_ps':    s_has_ps,
                            'soob':      s_soob,
                            'exc':       s_exc,
                        })

    return issues


def main():
    modules = sorted(ROOT.rglob("Forms/**/Module.bsl"))
    report = []
    total_files_with_issues = 0
    total_issues = 0

    for mod in modules:
        rel = str(mod.relative_to(ROOT))
        issues = analyze_module(mod)
        if issues is None:
            continue
        if not issues:
            continue

        total_files_with_issues += 1
        total_issues += len(issues)

        report.append(f"\n{'='*60}")
        report.append(rel)
        for iss in issues:
            ps_tag = "ПС✓" if iss['has_ps'] else "ПС✗"
            callee_str = f"  [{iss['annotation']}] {iss['callee']} ({ps_tag})"
            report.append(callee_str)
            if iss['exc']:
                report.append(f"    Исключение без ДобавитьТекстОшибки: {iss['exc']} шт.")
            for s in iss['soob']:
                short = s[:100]
                report.append(f"    СообщитьПользователю без покрытия: {short}")

    summary = [
        f"ИТОГО файлов с проблемами: {total_files_with_issues}",
        f"ИТОГО мест без ДобавитьТекстОшибки: {total_issues}",
        "",
    ]

    full = summary + report
    REPORT.write_text('\n'.join(full), encoding='utf-8')
    for line in summary:
        print(line)
    print(f"Полный отчёт: {REPORT}")


if __name__ == '__main__':
    main()
