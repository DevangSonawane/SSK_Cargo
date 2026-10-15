import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import type { GoldieConfig, ScreenshotScene } from './.tooling/goldie/src/config.ts';

export const root = dirname(fileURLToPath(import.meta.url));
export const sources = {
  client: [
    ['book', 'Client/WhatsApp Image 2026-10-09 at 15.43.58 (3).jpeg', 'Your cargo. Your move.', 'Book a truck for your next delivery.'],
    ['choose', 'Client/WhatsApp Image 2026-10-09 at 15.52.44.jpeg', 'The right truck awaits.', 'Choose your vehicle and search nearby.'],
    ['delivery', 'Client/WhatsApp Image 2026-10-09 at 15.43.58.jpeg', 'Every delivery, in view.', 'See route details, status and invoices.'],
    ['bookings', 'Client/WhatsApp Image 2026-10-09 at 15.43.58 (1).jpeg', 'Keep bookings together.', 'Review your trips, all in one place.'],
  ],
  driver: [
    ['requests', 'Driver/WhatsApp Image 2026-10-09 at 15.43.58 (6).jpeg', 'Your next trip starts here.', 'Review the route. Swipe to accept.'],
    ['online', 'Driver/WhatsApp Image 2026-10-09 at 15.43.58 (5).jpeg', 'Go online. Get moving.', 'Be ready for new delivery requests.'],
    ['earnings', 'Driver/WhatsApp Image 2026-10-09 at 15.43.58 (4).jpeg', 'Your earnings, at a glance.', 'See your balance and monthly totals.'],
  ],
} as const;

export function config(audience: keyof typeof sources): GoldieConfig {
  const scenes: ScreenshotScene[] = sources[audience].map(([id, , headline, subhead], index) => ({
    kind: 'screenshot', id, flow: `provided-image-${id}`,
    headline: { 'en-US': headline }, subhead: { 'en-US': subhead },
    layout: 'classic',
    background: index % 2 === 0
      ? 'linear-gradient(155deg, #092E29 0%, #0A4939 65%, #16744C 100%)'
      : 'linear-gradient(155deg, #103D32 0%, #126344 65%, #2FA56E 100%)',
    decorations: [{ kind: 'image', src: `../art/${audience}-${index + 1}.png`, x: 0, y: 0, width: 1 }],
  }));
  return {
    appRoot: resolve(root, '..'),
    // This setup imports existing images; capture/doctor are intentionally unused.
    // Set real build paths and author Argent flows before using live capture.
    appPath: '', bundleId: '',
    devices: ['iphone-6.9', 'ipad-13', 'pixel-10-pro'], locales: ['en-US'], appearance: 'light',
    frame: { variant: { 'iphone-6.9': '17-pro-silver', 'ipad-13': 'ipad-pro-13-silver' } },
    theme: {
      background: '#092E29', headlineColor: '#FFFFFF', subheadColor: '#B9DFCC',
      fontFamily: 'Inter',
      fontFiles: [{ family: 'Inter', files: {
        400: '../../assets/fonts/inter/Inter-Regular.ttf',
        700: '../../assets/fonts/inter/Inter-Bold.ttf',
      } }],
      screenOnly: true, copyHeightRatio: 0.20, deviceWidthRatio: 0.84,
      layout: 'classic',
    },
    store: {
      name: audience === 'client' ? 'gadidost' : 'gadidost Driver',
      subtitle: { 'en-US': audience === 'client' ? 'Truck booking made simple' : 'Deliver. Track. Keep moving.' },
      developer: 'gadidost', category: 'Business',
      // Studio placeholders, not assertions about published store ratings.
      rating: 0, ratingCount: 'Not yet rated', ageRating: '4+', price: 'Free',
      description: { 'en-US': audience === 'client'
        ? 'Book a truck, choose a vehicle nearby and manage your cargo deliveries. Review route details, booking status and invoices in one place.'
        : 'Go online to receive delivery requests. Review pickup and drop details, swipe to accept a trip and keep track of your earnings.' },
    },
    scenes,
  };
}
