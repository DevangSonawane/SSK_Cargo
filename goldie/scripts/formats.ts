import { mkdir, writeFile, stat } from 'node:fs/promises';
import { join } from 'node:path';
import { createCanvas, loadImage } from '../.tooling/goldie/node_modules/@napi-rs/canvas/index.js';
import { DEVICES } from '../.tooling/goldie/src/specs.ts';
import { loadConfig } from '../.tooling/goldie/src/config.ts';
import { renderScreenshots } from '../.tooling/goldie/src/render.ts';
import { root, sources } from '../shared.ts';
import { presets } from '../standards.ts';

export async function opaque(canvas: ReturnType<typeof createCanvas>, path: string) {
  const raw = `${path}.rgba.png`;
  await writeFile(raw, await canvas.encode('png'));
  const proc = Bun.spawn(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', raw, '-frames:v', '1', '-pix_fmt', 'rgb24', path], { stderr: 'inherit' });
  if (await proc.exited !== 0) throw new Error(`PNG encoding failed: ${path}`);
  await Bun.file(raw).delete();
}

export async function nativeFile(audience: string, preset: string, scene: string) {
  const file = join(root, 'native', audience, preset, `${scene}.png`);
  try { await stat(file); return file; } catch { return null; }
}

// Additional dimension-specific renders live outside Goldie's three fixed slots.
// Recompose the 6.5-inch screenshot with Goldie; never resize a finished poster.
const primarySize = { ...DEVICES['iphone-6.9'].screenshot };
for (const audience of ['client', 'driver'] as const) {
  const cfg = await loadConfig(join(root, audience, 'goldie.config.ts'));
  const renderRoot = join(root, audience, 'out', 'formats');
  await mkdir(renderRoot, { recursive: true });
  const raw = join(renderRoot, 'raw/iphone-6.9');
  await mkdir(raw, { recursive: true });
  await writeFile(join(raw, 'manifest.json'), await Bun.file(join(cfg.outDir, 'raw/iphone-6.9/manifest.json')).text());
  try {
    DEVICES['iphone-6.9'].screenshot = { width: 1242, height: 2688 };
    await renderScreenshots({ ...cfg, outDir: renderRoot }, 'iphone-6.9', 'en-US');
  } finally { DEVICES['iphone-6.9'].screenshot = primarySize; }

  for (const preset of presets.filter(p => p.tablet)) {
    const dest = join(renderRoot, preset.id);
    await mkdir(dest, { recursive: true });
    for (const [index, [id]] of sources[audience].entries()) {
      const native = await nativeFile(audience, preset.id, id);
      const image = await loadImage(native ?? join(cfg.outDir, 'prepared', `${id}.png`));
      const canvas = createCanvas(preset.width, preset.height);
      const ctx = canvas.getContext('2d');
      // No added marketing copy on tablet images. A neutral canvas preserves
      // source proportions. Phone-derived versions remain explicitly drafts.
      ctx.fillStyle = '#F5F7FB'; ctx.fillRect(0, 0, canvas.width, canvas.height);
      const scale = Math.min(canvas.width / image.width, canvas.height / image.height);
      const width = image.width * scale, height = image.height * scale;
      ctx.drawImage(image, (canvas.width - width) / 2, (canvas.height - height) / 2, width, height);
      await opaque(canvas, join(dest, `${String(index + 1).padStart(2, '0')}-${id}.png`));
    }
  }
}
