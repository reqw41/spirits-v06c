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
// Отпечаток картинки: контрольная сумма ВИДИМЫХ плоскостей A000..FFFF.
// Ею и доказывается «комната перерисована» — от снимка к снимку он обязан
// поменяться, а у двух сборок без читов обязан совпасть.
function planeCrc(m) {
  const b = Buffer.alloc(0x6000);
  for (let a = 0xA000; a < 0x10000; a++) b[a - 0xA000] = m.rd(a);
  return crc(b);
}

// ----------------------------------------------------------- сценарий
const FAIL = [];
function check(name, got, want) {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  if (!ok) FAIL.push(`${name}: получено ${JSON.stringify(got)}, ждали ${JSON.stringify(want)}`);
  console.log(`  [${ok ? 'ok ' : 'БЕДА'}] ${name}` + (ok ? '' : `  ${JSON.stringify(got)} != ${JSON.stringify(want)}`));
  return ok;
}

// Прогон одной сборки.  cheats:
//   true   — держим F1+F3 всё время заставки, справки и титров;
//   false  — не держим вовсе (та же раскладка нажатий);
//   'late' — КАК ДЕЛАЕТ ВЛАДЕЛЕЦ: F1+F3 зажаты ТОЛЬКО в момент нажатия
//            старта на титрах и первые 20 кадров игры.  До прежней правки
//            (окно = 150 кадров от V_START) этот случай читы НЕ включал:
//            окно истекало ещё на титрах, задолго до нажатия старта.
function run(romPath, { cheats, shots, tag }) {
  const m = machine(romPath);
  const det = require('./det_rng').install(m.cpu, -0xB700, SEED, M.i8080 ? require('./v06map').rngHooks(M, require('./det_rng').SITES, -0xB700) : null);
  let fnow = 0;                    // номер текущего кадра — для расписания
  const st = { it: -1, lastPc: -1, force: [],
               started: -1,      // кадр, на котором прошли V_START связки
               firstLoop: -1,    // кадр ПЕРВОГО витка игрового цикла
               // Сколько раз игра ПРИШЛА списывать энергию / убивать героя и
               // сколько раз это РЕАЛЬНО случилось.  Разность самих ячеек тут
               // не годится: энергию игра убавляет и сама по ходу дела, а флаг
               // смерти она тут же снимает, отыграв потерю жизни.  Метки взяты
               // из листинга модуля читов, счёт — по PC.
               eIn: 0, eGo: 0, dIn: 0, dNo: 0,
               pau: 0,           // входов в паузу
               draw: 0,          // входов в ROOMDRAW (D184) — «экран перерисован»
               mv: 0 };          // сколько раз V_CHEAT_MOVE прошёл оба гейта
  // Принудительный вызов процедуры игры НА ГРАНИЦЕ ВИТКА.  Зачем: чтобы
  // увидеть, списывается ли энергия и ставится ли флаг смерти, надо чтобы
  // герой кого-то коснулся; ловить это случайной ходьбой — замер, который
  // зависит от розыгрыша.  Здесь стенд зовёт ровно ту процедуру, которую в
  // игре зовёт касание (C92C и C625), тем же способом — call с возвратом в
  // голову витка, так что стек остаётся сбалансированным.
  m.v06c.check_breakpoint = function () {
    det.hook();
    const pc = m.cpu.pc;
    if (pc !== st.lastPc) {
      if (pc === A.pauseEnter) st.pau++;
      if (pc === A.roomDraw) st.draw++;
      // vcm_dir — РОВНО один раз на забранное нажатие: сам vcm_sh это цикл
      // поиска младшего бита и срабатывает по нескольку раз.
      if (pc === C.vcm_dir) st.mv++;
      if (pc === C.V_CHEAT_ENER) st.eIn++;
      else if (pc === C.vce_run) st.eGo++;
      else if (pc === C.V_CHEAT_DEATH) st.dIn++;
      else if (pc === C.vcd_no) st.dNo++;
      if (pc === GL.V_START && st.started < 0) st.started = fnow;
      if (pc === A.loop) {
        st.it++;
        if (st.firstLoop < 0) st.firstLoop = fnow;
        if (st.force.length) {
          const t = st.force.shift();
          m.cpu.sp = (m.cpu.sp - 2) & 0xffff;
          m.memory.write(m.cpu.sp, A.loop & 0xff, false);
          m.memory.write((m.cpu.sp + 1) & 0xffff, A.loop >> 8, false);
          m.cpu.pc = t;
        }
      }
      st.lastPc = pc;
    }
    return false;
  };
  const frame = (keys) => {
    m.held.clear();
    for (const k of keys) m.held.add(k);
    m.v06c.oneInterrupt(true);
    fnow++;
  };
  const run_ = (n, keys) => { for (let i = 0; i < n; i++) frame(keys); };
  // --- титры и справка: короткое нажатие огня раз в 200 кадров, как в
  //     tools/shot_v06js.js.  F1+F3 держим ВСЁ это время: окно включения
  //     открывается только в V_START, то есть уже после заставки.
  const base = cheats === true ? ['F1', 'F3'] : [];
  const LATE_TITLES = 300;   // сколько кадров смотрим ТИТРЫ, прежде чем нажать старт
  let f = 0;
  for (; f < (cheats === 'late' ? 1400 : 900); f++) {
    let fire = (f % 200) > 150;
    let k = base;
    if (cheats === 'late') {
      // ТИТРЫ СМОТРИМ ДОЛГО.  Ровно в этом и весь случай: прежнее окно жило
      // 150 кадров от V_START, поэтому старт, нажатый через 300 кадров
      // титров, в него уже не попадал.  Нажатие старта — ОДНО.
      if (st.started >= 0) {
        const press = st.started + LATE_TITLES;
        fire = f >= press && f < press + 5;
      }
      // «в момент нажатия старта» — F1+F3 зажаты вместе с ним;
      // «первые 20 кадров игры» — 20 кадров от первого витка.
      const atStart = fire && st.started >= 0 && st.firstLoop < 0;
      const early = st.firstLoop >= 0 && (f - st.firstLoop) < 20;
      k = (atStart || early) ? ['F1', 'F3'] : [];
    }
    frame(k.concat(fire ? ['fire'] : []));
    if (st.it >= 40) break;
  }
  const rep = { it0: st.it, frames: f, cheat: m.rd(A.cheat), carm: m.rd(A.carm),
                started: st.started, firstLoop: st.firstLoop };
  // Дальше F1/F3 не держим: режим либо уже включён, либо не включится.
  const steps = [];
  const step = (name, keys, holdF, gapF, fn) => {
    run_(holdF, keys); run_(gapF, []);
    const r = { name, room: m.rd(A.room), god: m.rd(A.god), ener: m.rd(A.ener),
                dead: m.rd(A.dead), it: st.it,
                nb: [0, 1, 2, 3].map(i => m.rd(A.nb + i)), low: m.rd(A.low) };
    if (fn) fn(r);
    steps.push(r);
    return r;
  };
  // 0. исходное состояние
  const s0 = step('старт', [], 0, 2);
  if (shots) shot(m.v06c, `${tag}-00-start.png`);
  // 1. G — god mode
  step('G', ['G'], 3, 6);
  // 2. форсированное списание энергии x4 и смерть
  const c0 = { eIn: st.eIn, eGo: st.eGo, dIn: st.dIn, dNo: st.dNo };
  st.force.push(A.enerCall, A.enerCall, A.enerCall, A.enerCall);
  run_(40, []);
  st.force.push(A.deadCall);
  run_(20, []);
  const sE = step('энергия/смерть при god', [], 0, 2);
  const godCnt = { eIn: st.eIn - c0.eIn, eGo: st.eGo - c0.eGo,
                   dIn: st.dIn - c0.dIn, dNo: st.dNo - c0.dNo };
  // 3. переходы по комнатам
  // Маршрут подобран так, чтобы КАЖДАЯ из четырёх клавиш сработала хотя бы
  // раз по-настоящему, и вдобавок проверилась ветка «соседа нет».  Партия
  // всегда начинается в комнате 0 (левый верхний угол сетки 5x18), у неё
  // сверху ноль — значит первое 8 обязано не сделать ничего.
  //   8 (0, соседа нет) -> 9 (0->5) -> 9 (5->0A) -> 8 (0A->5)
  //   -> 6 (5->4) -> 7 (4->5)
  const moves = [['8', 0], ['9', 1], ['9', 1], ['8', 0], ['6', 2], ['7', 3]];
  const mv = [];
  let mn = 0;
  for (const [key, idx] of moves) {
    const before = { room: m.rd(A.room), nb: [0, 1, 2, 3].map(i => m.rd(A.nb + i)) };
    const mark = m.rooms.length, d0 = st.draw;
    const r = step(`комната ${key}`, [key], 3, 40);
    mv.push({ key, idx, want: before.nb[idx], from: before.room, got: r.room,
              seen: m.rooms.slice(mark), drew: st.draw - d0 });
    if (shots) shot(m.v06c, `${tag}-${++mn}-${key}-room${r.room.toString(16).padStart(2, '0')}.png`);
  }
  // 4. K — комната нижнего окна
  const beforeK = { room: m.rd(A.room), low: m.rd(A.low) };
  const markK = m.rooms.length, dK = st.draw;
  const rK = step('комната K', ['K'], 3, 40);
  const kmove = { want: beforeK.low, from: beforeK.room, got: rK.room,
                  seen: m.rooms.slice(markK), drew: st.draw - dK };
  if (shots) shot(m.v06c, `${tag}-K-room${rK.room.toString(16).padStart(2, '0')}.png`);
  // 5. ВК — пауза.  Меряем витки: в паузе игра стоит в цикле ожидания и
  //    голову витка не проходит вовсе.
  // Сперва дать игре ОСЕСТЬ: после телепорта герой может свалиться в комнату
  // ниже, а перерисовка комнаты идёт по нескольку кадров, и всё это время
  // игра до проверки паузы (04A0) просто не доходит.  Держим ВК, пока игра
  // не войдёт в цикл паузы 155D, но не дольше 120 кадров — так замер не
  // зависит от того, на каком кадре кончилась отрисовка.
  run_(60, []);
  const itBefore = st.it;
  const pau0 = st.pau;
  let holdVK = 0;
  while (holdVK < 120 && st.pau === pau0) { frame(['VK']); holdVK++; }
  run_(20, []);                     // отпустили: игра ждёт «любую клавишу»
  const itPause = st.it;
  run_(40, []);                     // в паузе витков быть не должно НИ ОДНОГО
  const itStill = st.it;
  if (shots) shot(m.v06c, `${tag}-pause.png`);
  run_(6, ['VK']); run_(4, []); run_(6, ['fire']); run_(40, []);
  const itAfter = st.it;
  // 6. G — выключить god и повторить замер энергии/смерти
  step('G выкл', ['G'], 3, 6);
  const c1 = { eIn: st.eIn, eGo: st.eGo, dIn: st.dIn, dNo: st.dNo };
  st.force.push(A.enerCall, A.enerCall);
  run_(30, []);
  st.force.push(A.deadCall);
  run_(20, []);
  const offCnt = { eIn: st.eIn - c1.eIn, eGo: st.eGo - c1.eGo,
                   dIn: st.dIn - c1.dIn, dNo: st.dNo - c1.dNo };
  return { rep, s0, sE, mv, kmove, steps, godCnt, offCnt,
           pause: { itBefore, itPause, itStill, itAfter, holdVK,
                    entered: st.pau - pau0 },
           off: { god: m.rd(A.god) },
           mvTaken: st.mv, it: st.it, crc: planeCrc(m), m };
}

// ------------------------------------------ сверка «поведение не изменилось»
// Отдельный, НАРОЧНО ПРОСТОЙ прогон: ни одной клавиши чита, ни одного
// форсированного вызова, расписание ходьбы привязано к ВИТКАМ (как в
// tools/shot_v06js.js), а не к кадрам.  Только такой прогон можно
// сравнивать побайтно: в основном сценарии длительность удержания ВК
// подбирается на ходу, и две сборки разошлись бы уже поэтому.
function runPlain(romPath, marks) {
  const m = machine(romPath);
  const det = require('./det_rng').install(m.cpu, -0xB700, SEED, M.i8080 ? require('./v06map').rngHooks(M, require('./det_rng').SITES, -0xB700) : null);
  const st = { it: -1, lastPc: -1 };
  let keys = [];
  m.v06c.check_breakpoint = function () {
    det.hook();
    const pc = m.cpu.pc;
    if (pc !== st.lastPc) {
      if (pc === GL.V_START && st.started < 0) st.started = fnow;
      if (pc === A.loop) {
        st.it++;
        if (st.firstLoop < 0) st.firstLoop = fnow;
        const t = st.it % 150;
        keys = t < 50 ? ['right'] : t < 54 ? ['right', 'up']
          : t < 100 ? ['left'] : t < 104 ? ['left', 'up']
            : t < 108 ? ['fire'] : [];
      }
      st.lastPc = pc;
    }
    return false;
  };
  for (let f = 0; f < 900; f++) {
    m.held.clear();
    if ((f % 200) > 150) m.held.add('fire');
    m.v06c.oneInterrupt(true);
    if (st.it >= 20) break;
  }
  const out = [];
  const last = marks[marks.length - 1];
  for (let f = 1; f <= last; f++) {
    m.held.clear();
    for (const k of keys) m.held.add(k);
    m.v06c.oneInterrupt(true);
    if (marks.includes(f)) {
      out.push({ f, it: st.it, crc: planeCrc(m), rooms: m.rooms.join(','),
                 cells: [A.room, A.hx, A.hy, A.ener, A.dead, A.low]
                   .map(a => m.rd(a)).join(',') });
    }
  }
  return out;
}

// --------------------------------------------------------------- прогон
console.log(`СТЕНД ЧИТОВ: ${path.relative(ROOT, ROM)}  seed=${SEED}`);
console.log(`  ячейки: v_cheat=${A.cheat.toString(16)} v_god=${A.god.toString(16)}` +
  ` v_cpend=${A.pend.toString(16)}  процедуры: V_CHEAT_MOVE=${(C.V_CHEAT_MOVE || 0).toString(16)}` +
  ` V_CHEAT_ENER=${(C.V_CHEAT_ENER || 0).toString(16)} V_CHEAT_DEATH=${(C.V_CHEAT_DEATH || 0).toString(16)}`);

console.log('\nF1+F3 НА СТАРТЕ — режим читов');
const R = run(ROM, { cheats: true, shots: true, tag: 'ch' });
console.log(`  титры пройдены за ${R.rep.frames} кадров, витков ${R.rep.it0}`);
check('v_cheat = 1 (F1+F3 зажаты в окне включения)', R.rep.cheat, 1);
check('окно включения закрылось', R.rep.carm, 0);

console.log('\nG — GOD MODE');
check('до нажатия G god = 0', R.s0.god, 0);
console.log(`  за время god: вход в C92C ${R.godCnt.eIn} раз, списаний`
  + ` ${R.godCnt.eGo};  вход в C627 ${R.godCnt.dIn} раз, погашено ${R.godCnt.dNo}`);
check('энергия НИ РАЗУ не списана, а приходов было >= 4',
      [R.godCnt.eGo, R.godCnt.eIn >= 4], [0, true]);
check('смерть НИ РАЗУ не сработала, а приходов было >= 1',
      [R.godCnt.dNo === R.godCnt.dIn, R.godCnt.dIn >= 1], [true, true]);
check('флаг смерти чист', R.sE.dead, 0);

function hx(v) { return v.toString(16); }
function moveCheck(v, what) {
  const seen = v.seen.map(hx).join(',') || '—';
  if (v.want === 0 || v.want === 0xFF) {
    check(`${v.key}: ${what} = ${hx(v.want)} — не идём никуда`
      + `  (записей комнаты: ${seen})`, [v.seen.length, v.drew], [0, 0]);
  } else {
    check(`${v.key}: ${hx(v.from)} -> ${hx(v.want)} (${what}); дальше ${seen}`,
          v.seen.includes(v.want), true);
    check(`${v.key}: комната перерисована (входов в D184 ${v.drew})`,
          v.drew > 0, true);
  }
}
console.log('\n8 / 9 / 6 / 7 — СОСЕДНЯЯ КОМНАТА');
console.log('  (после перехода герой может свалиться дальше сам — это штатный'
  + ' C32C, поэтому меряется ВСЯ цепочка смен комнаты, а не конечное значение)');
for (const v of R.mv) moveCheck(v, 'сосед по записи комнаты');
console.log('\nK — КОМНАТА НИЖНЕГО ОКНА');
moveCheck(Object.assign({ key: 'K' }, R.kmove), 'LEVEL_VARS');

console.log('\nВК — ПАУЗА');
console.log(`  ВК держали ${R.pause.holdVK} кадров, вход в цикл паузы`
  + ` ${R.pause.entered} раз`);
check('ВК ввёл игру в паузу', R.pause.entered >= 1, true);
check('в паузе витков НЕ идёт вовсе (40 кадров)',
      R.pause.itStill - R.pause.itPause, 0);
check('после повторного нажатия витки пошли',
      R.pause.itAfter - R.pause.itStill > 0, true);

console.log('\nG ЕЩЁ РАЗ — GOD ВЫКЛЮЧЕН');
check('god снят', R.off.god, 0);
console.log(`  без god: вход в C92C ${R.offCnt.eIn}, списаний ${R.offCnt.eGo};`
  + ` вход в C627 ${R.offCnt.dIn}, погашено ${R.offCnt.dNo}`);
check('энергия списывается на каждом приходе',
      [R.offCnt.eGo === R.offCnt.eIn, R.offCnt.eIn >= 2], [true, true]);
check('смерть срабатывает на каждом приходе',
      [R.offCnt.dNo, R.offCnt.dIn >= 1], [0, true]);

console.log('\nБЕЗ F1+F3 — ТЕ ЖЕ НАЖАТИЯ НЕ ДЕЛАЮТ НИЧЕГО');
const N = run(ROM, { cheats: false, shots: true, tag: 'no' });
check('v_cheat = 0', N.rep.cheat, 0);
check('G не включил god', N.s0.god, 0);
console.log(`  вход в C92C ${N.godCnt.eIn}, списаний ${N.godCnt.eGo};`
  + ` вход в C627 ${N.godCnt.dIn}, погашено ${N.godCnt.dNo}`);
check('энергия списывается, смерть срабатывает — как и без читов',
      [N.godCnt.eGo === N.godCnt.eIn, N.godCnt.dNo], [true, 0]);
// ПРЯМОЙ признак: сколько раз V_CHEAT_MOVE прошёл оба гейта (v_cheat и
// копилку фронтов) и забрал нажатие.  Номер комнаты сам по себе не улика:
// без god герой от форсированной смерти теряет жизнь, и игра переставляет
// комнату сама.
console.log(`  нажатий, забранных читом: с F1+F3 ${R.mvTaken}, без ${N.mvTaken}`);
check('чит не забрал НИ ОДНОГО нажатия направления', N.mvTaken, 0);
check('с F1+F3 чит забрал все 7 нажатий (6 направлений + K)', R.mvTaken, 7);

// -------------------------- F1+F3 ТОЛЬКО ПРИ НАЖАТИИ СТАРТА НА ТИТРАХ
// СЛУЧАЙ ВЛАДЕЛЬЦА (наблюдение на MiSTer, 2026-09-23).  Он не держит F1+F3
// всю заставку — он зажимает их, когда нажимает старт на титрах, и
// отпускает уже в игре.  Прежнее окно (150 кадров от V_START) к этому
// моменту было закрыто: между V_START и первым витком игры лежат ВСЕ
// титры, а их длительность выбирает игрок.  Теперь окно открыто без срока
// до первого витка, и срок ему ставит V_JOY_PACE связки.
console.log('\nF1+F3 ТОЛЬКО В МОМЕНТ СТАРТА НА ТИТРАХ + 20 кадров игры');
const LT = run(ROM, { cheats: 'late', shots: false, tag: 'lt' });
console.log(`  V_START на кадре ${LT.rep.started}, первый виток игры на`
  + ` ${LT.rep.firstLoop} — титры длились ${LT.rep.firstLoop - LT.rep.started}`
  + ` кадров (прежнее окно жило 150 и кончалось на них)`);
check('титры длиннее прежнего окна в 150 кадров',
      LT.rep.firstLoop - LT.rep.started > 150, true);
check('v_cheat = 1 (F1+F3 зажаты только при нажатии старта)', LT.rep.cheat, 1);
check('окно включения закрылось', LT.rep.carm, 0);
console.log(`  нажатий, забранных читом: ${LT.mvTaken}`);
check('чит забрал все 7 нажатий (6 направлений + K)', LT.mvTaken, 7);
check('god mode включается и выключается, как и в первом прогоне',
      [LT.s0.god, LT.godCnt.eGo, LT.off.god], [0, 0, 0]);

// ------------------------------------------- сверка с прежней сборкой
if (BASE_ROM) {
  console.log(`\nСВЕРКА С ПРЕЖНЕЙ СБОРКОЙ: ${path.relative(ROOT, BASE_ROM)}`);
  // ЧЕСТНО О ЦЕНЕ.  Скан клавиатуры подорожал (adapter_probe печатает точное
  // число тактов), и на длинной дистанции это СДВИГАЕТ игру: тяжёлый виток
  // перешагивает границу кадра на такт раньше или позже, V_JOY_PACE выдаёт
  // на виток больше или меньше, и герой оказывается в другом пикселе.
  // Поэтому сверка не одна, а по контрольным точкам: печатается, до какого
  // кадра две сборки идут БАЙТ В БАЙТ.  Гейт — не меньше 900 кадров (18 с).
  const MARKS = (process.env.CHEAT_PLAIN || '300,600,900,1200,1500,1800,2400')
    .split(',').map(Number);
  const P = runPlain(ROM, MARKS), B = runPlain(BASE_ROM, MARKS);
  // Витки НЕ входят в условие совпадения: это фаза, а не состояние.  Виток
  // отмеряет V_JOY_PACE по 3-4 кадра попеременно, и подорожавший скан
  // сдвигает эту сетку на один кадр — счётчик расходится на единицу, пока
  // и картинка, и координаты, и цепочка комнат ещё совпадают байт в байт.
  let same = 0;
  for (let i = 0; i < P.length; i++) {
    const eq = P[i].crc === B[i].crc && P[i].rooms === B[i].rooms
      && P[i].cells === B[i].cells;
    console.log(`  ${String(P[i].f).padStart(5)} кадров: картинка`
      + ` ${P[i].crc.toString(16)}/${B[i].crc.toString(16)},`
      + ` комната/X/Y/энергия/смерть/низ ${P[i].cells}|${B[i].cells},`
      + ` витков ${P[i].it}/${B[i].it}  ${eq ? 'СОВПАЛО' : 'разошлось'}`);
    if (!eq) break;
    same = P[i].f;
  }
  check('без читов сборки идут байт в байт не меньше 900 кадров'
    + ` (совпало ${same})`, same >= 900, true);
}

console.log(`\nкадры: ${OUT}`);
if (FAIL.length) {
  console.log(`\nБЕДА, ${FAIL.length}:`);
  for (const s of FAIL) console.log('  ' + s);
  process.exit(1);
}
console.log('\nВСЁ СОШЛОСЬ');
