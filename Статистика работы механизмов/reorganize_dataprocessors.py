# -*- coding: utf-8 -*-
"""Реорганизация DataProcessors: плоская структура -> пара _Имя\_Имя\."""

import os
import shutil
from pathlib import Path

ROOT = Path(r"C:\Users\DETarasov\Documents\Link\Статистика работы механизмов\Конфигурация\DataProcessors")

LOG = []


def log(msg: str) -> None:
    LOG.append(msg)
    print(msg)


def reorganize_processor(outer_dir: Path) -> None:
    name = outer_dir.name
    inner_dir = outer_dir / name
    xml_top = ROOT / f"{name}.xml"
    xml_dest = outer_dir / f"{name}.xml"

    if inner_dir.exists() and xml_dest.exists():
        log(f"SKIP (уже пара): {name}")
        return

    if inner_dir.exists():
        log(f"WARN: вложенная папка есть, xml нет: {name}")

    inner_dir.mkdir(exist_ok=True)

    for item in list(outer_dir.iterdir()):
        if item.name == name:
            continue
        dest = inner_dir / item.name
        if dest.exists():
            raise FileExistsError(f"{dest} уже существует при переносе {item}")
        shutil.move(str(item), str(dest))

    if xml_top.exists():
        if xml_dest.exists():
            raise FileExistsError(f"xml уже на месте: {xml_dest}")
        shutil.move(str(xml_top), str(xml_dest))
    elif not xml_dest.exists():
        log(f"WARN: xml не найден: {name}")

    # Проверка: во внешней папке только вложенная + xml
    leftover = [
        p.name
        for p in outer_dir.iterdir()
        if p.name not in (name, f"{name}.xml")
    ]
    if leftover:
        log(f"WARN: лишнее в {name}: {leftover}")


def main() -> None:
    if not ROOT.is_dir():
        raise SystemExit(f"Папка не найдена: {ROOT}")

    processors = sorted(
        p for p in ROOT.iterdir() if p.is_dir() and not p.name.startswith(".")
    )
    log(f"Обработок: {len(processors)}")

    errors = []
    for outer in processors:
        try:
            reorganize_processor(outer)
        except Exception as exc:
            errors.append((outer.name, str(exc)))
            log(f"ERROR {outer.name}: {exc}")

    # Удалить xml на верхнем уровне (если остались)
    top_xml = list(ROOT.glob("*.xml"))
    if top_xml:
        log(f"Лишние xml на верхнем уровне: {len(top_xml)}")
        for xf in top_xml:
            log(f"  удаляю дубликат/осиротевший: {xf.name}")
            xf.unlink()

    nested = sum(1 for p in processors if (p / p.name).is_dir())
    top_xml_left = len(list(ROOT.glob("*.xml")))
    log(f"Итог: вложенных пар {nested}/{len(processors)}, xml на верхнем уровне: {top_xml_left}")

    if errors:
        log(f"Ошибок: {len(errors)}")
        for name, err in errors:
            log(f"  {name}: {err}")

    log_path = ROOT.parent / "reorganize_dataprocessors_log.txt"
    log_path.write_text("\n".join(LOG), encoding="utf-8")
    log(f"Лог: {log_path}")


if __name__ == "__main__":
    main()
