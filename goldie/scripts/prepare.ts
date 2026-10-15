import { mkdir, writeFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { createCanvas, loadImage, GlobalFonts } from '../.tooling/goldie/node_modules/@napi-rs/canvas/index.js';
import { root, sources } from '../shared.ts';
import { FRAMES } from '../.tooling/goldie/src/frame.ts';

// Import the provided JPEGs into Goldie's documented capture-manifest format.
// Crop only Android system chrome; app content and displayed data stay intact.
GlobalFonts.registerFromPath(resolve(root, '../assets/fonts/inter/Inter-Bold.ttf'), 'Inter');
await mkdir(join(root, 'art'), { recursive: true });
for (const audience of ['client', 'driver'] as const) {
  const shots: { sceneId: string; file: string }[] = [];
  const prepared = join(root, audience, 'out', 'prepared');
  await mkdir(prepared, { recursive: true });
  for (const [index, [id, filename]] of sources[audience].entries()) {
    const source = resolve(root, '../assets/Store Publishing', filename);
    const image = await loadImage(source);
    const top = Math.round(image.height * 0.043);
    // The truck picker has system buttons overlaid on the app's bottom CTA.
    // Keep that CTA intact rather than cropping through it.
    const bottom = id === 'choose' ? 0 : Math.round(image.height * 0.055);
    const canvas = createCanvas(image.width, image.height - top - bottom);
    canvas.getContext('2d').drawImage(image, 0, top, image.width, canvas.height, 0, 0, canvas.width, canvas.height);
    const file = join(prepared, `${id}.png`);
    await writeFile(file, await canvas.encode('png'));
    shots.push({ sceneId: id, file });

    // Transparent, code-drawn route artwork. Goldie composites this beneath UI.
    const art = createCanvas(1320, 2868);
    const ctx = art.getContext('2d');
    ctx.strokeStyle = '#FFFFFF0C'; ctx.lineWidth = 2;
    for (let x = -2400; x < 2000; x += 190) {
      ctx.beginPath(); ctx.moveTo(x, 500); ctx.lineTo(x + 1800, 2868); ctx.stroke();
    }
    ctx.strokeStyle = '#61DCA133'; ctx.lineWidth = 5;
    ctx.beginPath(); ctx.moveTo(-100, 2400); ctx.bezierCurveTo(680, 2500, 1000, 550, 1500, 1050); ctx.stroke();
    ctx.fillStyle = '#A7F3C9'; ctx.font = 'bold 32px Inter';
    ctx.fillText('gadidost', 119, 91);
    ctx.textAlign = 'right'; ctx.font = 'bold 20px Inter';
    ctx.fillStyle = '#B9DFCC';
    ctx.fillText(`${audience === 'client' ? 'FOR YOUR CARGO' : 'FOR DRIVERS'}  /  0${index + 1}`, 1201, 88);
    await writeFile(join(root, 'art', `${audience}-${index + 1}.png`), await art.encode('png'));
  }
  for (const device of ['iphone-6.9', 'ipad-13', 'pixel-10-pro']) {
    const raw = join(root, audience, 'out', 'raw', device);
    await mkdir(raw, { recursive: true });
    // Goldie fills the device rectangle. Pad to its exact aspect ratio first,
    // keeping the supplied UI at its original proportions and fully visible.
    const screen = FRAMES[device as keyof typeof FRAMES].screen;
    const deviceShots = [];
    for (const shot of shots) {
      const image = await loadImage(shot.file);
      const sample = createCanvas(image.width, image.height);
      const sampleCtx = sample.getContext('2d');
      sampleCtx.drawImage(image, 0, 0);
      const targetHeight = Math.round(image.width * screen.height / screen.width);
      const fitted = createCanvas(image.width, targetHeight);
      const ctx = fitted.getContext('2d');
      const color = (y: number) => {
        const [r, g, b] = sampleCtx.getImageData(Math.floor(image.width / 2), y, 1, 1).data;
        return `rgb(${r}, ${g}, ${b})`;
      };
      ctx.fillStyle = color(0); ctx.fillRect(0, 0, fitted.width, fitted.height / 2);
      ctx.fillStyle = color(image.height - 1); ctx.fillRect(0, fitted.height / 2, fitted.width, fitted.height / 2);
      const scale = Math.min(1, targetHeight / image.height);
      const w = image.width * scale, h = image.height * scale;
      ctx.drawImage(image, (fitted.width - w) / 2, (fitted.height - h) / 2, w, h);
      const file = join(raw, `${shot.sceneId}.png`);
      await writeFile(file, await fitted.encode('png'));
      deviceShots.push({ sceneId: shot.sceneId, file });
    }
    await writeFile(join(raw, 'manifest.json'), JSON.stringify({
      device, udid: 'provided-android-images', capturedAt: new Date().toISOString(),
      screenshots: deviceShots, preview: null,
    }, null, 2));
  }
}
console.log('Prepared 4 client and 3 driver images, plus route artwork.');
