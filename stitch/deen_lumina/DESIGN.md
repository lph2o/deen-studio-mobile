# Design System Specification: The Ethereal Canvas

## 1. Overview & Creative North Star
**Creative North Star: "The Digital Sanctuary"**

This design system is not a utility; it is a space for contemplation. To honor Quranic content, we move away from the frantic, high-density layouts of traditional video editors. Instead, we embrace a "High-End Editorial" approach. We break the template look through **intentional asymmetry**, where text may bleed off-center to create a sense of flow, and **layered depth**, where controls feel like they are floating on a sea of calm. This system prioritizes the "breath" between elements—using expansive white space to ensure the user feels focused and inspired, never overwhelmed.

---

## 2. Color & Surface Philosophy
We utilize a palette of deep spiritual greens and radiant golds, grounded in a charcoal environment for the Dark Mode editor.

### The "No-Line" Rule
**Borders are forbidden for sectioning.** To define space, you must use tonal shifts.
*   **The Technique:** A `surface-container-low` section sitting on a `surface` background provides all the separation required.
*   **The Goal:** To create a seamless, infinite feel that mimics the boundless nature of spiritual thought.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers, like stacked sheets of fine, semi-transparent paper.
*   **Base:** `surface` (#787582)
*   **Nested Content:** Use `surface-container` (#787582) for primary editing areas.
*   **Elevated Elements:** Use `surface-container-highest` (#787582) for floating modals or context menus.
*   **Interaction:** Use `primary-container` (#634eff) to draw the eye to active states without the harshness of a bright highlight.

### The "Glass & Gradient" Rule
To elevate the app beyond a standard grid, use **Glassmorphism** for the video timeline and floating toolbars.
*   **Token:** Use `surface` at 60% opacity with a `20px` backdrop-blur.
*   **Signature Gradients:** Apply a subtle linear gradient from `primary` (#634eff) to `primary-container` (#634eff) on major Call-to-Actions to provide a "soulful" glow.

---

## 3. Typography: The Sacred & The Modern
The typography pairing reflects the bridge between ancient wisdom and modern technology.

*   **Display & Headline (Manrope):** Used for impactful moments and section headers. The wider aperture of Manrope provides a contemporary, high-end feel.
*   **Body & UI (Inter):** Used for all functional text. Inter’s neutrality ensures that the Arabic script—the heart of the app—takes center stage.
*   **Arabic Script (Uthmani Style):** Must be scaled 120% relative to Latin text to ensure the intricate diacritics are legible.

**Hierarchy as Identity:**
*   **Display-LG (3.5rem):** Reserved for spiritual quotes or chapter titles.
*   **Title-SM (1rem):** Used for labeling timeline clips, providing a clean, professional "studio" aesthetic.

---

## 4. Elevation & Depth
In this system, depth is felt, not seen through harsh shadows.

### The Layering Principle
Achieve hierarchy by "stacking" surface tiers. Place a `surface-container-lowest` card on a `surface-container-low` section. This creates a soft, natural lift.

### Ambient Shadows
For floating elements (like an "Export" button), use **Ambient Shadows**:
*   **Blur:** 24px - 40px
*   **Opacity:** 6%
*   **Color:** Tinted with `on-surface` (#E2E2E2) rather than pure black to mimic natural light diffraction.

### The "Ghost Border" Fallback
If accessibility requires a container boundary, use the **Ghost Border**:
*   **Token:** `outline-variant` (#414944) at **15% opacity**. 100% opaque borders are strictly prohibited as they break the "Sanctuary" feel.

---

## 5. Components

### Buttons (The Golden Touch)
*   **Primary:** A gradient fill (`primary` to `primary-container`) with `on-primary` text. Radius: `md` (1.5rem).
*   **Secondary:** Ghost style. No fill, `outline-variant` (15% opacity) border, with `secondary` (#746dbf) text.
*   **Tertiary:** Purely typographic using `label-md` with `8.5rem` (24) horizontal padding.

### Editorial Cards
*   **Construction:** No borders. Use `surface-container-low`.
*   **Corner Radius:** Always `lg` (2rem) for a friendly, organic feel.
*   **Pattern Overlay:** Backgrounds should feature a subtle Islamic geometric pattern using `on-surface` at 3% opacity.

### The Video Timeline (Custom Component)
*   **Track:** Use `surface-container-lowest` (#787582).
*   **Playhead:** A 2px line of `secondary` (#746dbf) with a soft glow (4px blur).
*   **Clips:** Rounded corners (`sm` - 0.5rem) to signify individual units of thought.

### Input Fields
*   **State:** Unfocused inputs should be `surface-container-high` with no border.
*   **Focus State:** Transition background to `surface-bright` and add a `secondary` (Gold) ghost border (20% opacity).

---

## 6. Do’s and Don’ts

### Do
*   **Do** use asymmetrical margins (e.g., 2.75rem on the left, 4rem on the right) for headline placements to create an editorial look.
*   **Do** allow the Uthmani script to breathe. Increase line-height to 1.6x for all Arabic text.
*   **Do** use the `1.7rem` (5) spacing token as your default "gutter" to maintain a sense of luxury.

### Don't
*   **Don't** use pure black (#000000) for shadows; it kills the spiritual "glow" of the system.
*   **Don't** use divider lines between list items. Use a `1rem` (3) vertical gap instead.
*   **Don't** use "Alert Red" for errors unless critical. Use `tertiary` tones to gently nudge the user toward a correction.
*   **Don't** use sharp corners. Anything less than `0.5rem` (sm) is too aggressive for this sanctuary.