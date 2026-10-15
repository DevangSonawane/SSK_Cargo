import { mkdir, readdir, copyFile, writeFile, stat } from 'node:fs/promises';
import { join, relative } from 'node:path';
import { createCanvas, loadImage, GlobalFonts } from '../.tooling/goldie/node_modules/@napi-rs/canvas/index.js';
import { pngInfo } from '../.tooling/goldie/src/image.ts';
import { root, sources } from '../shared.ts';
import { presets, standards } from '../standards.ts';

const exports = join(root, 'exports');
const bundle = join(exports, 'standards-2026-10-15');
await mkdir(bundle, { recursive: true });
GlobalFonts.registerFromPath(join(root, '../assets/fonts/inter/Inter-Bold.ttf'), 'Inter');
const report: any = { ...standards, sizeChecksPassed: true, submissionReady: false, sets: [] };
for (const audience of ['client', 'driver'] as const) {
  for (const preset of presets) {
    let source: string;
    if (preset.tablet) source = join(root, audience, 'out/formats', preset.id);
    else if (preset.id === 'iphone-6.5') source = join(root, audience, 'out/formats/screenshots/iphone-6.9/en-US');
    else source = join(root, audience, 'out/screenshots', preset.goldie!, 'en-US');
    const isDraft = preset.store === 'apple' || preset.tablet;
    const folder = `${preset.id}${isDraft ? '-design-drafts' : ''}`;
    const dest = join(bundle, audience, folder);
    await mkdir(dest, { recursive: true });
    for (const old of await readdir(dest)) if (old.endsWith('.png')) await Bun.file(join(dest, old)).delete();
    const files = (await readdir(source)).filter(f => f.endsWith('.png')).sort();
    if (files.length !== sources[audience].length) throw new Error(`Unexpected screenshot count in ${source}`);
    const checks = [], altText = [];
    for (const [index, file] of files.entries()) {
      const target = join(dest, file);
      await copyFile(join(source, file), target);
      const info = await pngInfo(target);
      const bytes = (await stat(target)).size;
      const data = new Uint8Array(await Bun.file(target).arrayBuffer());
      // IHDR color type 2 is truecolor RGB, with no alpha or palette.
      const ok = info.width === preset.width && info.height === preset.height && !info.hasAlpha && data[25] === 2 && bytes < 8 * 1024 * 1024;
      if (!ok) throw new Error(`Export validation failed: ${target}`);
      if (preset.store === 'google' && (info.width * 16 !== info.height * 9 || Math.max(info.width, info.height) > 2 * Math.min(info.width, info.height))) throw new Error(`Invalid Play aspect ratio: ${target}`);
      checks.push({ file, width: info.width, height: info.height, bytes, rgb24: true, alpha: false });
      altText.push({ file, text: sources[audience][index][3] });
    }
    await writeFile(join(dest, 'alt-text.json'), JSON.stringify(altText, null, 2));
    const issues = ['WhatsApp-compressed sources; original-resolution images recommended.'];
    if (isDraft) issues.push('Android phone source; native device-specific captures still needed.');
    if (audience === 'driver' && preset.store === 'google') issues.push(preset.tablet
      ? 'Only 3 distinct sources; large-screen guidance calls for at least 4.'
      : 'Only 3 screenshots; 4 needed for screenshot-based promotional eligibility, not basic listing.');
    report.sets.push({ audience, preset: preset.id, path: relative(bundle, dest), ratio: `${preset.width}:${preset.height}`, note: preset.note, count: files.length, technicalChecksPassed: true, submissionReady: false, issues, files: checks });

    const width = preset.tablet ? 340 : 300, gap = 20;
    const height = Math.round(width * preset.height / preset.width);
    const board = createCanvas(files.length * (width + gap) + gap, height + 100);
    const ctx = board.getContext('2d');
    ctx.fillStyle = '#E9EFEA'; ctx.fillRect(0, 0, board.width, board.height);
    ctx.fillStyle = '#123D30'; ctx.font = 'bold 19px Inter';
    ctx.fillText(`gadidost / ${audience} / ${preset.id} / ${preset.width} × ${preset.height}${isDraft ? ' / DRAFT' : ''}`, gap, 40);
    for (const [i, file] of files.entries()) ctx.drawImage(await loadImage(join(dest, file)), gap + i * (width + gap), 65, width, height);
    await writeFile(join(bundle, `${audience}-${preset.id}-overview.jpg`), await board.encode('jpeg', 90));
  }
}
await copyFile(join(root, 'RELEASE-NOTES.md'), join(bundle, 'READ-BEFORE-UPLOADING.md'));
await copyFile(join(root, 'STANDARDS.md'), join(bundle, 'STANDARDS.md'));
await writeFile(join(bundle, 'validation-report.json'), JSON.stringify(report, null, 2));
const zipFile = join(exports, 'gadidost-store-screenshots.zip');
if (await Bun.file(zipFile).exists()) await Bun.file(zipFile).delete();
const zip = Bun.spawn(['zip', '-qr', 'gadidost-store-screenshots.zip', 'standards-2026-10-15'], { cwd: exports });
if (await zip.exited !== 0) throw new Error('Could not create export ZIP');
console.log(`Verified ${report.sets.reduce((n: number, s: any) => n + s.count, 0)} RGB PNGs in ${report.sets.length} sets. Export: ${zipFile}`);
