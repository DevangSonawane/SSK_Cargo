# Screenshot standards checked 2026-10-15

Official references:

- Apple: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- Google: https://support.google.com/googleplay/android-developer/answer/9866151?hl=en

| Store slot | Export pixels | Aspect ratio | Purpose |
| --- | --- | --- | --- |
| iPhone 6.9-inch | 1320 × 2868 | 110:239 (about 9:19.55) | Primary iPhone set |
| iPhone 6.5-inch | 1242 × 2688 | 207:448 (about 9:19.48) | Optional fallback |
| iPad 13-inch | 2064 × 2752 | 3:4 | Required for this app's enabled iPad target |
| Android phone | 1080 × 1920 | 9:16 | Recommended portrait format |
| Android 7-inch tablet | 1080 × 1920 | 9:16 | Chosen tablet preset |
| Android 10-inch tablet | 1440 × 2560 | 9:16 | Chosen tablet preset |

Apple accepts specific dimensions, not arbitrary images of a similar ratio.
It permits 1–10 JPEG/PNG screenshots per set without transparency. A 6.9-inch
set covers the main iPhone requirement; 6.5-inch is an optional fallback.
Smaller slots generally use Apple's documented scaling. The iPad 13-inch set
is required when the app supports iPad.

Google permits up to eight screenshots per device type; the basic listing minimum
is two across device types. Its general limits are 320–3840 px with a longest side
no more than twice the shortest. Screenshot-based app promotion calls for four or
more images, at least 1080 × 1920 portrait or 1920 × 1080 landscape. Phone taglines
should occupy no more than 20% of the image.

Google's large-screen guidance specifies at least four images, 1080–7680 px,
9:16 portrait or 16:9 landscape, without added text outside the app experience.
Our tablet presets also fit the narrower general pixel limits. They are output
choices, not mandated resolutions for physical tablet sizes.

All exports are RGB PNGs without alpha. Validation checks dimensions, color type,
ratio, count and a conservative 8 MiB file cap. Native-capture and count gaps are
reported separately. Pixel checks do not establish store approval.
