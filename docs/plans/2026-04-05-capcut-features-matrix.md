# CapCut → Deen Studio: Features Matrix & Implementation Plan

## Comprehensive CapCut Features List (from knowledge)

### ✅ Already Implemented
| Feature | CapCut | Deen Studio | Notes |
|---------|--------|-------------|-------|
| Cut/Split clips | ✅ | ✅ | Split at playhead |
| Timeline multi-track | ✅ | ✅ | 7 tracks |
| Drag & trim clips | ✅ | ✅ | Long-press drag + handles |
| Undo/Redo | ✅ | ✅ | 30 levels |
| Text (styles, fonts) | ✅ | ✅ | 5 tabs, 40+ fonts |
| Text animations | ✅ | ✅ | 16 presets |
| Keyframe animations | ✅ | ✅ | 4 easings, full interpolation |
| Transitions | 100+ | ✅ 9 types | fade, slides, zoom, blur |
| Volume control | ✅ | ✅ | 0-200% with real setVolume |
| Speed control | ✅ | ✅ | 0.25x-4.0x with real setSpeed |
| Fade in/out audio | ✅ | ✅ | Per-layer fade times |
| Effects (brightness, etc.) | 200+ | ✅ 4 types | brightness, saturation, grayscale, contrast |
| Export FFmpeg | ✅ | ✅ | 480p/720p/1080p, multi-bitrate |
| Text-to-Speech | ✅ | ✅ | Native + ElevenLabs |
| Auto Captions | ✅ | ✅ | speech_to_text, 5 languages |
| Pixabay media import | - | ✅ | Images + videos |
| Local file import | ✅ | ✅ | file_picker |
| Track lock/hide/mute | ✅ | ✅ | Per-track toggles |
| Magnetic timeline | ✅ | ✅ | Snap to playhead + clips |
| Audio waveform | ✅ | ✅ | Seeded random visualization |
| Blend modes | ❌ | ❌ | Missing |
| Picture-in-Picture | ✅ | ❌ | Missing |
| Freeze Frame | ✅ | ❌ | Missing |
| Reverse Video | ✅ | ❌ | Missing |
| Masks | ✅ | ❌ | Missing |
| Chroma Key | ✅ | ❌ | Missing |
| Speed Curves | ✅ | ❌ | Missing (only constant speed) |
| Video Stabilization | ✅ | ❌ | Missing |
| Filters (LUTs) | 200+ | ❌ | Missing |
| Stickers/Emojis | ✅ | ❌ | Missing |
| Color Grading (curves, HSL) | ✅ | ❌ | Missing |
| Body/Face Tracking | ✅ | ❌ | Missing |
| Ripple Edit | ✅ | ❌ | Missing |
| Templates | ✅ | ❌ | Missing (functional) |
| Auto Reframe | ✅ | ❌ | Missing |
| Beat Sync | ✅ | ❌ | Missing |
| Voice Effects | ✅ | ❌ | Missing |
| Noise Reduction | ✅ | ❌ | Missing |
| Image Enhancement | ✅ | ❌ | Missing |
| Canvas/Backgrounds | ✅ | ❌ | Missing (presets) |
| Captions Styling | ✅ | ❌ | Missing (auto-caption styles) |
| Multi-cam | ✅ | ❌ | Missing |

---

## Implementation Priority (Vague 4)

### Tier 1 — High Impact / Core Editing
1. **Blend Modes** — multiply, screen, overlay, darken, lighten, difference
2. **Picture-in-Picture (PiP)** — multiple video layers visible simultaneously
3. **Masks** — rect, circle, split, heart, star
4. **Chroma Key** — green screen background removal
5. **Freeze Frame** — pause a specific frame
6. **Reverse Video** — play clip backwards
7. **Filters (LUTs)** — cinematic, vintage, B&W, warm, cool presets

### Tier 2 — Advanced Features
8. **Speed Curves** — variable speed within a single clip
9. **Stickers/Emojis** — built-in library + custom upload
10. **Canvas/Backgrounds** — blur, gradient, solid color, image presets
11. **Ripple Edit** — moving a clip shifts subsequent clips
12. **Voice Effects** — chipmunk, deep, robot, echo, reverb
13. **Noise Reduction** — basic audio noise gate

### Tier 3 — AI / Advanced
14. **Color Grading** — curves, HSL, color wheels
15. **Body/Face Tracking** — ML Kit integration
16. **Auto Reframe** — smart crop for different aspect ratios
17. **Beat Sync** — detect audio beats for timing
18. **Video Stabilization** — gyro-based or feature-point stabilization
19. **Multi-cam** — sync and switch between camera angles

---

## Implementation Plan

I will implement Tier 1 features first (highest impact), then Tier 2, then Tier 3.
Each feature will be self-contained and production-ready.
