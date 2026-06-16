# -*- coding: utf-8 -*-
"""Аудит статистики в правильной папке DataProcessors."""

import re
from pathlib import Path

ROOT = Path(r"C:\Users\DETarasov\Documents\Link\Статистика работы механизмов\Конфигурация\DataProcessors")

CMD_RE = re.compile(
    r"^&НаКлиенте\s*\n(?:&Асинхронно\s*\n)?Процедура\s+(\w+)\s*\([^)]*Команда[^)]*\)",
    re.MULTILINE,
)
SESSION_RE = re.compile(r"ЗарегистрироватьНовуюСессию\s*\(")
AREA_RE = re.compile(r"#Область\s+СтатистикаРаботыВнутреннихМеханизмов")


def audit_file(path: Path) -> dict:
    text = path.read_text(encoding="utf-8-sig")
    commands = CMD_RE.findall(text)
    has_area = bool(AREA_RE.search(text))
    sessions = len(SESSION_RE.findall(text))
    wrapped = len(re.findall(r"ПараметрыСессии\s*=\s*ЗарегистрироватьНовуюСессию", text))
    return {
        "path": str(path.relative_to(ROOT)),
        "commands": commands,
        "cmd_count": len(commands),
        "has_area": has_area,
        "sessions": sessions,
        "wrapped": wrapped,
    }


def main():
    modules = sorted(ROOT.rglob("Forms/**/Module.bsl"))
    rows = [audit_file(m) for m in modules]

    no_area = [r for r in rows if not r["has_area"]]
    partial = [r for r in rows if r["has_area"] and r["wrapped"] < r["cmd_count"]]
    done = [r for r in rows if r["has_area"] and r["wrapped"] >= r["cmd_count"] and r["cmd_count"] > 0]
    no_cmds = [r for r in rows if r["cmd_count"] == 0]

    lines = [
        f"Всего Module.bsl: {len(rows)}",
        f"С командами: {len(rows) - len(no_cmds)}",
        f"Готово (область + все команды): {len(done)}",
        f"Без области: {len(no_area)}",
        f"Частично (область есть, не все команды): {len(partial)}",
        f"Без команд: {len(no_cmds)}",
        "",
        "=== БЕЗ ОБЛАСТИ (нужна работа) ===",
    ]
    for r in no_area:
        if r["cmd_count"] > 0:
            lines.append(f"{r['path']} | команд: {r['cmd_count']} | {', '.join(r['commands'][:5])}")

    lines.append("")
    lines.append("=== ЧАСТИЧНО ===")
    for r in partial:
        lines.append(f"{r['path']} | команд: {r['cmd_count']} обёрнуто: {r['wrapped']}")

    lines.append("")
    lines.append("=== БЕЗ КОМАНД ===")
    for r in no_cmds:
        lines.append(r["path"])

    out = ROOT.parent / "audit_stats_correct_folder.txt"
    out.write_text("\n".join(lines), encoding="utf-8")
    print("\n".join(lines[:30]))
    print(f"...\nЛог: {out}")


if __name__ == "__main__":
    main()
