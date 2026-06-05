# -*- coding: utf-8 -*-
"""
Применяет паттерн ДобавитьТекстОшибки ко всем Module.bsl в DataProcessors.

Что делает:
1. Добавляет хелпер ДобавитьТекстОшибки в #Область СтатистикаРаботыВнутреннихМеханизмов
2. Заменяет прямые присваивания ПараметрыСессии.ТекстОшибки = ПодробноеПредставлениеОшибки(...)
   на ДобавитьТекстОшибки(ПараметрыСессии, ПодробноеПредставлениеОшибки(...))
3. Заменяет прямые присваивания ПараметрыСессии.ТекстОшибки = "строка"
   на ДобавитьТекстОшибки(ПараметрыСессии, "строка")
"""

import re
from pathlib import Path

ROOT = Path(r"C:\Users\DETarasov\Documents\Link\Статистика работы механизмов\Конфигурация\DataProcessors")
LOG_PATH = ROOT.parent / "apply_dobavit_text_oshibki_log.txt"

AREA_MARKER = "#Область СтатистикаРаботыВнутреннихМеханизмов"
HELPER_MARKER = "ДобавитьТекстОшибки"

HELPER_CODE = """\

&НаКлиентеНаСервереБезКонтекста
Процедура ДобавитьТекстОшибки(ПараметрыСессии, ТекстОшибки)

\tЕсли ПараметрыСессии = Неопределено Тогда
\t\tВозврат;
\tКонецЕсли;

\tЕсли Не ЗначениеЗаполнено(ТекстОшибки) Тогда
\t\tВозврат;
\tКонецЕсли;

\tЕсли ЗначениеЗаполнено(ПараметрыСессии.ТекстОшибки) Тогда
\t\tПараметрыСессии.ТекстОшибки = ПараметрыСессии.ТекстОшибки + Символы.ПС + ТекстОшибки;
\tИначе
\t\tПараметрыСессии.ТекстОшибки = ТекстОшибки;
\tКонецЕсли;

КонецПроцедуры
"""

# Паттерн 1: ПараметрыСессии.ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
# (только в блоках Исключение — но менять безопасно везде, хелпер сам разберётся с Неопределено)
PATTERN_PODROBNOE = re.compile(
    r'(\t*)ПараметрыСессии\.ТекстОшибки\s*=\s*(ПодробноеПредставлениеОшибки\(ИнформацияОбОшибке\(\)\));'
)

# Паттерн 2: ПараметрыСессии.ТекстОшибки = "строка";
PATTERN_STRING = re.compile(
    r'(\t*)ПараметрыСессии\.ТекстОшибки\s*=\s*("(?:[^"\\]|\\.)+")\s*;'
)

# Остаточные присваивания (не подпадающие под паттерны выше) — логируем
PATTERN_REMAINING = re.compile(
    r'ПараметрыСессии\.ТекстОшибки\s*='
)


def process_file(path: Path) -> tuple[int, list[str]]:
    text = path.read_text(encoding="utf-8-sig")
    messages = []
    changes = 0

    if AREA_MARKER not in text:
        return 0, ["SKIP: нет области статистики"]

    # 1. Добавить хелпер, если его ещё нет
    if HELPER_MARKER not in text:
        text = text.replace(
            AREA_MARKER + "\n",
            AREA_MARKER + "\n" + HELPER_CODE + "\n"
        )
        messages.append("HELPER: добавлен ДобавитьТекстОшибки")
        changes += 1

    # 2. Заменить ПараметрыСессии.ТекстОшибки = ПодробноеПредставлениеОшибки(...)
    def replace_podrobnoe(m):
        return f"{m.group(1)}ДобавитьТекстОшибки(ПараметрыСессии, {m.group(2)});"

    new_text, n = PATTERN_PODROBNOE.subn(replace_podrobnoe, text)
    if n:
        messages.append(f"PODROBNOE: {n} замен")
        changes += n
        text = new_text

    # 3. Заменить ПараметрыСессии.ТекстОшибки = "строка"
    def replace_string(m):
        return f"{m.group(1)}ДобавитьТекстОшибки(ПараметрыСессии, {m.group(2)});"

    new_text, n = PATTERN_STRING.subn(replace_string, text)
    if n:
        messages.append(f"STRING: {n} замен")
        changes += n
        text = new_text

    # 4. Проверить, остались ли ещё присваивания (внутри самого хелпера — допустимо)
    remaining = PATTERN_REMAINING.findall(text)
    helper_internal = text.count("ПараметрыСессии.ТекстОшибки = ПараметрыСессии.ТекстОшибки")
    helper_empty = text.count("ПараметрыСессии.ТекстОшибки = ТекстОшибки")
    unexpected = len(remaining) - helper_internal - helper_empty
    if unexpected > 0:
        messages.append(f"WARN: осталось {unexpected} неожиданных присваиваний ТекстОшибки")

    if changes:
        path.write_text(text, encoding="utf-8-sig")

    return changes, messages


def main() -> None:
    modules = sorted(ROOT.rglob("Forms/**/Module.bsl"))
    log = [f"ROOT: {ROOT}", f"Модулей: {len(modules)}", ""]

    total_files = 0
    total_changes = 0

    for mod in modules:
        rel = mod.relative_to(ROOT)
        count, msgs = process_file(mod)

        if count:
            total_files += 1
            total_changes += count
            log.append(f"{rel}")
            log.extend(f"  {m}" for m in msgs)

        # Логируем предупреждения даже без изменений
        warns = [m for m in msgs if m.startswith("WARN")]
        if warns and not count:
            log.append(f"{rel}")
            log.extend(f"  {m}" for m in warns)

    log.extend([
        "",
        f"Обработано файлов: {total_files}",
        f"Всего изменений: {total_changes}",
    ])

    LOG_PATH.write_text("\n".join(log), encoding="utf-8")
    print("\n".join(log[-5:]))
    print(f"Лог: {LOG_PATH}")


if __name__ == "__main__":
    main()
