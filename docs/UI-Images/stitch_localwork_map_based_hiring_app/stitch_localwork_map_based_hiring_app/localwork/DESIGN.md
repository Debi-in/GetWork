---
name: GetWork Blueprints
colors:
  surface: '#f7f9ff'
  surface-dim: '#d0dbe8'
  surface-bright: '#f7f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#ecf4ff'
  surface-container: '#e4effc'
  surface-container-high: '#dee9f6'
  surface-container-highest: '#d8e4f0'
  on-surface: '#121d26'
  on-surface-variant: '#424655'
  inverse-surface: '#27323b'
  inverse-on-surface: '#e7f2ff'
  outline: '#737687'
  outline-variant: '#c3c6d8'
  surface-tint: '#0052dc'
  primary: '#004fd2'
  on-primary: '#ffffff'
  primary-container: '#1a66ff'
  on-primary-container: '#faf8ff'
  inverse-primary: '#b4c5ff'
  secondary: '#a23f00'
  on-secondary: '#ffffff'
  secondary-container: '#ff8346'
  on-secondary-container: '#692600'
  tertiary: '#7f4f00'
  on-tertiary: '#ffffff'
  tertiary-container: '#9c6719'
  on-tertiary-container: '#fff7f2'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003da8'
  secondary-fixed: '#ffdbcc'
  secondary-fixed-dim: '#ffb595'
  on-secondary-fixed: '#351000'
  on-secondary-fixed-variant: '#7c2e00'
  tertiary-fixed: '#ffddb7'
  tertiary-fixed-dim: '#fcba65'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#f7f9ff'
  on-background: '#121d26'
  surface-variant: '#d8e4f0'
  map-grid: '#edf0f5'
  map-road: '#d1dbe8'
  urgent-glow: rgba(26, 102, 255, 0.3)
  glass-surface: rgba(247, 249, 255, 0.85)
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
  caption-bold:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  gutter: 16px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style

The brand identity for GetWork is built around **Efficiency, Mobility, and Urgent Opportunity**. It serves a gig-economy audience that requires immediate, glanceable information while on the move. 

The visual style is **Glassmorphic-Modern**, characterized by translucent surfaces, vibrant accent blurs, and high-energy status indicators. The interface balances a professional "SaaS-for-workers" feel with a friendly, approachable roundedness. Key characteristics include:
- **Clarity over Clutter:** Using depth and transparency to separate the map-based environment from the interactive UI controls.
- **Dynamic Feedback:** Subtle animations (like pulses) and glowing effects signify urgency and high-value opportunities.
- **Modern Utility:** A clean, systematic approach that feels technical enough for business but accessible enough for daily gig workers.

## Colors
The color palette is dominated by **Electric Blue (#1a66ff)**, chosen for its high visibility and association with technology and "verified" trust. 

- **Primary:** The core driver for actions, map markers, and active states.
- **Surface & Background:** A tinted white/blue-gray (#f7f9ff) maintains a "cool" professional temperature.
- **Semantic Accents:** Urgent tasks are highlighted with primary-colored glows and bolts, while errors use a standard red (#ba1a1a).
- **Glassmorphism:** Neutral colors are rarely opaque; they are often applied as 80-95% alpha layers with backdrop blurs to maintain context with the map underneath.

## Typography
We use **Plus Jakarta Sans** across all levels for its contemporary, geometric look and excellent legibility at small sizes. 

- **Headlines:** Use tight letter-spacing and heavy weights (600-700) to create strong hierarchy.
- **Labels:** Essential for the map markers and chips. These use a slightly tighter font size but keep weights at 600 to ensure they don't get lost against the map background.
- **Uppercase Usage:** Metadata tags (e.g., "URGENT", "FULL-DAY") use 10px bold uppercase with expanded tracking for a professional, "ticket-like" appearance.

## Layout & Spacing
The layout follows a **Safe Margin** model rather than a strict rigid grid, prioritizing floating interactive elements over the map.

- **Floating UI:** Controls (Search, Filters, FABs) are positioned with a 16px (mobile) or 32px (desktop) margin from the screen edges.
- **Padding Rhythm:** A 4px base unit is used. Internal card padding is typically 16px (md).
- **Z-Axis Hierarchy:**
    - Level 0: Map Layer
    - Level 10: Markers & Pins
    - Level 40: Floating Action Buttons & Job Cards
    - Level 50: App Bar & Bottom Navigation

## Elevation & Depth
Depth is expressed through a combination of **Glassmorphism** and **Soft Ambient Shadows**.

- **Surfaces:** Floating elements use `glass-blur` (12px blur) with a high-transparency white background (95% opacity). This maintains the sense that the user is "over" the map.
- **Shadows:** We use three distinct levels:
    - **Sm (Filters):** 2px blur, low opacity for subtle separation.
    - **Lg (FABs/Markers):** 8px-12px blur for interactive floating elements.
    - **Xl (Job Cards):** 20px+ blur for high-priority modal-like cards.
- **Glows:** "Urgent" markers utilize a colored shadow (`rgba(26, 102, 255, 0.3)`) with a pulse animation to draw immediate attention without using red, which is reserved for errors.

## Shapes
The shape language is **highly rounded** to feel modern and friendly.

- **Standard Containers:** Cards and the Search Bar use `rounded-2xl` (1.5rem/24px) or `rounded-xl` (1rem/16px) depending on size.
- **Interactive Elements:** Buttons and Chips use `rounded-full` (Pill-shaped) for a more "tappable" look on mobile.
- **Icons/Thumbnails:** Use `rounded-xl` (12px) to maintain a soft but structured look within cards.

## Components

### Buttons & Chips
- **Action Chips:** Pill-shaped, semi-transparent white background with a thin border and 18px leading icon. Active state toggles to Primary Blue text.
- **Floating Action Buttons (FAB):** 48x48px squares with `rounded-xl` corners and heavy shadows.

### Map Markers
- **Price Pins:** Pill-shaped badges containing the price and an optional "Bolt" icon for urgent tasks. Must include a 2px white border to separate from map details.
- **User Marker:** A concentric circle design with a pulse animation to signify "Current Location" status.

### Job Preview Cards
- **Structure:** 14px image/logo on the left, primary info in the center, and price/action on the right.
- **Tags:** Small, high-contrast rectangular labels with 10px uppercase bold text for "URGENT" or "FULL-DAY".

### Navigation
- **Bottom Bar:** A persistent surface with a slight top-edge shadow. Active items are highlighted using a `primary-container` (soft blue) background with `rounded-xl` corners, while inactive items remain neutral.