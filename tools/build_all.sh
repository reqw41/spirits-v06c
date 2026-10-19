#!/bin/sh
# ПОЛНАЯ СБОРКА ОДНОЙ КОМАНДОЙ — те же пять шагов, что в README, и копия образа в rom/.
#   sh tools/build_all.sh        -> build/port/spirits-port-i8080.rom и rom/spirits.rom
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
mkdir -p rom
cp build/port/spirits-port-i8080.rom rom/spirits.rom
ls -l rom/spirits.rom
