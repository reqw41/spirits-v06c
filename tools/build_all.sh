#!/bin/sh
# ПОЛНАЯ СБОРКА ОДНОЙ КОМАНДОЙ — те же пять шагов, что в README, и копия образа в rom/.
#   sh tools/build_all.sh        -> rom/spirits.rom (с заставкой, 65280 Б) и
#                                  rom/spirits-notitle.rom (без заставки — для Турбо+ из CP/M
#                                  и загрузчиков, которым 64 КБ не по силам);
#                                  rom/spirits-es.rom и rom/spirits-es-notitle.rom —
#                                  то же на испанском, языке оригинала MSX (--lang es)
# Ассемблер — zasm 4.5 (ключ --8080): путь в ZASM, иначе zasm из PATH.
set -e
cd "$(dirname "$0")/.."
if [ -z "${ZASM:-}" ]; then
  ZASM=$(command -v zasm || true)
  [ -n "$ZASM" ] || ZASM=$HOME/projects/kvalley-v06c/tools/bin/sjasm
fi
export ZASM
sh tools/build_adapter.sh
python3 tools/build_v06_rom.py
python3 tools/recompile_i8080.py
python3 tools/build_v06_rom.py --cpu i8080
python3 tools/build_port_rom.py --cpu i8080
python3 tools/build_port_rom.py build/port-notitle --cpu i8080 --no-title
# Испанский: код игры тот же (рекомпиляция от языка не зависит), меняются
# только строки, шрифт и текст справки (docs/help-page-es.md).
python3 tools/build_v06_rom.py --cpu i8080 --lang es
python3 tools/build_port_rom.py build/port-es --cpu i8080 --lang es
python3 tools/build_port_rom.py build/port-es-notitle --cpu i8080 --lang es --no-title
mkdir -p rom
cp build/port/spirits-port-i8080.rom rom/spirits.rom
cp build/port-notitle/spirits-port-i8080.rom rom/spirits-notitle.rom
cp build/port-es/spirits-port-i8080.rom rom/spirits-es.rom
cp build/port-es-notitle/spirits-port-i8080.rom rom/spirits-es-notitle.rom
ls -l rom/
