# -*- coding: utf-8 -*-
"""Отчёт по статистике: обработка за обработкой."""

import re
from pathlib import Path
from collections import defaultdict

ROOT = Path(
    r"C:\Users\DETarasov\Documents\Link\Статистика работы механизмов\Конфигурация\DataProcessors"
)
OUT = ROOT.parent / "отчет_статистика_по_обработкам.txt"

CMD_RE = re.compile(
    r"^&НаКлиенте(?:\s*\n&Асинхронно)?\s*\nПроцедура\s+(\w+)\(Команда\)",
    re.MULTILINE,
)
WRAPPED_RE = re.compile(
    r"ПараметрыСессии\s*=\s*ЗарегистрироватьНовуюСессию\s*\(\s*\"(\w+)\"\s*\)"
)
AREA_RE = re.compile(r"#Область\s+СтатистикаРаботыВнутреннихМеханизмов")


def processor_dirs() -> list[Path]:
    dirs = []
    for p in sorted(ROOT.iterdir()):
        if not p.is_dir():
            continue
        name = p.name
        if name.startswith("_") or name == "И":
            dirs.append(p)
    return dirs


def analyze_module(path: Path) -> dict:
    text = path.read_text(encoding="utf-8-sig")
    commands = CMD_RE.findall(text)
    wrapped = set(WRAPPED_RE.findall(text))
    has_area = bool(AREA_RE.search(text))
    unwrapped = [c for c in commands if c not in wrapped]
    rel = path.relative_to(ROOT)
    return {
        "rel": str(rel),
        "form": rel.parts[2] if len(rel.parts) > 2 else "Форма",
        "commands": commands,
        "cmd_count": len(commands),
        "wrapped_count": len([c for c in commands if c in wrapped]),
        "unwrapped": unwrapped,
        "has_area": has_area,
    }


def status_processor(modules: list[dict]) -> tuple[str, str]:
    with_cmds = [m for m in modules if m["cmd_count"] > 0]
    without_cmds = [m for m in modules if m["cmd_count"] == 0]

    if not with_cmds:
        forms = ", ".join(sorted({m["form"] for m in without_cmds})) or "—"
        return "НЕТ КОМАНД", f"нет клиентских команд (Команда); формы: {forms}"

    total_cmds = sum(m["cmd_count"] for m in with_cmds)
    total_wrapped = sum(m["wrapped_count"] for m in with_cmds)
    all_areas = all(m["has_area"] for m in with_cmds)
    unwrapped_all = []
    no_area = []
    for m in with_cmds:
        unwrapped_all.extend(m["unwrapped"])
        if not m["has_area"]:
            no_area.append(m["form"])

    if total_wrapped >= total_cmds and all_areas and not unwrapped_all:
        extra = ""
        if without_cmds:
            extra = f"; доп. формы без команд: {len(without_cmds)}"
        return "СДЕЛАНО", f"{total_cmds} команд в {len(with_cmds)} форм(ах){extra}"

    reasons = []
    if unwrapped_all:
        reasons.append(f"не обёрнуто: {', '.join(unwrapped_all[:5])}" + ("..." if len(unwrapped_all) > 5 else ""))
    if no_area:
        reasons.append(f"нет области статистики в: {', '.join(no_area)}")
    if total_wrapped < total_cmds:
        reasons.append(f"обёрнуто {total_wrapped}/{total_cmds}")
    return "ЧАСТИЧНО", "; ".join(reasons)


def main():
    lines = [
        "ОТЧЁТ: статистика работы внутренних механизмов",
        f"Папка: {ROOT}",
        "",
    ]

    done, partial, no_cmds, other = [], [], [], []

    for proc_dir in processor_dirs():
        proc_name = proc_dir.name
        if proc_name == "И":
            inner = list(proc_dir.iterdir())
            if inner:
                proc_name = inner[0].name

        modules = []
        for mod in sorted(proc_dir.rglob("Forms/**/Module.bsl")):
            modules.append(analyze_module(mod))

        status, reason = status_processor(modules)
        entry = (proc_name, status, reason, modules)

        if status == "СДЕЛАНО":
            done.append(entry)
        elif status == "ЧАСТИЧНО":
            partial.append(entry)
        elif status == "НЕТ КОМАНД":
            no_cmds.append(entry)
        else:
            other.append(entry)

    lines.append(f"Всего обработок: {len(done) + len(partial) + len(no_cmds) + len(other)}")
    lines.append(f"  СДЕЛАНО:      {len(done)}")
    lines.append(f"  ЧАСТИЧНО:     {len(partial)}")
    lines.append(f"  НЕТ КОМАНД:   {len(no_cmds)}")
    lines.append(f"  ПРОЧЕЕ:       {len(other)}")
    lines.append("")

    def block(title, items):
        lines.append(f"=== {title} ({len(items)}) ===")
        for name, status, reason, mods in sorted(items, key=lambda x: x[0]):
            lines.append(f"{name}")
            lines.append(f"  Статус: {status}")
            lines.append(f"  Причина: {reason}")
            with_cmds = [m for m in mods if m["cmd_count"] > 0]
            for m in with_cmds:
                lines.append(f"  - {m['form']}: {m['cmd_count']} команд")
        lines.append("")

    block("СДЕЛАНО — статистика добавлена во все команды", done)
    block("ЧАСТИЧНО — есть незавершённые команды", partial)
    block("НЕТ КОМАНД — статистика не требуется", no_cmds)
    if other:
        block("ПРОЧЕЕ", other)

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print("\n".join(lines[:40]))
    print("...")
    print(f"Полный отчёт: {OUT}")


if __name__ == "__main__":
    main()
