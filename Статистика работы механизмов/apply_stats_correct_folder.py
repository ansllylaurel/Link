# -*- coding: utf-8 -*-
"""
Добавить статистику в модули форм ТОЛЬКО в:
  Конфигурация/DataProcessors
Не трогает (сломанные) и уже обработанные модули.
"""

import re
from pathlib import Path

ROOT = Path(
    r"C:\Users\DETarasov\Documents\Link\Статистика работы механизмов\Конфигурация\DataProcessors"
)
LOG_PATH = ROOT.parent / "apply_stats_correct_folder_log.txt"

AREA_MARKER = "#Область СтатистикаРаботыВнутреннихМеханизмов"

STATS_AREA = """
#Область СтатистикаРаботыВнутреннихМеханизмов

&НаСервере
Функция ЗарегистрироватьНовуюСессию(ИмяКоманды)
 
 ОбъектОбработки = РеквизитФормыВЗначение("Объект");
 
 ПараметрыВыполненияДляСбораСтатистики = РегистрыСведений.СтатистикаРаботыВнутреннихМеханизмов.ПолучитьПараметрыВыполнения(ОбъектОбработки);
 
 Механизм = ОбъектОбработки.Метаданные().ПолноеИмя() + ":" + ИмяКоманды;
 Сессия   = РегистрыСведений.СтатистикаРаботыВнутреннихМеханизмов.ЗарегистрироватьНовуюСессию(
  Механизм,
  ПараметрыВыполненияДляСбораСтатистики.Хранилище,
  ПараметрыВыполненияДляСбораСтатистики.Описание);
  
 ПараметрыСессии = Новый Структура;
 ПараметрыСессии.Вставить("Механизм",     Механизм);
 ПараметрыСессии.Вставить("Сессия",        Сессия);
 ПараметрыСессии.Вставить("ДопПараметры",  Неопределено);
 ПараметрыСессии.Вставить("ТекстОшибки",   Неопределено);
  
 Возврат ПараметрыСессии;
 
КонецФункции

&НаСервереБезКонтекста
Процедура ЗарегистрироватьОкончаниеСессии(ПараметрыСессии)
 
 РегистрыСведений.СтатистикаРаботыВнутреннихМеханизмов.ЗарегистрироватьОкончаниеСессии(
  ПараметрыСессии.Механизм,
  ПараметрыСессии.Сессия,,
  ПараметрыСессии.ДопПараметры,
  ПараметрыСессии.ТекстОшибки);
 
КонецПроцедуры

#КонецОбласти
""".strip("\n")

PROC_RE = re.compile(
    r"(?P<header>(&НаКлиенте(?:\s*\n&Асинхронно)?\s*\n)"
    r"Процедура\s+(?P<name>\w+)\(Команда\)\s*\n)"
    r"(?P<body>.*?)"
    r"(?P<footer>КонецПроцедуры)",
    re.DOTALL,
)

SOFT_RETURN_PATTERNS = [
    (
        re.compile(r"(\t+)Если\s+Не\s+ПроверитьЗаполнение\(\)\s+Тогда\s*\n\t+Возврат;\s*\n\t+КонецЕсли;"),
        r'\1Если Не ПроверитьЗаполнение() Тогда\n\1\tПараметрыСессии.ТекстОшибки = "Проверка заполнения не прошла.";\n\1\tВозврат;\n\1КонецЕсли;',
    ),
]


def meaningful_lines(body: str) -> list[str]:
    return [ln for ln in body.splitlines() if ln.strip()]


def wrap_command(name: str, body: str, header: str) -> str:
    lines = meaningful_lines(body)
    helper_name = f"Выполнить{name}"

    if len(lines) <= 1:
        call = lines[0].strip() if lines else ""
        wrapped = (
            f"{header}"
            f"\t\n"
            f"\tПараметрыСессии = ЗарегистрироватьНовуюСессию(\"{name}\");\n"
            f"\tПопытка\n"
            f"\t\t{call}\n"
            f"\tИсключение\n"
            f"\t\tПараметрыСессии.ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());\n"
            f"\t\tЗарегистрироватьОкончаниеСессии(ПараметрыСессии);\n"
            f"\t\tВозврат;\n"
            f"\tКонецПопытки;\n"
            f"\tЗарегистрироватьОкончаниеСессии(ПараметрыСессии);\n"
            f"\t\n"
            f"КонецПроцедуры"
        )
        return wrapped

    helper_body = body
    for pattern, repl in SOFT_RETURN_PATTERNS:
        helper_body = pattern.sub(repl, helper_body)

    wrapped = (
        f"{header}"
        f"\t\n"
        f"\tПараметрыСессии = ЗарегистрироватьНовуюСессию(\"{name}\");\n"
        f"\tПопытка\n"
        f"\t\t{helper_name}(ПараметрыСессии);\n"
        f"\tИсключение\n"
        f"\t\tПараметрыСессии.ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());\n"
        f"\t\tЗарегистрироватьОкончаниеСессии(ПараметрыСессии);\n"
        f"\t\tВозврат;\n"
        f"\tКонецПопытки;\n"
        f"\tЗарегистрироватьОкончаниеСессии(ПараметрыСессии);\n"
        f"\t\n"
        f"КонецПроцедуры\n"
        f"\n"
        f"&НаКлиенте\n"
        f"Процедура {helper_name}(ПараметрыСессии)\n"
        f"{helper_body}"
        f"КонецПроцедуры"
    )
    return wrapped


def process_file(path: Path) -> tuple[int, list[str]]:
    text = path.read_text(encoding="utf-8-sig")
    if AREA_MARKER in text:
        return 0, ["SKIP: уже есть область статистики"]

    matches = list(PROC_RE.finditer(text))
    if not matches:
        return 0, ["SKIP: нет клиентских команд (Команда)"]

    changes = []
    # с конца, чтобы не сбивать позиции
    for m in reversed(matches):
        name = m.group("name")
        if "ЗарегистрироватьНовуюСессию" in m.group("body"):
            continue
        new_block = wrap_command(name, m.group("body"), m.group("header"))
        text = text[: m.start()] + new_block + text[m.end() :]
        changes.append(name)

    if not changes:
        return 0, ["SKIP: команды уже обёрнуты"]

    text = text.rstrip() + "\n\n" + STATS_AREA + "\n"
    path.write_text(text, encoding="utf-8-sig")
    return len(changes), [f"OK: {c}" for c in reversed(changes)]


def main() -> None:
    modules = sorted(ROOT.rglob("Forms/**/Module.bsl"))
    log: list[str] = [f"ROOT: {ROOT}", f"Модулей: {len(modules)}", ""]

    total_cmds = 0
    touched_files = 0

    for module in modules:
        rel = module.relative_to(ROOT)
        count, messages = process_file(module)
        if count:
            touched_files += 1
            total_cmds += count
            log.append(f"{rel} — команд: {count}")
            log.extend(f"  {msg}" for msg in messages)
        elif "SKIP: нет" not in messages[0] and "SKIP: уже" not in messages[0]:
            log.append(f"{rel} — {messages[0]}")

    log.extend(
        [
            "",
            f"Обработано файлов: {touched_files}",
            f"Обёрнуто команд: {total_cmds}",
        ]
    )
    LOG_PATH.write_text("\n".join(log), encoding="utf-8")
    print("\n".join(log[-10:]))
    print(f"Лог: {LOG_PATH}")


if __name__ == "__main__":
    main()
