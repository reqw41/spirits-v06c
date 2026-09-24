#!/bin/sh
# Сборка адаптера ввода и звука (src/v06) + проверка чистоты i8080.
# Ассемблер тот же, что у остальных портов Вектора: zasm из kvalley-v06c.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
ZASM=${ZASM:-$HOME/projects/kvalley-v06c/tools/bin/sjasm}

mkdir -p "$ROOT/build/v06"
"$ZASM" -b -w \
    "$ROOT/src/v06/adapter.asm" \
    "$ROOT/build/v06/adapter.lst" \
    "$ROOT/build/v06/adapter.bin"

python3 "$ROOT/tools/check_i8080.py" \
    "$ROOT/build/v06/adapter.bin" "$ROOT/build/v06/adapter.lst"
echo
python3 "$ROOT/tools/adapter_probe.py" \
    "$ROOT/build/v06/adapter.bin" "$ROOT/build/v06/adapter.lst"
