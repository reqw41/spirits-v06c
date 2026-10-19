#!/usr/bin/env node
// Ловушка непереехавших адресов: код игры, трогающий экранные плоскости напрямую.
//   node tools/trap_stale_v06js.js [rom] [кадров]
'use strict';
// ЯДРО И КАРТА АДРЕСОВ: CPU=i8080 — ванильный КР580ВМ80А и
// перекомпилированный образ; по умолчанию ядро Z80 и эталонный образ
// (docs/recompilation.md, §3в).
const M = require('./v06map').load((process.env.CPU || 'i8080') === 'i8080');
const CORE = M.i8080 ? [] : ['Z80_v06.js', 'z80_adapter.js'];
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.join(__dirname, '..');
const V06 = process.env.V06 || path.join(process.env.HOME, 'projects/vector06js');
const ROM = process.argv[2] || path.join(ROOT, 'build/adapter/spirits.rom');
const FRAMES = Number(process.argv[3] || 400);
const SHOW = Number(process.argv[4] || 40);

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
  ...CORE
]) {
  vm.runInContext(fs.readFileSync(path.join(V06, f), 'utf8'), ctx, { filename: f });
}
const { Memory, IO, AY, I8253, Keyboard, I8080, Vector06c, Floppy } = ctx;

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
const v06c = new Vector06c(cpu, memory, io, ay, tape);
v06c.tape_player = tape;
v06c.bmp = new Uint32Array(576 * 288);
v06c.displayFrame = () => {};
v06c.dbg = null;

const rom = new Uint8Array(fs.readFileSync(ROM));
memory.init_from_array(rom, 0x0100);
if (memory.detach_boot) memory.detach_boot();
cpu.pc = 0x0100; cpu.sp = 0; cpu.iff = false;
timer.Write(3, 0x36); timer.Write(3, 0x76); timer.Write(3, 0xb6);


// ---- НАЖАТИЕ ПРОБЕЛА: ДВА ПУТИ СРАЗУ ------------------------------------
// build/adapter/spirits.rom врезок ввода не имеет: игра там читает МАТРИЦУ MSX
// (out AAh — ряд, in A9h — маска), и нажатие подкладывается в эти порты.
// В build/port/spirits-port.rom тех обращений уже нет — там и игра, и ЗАСТАВКА
// (src/v06/title.asm) читают НАСТОЯЩИЕ порты Вектора: ВВ55 (выбор ряда 0x03,
// чтение 0x02) и джойстик 0x0E.  Без второго пути заставка не кончается и
// ловушка смотрела бы 3000 кадров на неподвижную картинку.
// Раскладка матрицы Вектора — docs/v06-input-sound.md §2; образец перехвата
// взят из tools/snd_v06_probe.js:91-117.
const msxRow = { v: 0xff };
const msxKeys = { space: false };
const VKEY_SPACE = [7, 7];                 // ряд 7, бит 7 — ПРОБЕЛ Вектора
const ROWSEL = { 0xFE: 0, 0xFD: 1, 0xFB: 2, 0xF7: 3, 0xEF: 4, 0xDF: 5, 0xBF: 6, 0x7F: 7 };
let lastRow = null;
const realOut = io.realoutput.bind(io);
io.realoutput = function (port, w8) {
  if (port === 0xaa) { msxRow.v = w8; return; }
  if ((port & 0xff) === 0x03) lastRow = ROWSEL[w8 & 0xff];
  realOut(port, w8);
};
const realIn = io.input.bind(io);
io.input = function (port) {
  const p = port & 0xff;
  if (p === 0xa9) { let m = 0xff; if ((msxRow.v & 0x0f) === 8 && msxKeys.space) m &= ~0x01; return m & 0xff; }
  if (p === 0x02) {
    let m = 0xff;
    if (msxKeys.space && lastRow === VKEY_SPACE[0]) m &= ~(1 << VKEY_SPACE[1]) & 0xff;
    return m;
  }
  if (p === 0x0E) return msxKeys.space ? 0xff & ~0x40 : 0xff;   // b6 = ОГОНЬ1
  return realIn(port);
};


// ---- ЛОВУШКА 2: ИСПОЛНЕНИЕ ВНУТРИ ОБЛАСТЕЙ ДАННЫХ ------------------------
// Дизассемблер ходит по потоку управления; до чего он не дошёл — печатается
// сырыми `db`, и операнды внутри такого куска НЕ ПЕРЕЕЗЖАЮТ.  Значит любое
// ИСПОЛНЕНИЕ внутри области, помеченной в disasm/msx/v06/*.asm как «данные»,
// — это код со стухшими операндами, даже если он не трогает плоскости
// (стухший адрес BB89..BF88 молча попадает в блок данных, а не на экран).
// Куски берём прямо из шапок `; данные XXXX..YYYY` векторного дизасма.
const DATA_RANGES = [];
for (const f of ['spirits2_head', 'spirits2_tail', 'resident', 'himem']) {
  const fp = path.join(ROOT, 'disasm/msx/v06', f + '.asm');
  if (!fs.existsSync(fp)) continue;
  for (const m of fs.readFileSync(fp, 'utf8').matchAll(/; данные ([0-9A-F]{4})\.\.([0-9A-F]{4})/g)) {
    // Островки данных ПЕРЕЕЗЖАЮТ вместе с кодом (сборка i8080): границы
    // берутся из карты, длина у островка та же — он кладётся как есть.
    const lo = parseInt(m[1], 16), hi = parseInt(m[2], 16);
    let a = lo, b = hi;
    if (M.i8080) { try { a = M.g(lo); b = a + (hi - lo); } catch (e) { continue; } }
    DATA_RANGES.push([a, b, f]);
  }
}
const inData = (pc) => DATA_RANGES.find(r => pc >= r[0] && pc <= r[1]);
const dataHits = new Map();          // начало куска -> {n, first, pcmin, pcmax}

// ---- ЛОВУШКА НЕПЕРЕЕХАВШИХ АДРЕСОВ --------------------------------------
// Схема цвета «Exolon»: ВИДИМЫ три верхние плоскости A000..FFFF, невидима
// нижняя 8000..9FFF — в ней лежит хвост блока данных игры 6847..9F88, и
// писать туда игра обязана. Код ИГРЫ не должен трогать ВИДИМЫЕ плоскости
// иначе как через адаптер. Любое такое обращение — это адрес из
// ОРИГИНАЛЬНОЙ раскладки (там по BB89..FAC5 жили код, слой и рабочая RAM),
// который при переезде остался числом.
const VIS = 0xA000;                          // первая ВИДИМАЯ плоскость
const DATA_LO = 0x6847, DATA_HI = 0x9F88;    // блок данных игры
const AD_LO = 0x4A00, AD_HI = 0x6426;        // оба адаптера: ввод/звук и экран
                                             // (слияние E + F: экранный занял
                                             //  всю зону 5000..6425)
// ЗАСТАВКА (src/v06/title.asm, только в build/port/spirits-port.rom) живёт в
// 4620..49FF — в МЁРТВЫХ ТЕНЕВЫХ ТАБЛИЦАХ спрайтов игры, следом за списками
// объектов SPRL/SPRO (сборка не даёт ей вылезти за 4A00,
// tools/build_port_rom.py).  Прежнее место 6100..64FF занял разросшийся
// адаптер экрана (слияние E + F).  Пока управление не дошло до SCR_INIT
// (5000), исполнение и обращения оттуда законны; после — прежнее правило в
// силе, и код игры в этой зоне по-прежнему считается срывом.
const TITLE_LO = 0x4620, TITLE_HI = 0x49FF;
let titleDone = false;
let curPC = 0, FR = 0;
const hits = new Map();                       // pc -> {n, first, addr, kind}
const portA2 = { n: 0, vals: new Set() };
function inTitle(pc) { return !titleDone && pc >= TITLE_LO && pc <= TITLE_HI; }
function inGame(pc) { return !(pc >= AD_LO && pc < AD_HI) && pc >= 0x0100 && !inTitle(pc); }
function note(kind, addr) {
  if (!inGame(curPC)) return;
  const k = curPC * 4 + (kind === 'R' ? 0 : kind === 'W' ? 1 : 2);
  let h = hits.get(k);
  if (!h) { h = { pc: curPC, kind, n: 0, first: FR, addr, amin: addr, amax: addr }; hits.set(k, h); }
  h.n++; if (addr < h.amin) h.amin = addr; if (addr > h.amax) h.amax = addr;
}
// ---- ЛОВУШКА 3: ДЫРКИ ВЫРАВНИВАНИЯ И СВОБОДНАЯ ЗОНА ----------------------
// Стухший адрес не обязан попасть в плоскости: числа 0x8447..0x8846 (данные
// оригинала) и 0x64AA.. (page 1) ложатся в свободную зону, а дырки между
// кусками раскладки не принадлежат никому.  Чтение оттуда кодом ИГРЫ — либо
// стухший адрес, либо мусор; и то и другое надо видеть.  Стек (45FC..49FF)
// и оба адаптера исключены.
const HOLES = [
  // 39C6..49FF — РАБОЧАЯ ОБЛАСТЬ ИГРЫ (буферы, теневые таблицы спрайтов и
  // страница заворота), писать туда игра обязана: не следим.
  [0x4A00, 0x4C92, 'адаптер ввода/звука 4A00..4C92'],
  [0x4D00, 0x4DFF, 'дырка 4D00..4DFF'],
  [0x5000, 0x6425, 'адаптер экрана 5000..6425'],
  [0x4EAA, 0x4F21, 'ТАБЛИЦА ЭФФЕКТОВ 4EAA..4F21'],
  // 5F80..5FFF — стек, туда пишут все.
  // ЭТАП E: SPRST (6000..6083) и HR_SAV (6084..60E3) умерли вместе с
  // теневыми таблицами игры.  СЛИЯНИЕ E + F: всю зону 5000..6425 занял
  // сам адаптер экрана, списки объектов уехали в мёртвые теневые таблицы
  // (SPRL 4400, SPRO 4510).  СЛИЯНИЕ СТИРАНИЯ И РИСОВАНИЯ (2026-09-22):
  // зона адаптера продлена до стека (5000..6425), а MIRBUF (4864..488B),
  // таблицы адресов записей банков (488C..4969) и таблички слияния
  // (MG_ZBUF 4990, MG_CARRY 49D8) уехали в те же мёртвые теневые таблицы.
  // Стек (6426..64FF) на месте; свободных дырок тут нет.
  // 4F22..4FFF — ничейная дырка между таблицей эффектов и адаптером: туда
  // уехали вторая зона переменных адаптера (4F22..4F35) и ПРИЁМНИК мёртвой
  // записи 2:CE83 (4F36..4F3D, 8 ожидаемых записей ldir'ом за прогон, см.
  // BYTE_TAB адаптера).  За ней не следим по той же причине, по какой не
  // следили за 60E4..60FF.
  [0x6800, DATA_LO - 1, 'свободная зона 6800..6846'],
  [DATA_HI + 1, VIS - 1, 'хвост невидимой плоскости 9F89..9FFF'],
];
const holeHits = new Map();
function noteHole(kind, a) {
  if (!inGame(curPC)) return;
  const h = HOLES.find(r => a >= r[0] && a <= r[1]);
  if (!h) return;
  const k = h[0] * 8 + (kind === 'R' ? 0 : 1);
  let e = holeHits.get(k);
  if (!e) { e = { name: h[2], kind, n: 0, first: FR, amin: a, amax: a, pc: curPC }; holeHits.set(k, e); }
  e.n++; if (a < e.amin) e.amin = a; if (a > e.amax) e.amax = a;
}

// ЭТАП E: теневые таблицы спрайтов игры (SAT F77E -> 407E, образы F800 ->
// 4100, страница заворота 4900) должны быть МЕРТВЫ: объект попадает на
// экран прямо из D0A0, а чистку в D0F2 перепрыгивает патч BYTE_TAB.
// Считаем ВСЕ обращения кода игры к 407E..49FF и запоминаем pc.
const SHADOW = { lo: 0x407E, hi: 0x49FF, r: 0, w: 0, pcs: new Map() };
// ЗОНЫ БАЙТ-КОДА ХОДА БРОДЯЧИХ ОБЪЕКТОВ (tools/mk_scripts.py): часть из них
// лежит ВНУТРИ теневых таблиц, и ЧИТАТЬ их игра обязана — это данные.  А вот
// ИСПОЛНЯТЬСЯ там нечему: попал туда pc — срыв.  Раскладку берём из сборки,
// чтобы список не разъехался с образом.
const SCRZ = (() => {
  const f = path.join(ROOT, 'build/port/scripts-zones.json');
  if (!fs.existsSync(f)) return [];
  return JSON.parse(fs.readFileSync(f, 'utf8')).zones.map(z => [z.lo, z.hi]);
})();
const inScr = (a) => SCRZ.some(([lo, hi]) => a >= lo && a <= hi);
const SCREXEC = { n: 0, pcs: new Map() };
function noteShadow(kind, a) {
  if (a < SHADOW.lo || a > SHADOW.hi) return;
  if (inScr(a)) return;          // байт-код хода объектов — законные данные
  if (!inGame(curPC)) return;
  if (kind === 'R') SHADOW.r++; else SHADOW.w++;
  const k = kind + curPC.toString(16);
  SHADOW.pcs.set(k, (SHADOW.pcs.get(k) || 0) + 1);
}

const mr = memory.read.bind(memory), mw = memory.write.bind(memory);
memory.read = function (a, s) { a &= 0xffff; if (!s) { if (a >= VIS) note('R', a); else { noteHole('R', a); noteShadow('R', a); } } return mr(a, s); };
memory.write = function (a, v, s) {
  a &= 0xffff;
  // MASKW (операнд `or 0x40` в VDP_SET_WADDR, res:D30D+1): его ставила
  // res:DA86, чтобы переключить запись на таблицу цвета.  Этап F перестал
  // его читать — значит надо доказать, что его никто и не пишет.
  if (a === M.g(0x1C0E) && !s) { maskwW.n++; maskwW.pc = curPC; }
  if (!s) { if (a >= VIS) note('W', a); else { noteHole('W', a); noteShadow('W', a); } }
  return mw(a, v, s);
};
const in0 = io.input.bind(io);
io.input = function (port) {
  const v = in0(port);
  if ((port & 0xff) === 0xA2) { portA2.n++; portA2.vals.add(v); }
  if ((port & 0xff) === 0x98 || (port & 0xff) === 0x99) vdpPorts.rd++;
  return v;
};
const out0 = io.realoutput.bind(io);
io.realoutput = function (port, w8) {
  if ((port & 0xff) === 0x98 || (port & 0xff) === 0x99) vdpPorts.wr++;
  return out0(port, w8);
};
// ---- ЛОВУШКА 4: ЗАГЛУШЁННЫЕ ВХОДЫ РЕЗИДЕНТА И ПОРТЫ VDP ------------------
// Этап F убрал модель адресов VRAM целиком, и в головы четырёх процедур
// слоя легли заглушки.  Если игра всё же туда приходит — это не срыв, но
// это надо ВИДЕТЬ: заглушка молча ничего не делает, и пропажа картинки
// выглядела бы как дефект вывода.  Сюда же — прямые обращения к портам
// MSX VDP 98/99: на Векторе их не существует, и любое обращение означает
// кусок пути вывода, мимо которого прошёл перехват.
const STUBS = [
  [M.g(0x1BFD), 'VDP_SET_RADDR 1BFD (заглушка ret)'],
  [M.g(0x1C06), 'VDP_SET_WADDR 1C06 (заглушка ret)'],
  [M.g(0x1C20), 'VDP_RD_BYTE 1C20 (заглушка xor a/ret)'],
  [M.g(0x1C28), 'VDP_WR_BYTE 1C28 (заглушка ret)'],
  [M.g(0x1A50), 'зеркальный вывод D150 (заглушка ret)'],
  [M.g(0x1694), 'CD94 значки заранее (заглушка ret)'],
  [M.g(0x200D), 'D70D выгрузка окна героя (заглушка ret)'],
  [M.g(0x1F92), 'D692 захват окна героя (заглушка ret)'],
  [M.g(0x1F9F), 'D69F то же (заглушка ret)'],
];
const stubHits = new Map();
const vdpPorts = { rd: 0, wr: 0 };
const maskwW = { n: 0, pc: 0 };

let crashed = null;
v06c.check_breakpoint = function () {
  curPC = cpu.pc;
  if (curPC === 0x5000) titleDone = true;     // заставка ушла в SCR_INIT
  if (inTitle(curPC)) return false;
  for (const [a, name] of STUBS) if (curPC === a) {
    let e = stubHits.get(a);
    if (!e) { e = { name, n: 0, first: FR }; stubHits.set(a, e); }
    e.n++;
  }
  if (curPC >= 0x0100 && curPC < 0x4A00) {
    const r = inData(curPC);
    if (r) {
      let h = dataHits.get(r[0]);
      if (!h) { h = { lo: r[0], hi: r[1], seg: r[2], n: 0, first: FR, pcmin: curPC, pcmax: curPC }; dataHits.set(r[0], h); }
      h.n++; if (curPC < h.pcmin) h.pcmin = curPC; if (curPC > h.pcmax) h.pcmax = curPC;
    }
  }
  // ИСПОЛНЕНИЕ В ЗОНЕ БАЙТ-КОДА ХОДА ОБЪЕКТОВ = СРЫВ.  Данные читать можно,
  // исполнять — нельзя: значит, куда-то уехал указатель или стек.
  if (inScr(curPC)) {
    SCREXEC.n++;
    const k = curPC.toString(16);
    SCREXEC.pcs.set(k, (SCREXEC.pcs.get(k) || 0) + 1);
  }
  // исполнение в видимых плоскостях, в таблицах адаптера, в свободной зоне
  // или ВНУТРИ блока данных = срыв.
  // СЛИЯНИЕ E + F: порог был 0x5F80 — бывшее дно стека.  Тело адаптера
  // выросло до 5000..6172, и его собственный КОД пошёл выше 5F80: прежний
  // порог объявлял бы срывом нормальную работу.  Порог был 6320 (начало
  // MIRBUF/BKP); со слиянием стирания и рисования тело дошло до 6420, а
  // таблицы уехали в низкую память — новый порог 6426, дно стека.
  if (!crashed && (curPC >= VIS || (curPC >= 0x6426 && curPC <= DATA_HI))) {
    crashed = { pc: curPC, fr: FR };
  }
  return false;
};
const FRAMES2 = Number(process.argv[3] || 1200);
for (let f = 0; f < FRAMES2; f++) {
  msxKeys.space = (f % 200) > 150;
  FR = f; v06c.oneInterrupt(true);
  if (crashed) break;
}
const drows = [...dataHits.values()].sort((a, b) => a.first - b.first || a.lo - b.lo);
console.log(`кусков «данных», в которых ИСПОЛНЯЛСЯ код: ${drows.length}` +
  `  (всего кусков данных: ${DATA_RANGES.length})`);
for (const h of drows) {
  console.log(`  ${h.lo.toString(16).padStart(4, '0')}..${h.hi.toString(16).padStart(4, '0')}` +
    ` (${h.seg}) x${h.n} кадр ${h.first}  исполнялось ${h.pcmin.toString(16)}..${h.pcmax.toString(16)}`);
}
const hrows = [...holeHits.values()].sort((a, b) => a.first - b.first);
console.log(`обращений кода игры в дырки выравнивания и свободную зону: ${hrows.length}`);
for (const h of hrows) {
  console.log(`  ${h.name} ${h.kind} x${h.n} кадр ${h.first}` +
    `  адреса ${h.amin.toString(16)}..${h.amax.toString(16)}  pc=${h.pc.toString(16)}`);
}
// Таблица звуковых эффектов 4EAA..4F21 (SPIRITS.1[104B..10C2]) — её кладёт
// сборка ROM, и переписать её никто не должен.
{
  let bad = 0, first = -1;
  for (let a = 0x4EAA; a <= 0x4F21; a++) {
    const want = rom[a - 0x0100], got = memory.read(a, true);
    if (want !== got) { if (first < 0) first = a; bad++; }
  }
  console.log(`таблица эффектов 4EAA..4F21: изменено ${bad} байт из 120` +
    (bad ? `, первый ${first.toString(16)}` : ''));
}
{ // ЭТАП E: теневые таблицы спрайтов 407E..49FF обязаны быть мертвы
  const top = [...SHADOW.pcs.entries()].sort((a, b) => b[1] - a[1]).slice(0, 8);
  {
  const top = [...SCREXEC.pcs.entries()].sort((a, b) => b[1] - a[1]).slice(0, 6);
  console.log(`зоны байт-кода хода объектов (${SCRZ.length} шт.): ИСПОЛНЕНИЙ` +
    ` ${SCREXEC.n}` + (top.length ? '  ' + top.map(([k, n]) => `${k}x${n}`).join(' ') : '')
    + (SCREXEC.n ? '  !!! СРЫВ' : ''));
  if (SCREXEC.n) process.exitCode = 7;
}
console.log(`теневые таблицы спрайтов 407E..49FF: код игры читал ${SHADOW.r},` +
    ` писал ${SHADOW.w}` + (top.length ? '  места: ' + top.map(([k, n]) => `${k}x${n}`).join(' ') : ''));
}
// ЗОНЫ ПЕРЕВОДА (--lang ru): русские строки и глифы кириллицы лежат в
// образе как данные, писать туда не должен никто — ни игра, ни адаптер.
// Приписанные глифы 9F8A..9FF1 стоят в хвосте НЕВИДИМОЙ плоскости, и эта
// сверка — прямой замер того, что хвост действительно мёртв.
{
  const zf = path.join(ROOT, 'build/i18n/ru-expect.json');
  if (fs.existsSync(zf)) {
    const zones = JSON.parse(fs.readFileSync(zf, 'utf8')).zones || [];
    let bad = 0, n = 0, worst = '';
    for (const [lo, hi, name] of zones) {
      let z = 0;
      for (let a = lo; a <= hi; a++) {
        n++;
        if (rom[a - 0x0100] !== memory.read(a, true)) { bad++; z++; }
      }
      if (z) worst += `\n  ПЕРЕПИСАНО ${z} б в зоне ${name} ` +
        `${lo.toString(16)}..${hi.toString(16)}`;
    }
    console.log(`зоны перевода (${zones.length} шт., ${n} б): изменено ${bad} байт` + worst);
  }
}
const rows = [...hits.values()].sort((a, b) => a.first - b.first || a.pc - b.pc);
console.log(`кадров: ${FR + 1}, срыв: ${crashed ? 'pc=' + crashed.pc.toString(16) + ' кадр ' + crashed.fr : 'нет'}`);
console.log(`порт A2 (джойстик MSX через PSG): чтений ${portA2.n}, значения: ${[...portA2.vals].map(v => v.toString(16)).join(',') || '—'}`);
console.log(`порты MSX VDP 98/99: чтений ${vdpPorts.rd}, записей ${vdpPorts.wr} (ждём 0/0)`);
console.log(`MASKW (1C0E) переписан ${maskwW.n} раз` +
  (maskwW.n ? `, последний pc=${maskwW.pc.toString(16)}` : ' — операнд мёртв, его незачем читать'));
{
  const sr = [...stubHits.entries()].sort((a, b) => b[1].n - a[1].n);
  console.log(`заглушённые входы резидента, в которые игра ВСЁ ЖЕ приходит: ${sr.length}`);
  for (const [, e] of sr) console.log(`  ${e.name}: x${e.n}, впервые кадр ${e.first}`);
}
console.log(`мест в коде игры, трогающих ВИДИМЫЕ плоскости (>=A000) напрямую: ${rows.length}`);
for (const h of rows.slice(0, 60)) {
  console.log(`  pc=${h.pc.toString(16).padStart(4, '0')} ${h.kind} x${String(h.n).padStart(6)} ` +
    `кадр ${String(h.first).padStart(4)}  адреса ${h.amin.toString(16)}..${h.amax.toString(16)}`);
}
