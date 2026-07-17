---
name: Academic Precision
colors:
  surface: '#f9f9ff'
  surface-dim: '#d3daef'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f3ff'
  surface-container: '#e9edff'
  surface-container-high: '#e1e8fd'
  surface-container-highest: '#dce2f7'
  on-surface: '#141b2b'
  on-surface-variant: '#484555'
  inverse-surface: '#293040'
  inverse-on-surface: '#edf0ff'
  outline: '#797587'
  outline-variant: '#c9c4d8'
  surface-tint: '#5f3ce4'
  primary: '#532cd8'
  on-primary: '#ffffff'
  primary-container: '#6c4cf1'
  on-primary-container: '#f0eaff'
  inverse-primary: '#c9beff'
  secondary: '#5c5f60'
  on-secondary: '#ffffff'
  secondary-container: '#dee0e2'
  on-secondary-container: '#606365'
  tertiary: '#505356'
  on-tertiary: '#ffffff'
  tertiary-container: '#686b6f'
  on-tertiary-container: '#ebecf0'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e6deff'
  primary-fixed-dim: '#c9beff'
  on-primary-fixed: '#1b0062'
  on-primary-fixed-variant: '#4616cc'
  secondary-fixed: '#e1e2e4'
  secondary-fixed-dim: '#c5c7c8'
  on-secondary-fixed: '#191c1e'
  on-secondary-fixed-variant: '#444749'
  tertiary-fixed: '#e0e2e6'
  tertiary-fixed-dim: '#c4c7ca'
  on-tertiary-fixed: '#191c1f'
  on-tertiary-fixed-variant: '#44474a'
  background: '#f9f9ff'
  on-background: '#141b2b'
  surface-variant: '#dce2f7'
typography:
  display:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  margin-mobile: 20px
  gutter: 12px
---

## Brand & Style
The design system is rooted in the philosophy of "clarity through reduction." It is tailored for high-achieving students and professionals who require a focused environment to manage cognitive load. 

The aesthetic draws heavily from Apple’s Human Interface Guidelines and the systematic modularity of Notion. It prioritizes functionality and legibility, utilizing a **Minimalist** style with high-quality typography and intentional whitespace. The emotional response is one of calm, control, and intellectual readiness. Visual flair is restricted to functional accents, ensuring the AI-driven content remains the primary focus.

## Colors
The palette is restrained to maintain a professional, academic atmosphere. 

- **Primary (#6C4CF1):** Used exclusively for high-intent actions, active states, and critical progress indicators. 
- **Surface (#FFFFFF):** Used for cards, sheets, and elevated containers to separate content from the background.
- **Background (#F7F8FA):** The foundation of the app, providing a soft contrast against white cards to create depth without shadows.
- **Text Primary (#111827):** High-contrast ink for headings and body text to ensure maximum readability.
- **Text Secondary (#6B7280):** Used for captions, labels, and metadata to establish clear information hierarchy.
- **Border (#E5E7EB):** A subtle hairline divider used for structural definition and input fields.

## Typography
The system uses **Inter** for its systematic, utilitarian nature. The scale is tight and professional.

- **Headings:** Use a semi-bold weight (600) with slight negative letter-spacing to appear more compact and "editorial."
- **Body Text:** Standardized at 16px for primary reading and 14px for secondary descriptions.
- **Labels:** Use a medium weight (500) to remain legible at small sizes (12px), often used for tags or category headers in all-caps.
- **Hierarchy:** Ensure at least an 8px size difference between distinct hierarchical levels (e.g., Title vs. Subtitle).

## Layout & Spacing
This design system utilizes a **Fluid Grid** for mobile, centered around a 4-pixel base unit. 

- **Safe Zones:** Horizontal page margins are fixed at 20px to ensure content doesn't feel cramped against the bezel.
- **Container Padding:** Standard cards use 16px (`md`) internal padding.
- **Stacking:** Use 12px (`sm`) for related elements and 24px (`lg`) to separate distinct sections.
- **Rhythm:** Vertical rhythm should be strictly maintained in multiples of 4px.

## Elevation & Depth
Depth is primarily communicated through **Tonal Layers** rather than heavy shadows.

- **Level 0 (Base):** The secondary background (#F7F8FA).
- **Level 1 (Card):** Pure white (#FFFFFF) surfaces with a 1px border (#E5E7EB).
- **Shadows:** Use a singular, highly-diffused "Ambient Shadow" for floating elements (like a FAB or focused card). 
  - *Shadow Spec:* `0px 4px 20px rgba(0, 0, 0, 0.04)`.
- **Interaction:** When a card is pressed, it should not lift; instead, it should slightly dim or shrink (98% scale) to mimic a physical press.

## Shapes
The shape language is friendly yet structured. 

- **Standard Containers:** Use a 16px corner radius for cards and main UI modules.
- **Secondary Elements:** Inputs and small buttons use a 12px radius.
- **Large Components:** Bottom sheets or large modal containers use 24px for a softer, more modern feel.
- **Icons:** Icons must follow a 2px stroke weight with rounded caps and joins to match the corner radius of the UI.

## Components
- **Buttons:**
  - *Primary:* Solid #6C4CF1, white text, 12px-16px radius, no shadow.
  - *Secondary:* Solid #F7F8FA, #111827 text, no border.
  - *Ghost:* Transparent background, #6C4CF1 text, for low-priority actions.
- **Input Fields:**
  - White background, 1px #E5E7EB border.
  - Focus state: 1px #6C4CF1 border with a 2px outer glow of `rgba(108, 76, 241, 0.1)`.
- **Chips/Tags:**
  - Small (12px text), 100px radius (pill), background #F7F8FA, border #E5E7EB.
- **Cards:**
  - White background, 16px radius, 1px border. No shadow unless the card is "active" or "floating."
- **Lists:**
  - Borderless with 12px vertical spacing. Use a thin 1px separator (#E5E7EB) that stops 16px before the edge of the container.
- **Progress Bars:**
  - 6px height, rounded caps. Track is #F7F8FA, fill is #6C4CF1.