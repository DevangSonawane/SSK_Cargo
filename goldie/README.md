# gadidost store screenshots

Two editable Goldie projects using the images supplied in `assets/Store Publishing`.
The client strip has 4 scenes; the driver strip has 3. Both export in six presets:
iPhone 6.9 and 6.5, iPad 13, Android phone, 7-inch tablet and 10-inch tablet.
English copy, bundled Inter, green route artwork and
screen-only framing are defined in `shared.ts`.

## Run

Requires Bun, Node 20+, ffmpeg and zip. From the Flutter project root:

```bash
bash goldie/run.sh render
bash goldie/run.sh studio client  # http://localhost:4321
bash goldie/run.sh studio driver  # http://localhost:4322 (another terminal)
```

The renderer imports supplied images, creates Goldie capture manifests, renders,
writes the studio manifests, verifies dimensions/alpha and packages the exports.
It does not launch an emulator or modify the Flutter application.

## Files

- `shared.ts`: screenshot order, source image paths, headlines, colors and fonts.
- `client/goldie.config.ts`, `driver/goldie.config.ts`: audience configurations.
- `client/goldie.design.json`, `driver/goldie.design.json`: optional studio edits.
- `standards.ts`, `STANDARDS.md`: export dimensions and official source references.
- `exports/standards-2026-10-15/`: 42 PNGs, 12 overview boards and validation report.
- `exports/gadidost-store-screenshots.zip`: complete current bundle.
- `.tooling/goldie/`: downloaded upstream repository and dependencies (gitignored).

Goldie was downloaded from https://github.com/software-mansion-labs/goldie at
commit `699578cefe908141433489125599d12a29a9f8db` (version 0.5.0).
Upstream is MIT licensed; its LICENSE and asset attributions remain in the checkout.

For a fresh checkout of this project, restore the local tool once:

```bash
git clone https://github.com/software-mansion-labs/goldie.git goldie/.tooling/goldie
git -C goldie/.tooling/goldie checkout 699578cefe908141433489125599d12a29a9f8db
(cd goldie/.tooling/goldie && bun install --frozen-lockfile)
(cd goldie/.tooling/goldie/studio && bun install --frozen-lockfile && bun run build)
bash goldie/run.sh render
```

Use the studio to edit layouts and text, then run `render` to refresh the organized
exports and ZIP. Goldie itself also offers a studio export. For this still-image
workflow, `run.sh render` is the verified packaging path.

See `RELEASE-NOTES.md` before submitting assets to either store.

Tablet outputs omit marketing overlays and remain drafts based on phone captures.
Optional native tablet replacements can be placed at
`goldie/native/<client|driver>/<ipad-13|android-tablet-7|android-tablet-10>/<scene-id>.png`.
