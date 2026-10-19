#!/usr/bin/env node
// СТЕНД ЧИТОВ (docs/cheats.md).  Прогоняет ПОЛНЫЙ порт на vector06js и
// проверяет каждое обещание чита замером, а не глазами:
//   * F1+F3 на старте включают режим, без них не включается ничего;
//   * G — god mode: энергия не убывает, флаг смерти не ставится;
//   * 8/9/6/7 — комната меняется на ту, что записана в соседях, и экран
//     перерисован;  K — комната нижнего («смотрового») окна;
//   * ВК — пауза: витки игрового цикла останавливаются, повторное нажатие
//     продолжает;
//   * без F1+F3 клавиши G/6/7/8/9/K не делают РОВНО НИЧЕГО.
// Плюс СВЕРКА С ПРЕЖНЕЙ СБОРКОЙ: если дать вторым образом порт без читов,
// стенд прогоняет оба без единого нажатия чита и сравнивает картинку и
// игровые ячейки — так видно, что врезки читов ничего не сдвинули.
//
//   node tools/cheat_probe_v06js.js [rom] [outdir] [базовый-rom]
//
// Кадры кладутся в outdir (по умолчанию build/adapter/shots-cheat).
'use strict';
// ЯДРО И КАРТА АДРЕСОВ: CPU=i8080 — ванильный КР580ВМ80А и
// перекомпилированный образ; по умолчанию ядро Z80 и эталонный образ
// (docs/recompilation.md, §3в).
const M = require('./v06map').load((process.env.CPU || 'i8080') === 'i8080');
const CORE = M.i8080 ? [] : ['Z80_v06.js', 'z80_adapter.js'];
const fs = require('fs');
const zlib = require('zlib');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const ROM = process.argv[2] || path.join(ROOT, 'build/port/spirits-port-i8080.rom');
const OUT = process.argv[3] || path.join(ROOT, 'build/adapter/shots-cheat');
const BASE_ROM = process.argv[4] || null;
const SEED = process.env.SPIRITS_SEED !== undefined
  ? Number(process.env.SPIRITS_SEED) : 1;
fs.mkdirSync(OUT, { recursive: true });

// ---------------------------------------------------------------- vector06js
global.window = global;
global.document = { createElement: () => fc(), getElementById: () => fc() };
function fcx() {
  return {
    createImageData: (w, h) => ({ data: new Uint8ClampedArray((w || 1) * (h || 1) * 4), width: w, height: h }),
    putImageData: () => {}, drawImage: () => {}, getImageData: () => ({ data: new Uint8ClampedArray(4) }),
    fillRect: () => {}, save: () => {}, restore: () => {}, scale: () => {}, setTransform: () => {}
  };
}
function fc() { return { width: 0, height: 0, style: {}, getContext: () => fcx() }; }
global.requestAnimationFrame = () => 0;
global.setTimeout = () => 0;
global.print = () => {};
global.console.debug = () => {};
const g = {};
for (const k of Object.getOwnPropertyNames(global)) g[k] = global[k];
g.window = g;
const ctx = vm.createContext(g);
for (const f of [
  'i8080-js/i8080_trace.js', 'i8080-js/i8080_disasm.js', 'i8080-js/i8080.js',
  'src/fili.js', 'src/ay.js', 'src/fd1793.js', 'src/fddimage.js', 'src/i8253.js',
  'src/io.js', 'src/keyboard.js', 'src/memory.js', 'src/sound.js', 'src/tv.js',
  ...CORE                             // ПОСЛЕ tv.js: подменяет глобальный I8080
]) vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;

// -------------------------------------------------------------------- адреса
// Ячейки читов ведёт адаптер (src/v06/kbd.asm), процедуры — модуль
// src/v06/cheat.asm; и те и другие адреса берутся из ЛИСТИНГОВ сборки, а не
// вписываются сюда руками: сдвинется код — стенд поедет вместе с ним.
function labels(lst) {
  const out = {};
  const t = fs.readFileSync(lst, 'utf8');
  for (const m of t.matchAll(/^(\w+)\s+= \$([0-9A-F]{4}) =/gm)) out[m[1]] = parseInt(m[2], 16);
  return out;
}
const L = labels(path.join(ROOT, 'build/v06/adapter.lst'));
const C = labels(path.join(ROOT, 'build/port/cheat.lst'));
// Связка: V_START (там открывается окно читов) и V_JOY_PACE (первый виток
// игры ставит окну срок).  Нужны РАСПИСАНИЮ НАЖАТИЙ, а не проверкам.
const GL = labels(path.join(ROOT, 'build/port/glue.lst'));
for (const n of ['v_cheat', 'v_god', 'v_cpend', 'v_carm']) {
  if (L[n] === undefined) { console.error(`в листинге адаптера нет ${n}`); process.exit(2); }
}
const A = {
  cheat: L.v_cheat, god: L.v_god, pend: L.v_cpend, carm: L.v_carm,
  room: M.g(0x0AF6),          // GAME_VARS+0xC — номер ВЕРХНЕЙ (игровой) комнаты
  hy: M.g(0x0AF4), hx: M.g(0x0AF5),
  nb: M.g(0x1D08),            // D408 — соседи [верх][низ][лево][право]
  low: M.g(0x167B),           // LEVEL_VARS+0 — комната нижнего окна
  ener: M.g(0x122D),          // C92D — счётчик энергии
  enerCall: M.g(0x122C),      // вход «убавить энергию на единицу»
  dead: M.g(0x0838),          // BF38 — флаг смерти
  deadCall: M.g(0x0F25),      // C625 — «мгновенная смерть»
  loop: M.g(0x19F2),          // голова игрового цикла (виток)
  roomDraw: M.g(0x1A84),      // D184 ROOMDRAW — отрисовка комнаты целиком
  pauseEnter: M.g(0x1F8D),    // D68D: `jp C55D` в KBD_CHK — РОВНО один раз на вход
                         // в паузу (сам цикл 155D крутится тысячи раз, по нему
                         // входы не сосчитать)
};

// ------------------------------------------------------- клавиши Вектора
// Ряд/бит по матрице ВВ55 (docs/v06-input-sound.md §2, vector06js
// src/keyboard.js).  Джойстик стенд НЕ подключает (порт 0x0E = FF): чит
// живёт только на клавиатуре, и подмешанный джойстик прятал бы ошибки.
const VKEY = {
  // Ход — стрелки ряда 0 (буквы QAOP в тень не идут, docs/v06-input-sound.md).
  fire: [7, 7], right: [0, 6], left: [0, 4], up: [0, 5], down: [0, 7],
  F1: [1, 3], F3: [1, 5],
  G: [4, 7], K: [5, 3],
  8: [3, 0], 9: [3, 1], 6: [2, 6], 7: [2, 7],   // читы комнат
  VK: [0, 2],
};
const ROWSEL = { 0xFE: 0, 0xFD: 1, 0xFB: 2, 0xF7: 3, 0xEF: 4, 0xDF: 5, 0xBF: 6, 0x7F: 7 };

function machine(romPath) {
  const memory = new Memory();
  const keyboard = new Keyboard();
  const timer = new I8253();
  const ay = new AY();
  const floppy = new (Floppy().FD1793)();
  const io = new IO(keyboard, timer, memory, ay, floppy);
  io.Palette = new Array(16).fill(0xff000000);
  const tape = { advance: () => {}, sample: 0, reset: () => {}, stop: () => {}, sampleAt: () => 0 };
  io.tape_player = tape;
  const cpu = new I8080(memory, io);
require('./v06map').shimState(cpu);   // единый доступ к регистрам
  const v06c = new Vector06c(cpu, memory, io, ay, tape);
  v06c.tape_player = tape;
  v06c.bmp = new Uint32Array(576 * 288);
  v06c.displayFrame = () => {};
  v06c.dbg = null;
  const rom = new Uint8Array(fs.readFileSync(romPath));
  memory.init_from_array(rom, 0x0100);
  if (memory.detach_boot) memory.detach_boot();
  cpu.pc = 0x0100; cpu.sp = 0; cpu.iff = false;
  timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);
  if (ay.reset) ay.reset();

  const held = new Set();
  let lastRow = null;
  const realOut = io.realoutput.bind(io);
  io.realoutput = function (port, w8) {
    if ((port & 0xff) === 0x03) lastRow = ROWSEL[w8 & 0xff];
    realOut(port, w8);
  };
  const realIn = io.input.bind(io);
  io.input = function (port) {
    const p = port & 0xff;
    if (p === 0x02) {
      let m = 0xff;
      if (lastRow !== null) {
        for (const k of held) {
          const v = VKEY[k];
          if (v && v[0] === lastRow) m &= ~(1 << v[1]) & 0xff;
        }
      }
      return m;
    }
    if (p === 0x0E) return 0xff;             // джойстика нет
    return realIn(port);
  };
  const rd = (a) => memory.read(a & 0xffff, false);
  // ЖУРНАЛ СМЕН КОМНАТЫ.  Читать ячейку «до и после» мало: герой, попав
  // наверх к самому полу (Y = 0x60), может тут же провалиться обратно —
  // штатный C32C уведёт его вниз, и по конечному значению переход выглядел
  // бы несостоявшимся.  Поэтому пишем ВСЮ последовательность.
  const rooms = [];
  const mw = memory.write.bind(memory);
  memory.write = function (a, v, s2) {
    if ((a & 0xffff) === M.g(0x0AF6)) rooms.push(v & 0xff);
    return mw(a, v, s2);
  };
  return { memory, cpu, io, v06c, held, rd, rooms };
}

// ----------------------------------------------------------------- PNG
const CRCT = (() => {
  const t = [];
  for (let n = 0; n < 256; n++) { let x = n; for (let k = 0; k < 8; k++) x = (x & 1) ? (0xedb88320 ^ (x >>> 1)) : (x >>> 1); t[n] = x >>> 0; }
  return t;
})();
const crc = (b) => { let x = 0xffffffff; for (let i = 0; i < b.length; i++) x = CRCT[(x ^ b[i]) & 255] ^ (x >>> 8); return (x ^ 0xffffffff) >>> 0; };
function shot(v06c, name) {
  const W = 576, H = 288;
  const raw = Buffer.alloc((W * 3 + 1) * H);
  let nz = 0;
  for (let y = 0; y < H; y++) {
    let o = y * (W * 3 + 1); raw[o++] = 0;
    for (let x = 0; x < W; x++) {
      const col = v06c.bmp[y * W + x] >>> 0;
      raw[o + x * 3] = col & 255; raw[o + x * 3 + 1] = (col >> 8) & 255; raw[o + x * 3 + 2] = (col >> 16) & 255;
      if ((col & 0xffffff) !== 0) nz++;
    }
  }
  const ch = (t, d) => {
    const ty = Buffer.from(t), l = Buffer.alloc(4), cr = Buffer.alloc(4);
    l.writeUInt32BE(d.length); cr.writeUInt32BE(crc(Buffer.concat([ty, d])));
    return Buffer.concat([l, ty, d, cr]);
  };
  const ih = Buffer.alloc(13);
  ih.writeUInt32BE(W, 0); ih.writeUInt32BE(H, 4); ih[8] = 8; ih[9] = 2;
  fs.writeFileSync(path.join(OUT, name), Buffer.concat([
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    ch('IHDR', ih), ch('IDAT', zlib.deflateSync(raw)), ch('IEND', Buffer.alloc(0))]));
  return nz;
}

// ----------------------------------------------------------- сценарий
// SHOTS: кадры по расписанию «кадр:клавиша» (клавиша держится 3 кадра) и
// снимки «кадр=имя.png».  Пример:
//   SHOTS="200=title.png 220:fire 300=help.png 320:fire 420=credits.png" \
//     node tools/shots_v06js.js rom outdir
const m = machine(ROM);
m.v06c.check_breakpoint = () => false;
const plan = (process.env.SHOTS || '').split(/\s+/).filter(Boolean);
const press = new Map(), snap = new Map();
let last = 0;
for (const p of plan) {
  let r;
  if ((r = p.match(/^(\d+):(\w+)$/))) press.set(+r[1], r[2]);
  else if ((r = p.match(/^(\d+)=(.+)$/))) snap.set(+r[1], r[2]);
  else { console.error('не понял: ' + p); process.exit(2); }
  last = Math.max(last, parseInt(p));
}
const release = new Map();
for (let f = 0; f <= last; f++) {
  if (press.has(f)) { m.held.add(press.get(f)); release.set(f + 3, press.get(f)); }
  if (release.has(f)) m.held.delete(release.get(f));
  m.v06c.oneInterrupt(true);
  if (snap.has(f)) { shot(m.v06c, snap.get(f)); console.log(`кадр ${f} -> ${snap.get(f)}`); }
}
