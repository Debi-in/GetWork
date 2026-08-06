# GetWork App — Development Rules

## Rule 1: NO EMOJIS — USE ICONS & ASSETS ONLY

**Never** use Unicode emoji characters anywhere in the Flutter codebase — not in UI labels, badges, snackbars, buttons, titles, tags, or any widget text.

**Always** replace emojis with one of the following:
- `Icon(Icons.<name>)` — Material Design vector icons
- `Icon(CupertinoIcons.<name>)` — Cupertino icons
- `Image.asset(...)` or `SvgPicture.asset(...)` — custom SVG/PNG logo assets

**Examples of WRONG usage:**
```dart
// ❌ NEVER DO THIS
Text('🔥 Urgent')
Text('✅ Applied!')
Text('⚒️ Worker Mode')
Text('🏢 Business Mode')
Text('💼 Applied')
Text('⭐ Rating')
```

**Examples of CORRECT usage:**
```dart
// ✅ ALWAYS DO THIS
Row(children: [
  Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 14),
  SizedBox(width: 4),
  Text('Urgent'),
])

Icon(Icons.check_circle_rounded, color: AppColors.success)
Icon(Icons.handyman_rounded)   // Worker Mode
Icon(Icons.storefront_rounded) // Business Mode
Icon(Icons.work_history_rounded) // Applied count
Icon(Icons.star_rounded)       // Rating
```

This applies to ALL files in `lib/` including:
- Screens, widgets, dialogs, bottom sheets
- Snackbar messages and toast content
- Map pin labels and cluster overlays
- Category tags and status badges
- Debug print statements (use `[DEBUG]` prefix instead)

---

## Rule 2: NO PLAIN/FLAT COLORS — USE GRADIENTS ALWAYS

**Never** use a solid flat `color:` for any significant UI surface. Every background, badge, pill, button, container, card, or header **must** use a `LinearGradient` or `RadialGradient`.

**Plain colors are only acceptable for:**
- Text color (`style: TextStyle(color: ...)`)
- Icon color (`Icon(..., color: ...)`)
- `Colors.transparent`
- Border colors

**Examples of WRONG usage:**
```dart
// ❌ NEVER DO THIS
decoration: BoxDecoration(color: AppColors.primary)
decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15))
ElevatedButton.styleFrom(backgroundColor: AppColors.primary)
Container(color: AppColors.accentContainer)
```

**Examples of CORRECT usage:**
```dart
// ✅ ALWAYS DO THIS
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [Color(0xFF0F5132), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.circular(16),
)

// Glassmorphic overlay gradient (for cards on gradient backgrounds)
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.22),
      Colors.white.withValues(alpha: 0.08),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
)

// Urgent gradient pill
gradient: LinearGradient(
  colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
)

// Buttons — use ShaderMask or gradient container wrapping
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
    borderRadius: BorderRadius.circular(16),
  ),
  child: ElevatedButton(...),
)
```

### Recommended Gradient Palettes for GetWork:

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

---

## Summary Checklist Before Every Commit

- [ ] Zero emoji characters in any `.dart` file
- [ ] All `BoxDecoration` backgrounds use `gradient:` not `color:`
- [ ] All buttons have gradient treatment (via container wrap or `ShaderMask`)
- [ ] All badges/pills use gradient backgrounds
- [ ] All icons use Material/Cupertino `Icon()` widgets or SVG assets
