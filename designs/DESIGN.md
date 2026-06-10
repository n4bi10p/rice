---
name: Terminal Noir
colors:
  surface: '#141313'
  surface-dim: '#141313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353434'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c4c7c8'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#8e9192'
  outline-variant: '#444748'
  surface-tint: '#c6c6c6'
  primary: '#fdfdfc'
  on-primary: '#2f3131'
  primary-container: '#e0e0e0'
  on-primary-container: '#626363'
  inverse-primary: '#5d5f5f'
  secondary: '#c7c6c6'
  on-secondary: '#303031'
  secondary-container: '#464747'
  on-secondary-container: '#b5b5b5'
  tertiary: '#fffbff'
  on-tertiary: '#342f2d'
  tertiary-container: '#e7deda'
  on-tertiary-container: '#67615e'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e2e2e2'
  primary-fixed-dim: '#c6c6c6'
  on-primary-fixed: '#1a1c1c'
  on-primary-fixed-variant: '#454747'
  secondary-fixed: '#e3e2e2'
  secondary-fixed-dim: '#c7c6c6'
  on-secondary-fixed: '#1b1c1c'
  on-secondary-fixed-variant: '#464747'
  tertiary-fixed: '#eae1dd'
  tertiary-fixed-dim: '#cdc5c1'
  on-tertiary-fixed: '#1f1b19'
  on-tertiary-fixed-variant: '#4b4643'
  background: '#141313'
  on-background: '#e5e2e1'
  surface-variant: '#353434'
  surface-black: '#000000'
  surface-soft: '#0a0a0a'
  surface-raised: '#1c1c1c'
  text-muted: '#555555'
  border-subtle: '#1c1c1c'
  border-medium: '#333333'
  separator: '#2a2a2a'
typography:
  headline-lg:
    fontFamily: JetBrains Mono
    fontSize: 16px
    fontWeight: '700'
    lineHeight: 24px
    letterSpacing: -0.02em
  body-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 14px
  mono-ui:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
spacing:
  panel-h: 28px
  gutter-xs: 4px
  gutter-sm: 8px
  gutter-md: 12px
  margin-page: 12px
---

## Brand & Style
The brand identity is rooted in **Cyber-Brutalism** and a high-performance terminal aesthetic. It evokes a sense of "digital craftsmanship" and "uncompromised utility," tailored for a developer or power-user audience. The style is intentionally raw and monochromatic, drawing inspiration from Linux window managers (like Hyprland/Waybar).

The visual language relies on absolute precision: zero-radius corners, monospaced typography, and a strict adherence to a "system status" hierarchy. It is a "no-frills" environment where aesthetics are derived from the structure of information rather than decorative elements.

## Colors
The palette is a strictly controlled **Monochrome Grayscale**. 

- **Backgrounds:** Deep blacks (`#000000`) and near-blacks (`#0a0a0a`) provide the foundation.
- **Surfaces:** Elevated panels use `#1c1c1c` to create a logical separation without using shadows.
- **Accents:** High-contrast whites (`#e0e0e0`) are reserved for active states and critical data.
- **Muted Tones:** Two levels of gray (`#888888` and `#555555`) handle secondary information and inactive UI elements, ensuring a clear information hierarchy.

## Typography
The system uses **JetBrains Mono** exclusively to maintain a technical, monospaced aesthetic across all UI layers. 

- **System Labels:** Smaller font sizes (10px - 11px) are used for "status-bar" style information, often in uppercase with slight letter spacing to improve legibility at small scales.
- **Weight Strategy:** Bold weights are used to indicate "Active" or "Focused" states rather than size increases.
- **Functional Hierarchy:** The interface treats text as data; vertical alignment and spacing are more critical than font-size variance.

## Layout & Spacing
The layout follows a **Technical Grid** model, characterized by:

- **Compact Headers:** Fixed-height utility bars (28px) at the screen edges.
- **Fixed-Width Containers:** Command palettes and notification toasts use fixed widths (e.g., 500px or 320px) centered or anchored to corners.
- **Density:** High density is preferred, with small 8px and 12px increments for internal padding.
- **Alignment:** Strict adherence to corner-anchored "widgets" and centered focal points (like the search bar). Elements are often separated by 1px vertical or horizontal separators (`#2a2a2a`).

## Elevation & Depth
Elevation is expressed through **Tonal Layering and Borders** rather than shadows.

- **Level 0 (Background):** Pure black `#000000`.
- **Level 1 (Containers):** Panels use `#0a0a0a` with a 1px border of `#333333`.
- **Level 2 (In-Panel Selection):** Active items or buttons use `#1c1c1c` to "lift" from the container.
- **Depth FX:** Backgrounds may feature a desaturated, high-contrast image with a 40-60% black overlay to maintain focus on the foreground UI. No box-shadows are permitted (`shadow-none`).

## Shapes
The shape language is **Strictly Linear**. 

All corner radii are set to `0px`. This applies to buttons, panels, input fields, and even hover states. This "sharp" aesthetic reinforces the brutalist, terminal-inspired nature of the interface. Geometric icons (Material Symbols) should be used, preferably with a "Sharp" or "Outlined" variant to match the line-work of the UI.

## Components

- **Buttons & Inputs:** No rounded corners. Buttons use a 1px border (`#333333`). Secondary buttons have transparent backgrounds; primary actions use a `#1c1c1c` fill.
- **Workspace Switcher:** A series of square buttons where the `active` state is indicated by a background color swap (`#1c1c1c`) and text color change to white.
- **Command Palette:** A centered, border-heavy modal. The search input has no internal borders, just a bottom-border separator.
- **Notification Toasts:** Anchored to corners, using a strict vertical stack with a "metadata" header (label-sm) and a "content" body.
- **Status Indicators:** Icons paired with bold 11px text. Icons should be sized at 13px to align with the text height.
- **Media Player:** A small, fixed-width widget using a grayscale image-square (1:1 ratio) with a 1px border.