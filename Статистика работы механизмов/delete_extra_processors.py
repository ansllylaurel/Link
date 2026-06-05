# -*- coding: utf-8 -*-
"""Удалить из DataProcessors обработки, которых нет в (сломанные)."""

import re
import shutil
from pathlib import Path

NEW = Path(r"C:\Users\DETarasov\Documents\Link\Статистика работы механизмов\Конфигурация\DataProcessors")
OLD = Path(r"C:\Users\DETarasov\Documents\Link\Статистика работы механизмов\Конфигурация\DataProcessors (сломанные)")
LOG = NEW.parent / "delete_extra_processors_log.txt"


def base_name(folder_name: str) -> str:
    match = re.match(r"^(.+?) \(.+\)$", folder_name)
    return match.group(1) if match else folder_name


def main() -> None:
    old_names = {base_name(p.name) for p in OLD.iterdir() if p.is_dir()}
    new_dirs = sorted(p for p in NEW.iterdir() if p.is_dir())
    to_delete = [p for p in new_dirs if p.name not in old_names]

    lines = [
        f"В (сломанные): {len(old_names)}",
        f"В NEW до удаления: {len(new_dirs)}",
        f"Удалить: {len(to_delete)}",
        "",
    ]

    for path in to_delete:
        shutil.rmtree(path)
        lines.append(f"DELETED: {path.name}")

    remaining = sorted(p.name for p in NEW.iterdir() if p.is_dir())
    lines.extend(["", f"Осталось в NEW: {len(remaining)}"])

    missing = sorted(old_names - set(remaining))
    if missing:
        lines.append(f"WARN — нет в NEW после удаления: {missing}")

    LOG.write_text("\n".join(lines), encoding="utf-8")
    print("\n".join(lines[-5:]))
    print(f"Лог: {LOG}")


if __name__ == "__main__":
    main()
