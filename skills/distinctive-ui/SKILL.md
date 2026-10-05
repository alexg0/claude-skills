---
name: distinctive-ui
description: Redesign or style an app's UI with a deliberate visual identity that does not read as AI-generated, by writing a design brief, naming real-world design references, offering three viewable directions for the user to pick, and then applying the chosen one as design tokens. Use when the user asks to restyle, redesign, or give a distinctive look to an app or page, or asks for a UI that does not look AI-generated.
---

# Distinctive UI

Generic AI-looking UI is a taste problem, not a capability problem. Start from a
real design reference and keep the user in the visual review loop.

## Before writing code

1. Study the product: who uses it, in what mood, on what device. Write a
   three-sentence design brief covering personality, audience, and a one-word feel.
2. Pick a reference direction from real-world design, not other AI apps (for
   example editorial print, Swiss/International, Japanese stationery, field
   guides, banking-app restraint). Name the specific influences.
3. Propose three distinct directions on a single HTML page the user can open in
   a browser. Give each one a type pairing, color palette, spacing scale, and one
   key screen mocked at desktop and phone width.
4. Stop and let the user pick. Do not implement until they choose.

## After the pick

Implement the chosen direction as design tokens (CSS custom properties). Apply
them consistently to every screen and state: empty, loading, error, forms, and
modals.

## Hard bans

These read as AI-generated:

- purple, indigo, or blue gradients; glassmorphism; glows; neon accents
- Inter or system-ui as the only font; a centered hero with three feature cards
- every surface a rounded white card with the same soft shadow
- emoji or sparkle icons, "AI-powered" badges, gradient text
- a uniform 8px radius and equal padding on everything

## Do instead

- A real type hierarchy: a characterful display face and a workhorse text face,
  on a tight, intentional scale.
- A restrained palette with one confident accent, used sparingly.
- Asymmetry, rules, dividers, and whitespace doing the structural work instead
  of boxes.
- Density that fits the task, and real copy rather than lorem ipsum.
- WCAG AA contrast, visible focus states, and `prefers-reduced-motion` support.

## Verify

Screenshot every screen at 375px and 1440px, in light and dark themes. Fix
anything that looks generic before calling it done.
