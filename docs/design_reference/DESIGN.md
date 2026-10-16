---
name: Lab Precision System
colors:
  surface: '#f7f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#45464d'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#76777d'
  outline-variant: '#c6c6cd'
  surface-tint: '#565e74'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#131b2e'
  on-primary-container: '#7c839b'
  inverse-primary: '#bec6e0'
  secondary: '#0051d5'
  on-secondary: '#ffffff'
  secondary-container: '#316bf3'
  on-secondary-container: '#fefcff'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#0b1c30'
  on-tertiary-container: '#75859d'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dae2fd'
  primary-fixed-dim: '#bec6e0'
  on-primary-fixed: '#131b2e'
  on-primary-fixed-variant: '#3f465c'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#b4c5ff'
  on-secondary-fixed: '#00174b'
  on-secondary-fixed-variant: '#003ea8'
  tertiary-fixed: '#d3e4fe'
  tertiary-fixed-dim: '#b7c8e1'
  on-tertiary-fixed: '#0b1c30'
  on-tertiary-fixed-variant: '#38485d'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
typography:
  h1:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  h2:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
  h3:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: '1.4'
  body-main:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: '1'
    letterSpacing: 0.05em
  technical-data:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: '1'
    letterSpacing: '0'
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 8px
  container-margin: 24px
  gutter: 16px
  component-padding-sm: 8px
  component-padding-md: 16px
  component-padding-lg: 24px
---

## Brand & Style

This design system is engineered for high-stakes institutional environments where technical accuracy and inventory integrity are paramount. The brand personality is authoritative, reliable, and meticulously organized, reflecting the structured nature of computer science laboratories.

The visual style follows a **Corporate Modern** approach with a "Technical Utility" edge. It prioritizes information density and clarity over decorative elements. By utilizing a strict "order-first" philosophy, the UI minimizes cognitive load for lab administrators while providing a sense of technological sophistication. The aesthetic evokes the feeling of a high-end control center, using structured whitespace and a rigid alignment to signify precision.

## Colors

The palette is anchored by "Deep Navy" (#0F172A), representing institutional stability and professional trust. This is used for primary navigation and high-level headers to provide a strong visual frame. 

A "Tech Blue" is employed for primary actions and interactive states, signaling the technological nature of the platform. "Clean White" and "Slate Grays" form the canvas of the application, ensuring that the interface feels airy and organized.

**Semantic States:**
- **Completo (Green):** Used for stations where all hardware components are verified and present.
- **Falta Componente (Red):** Reserved for immediate alerts where hardware is missing or a QR scan fails to match the inventory.
- **Maintenance (Amber):** Used for equipment currently undergoing technical service.

## Typography

This design system utilizes **Inter** across all levels to maintain a systematic and utilitarian feel. As a highly legible sans-serif, Inter excels in displaying alphanumeric technical data (serial numbers, IP addresses, QR codes), which is critical for inventory management.

Headlines use tighter letter spacing and heavier weights to establish a clear hierarchy. For technical labels and metadata—such as equipment IDs—the design system employs a small, uppercase bold style to distinguish static labels from dynamic data.

## Layout & Spacing

The layout is built on a **12-column fluid grid** for administrative dashboards, transitioning to a specialized **Workstation Grid** for laboratory floor plans. 

- **Workstation Grid:** A custom-defined CSS grid where each cell represents a physical desk. These cells maintain a square aspect ratio to reflect the spatial reality of the lab.
- **Rhythm:** An 8px linear scale is used for all spacing. This "power of two" approach ensures that vertical rhythm is maintained across complex lists and equipment detail panels.
- **Margins:** Large page margins (24px) prevent the UI from feeling claustrophobic, reinforcing the "clean and orderly" brand pillar.

## Elevation & Depth

To maintain a professional, institutional aesthetic, this design system avoids aggressive shadows in favor of **Tonal Layers** and **Low-Contrast Outlines**.

- **Level 0 (Surface):** The background layer, using the lightest gray neutral.
- **Level 1 (Cards/Containers):** Pure white surfaces with a subtle 1px border (#E2E8F0). This is the default state for workstation cards and list items.
- **Level 2 (Active/Hover):** A very soft, diffused shadow (0px 4px 12px rgba(15, 23, 42, 0.05)) to indicate interactivity.
- **Level 3 (Modals/Overlays):** These use a stronger depth to pull focus, utilizing a semi-transparent dark overlay behind the modal to dim the background inventory grid.

## Shapes

The design system utilizes **Soft (Level 1)** roundedness. 

A corner radius of 4px-8px is applied to all buttons, input fields, and equipment cards. This subtle rounding provides a modern touch without sacrificing the professional, "engineered" look of the system. Larger components like Modals use 12px (rounded-xl) to feel more distinct from the background grid, while status indicators (chips) use a full pill-shape to contrast against the rectangular workstation grid.

## Components

### Workstation Grid & Cards
Individual stations are represented as cards within a grid.
- **Visual Indicator:** A thick left-border or a status dot in the corner using semantic colors (Green for Complete, Red for Missing).
- **Content:** Station ID, primary PC status, and a mini-QR icon.

### Equipment Detail Modals
Triggered when a workstation is selected or a QR is scanned.
- **Layout:** Two-column split. Left side shows the QR code and equipment image; right side lists a technical checklist of components (CPU, RAM, Peripherals).
- **Interactivity:** Toggle switches for manual verification overrides.

### Status Chips
Compact labels used in lists and headers.
- **Style:** Light tinted backgrounds with dark text (e.g., Light Green background with Dark Green text) for high readability and professional "tagging" appearance.

### Expandable Lists
Used for bulk inventory views.
- **Behavior:** Clicking a row expands it to show a sub-list of components and their individual QR history.

### Floating Action Button (FAB)
The primary trigger for the QR Scanner.
- **Style:** Circular, utilizing the Primary Navy color with a white Scan icon. Positioned in the bottom-right corner for ergonomic mobile/tablet use during physical lab audits.

### Input Fields
- **Style:** Outlined with 1px border. Focus states use the Tech Blue for the border and a subtle blue outer glow to guide the user's attention.