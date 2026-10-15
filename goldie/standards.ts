// Checked against the official Apple and Google documentation on 2026-10-15.
export const standards = {
  checkedOn: '2026-10-15',
  apple: 'https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/',
  google: 'https://support.google.com/googleplay/android-developer/answer/9866151?hl=en',
};

export const presets = [
  { id: 'iphone-6.9', width: 1320, height: 2868, store: 'apple', tablet: false, goldie: 'iphone-6.9', note: 'Primary 6.9-inch iPhone slot.' },
  { id: 'iphone-6.5', width: 1242, height: 2688, store: 'apple', tablet: false, goldie: 'iphone-6.9', note: 'Optional 6.5-inch fallback; not needed when 6.9-inch is supplied.' },
  { id: 'ipad-13', width: 2064, height: 2752, store: 'apple', tablet: true, goldie: 'ipad-13', note: '13-inch iPad slot, required when supporting iPad; ratio 3:4.' },
  { id: 'android-phone', width: 1080, height: 1920, store: 'google', tablet: false, goldie: 'pixel-10-pro', note: 'Chosen recommended portrait size; ratio 9:16.' },
  { id: 'android-tablet-7', width: 1080, height: 1920, store: 'google', tablet: true, goldie: null, note: 'Chosen 7-inch tablet preset, not a mandated device resolution; ratio 9:16.' },
  { id: 'android-tablet-10', width: 1440, height: 2560, store: 'google', tablet: true, goldie: null, note: 'Chosen 10-inch tablet preset, not a mandated device resolution; ratio 9:16.' },
] as const;
