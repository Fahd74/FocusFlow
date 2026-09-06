---
name: Network Flow Aesthetic
colors:
  surface: '#faf9f9'
  surface-dim: '#dadada'
  surface-bright: '#faf9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f3'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e3e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#414750'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f1f0f0'
  outline: '#727781'
  outline-variant: '#c1c7d1'
  surface-tint: '#1a619d'
  primary: '#003e6b'
  on-primary: '#ffffff'
  primary-container: '#005691'
  on-primary-container: '#a0cbff'
  inverse-primary: '#9ecaff'
  secondary: '#1a619d'
  on-secondary: '#ffffff'
  secondary-container: '#83bdfe'
  on-secondary-container: '#004c80'
  tertiary: '#3b3d3d'
  on-tertiary: '#ffffff'
  tertiary-container: '#525454'
  on-tertiary-container: '#c7c8c8'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d1e4ff'
  primary-fixed-dim: '#9ecaff'
  on-primary-fixed: '#001d36'
  on-primary-fixed-variant: '#00497c'
  secondary-fixed: '#d1e4ff'
  secondary-fixed-dim: '#9ecaff'
  on-secondary-fixed: '#001d36'
  on-secondary-fixed-variant: '#00497c'
  tertiary-fixed: '#e2e2e2'
  tertiary-fixed-dim: '#c6c6c7'
  on-tertiary-fixed: '#1a1c1c'
  on-tertiary-fixed-variant: '#454747'
  background: '#faf9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e3e2e2'
typography:
  mobile:
    display-hero:
      fontSize: 28px - 32px (30px)
      fontWeight: '800'
      context: Splash & Onboarding
    h1:
      fontSize: 22px - 24px (23px)
      fontWeight: '700'
      context: App Bar & Screen Titles
    h2:
      fontSize: 18px - 20px (19px)
      fontWeight: '600'
      context: Cards & Sections
    body-lg:
      fontSize: 16px
      fontWeight: '400'
      context: Long texts & Inputs
    body-md:
      fontSize: 14px
      fontWeight: '400'
      context: Secondary description & Helper text
    caption:
      fontSize: 12px - 13px (12.5px)
      fontWeight: '500'
      context: Dates & Bottom Nav
    buttons:
      fontSize: 14px - 16px (15px)
      fontWeight: '600'
      context: Button texts & CTA
  desktop:
    page-title-h1:
      fontSize: 32px - 40px (36px)
      fontWeight: '800'
      context: Page Titles & Dashboards
    h2:
      fontSize: 24px - 28px (26px)
      fontWeight: '700'
      context: Large Table Titles & Widgets
    h3:
      fontSize: 18px - 20px (19px)
      fontWeight: '600'
      context: Modals & Cards
    body-lg:
      fontSize: 16px
      fontWeight: '400'
      context: Dense texts & Articles
    body-md:
      fontSize: 14px
      fontWeight: '400'
      context: Tables, Sidebar & Forms
    caption:
      fontSize: 12px - 13px (12.5px)
      fontWeight: '400'
      context: Explanatory notes & Data details
    buttons:
      fontSize: 14px - 16px (15px)
      fontWeight: '600'
      context: Buttons & Menu navigation
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 0.5rem
  scale-025: 0.125rem
  scale-05: 0.25rem
  scale-1: 0.5rem
  scale-1-5: 0.75rem
  scale-2: 1rem
  scale-3: 1.5rem
  scale-4: 2rem
  scale-6: 3rem
  scale-8: 4rem
  scale-12: 6rem
  scale-16: 8rem
  section-gap: clamp(4rem, 8vw, 8rem)
  max-width: 1280px
  side-padding: 1.5rem
---

## Brand & Style

The design system is built upon a **Corporate / Modern** foundation with a distinct technical edge inspired by networking infrastructure. It evokes a sense of robustness, connectivity, and peak efficiency. The aesthetic is designed to feel high-tech yet professional, catering to environments where data integrity and system uptime are paramount.

The design narrative focuses on the "Flow of Data." This is visualized through structured layouts, technical metadata visibility, and signature connectivity elements. The UI avoids fluff and decorative clichés, favoring a pragmatic, "engineered" appearance that remains accessible. 

Key stylistic pillars:
- **Connected Surfaces:** Use of SVG-driven path lines to connect disparate UI elements, simulating network nodes.
- **Technical Precision:** Strategic use of monospaced fonts for data points to reinforce the "infrastructure" theme.
- **Robustness:** Solid borders and deliberate spacing that suggest a stable, reliable architecture.

## Colors

The palette is strictly restricted to a **light theme** to ensure maximum clarity and a "clean room" data-center feel. This configuration utilizes a unified primary and secondary scheme for maximum brand consistency.

- **Primary & Secondary (Connectivity Blue):** #005691. This unified color is used for all critical actions, active states, and high-contrast brand surfaces. It represents the singular, strong link between nodes.
- **Tertiary (White):** #ffffff. The primary surface color for cards and content containers, maintaining a clinical and efficient backdrop.
- **Neutral (Gray):** #cccccc. Reserved for borders, secondary labels, and muted metadata.
- **Semantic Accents:** 
    - **Electric Green** is used exclusively for success indicators and active system pulses.
    - **Warm Orange** serves as a secondary CTA or warning accent.
    - **Data Cyan** is reserved for decorative SVG flow lines and network shimmers.

## Typography

This design system utilizes a dual-font strategy to balance approachability with technical authority.

- **Open Sans** handles all standard UI roles. It is chosen for its high legibility and professional, neutral tone. Headlines use tighter letter spacing and heavier weights to suggest stability.
- **JetBrains Mono** is the "Technical Metadata" role. It must be used for any non-prose data, such as IP addresses, timestamps, status codes, and system metrics.

### Mobile View Typography (وضع الموبايل)

| العنصر (Element) | الحجم الشائع (px / sp) | سمك الخط (Font Weight) | الاستخدام الشائع (UX Context) |
| :--- | :--- | :--- | :--- |
| **عنوان شاشة رئيسي (Display/Hero)** | 28px - 32px | Bold (700) / ExtraBold (800) | شاشات الترحيب (Splash & Onboarding) |
| **عنوان قسم رئيسي (H1)** | 22px - 24px | Bold (700) / SemiBold (600) | شريط التطبيق (App Bar) وعناوين الشاشات |
| **عنوان فرعي (H2)** | 18px - 20px | SemiBold (600) / Medium (500) | عناوين البطاقات (Cards) والأقسام |
| **النص الأساسي (Body Large)** | 16px (الأساسي) | Regular (400) / Medium (500) | النصوص الطويلة وحقول الإدخال (Inputs) |
| **النص الثانوي (Body Medium)** | 14px | Regular (400) | الوصف الثانوي والنصوص المساعدة |
| **التسميات المصغرة (Caption)** | 12px - 13px | Regular (400) / Medium (500) | التواريخ وشريط التنقل السفلي (Bottom Nav) |
| **الأزرار (Buttons)** | 14px - 16px | SemiBold (600) / Medium (500) | نصوص الأزرار والتفاعلات (CTA) |

### Desktop View Typography (وضع الديسكتوب)

| العنصر (Element) | الحجم الشائع (px) | سمك الخط (Font Weight) | الاستخدام الشائع (UX Context) |
| :--- | :--- | :--- | :--- |
| **عنوان الصفحة (H1 / Page Title)** | 32px - 40px | Bold (700) / Heavy (800) | عناوين الصفحات الرئيسية واللوحات |
| **عنوان قسم كبير (H2)** | 24px - 28px | Bold (700) / SemiBold (600) | عناوين الجداول الكبيرة والـ Widgets |
| **عنوان فرعي (H3)** | 18px - 20px | SemiBold (600) / Medium (500) | عناوين النوافذ المنبثقة (Modals) والكروت |
| **النص الأساسي للمقالات (Body Large)** | 16px | Regular (400) | النصوص الكثيفة والمقالات |
| **نص لوحات التحكم والجداول (Body Medium)** | 14px (الأكثر استخداماً) | Regular (400) | الجداول (Tables)، القوائم (Sidebar)، والاستمارات |
| **النص المصغر (Caption / Metadata)** | 12px - 13px | Regular (400) / Medium (500) | الملاحظات التوضيحية وتفاصيل البيانات |
| **الأزرار وعناصر التحكم (Buttons)** | 14px - 16px | Medium (500) / SemiBold (600) | الأزرار وتنقلات القوائم |

**Constraints:**
- Sentence case should be used for all UI labels (except for `label-caps`).
- Body text should never exceed a width of `72ch` to maintain readability.
- No emojis are permitted; use the icon system exclusively.

## Layout & Spacing

The layout philosophy is a **Fixed Grid** with a maximum width of 1280px, ensuring content remains readable on ultra-wide monitors.

- **Grid Strategy:** Use CSS Grid as the primary engine. Feature sections must follow a "zig-zag" alternating pattern (text + image). Avoid 3-equal-column layouts to prevent the UI from appearing generic.
- **Mobile Adaptivity:** At the 768px breakpoint, all multi-column layouts must collapse into a single vertical stack.
- **Hero Layout:** Always use a split-screen approach with text content on the left and technical visuals (network diagrams, data flows) on the right.
- **Rhythm:** A strict 8px (0.5rem) base unit governs all dimensions. Section gaps are dynamic, scaling with the viewport to maintain a spacious, professional feel.

## Elevation & Depth

Visual hierarchy is established through **Low-Contrast Outlines** and subtle **Tonal Layers**, avoiding heavy shadows that would conflict with the clean, technical aesthetic.

- **Surface Strategy:** Backgrounds are primarily Tertiary (White). Because Primary and Secondary colors are now unified, the Connectivity Blue (#005691) is used for high-contrast anchors like navigation bars or footers.
- **Outlines:** Most cards and input fields use a `1px` solid border in Neutral (#cccccc) to define their boundaries.
- **Subtle Elevation:** 
    - **Default Card:** A faint, diffused shadow (`0 2px 12px rgba(0,0,0,0.06)`) is used to lift primary content containers.
    - **Hover/Lifted:** Upon interaction, increase the shadow slightly to provide tactile feedback without looking "soft."
- **Connectivity Glows:** Instead of traditional depth, use "Active Links" with a 40% opacity Primary (Connectivity Blue) glow to indicate flow and status.

## Shapes

The shape language is precise and modular. While the "Rounded" (0.5rem) setting is used for most UI components like buttons and cards, it is balanced by the underlying grid structure to maintain a "robust" look.

- **Default (0.5rem):** Applied to standard buttons, input fields, and content cards.
- **Large (1rem):** Used for primary container groups or modal wrappers to create a softer hierarchy.
- **None (0px):** Used for system-level elements like top-level navigation bars or technical dividers to emphasize the infrastructure theme.

## Components

### Buttons
- **Primary:** Connectivity Blue background with White text. Heavy-weight font (600). On hover, darken by 8% and apply a "lifted" shadow.
- **Secondary:** Transparent background with a Connectivity Blue border and text. On hover, apply a subtle 8% opacity fill of the primary color.

### Connectivity Elements (Signature)
- **Data-Flow Lines:** Use SVG paths to connect cards or sections. Animate a "shimmer" effect along these paths to represent active traffic.
- **Status Nodes:** Use small circular dots. Success states should use Electric Green with a subtle pulse animation (opacity 0.4 to 1.0).

### Cards
- Tertiary (White) background with a 0.5rem corner radius and a Neutral (#cccccc) border. Content inside should follow the 8px grid.

### Input Fields
- Labels must always be positioned above the field (no floating labels). 
- Focus state: A 2px Connectivity Blue ring with a 2px offset.
- Metadata/Help text should use JetBrains Mono to signify its technical nature.

### Navigation
- Use the unified Connectivity Blue (#005691) for the background to create a strong, singular brand anchor.
- Active links are indicated with a White underline or side-accent and a 500 font weight.

### Motion & Micro-interactions
- **Entry:** Elements should fade in and translate upward by 16px over 420ms.
- **Hover:** All interactive elements must transition color or shadow over 200ms using an `ease-out` curve.