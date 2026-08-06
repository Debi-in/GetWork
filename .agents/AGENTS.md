# GetWork — UI Build Rules
Read this before building or editing ANY screen, widget, or layout. These are non-negotiable defaults for this app.

---

## 1. Screen sizing — always responsive, never hardcoded
- Every widget must use `flutter_screenutil` (`.w`, `.h`, `.sp`, `.r`) instead of raw numbers.
  - ✅ `width: 200.w` `fontSize: 16.sp` `padding: EdgeInsets.all(12.r)`
  - ❌ `width: 200` `fontSize: 16`
- Exception: don't wrap values already inside `Expanded`, `Flexible`, `Spacer`, or `MediaQuery` percentage-based sizing — those are already responsive, adding `.w`/`.h` there is redundant.
- `ScreenUtilInit` must wrap the app root in `main.dart` with `designSize` matching whatever Figma/design frame this UI was designed at (confirm the frame size before assuming 375x812).

## 2. Text — must never overflow, at any device or font-scale setting
- Any `Text` widget sitting next to another widget (in a `Row`, near screen edges, in a card) must have:
  - `overflow: TextOverflow.ellipsis`
  - `maxLines:` set explicitly (usually 1 or 2)
  - Wrapped in `Expanded` or `Flexible` if inside a `Row`
- Clamp system text scale so accessibility settings can't break layouts, but never disable it fully:
  `textScaler: MediaQuery.of(context).textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.2)`

## 3. Map pins / markers — never allow raw overlap
- If two or more pins would render within ~40px of each other at the current zoom level, they must **cluster** into a single "N jobs" bubble instead of stacking raw and unreadable.
- Pin color must follow a fixed, documented meaning — do not introduce a new color without updating the legend below.
  - 🟧 Orange = urgent / hiring now
  - 🟩 Green = standard job
  - Never mix meanings across the same color.

## 4. Consent-sensitive actions — never default to automatic
- Any feature that takes an action on the user's behalf (auto-apply, auto-accept, auto-message) must:
  - Require an explicit opt-in tap, never be the default/primary CTA
  - Show exactly what it's about to do before doing it (which jobs, which employer) — never a black-box "apply to 6 jobs" with no preview
- This applies to worker-side AND business-side automation equally.

## 5. Placeholder / test data
- No test strings (`hi`, `jhgfzdfxghj`, `test123`) may ship in any build shown to a real user or reviewer. Use realistic placeholder content or an actual empty-state design instead.
- Any icon (like a 🔒 lock) shown to the user must have an obvious meaning or a tooltip — never decorative-but-unexplained.

## 6. Empty space / unfinished sections
- No screen should ship with large unexplained blank areas (e.g. empty space below a profile menu). If content isn't ready yet, use a proper empty-state (icon + short message), not blank space.

## 7. No emoji characters — icons/assets only
- Never use Unicode emoji anywhere in the codebase (labels, badges, snackbars, buttons, titles, tags, debug prints).
- Always use `Icon(Icons.<name>)`, `Icon(CupertinoIcons.<name>)`, or `Image.asset()`/`SvgPicture.asset()` instead.
- Debug prints use a `[DEBUG]` text prefix, never an emoji.
  - ❌ `Text('🔥 Urgent')` → ✅ `Icon(Icons.local_fire_department_rounded)` + `Text('Urgent')`
  - ❌ `Text('⭐ Rating')` → ✅ `Icon(Icons.star_rounded)` + `Text('Rating')`

## 8. No flat/plain colors on surfaces — gradients only
- Never use a solid `color:` for a background, badge, pill, button, container, card, or header. Use `LinearGradient` or `RadialGradient` via `BoxDecoration(gradient: ...)` instead.
- Plain color is only acceptable for: text color, icon color, `Colors.transparent`, and border colors.
- Buttons get their gradient via a wrapping `Container` + `BoxDecoration(gradient:)`, not `backgroundColor:` on the button itself.

**Reference gradient palette:**

| Usage | Colors |
|---|---|
| Primary header/drawer | `#0F5132` → `#0D9488` → `#14B8A6` |
| Primary button | `#0D9488` → `#0F766E` |
| Accent/Urgent | `#FF6B35` → `#E53935` |
| Worker Mode badge | `#2563EB` → `#1D4ED8` |
| Business Mode badge | `#F97316` → `#EA580C` |
| Success pill | `#059669` → `#047857` |
| Glassmorphic overlay | `rgba(255,255,255,0.22)` → `rgba(255,255,255,0.08)` |
| Dark card | `#1E293B` → `#0F172A` |
| Salary/Money pill | `#D1FAE5` → `#A7F3D0` (tinted light) |

## 9. Before marking any UI task "done"
- [ ] Tested on at least 3 device/DPI presets (small phone, standard phone, tablet)
- [ ] No yellow/black overflow banners on any screen
- [ ] No hardcoded pixel values outside of exempted responsive widgets
- [ ] All interactive text has overflow handling
- [ ] Any automation feature has explicit opt-in + preview
- [ ] No placeholder/test strings visible
- [ ] Color usage matches the documented meaning (pin colors, badge colors, etc.)
- [ ] Zero emoji characters in any file
- [ ] Every background/badge/button/card uses a gradient, not a flat color

---

## Color reference (keep in sync with design system)
- Primary / action: `#F57C3F` (warm orange)
- Trust / verified / success: `#22C55E` or `#1D6B4A`
- Background: `#FAF8F5`
- Cards/surface: `#FFFFFF`
- Text primary: `#1F2933`
- Text secondary: `#6B7280`
- Warning: `#F59E0B`
- Error: `#EF4444`

Rule of thumb: 60% warm neutrals, 30% primary action color, 10% accent/urgent highlights.
