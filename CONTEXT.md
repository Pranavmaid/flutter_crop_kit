# flutter_crop_kit — Session Continuation Context

Session paused 2026-05-21 mid-flow of superpowers brainstorming skill.

## Where work paused

Brainstorming flow complete. Spec written + committed. **Next step: invoke `superpowers:writing-plans` skill** to generate ordered implementation tasks from the spec.

Do NOT redo brainstorming. Spec is locked.

## Read first

1. `docs/superpowers/specs/2026-05-21-flutter-crop-kit-design.md` — full design spec
2. `~/.claude/projects/-Users-pranav-Documents-projects-flutter_crop_kit/memory/MEMORY.md` — memory index

## TL;DR for new session

- Pure-Dart Flutter image cropper, MIT, pub.dev target
- Approach A: monolithic `CropView` + `ChangeNotifier` controller + one `CustomPainter`
- v0.1 ships all features: rect/circle/oval/polygon/custom masks, 90° + free rotation, pinch/pan, grid overlay, 4 input sources, PNG output + live `Stream<Rect>`
- Tests: unit + widget + golden, 85%+ coverage
- Build order hint: geometry → mask paths → image source → controller → painter → gestures → CropView → showCropper → theme → goldens

## User style

- Caveman mode default (terse, fragments OK, no articles)
- Never use em-dashes
- Approves quickly, trusts judgment, wants execution not over-confirmation
