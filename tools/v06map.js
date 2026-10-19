// КАРТА АДРЕСОВ КОДА ИГРЫ ДЛЯ СТЕНДОВ.
//
// Стенды знают игру по адресам её Z80-раскладки (19F2 — граница итерации,
// 2168 — «нарисовать героя» и так далее).  Перекомпилированный в i8080 образ
// собран ПО МЕТКАМ, и там эти адреса другие: карту ведёт
// tools/recompile_i8080.py -> build/i8080/labels.json.
//
//   const M = require('./v06map').load(process.env.CPU === 'i8080');
//   M.g(0x19F2)      // адрес в текущем образе
//
// Для образа Z80 карта — тождество, и стенд работает как раньше.
'use strict';
const fs = require('fs'), path = require('path');

function load(i8080) {
  if (!i8080) return { g: (a) => a, i8080: false, map: null };
  const p = path.join(__dirname, '..', 'build/i8080/labels.json');
  const map = JSON.parse(fs.readFileSync(p, 'utf8')).map;
  const g = (a) => {
    const k = (a & 0xFFFF).toString(16).toUpperCase().padStart(4, '0');
    if (!(k in map)) throw new Error('адреса ' + k + ' нет в карте i8080 '
      + '(рекомпиляция его не собирает) — стенд надо чинить, а не гадать');
    return parseInt(map[k], 16);
  };
  return { g, i8080: true, map };
}

// Точки перехвата ряда случайности для образа i8080: `ld a,r` стал
// `call il_rnd` (3 байта), перехват ставится за ним.
function rngHooks(M, sites, adj) {
  const h = {};
  sites.forEach(([a], i) => { h[M.g((a + adj) & 0xFFFF) + 3] = i; });
  return h;
}

// ЕДИНЫЙ ДОСТУП К РЕГИСТРАМ.  Ядро Z80 (z80_adapter) даёт getState/setState,
// ядро i8080 — reg()/set_reg()/pc/sp.  Стенды писались под первое; здесь
// второму дописывается тот же интерфейс, чтобы стенд не знал, какое ядро
// под ним.  Флаги (f) не эмулируются: ни один стенд их не читает.
const IDX = { b: 0, c: 1, d: 2, e: 3, h: 4, l: 5, a: 7 };

function shimState(cpu) {
  if (cpu.getState) return cpu;
  cpu.getState = function () {
    const s = { pc: cpu.pc, sp: cpu.sp };
    for (const k of Object.keys(IDX)) s[k] = cpu.reg(IDX[k]);
    return s;
  };
  cpu.setState = function (s) {
    for (const k of Object.keys(IDX)) if (s[k] !== undefined) cpu.set_reg(IDX[k], s[k]);
    if (s.pc !== undefined) cpu.pc = s.pc;
    if (s.sp !== undefined) cpu.sp = s.sp;
  };
  return cpu;
}

module.exports = { load, rngHooks, shimState };
