// terrimap_core の地図を実ブラウザ(Chromium)で動かして確認する。
// 使い方: demo/run_e2e.sh（ビルド→配信→このスクリプト）。結果とスクリーンショットは demo/e2e/out/ に出る。
import fs from 'node:fs';
import { createRequire } from 'node:module';
// ESM は NODE_PATH を見ないため、グローバルの playwright は require 経由で読む
const { chromium } = createRequire(import.meta.url)('playwright');

const BASE = process.env.DEMO_URL ?? 'http://localhost:8765';
const OUT = new URL('./out/', import.meta.url).pathname;
fs.mkdirSync(OUT, { recursive: true });

const TARGETS = {
  us: ['US-TX', 'US-CA', 'US-RI', 'US-DC', 'US-DE', 'US-NJ', 'US-CT', 'US-NH', 'US-VT', 'US-MA', 'US-MD'],
  de: ['DE-BY', 'DE-HB', 'DE-HH', 'DE-BE'],
};
const VIEWPORTS = [[320, 480], [390, 700], [412, 800]];

let failures = 0;
const ok = (cond, msg) => {
  console.log(`${cond ? 'PASS' : 'FAIL'}  ${msg}`);
  if (!cond) failures++;
};

// デモは document.title に "tapped=..;scale=..;pos=ID:x:y,.." を出している
async function readState(page) {
  const t = await page.title();
  const f = Object.fromEntries(t.split(';').map((kv) => kv.split(/=(.*)/s).slice(0, 2)));
  const pos = {};
  for (const e of (f.pos ?? '').split(',').filter(Boolean)) {
    const [id, x, y] = e.split(':');
    pos[id] = [parseFloat(x), parseFloat(y)];
  }
  return { tapped: f.tapped, scale: parseFloat(f.scale), pos };
}

// ズームボタンは右下に縦並び(拡大・縮小・リセット)。中心座標を画面サイズから求めてクリックする
const zoomBtn = (vp, which) => [vp[0] - 28, vp[1] - 112 + 16 + 36 * { in: 0, out: 1, reset: 2 }[which]];
const press = async (page, vp, which) => {
  const [x, y] = zoomBtn(vp, which);
  await page.mouse.click(x, y);
  await page.waitForTimeout(120);
};

async function open(browser, pack, [w, h], probes) {
  const page = await browser.newPage({ viewport: { width: w, height: h }, locale: 'en-US' });
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
  await page.goto(`${BASE}/?pack=${pack}&probe=${probes.join(',')}`);
  await page.waitForFunction(() => document.title.startsWith('tapped='), null, { timeout: 30000 });
  await page.waitForTimeout(500);
  return { page, errors };
}

// 画面内(ズームボタンの列・上端の状態表示の外)にあるか
const visible = ([x, y], [w, h]) => x > 4 && x < w - 52 && y > 56 && y < h - 4;

async function panTowardCenter(page, id, [w, h]) {
  for (let i = 0; i < 3; i++) {
    const p = (await readState(page)).pos[id];
    const dx = (w - 52) / 2 - p[0], dy = (h + 48) / 2 - p[1];
    if (Math.abs(dx) < 6 && Math.abs(dy) < 6) return;
    // 状態表示・ズームボタンを避け、地図の中ほどからドラッグする
    const sx = (w - 52) / 2, sy = (h + 48) / 2;
    const cl = (v, lim) => Math.max(-lim, Math.min(lim, v));
    await page.mouse.move(sx, sy);
    await page.mouse.down();
    await page.mouse.move(sx + cl(dx, (w - 80) / 2), sy + cl(dy, (h - 120) / 2), { steps: 8 });
    await page.mouse.up();
    await page.waitForTimeout(150);
  }
}

const browser = await chromium.launch({ executablePath: process.env.CHROME_PATH });
const summary = [];

for (const pack of ['us', 'de']) {
  for (const vp of VIEWPORTS) {
    const { page, errors } = await open(browser, pack, vp, TARGETS[pack]);
    await page.screenshot({ path: `${OUT}${pack}_${vp[0]}x${vp[1]}_1x.png` });
    ok(errors.length === 0, `${pack} ${vp.join('x')}: 読み込み時にエラーなし ${errors.slice(0, 1)}`);

    // 拡大ボタン: 押すと倍率が上がり、上限12倍で止まり、リセットで1倍に戻る
    await press(page, vp, 'in');
    ok(Math.abs((await readState(page)).scale - 2) < 0.01, `${pack} ${vp.join('x')}: 拡大ボタンで2倍`);
    for (let i = 0; i < 6; i++) await press(page, vp, 'in');
    ok(Math.abs((await readState(page)).scale - 12) < 0.01, `${pack} ${vp.join('x')}: 拡大は12倍で止まる`);
    await page.screenshot({ path: `${OUT}${pack}_${vp[0]}x${vp[1]}_12x.png` });
    await press(page, vp, 'reset');
    ok(Math.abs((await readState(page)).scale - 1) < 0.01, `${pack} ${vp.join('x')}: リセットで1倍`);
    await page.close();
  }

  // 各州を、実際のクリックで選べるか(必要なら拡大・移動)。中間サイズで測る。
  const vp = [390, 700];
  for (const id of TARGETS[pack]) {
    const { page } = await open(browser, pack, vp, TARGETS[pack]);
    let found = null;
    for (let step = 0; step <= 4 && found === null; step++) {
      if (step > 0) await press(page, vp, 'in');
      if (step > 0) await panTowardCenter(page, id, vp);
      const st = await readState(page);
      const p = st.pos[id];
      if (!p || !visible(p, vp)) continue;
      await page.mouse.click(p[0], p[1]);
      await page.waitForTimeout(150);
      if ((await readState(page)).tapped === id) found = (await readState(page)).scale;
    }
    summary.push({ pack, id, zoom: found });
    ok(found !== null, `${pack} ${id}: ${found === null ? '12倍まで拡大しても選べない' : `${found.toFixed(1)}倍で選べた`}`);
    await page.close();
  }
}
await browser.close();

fs.writeFileSync(`${OUT}summary.json`, JSON.stringify(summary, null, 2));
console.log(`\n${failures === 0 ? '全部OK' : `失敗 ${failures} 件`}`);
process.exit(failures === 0 ? 0 : 1);
