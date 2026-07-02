# SPEC B — Design system « Grand Siècle » hors pb-components (site statique MaX v1 + Bootstrap 5 / vanilla)

> Source analysée : `/home/rayondemiel/Projet_UNIL/grand-siecle-TeiAPP` (TEI Publisher / eXist-db).
> Objectif : reproduire l'identité visuelle et les composants UI dans un site statique généré par MaX (BaseX + XSLT), gelé par wget, sans Web Components `pb-*`.
> Tous les chemins ci-dessous sont relatifs à la racine du dépôt source sauf mention contraire.

---

## 1. Design tokens

### 1.1 Palette « marque » Grand Siècle (`resources/css/grand-siecle.css`, lignes 10–26)

C'est LA palette canonique du projet — thème « papier ancien / bleu royal / or ». À copier telle quelle dans le CSS racine du site statique :

```css
:root {
    --gs-cream: #F5F0E8;        /* fond principal (body) */
    --gs-cream-light: #FEFCF7;  /* fond secondaire (cartes, inputs) */
    --gs-cream-warm: #EDE5D8;   /* fond tertiaire (encarts, chips) */
    --gs-sepia: #2C2418;        /* texte principal */
    --gs-sepia-medium: #5a4a3a; /* texte secondaire */
    --gs-sepia-light: #8a7a6a;  /* texte discret / méta */
    --gs-blue: #1E3A6D;         /* accent primaire : titres, liens, boutons */
    --gs-blue-light: #2B5B8A;   /* accent personnes */
    --gs-blue-dark: #0F2340;    /* fonds sombres (menubar, section explore, bottom) */
    --gs-gold: #9C7A3C;         /* accent secondaire : filets, kickers, hover liens */
    --gs-gold-light: rgba(156, 122, 60, 0.25); /* bordures dorées discrètes */
    --gs-gold-bright: #C49A4A;  /* or vif (hover sur fond sombre) */
    --gs-bordeaux: #7A2E2E;
    --gs-green: #3A6B4A;        /* accent lieux */
    --gs-purple: #5B3A7A;       /* accent organisations */
}
```

Alias utilisés ponctuellement (fallbacks dans `document-view.css`, `entity-aside.css`, fin de `grand-siecle.css` lignes 1264+) : `--gs-bg-primary` = #F5F0E8, `--gs-bg-secondary` = #FEFCF7, `--gs-text-primary` = #2C2418, `--gs-text-secondary` = **#6F5C3F**, `--gs-accent-primary` = #1E3A6D, `--gs-accent-secondary` = #9C7A3C. Bordures « hors token » récurrentes : `#E0D5BC`, `#D9CFB8`, `#E8DEC7`, `#FBF5E8` (fond hover panneaux).

### 1.2 Couleurs par TYPE d'entité (canoniques — `resources/css/registers-theme.css`, lignes 154–167)

Déclarées sur `.gs-register, .gs-entity-detail, .gs-hub` ; à déclarer sur `:root` en statique :

| Type          | Custom property           | Hex       |
|---------------|---------------------------|-----------|
| person        | `--gs-type-person`        | `#2B5B8A` |
| place         | `--gs-type-place`         | `#3A6B4A` |
| organization  | `--gs-type-organization`  | `#5B3A7A` |
| work          | `--gs-type-work`          | `#A85831` |
| event         | `--gs-type-event`         | `#5C4B8C` |
| technique     | `--gs-type-technique`     | `#6B6B2F` |
| date          | `--gs-type-date`          | `#7A5A3A` |
| artwork       | `--gs-type-artwork`       | `#8A5A2A` |
| material      | `--gs-type-material`      | `#4A5A6A` |

⚠️ Divergences internes à connaître : dans le texte des documents (`grand-siecle.css` lignes 670–749) `entity-technique` = `#6B7A3A` (et non #6B6B2F), `entity-object` = `#8B4513`, `entity-material` = `#5A5F6A`, `entity-event` = `#5C4B8C` (identique). Le panneau d'entités (`entity-aside.css` lignes 46–54) reprend la série « document ». Recommandation : garder les deux séries (série *registres* pour index/fiches, série *document* pour le surlignage in-texte) ou unifier sur la série registres.

### 1.3 Typographie

- **Import Google Fonts** (`resources/css/grand-siecle.css`, ligne 8) :
  ```css
  @import url('https://fonts.googleapis.com/css2?family=EB+Garamond:ital,wght@0,400;0,500;0,600;0,700;1,400;1,500&family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;0,600;0,700;1,300;1,400;1,500&display=swap');
  ```
  Pour un site statique RGPD-friendly : auto-héberger ces deux familles (comme le projet le fait déjà pour **Inter** : `resources/fonts/font.css` + `inter-v19-latin_latin-ext-{regular,italic,500,500italic,600,600italic}.woff2`).
- **Familles et rôles** :
  - `'Cormorant Garamond', serif` — display : h1–h6, kickers, labels uppercase, boutons, compteurs.
  - `'EB Garamond', serif` — corps de texte, contenu TEI (`pb-view` : 1.25rem / line-height 1.7), listes, metas.
  - `'Inter', sans-serif` — UI utilitaire (toolbar document, panneau d'entités, tooltips) — locale, cf. `resources/fonts/font.css`.
  - `"JetBrains Mono", ui-monospace, monospace` — identifiants, compteurs de facettes, chips d'autorité, variantes (n'est PAS importée : fallback ui-monospace assumé).
- **Hiérarchie** (grand-siecle.css + jinks-variables.css) :
  - Titre hero : `clamp(4rem, 10vw, 8rem)` (« GRAND », weight 300, uppercase, bleu) / `clamp(4.5rem, 11vw, 9rem)` (« Siècle », italique, or).
  - h2 sections landing : `clamp(2rem, 4.5vw, 3rem)`, weight 300.
  - Titre registre/hub `.gs-register-title, .gs-hub-title` : `clamp(1.8rem, 3vw, 2.4rem)`, weight 600, bleu.
  - Titre fiche autorité `.gs-authority-title` : `clamp(1.9rem, 3.5vw, 2.6rem)`.
  - Base UI : 16px (`--jinks-base-font-size`), contenu : 1.25rem/150% (`--jinks-content-font-size`), max-width contenu : `70ch`, max-width page : `84rem` (`resources/css/jinks-variables.css` lignes 72–111).

### 1.4 Espacements, radius, ombres, animations

- **Radius signature : 2px partout** (boutons, inputs, chips, cartes KWIC) ; 3px pour cartes hub et tooltips ; 9px (pill) pour le compteur de mentions ; `--jinks-form-border-radius: 90px` (formulaires jinks, non repris dans le thème GS).
- **Ombres** : cartes hub hover `0 6px 18px rgba(44,36,24,0.08)` → `0 10px 28px rgba(44,36,24,0.10)` ; bouton primaire hover `0 6px 20px rgba(30,58,109,0.25)` ; peinture hero `0 4px 20px rgba(44,36,24,0.15), 0 20px 60px rgba(44,36,24,0.1)`.
- **Easing signature** : `cubic-bezier(0.22, 1, 0.36, 1)` (reveals, cartes, boutons).
- **Animations** (grand-siecle.css lignes 63–94) : `gs-fadeUp`, `gs-fadeIn`, `gs-lineGrow`, `gs-float` (flottement 6s de la peinture hero) ; `.gs-reveal`/`.gs-visible` (reveal au scroll, 0.9s). `registers-theme.css` ajoute un stagger `animation-delay: calc(var(--i) * 12ms)` sur les lignes de résultats + support `prefers-reduced-motion` (lignes 1108–1129).
- **Ornement typographique** : le fleuron `❦` (avant `.gs-backlinks-title`, `.gs-cooccur-title`, `.gs-metadata-heading`, `.gs-empty`) et l'astérisme `✶` (avant `.gs-authority-sub`) — motif « gilded rule / fleuron » de la marque.

### 1.5 Couches jinks/Pico (contexte)

`resources/css/jinks-variables.css` fait le pont vers Pico CSS et pb-components : overrides GS lignes 8–12 (`--jinks-colors-100:#F5F0E8`, `--jinks-colors-200:#FEFCF7`, `--jinks-colors-700:#1E3A6D`, `--jinks-colors-accent:#9C7A3C`). Les `palette-*.css` (beige/blue/green/neutral/teal) sont des thèmes jinks génériques alternatifs — `config.json` sélectionne `"palette": "green"` mais les overrides GS priment. **En statique Bootstrap 5 : ignorer palette-*.css et jinks-*, ne porter que les tokens §1.1–1.4** (remapper sur `--bs-body-bg: var(--gs-cream)` etc.).

---

## 2. Header, footer, landing page

### 2.1 Menubar (header)

Markup : `templates/menu.html` (rendu jinks) ; items définis dans `context.json` (clé `menu.items`) ; styles : `resources/css/menu.css` + `grand-siecle.css` lignes 1152–1218.

Structure réelle rendue (simplifiée pour statique) :

```html
<header class="page-header">
  <nav class="menubar">
    <ul> <!-- gauche, gap 2.5rem -->
      <li class="logo"><a href="/"></a></li>
      <li><a href="browse.html">Parcourir</a></li>            <!-- id "Start" -->
      <li>
        <details class="dropdown gs-nav-dropdown">            <!-- hybride : lien + caret -->
          <summary><a class="gs-nav-link" href="entities">Index</a></summary>
          <ul>
            <li><a href="people">Personnes</a></li>
            <li><a href="places">Lieux</a></li>
            <li><a href="organizations">Organisations</a></li>
            <li><a href="works">Œuvres</a></li>
            <li><a href="events">Événements</a></li>
            <li><a href="artworks">Objets &amp; œuvres d'art</a></li>
            <li><a href="materials">Matériaux</a></li>
            <li><a href="techniques">Techniques</a></li>
            <li><a href="dates">Chronologie</a></li>
          </ul>
        </details>
      </li>
    </ul>
    <ul> <!-- droite -->
      <li><form action="search.html"><input type="search" name="query"/></form></li>
      <li><!-- pb-lang : sélecteur fr/en/de → simple <select> ou omis --></li>
      <li class="mobile trigger"><button data-toggle=".mobile.menubar">☰</button></li>
    </ul>
  </nav>
  <!-- templates/menu-mobile.html : .mobile.menubar.hidden, liste plate items + .mobile-subitem -->
</header>
```

Styles clés : menubar fond `var(--gs-blue-dark)` (#0F2340), bordure basse `1px solid rgba(196,154,74,0.12)`, liens `rgba(254,252,247,0.85)` EB Garamond, hover `var(--gs-gold-bright)`. Sur la landing : verre flottant `rgba(15,35,64,0.88)` + `backdrop-filter: blur(16px)` (`.landing-layout .page-header .menubar`, grand-siecle.css lignes 1195–1203). Le pattern `<details class="dropdown">` est du HTML natif Pico → **fonctionne tel quel en statique** (remplacer par le dropdown Bootstrap si souhaité, mais inutile). Note : le chevron du dropdown est forcé en clair par `filter: brightness(0) invert(1)` (menu.css lignes 67–72).

### 2.2 Footer et section « bottom »

- `templates/bottom.html` : `<section id="bottom" class="gs-section-bottom">` — fond `--gs-blue-dark`, filet doré dégradé en ::before, deux `ul.link-group` (Parcourir / Personnes / Lieux / Organisations ; Recherche / À propos / Contact) + baseline : *« Grand Siècle — Les premiers discours français sur la peinture. Projet de recherche de l'Université de Lausanne — UNIL. »*
- `templates/footer.html` : `<footer class="gs-footer">` fond `--gs-sepia` (#2C2418) — `span.gs-footer-title` « Grand Siecle » (uppercase Cormorant) + `span.gs-footer-sep` « | » doré + « Université de Lausanne — UNIL » + lien licence CC BY-NC-SA 4.0 avec 2 SVG inline (pictos CC). 100 % copiable en statique.

### 2.3 Landing page (`templates/index.html` + `grand-siecle.css` sections HERO/SECTIONS)

- **Hero** `.gs-hero` (min-height 100vh, dégradé crème 135deg, texture papier SVG-noise en ::before opacité 0.025, filet doré 3px en ::after) contenant `.gs-hero-inner` (grid 1fr 1fr, max-width 84rem, padding 8rem 4rem 4rem) :
  - Gauche `.gs-hero-content` : `.gs-hero-kicker` « XVIe–XVIIe siècle » (uppercase or, letter-spacing 0.25em) ; `.gs-hero-title` avec `.gs-hero-title-grand` (« Grand ») et `.gs-hero-title-siecle` (« Siècle », italique or) ; `.gs-hero-subtitle` (« Qu'est-ce qu'une bonne peinture ? … ») ; `.gs-hero-cta` : `a.gs-btn.gs-btn-primary` « Explorer le corpus » → browse.html + `a.gs-btn.gs-btn-ghost` « Découvrir le projet » → #about ; `.gs-hero-stats` (3 × `.gs-stat` : `300+ sources`, `3 langues`, `1590 —1650`).
  - Droite `.gs-hero-visual` > `.gs-hero-frame` (aspect-ratio 3/4, animation gs-float) : `img.gs-hero-painting` = `resources/images/image-front_1.jpg` + `.gs-hero-frame-border` (double cadre doré en inset −12px/−6px).
  - `.gs-hero-scroll-hint` « Défiler » + flèche SVG.
- **Sections numérotées** : `section.gs-section.gs-reveal > .gs-section-inner` (grid `80px 1fr`) avec `.gs-section-marker` = chiffre romain doré (I à IV) + filet vertical. Variantes : `#about .gs-section-about` (fond crème, lettrine `::first-letter` sur le 1er paragraphe), `#highlights .gs-section-explore` (fond `--gs-blue-dark`, cartes `.highlight-card` sur image avec dégradé + `backdrop-filter: blur`), `#axes .gs-section-axes` (fond `--gs-cream-warm`, `h3::after` = trait doré 3rem×2px), `#team .gs-section-team` (`.member-card` : bordure `--gs-gold-light`, fond crème clair, hover translateY(-3px)), `#project-partners` (layout TEI Publisher par défaut).
- Le **contenu** des sections vient de `data/landing-page/*` via `landing:section(...)` (XQuery) — en statique MaX, l'injecter à la génération XSLT. Les classes `label`, `highlight-card`, `teaser`, `member-card` viennent de `resources/css/landing-page.css` (lignes 233–300, 368–410, 469–500).
- **JS landing** (`resources/scripts/landing.js`) : IntersectionObserver ajoute `.gs-visible` aux `.gs-reveal` (threshold 0.12, rootMargin -60px), parallaxe hero au scroll, stagger `animationDelay` sur les éléments hero. **Vanilla pur, copiable tel quel.**

---

## 3. Composants récurrents (catalogue)

### 3.1 Cartes de documents (browse)

Markup émis par l'ODD `resources/odd/grand_siecle.odd` (lignes 540–555, modèle `teiHeader` prédicat `display='browse'`) ; styles `grand-siecle.css` lignes 1267–1305 :

```html
<a href="{uri}" class="gs-browse-card-link">
  <h3 class="gs-browse-title">{titre}</h3>
  <div class="gs-browse-meta">
    <span class="gs-browse-author">{auteur}</span>
    <span class="gs-browse-place">{lieu, italique}</span>
    <span class="gs-browse-date">{date, couleur or}</span>
  </div>
</a>
```

Mode grille : `#document-list.browse-list.toggle` → `grid-template-columns: repeat(auto-fill, minmax(280px, 1fr))`, chaque `.document-info` encadrée `1px solid var(--gs-cream-warm)` fond crème clair (lignes 651–665). En statique : générer ces cartes en XSLT + toggle liste/grille en vanilla (ajout/retrait de la classe `toggle`), remplaçant `pb-select-feature`.

### 3.2 Badge de confiance de RÉCONCILIATION (registres) — glyphes ◆

Émis par `modules/registers-api.xql` `rview:confidence-badge()` (lignes 406–420) ; styles `registers-theme.css` lignes 588–592 :

| Niveau  | Glyphe | Classe          | Couleur                 | Libellé (title)            |
|---------|--------|-----------------|-------------------------|----------------------------|
| high    | ◆◆◆    | `.gs-conf-high`   | `#2e7d32` (vert)        | réconciliation fiable      |
| medium  | ◆◆     | `.gs-conf-medium` | `var(--gs-gold)` #9C7A3C | réconciliation moyenne     |
| low     | ◆      | `.gs-conf-low`    | `#b06a28` (orange brûlé) | réconciliation incertaine  |
| (none)  | ○      | `.gs-conf-none`   | `#b3a48f` / sepia-light  | non réconciliée            |

```html
<span class="gs-conf gs-conf-high" title="réconciliation fiable"><span class="gs-conf-glyph">◆◆◆</span></span>
```

Légende associée `.gs-conf-legend` (register-index.html lignes 156–161) avec pseudo-libellé `::before { content: "Réconciliation" }` (registers-theme.css lignes 969–978). Principe d'accessibilité affiché dans le code : « glyph + colour, never colour alone ».

### 3.3 Confiance NER in-texte (documents) — `data-cert`

Distincte du badge ◆ : dans le corps des documents, chaque entité porte `data-cert="high|mid|low"` (ou une valeur numérique). Styles `grand-siecle.css` lignes 884–891 :

```css
[data-cert="high"] { border-bottom-style: solid; }
[data-cert="mid"]  { border-bottom-style: dashed; }
[data-cert="low"]  { border-bottom-style: dotted; opacity: 0.55; }
.entity-low-confidence { opacity: 0.3; border-bottom-style: dashed; }  /* appliqué par ner-slider.js */
```

### 3.4 Surlignage des entités in-texte

`grand-siecle.css` lignes 670–755 : `span/a.entity-{person|place|org|work|event|technique|date|object|material}` — fond `rgba(<couleur>, 0.08)`, `border-bottom: 2px solid <couleur>`, hover 0.18. `.entity-rs` (générique) : pointillé gris. Tooltip `.entity-tooltip` avec badges `.person-badge/.place-badge/.org-badge` (fond teinté 0.15). Dans l'app le tooltip est un `pb-popover` → en statique remplacer par un tooltip Bootstrap ou un `<details>`/CSS pur ; le contenu du template popover est dans l'ODD (grand_siecle.odd lignes 208–420 : nom, type, `entity-cert`, lien « Voir la fiche → »).

### 3.5 Lignes de résultats (browse registres) et chips

Markup émis par `rview:overview-row()` (`modules/registers-api.xql` lignes 480–508) :

```html
<div class="split-list-item">
  <a class="gs-entity-item gs-entity-item-person gs-recon" href="people/person-000123">
    <span class="gs-entity-label">Nicolas Poussin</span>
    <span class="gs-entity-mentions gs-m3" title="42 mentions dans le corpus">42</span>
    <span class="gs-entity-row-meta">
      <span class="gs-entity-meta">1594–1665 · peintre</span>
      <span class="gs-conf gs-conf-high" title="réconciliation fiable"><span class="gs-conf-glyph">◆◆◆</span></span>
      <span class="gs-auth-chips"><span class="gs-auth-chip gs-auth-wikidata">Wikidata</span>…</span>
    </span>
  </a>
</div>
```

- Bordure gauche 3px couleur du type via `--gs-type` (`.gs-entity-item-{type}` définit `--gs-type: var(--gs-type-{type})`, registers-theme.css lignes 543–551) ; hover : bordure 6px + fond blanc.
- Hiérarchie réconcilié/non : `.gs-recon .gs-entity-label` bleu 500, `.gs-unrecon` sépia 400 (lignes 314–321).
- **Pastille mentions** `.gs-entity-mentions` : mono 0.7rem, pill radius 9px ; tiers de magnitude `gs-m1` (opacité 0.6, n=1) / `gs-m2` (2–9) / `gs-m3` (≥10 : gras + bord or) / `gs-m4` (≥50 : fond `--gs-gold-light`). Seuils dans registers-api.xql ligne 489.
- **Chips d'autorité** `.gs-auth-chip` : uppercase mono 0.62rem fond `--gs-cream-warm`, libellés Wikidata / VIAF / ISNI / GND / BnF / LCCN / GeoNames / Getty AAT (`rview:auth-abbr`, lignes 422–433 ; URL par référentiel : `rview:auth-url` lignes 435–450).

### 3.6 Sidebar de facettes (browse)

Markup : `templates/register-index.html` lignes 57–154 ; styles registers-theme.css lignes 179–307 + 906–943. Look : colonne 260px, bord gauche `1px solid --gs-gold-light`, groupes `fieldset.gs-facet-group` séparés par filets dorés, `legend` uppercase Cormorant avec tiret doré en ::before, cases `label.gs-check` avec `accent-color: var(--gs-blue)` + compteur mono `.gs-count`. Composants : recherche `input.gs-filter-search`, filtre par facette `.gs-facet-filter` (« Filtrer… »), bouton `.gs-facet-more` (« + N autres » / « Voir moins »), toggle `.gs-more-params` (préfixe `+`/`−` via `aria-expanded`), plage d'années `.gs-year-range` (2 `input[type=number]` `.gs-year-input` séparés par `→`), slider simple `.gs-slider-single` (mentions min, `accent-color` bleu), bouton `#gsReset` (`.gs-btn.gs-btn-ghost`). Il existe aussi un dual-range custom `.gs-range` (thumbs 24px bleus, lignes 446–471 + 933–943), remplacé dans le template par les inputs numériques.

### 3.7 KWIC « Cité dans » (fiche autorité)

Markup émis par registers-api.xql lignes 168–200 ; styles registers-theme.css lignes 336–434 :

```html
<div class="gs-backlinks">
  <h2 class="gs-backlinks-title">Cité dans <span class="gs-backlinks-count">7</span> documents
      <span class="gs-backlinks-sep"> · </span><span class="gs-backlinks-mentions">42</span> mentions</h2>
  <ul class="gs-backlinks-list">
    <li class="gs-backlinks-item">
      <button type="button" class="gs-kwic-toggle" data-id="person-000123" data-doc="LIV0326a" aria-expanded="false">
        <span class="gs-backlinks-doc">Titre du document</span>
        <span class="gs-backlinks-id">LIV0326a</span>
      </button>
      <div class="gs-kwic-panel" hidden><!-- injecté par /api/cited --></div>
    </li>
  </ul>
</div>
```

Style KWIC : `.gs-kwic-line` = bloc EB Garamond, `border-left: 2px solid --gs-gold-light`, fond crème clair, **mot-clé `<mark>`** : fond `--gs-gold-light` (0.3), texte bleu, weight 600, padding 0 0.15rem, radius 1px. Chevron ▸ doré rotatif sur `.gs-kwic-toggle[aria-expanded=true]`. En statique : soit pré-générer tous les passages (panneau rempli à la génération, le JS ne fait plus qu'ouvrir/fermer), soit générer des fragments HTML par (entité, doc) crawlés et fetchés — le CSS et le pattern `aria-expanded` sont réutilisables tels quels.

### 3.8 Cartes du hub `/entities`

Markup `rview:hub-overview()` (registers-api.xql lignes 1206–1234) + `templates/entities.html` ; styles registers-theme.css lignes 756–812 et 869–904 :

```html
<a class="gs-hub-card gs-hub-card-person" href="people">
  <span class="gs-hub-type">Personnes <span class="gs-exp-badge">exp.</span><!-- si date/artwork --></span>
  <span class="gs-hub-total">312</span>
  <span class="gs-hub-stats">
    <span class="gs-hub-recon">204 réconciliées</span>   <!-- ::before "✓ " vert -->
    <span class="gs-hub-top">Poussin · 87 mentions</span>
  </span>
</a>
```

Grille 3 colonnes (2 à ≤820px, 1 à ≤520px), bordure gauche 4px couleur type, dégradé teinté `color-mix` en fond, coin décoratif doré en ::after, grand chiffre 2.9rem couleur type. Header du hub : `.gs-section-marker` « Référentiels d'autorité » entouré de deux filets dorés (::before/::after).

### 3.9 Pagination, toggles, divers

- **Pagination** : browse documents = `pb-paginate` (à remplacer par la pagination Bootstrap ou par Pagefind) ; browse registres = bouton **« Afficher plus »** `#gsMore` (`.gs-btn.gs-btn-ghost`, offset+limit) — en statique, pré-paginer ou tout charger + filtrage client.
- **Bascule Original/Modernisé** : deux mécanismes. (1) Dans un même rendu : spans `.choice-orig` (visible) / `.choice-reg` (masqué), inversés par ajout de `.toggled` (grand-siecle.css lignes 974–977) — piloté dans l'app par `pb-toggle-feature`, trivial à refaire en vanilla (un bouton qui toggle une classe sur le conteneur). (2) Vues parallèles : `resources/css/modernized.css` (5 lignes) inverse orig/reg pour le panneau « Modernisé ». Boutons : style `.gs-toolbar-btn` (Cormorant 0.85rem, bord `--gs-gold-light`, hover/active fond or texte crème, grand-siecle.css lignes 1115–1132).
- **Toggle Liste/Carte (lieux)** : segmented control `.gs-view-toggle` > `button.gs-view-btn` (+ `.is-active` fond `--gs-type-place`), registers-theme.css lignes 1233–1262.
- **Lien d'export** `.gs-export-link` (uppercase or, préfixe `↓`, hover inversé) + `.gs-export-actions` (fiche autorité).
- **Encart expérimental** `.gs-exp-notice` + badge `.gs-exp-badge` (mono uppercase fond or) — types `date` et `artwork`.
- **Fiche autorité** : layout 2 colonnes ≥880px (`.gs-authority` grid `1fr 16rem`), encadré référentiels `.gs-authority-ids` (bord supérieur 3px or), variantes `.gs-variant` (chips mono), méta `.gs-meta-row` (grid `9rem 1fr`, clés uppercase dorées), provenance `.gs-provenance` (bord gauche or, italique ; texte : « Entité détectée automatiquement (NER CamemBERT + GLiNER), réconciliation Wikidata : fiable/moyenne/incertaine/non réconciliée »), co-occurrences `.gs-cooccur-item` (chips bord gauche couleur type).
- **Notice (aside métadonnées)** : `.gs-metadata-heading` avec fleuron ❦ doré (grand-siecle.css lignes 1316–1336) ; contenu stylé par `resources/css/metadata-aside.css` (chargé dans le shadow DOM via `load-css` — en statique, charger en CSS normal).

---

## 4. Slider NER et panneau d'entités : analyse portage

### 4.1 `resources/scripts/ner-slider.js` (44 lignes) — **copiable tel quel à 95 %**

Fonctionnement exact :
1. Markup attendu (défini dans `templates/pages/view.html` lignes 53–60) :
   ```html
   <div class="ner-slider-container">
     <label for="ner-threshold">Confiance NER</label>
     <input type="range" id="ner-threshold" min="0" max="1" step="0.05" value="0.5"/>
     <span id="ner-threshold-value">0.50</span>
   </div>
   ```
2. Mapping des valeurs textuelles → numériques : `{ high: 0.9, mid: 0.6, low: 0.3 }` (une valeur `data-cert` numérique est aussi acceptée via `parseFloat`).
3. À chaque `input` : met à jour l'affichage (`toFixed(2)`) puis `applyThreshold(val)` : pour **tout** `[data-cert]` du document, `el.classList.toggle('entity-low-confidence', cert < threshold)` → opacité 0.3 + soulignement dashed (CSS §3.3).
4. Init sur `DOMContentLoaded` **et** sur l'événement **`pb-update`** (re-rendu de pb-view).

Portage statique : supprimer uniquement le listener `pb-update` (le contenu étant rendu à la génération, `DOMContentLoaded` suffit). ⚠️ Condition : le HTML gelé doit exposer les `data-cert` dans le light DOM (rendu XSLT MaX), pas dans un shadow DOM. Aucune API appelée. CSS nécessaire : `[data-cert=…]` + `.entity-low-confidence` + `.ner-slider-container` (§1, §3.3, grand-siecle.css lignes 1133–1141 : `input[type=range] { width: 100px; accent-color: var(--gs-blue); }`).

### 4.2 `resources/scripts/entity-panel.js` (364 lignes) — **à réécrire partiellement**

Ce qu'il fait : pour chaque `pb-panel` du visualiseur (`templates/pages/view.html`), il crée un `<aside class="gs-panel-entity-aside">` (résumé + recherche + liste), ouvert par `button.gs-entity-aside-toggle` de la toolbar du panneau.

Dépendances pb-components / serveur (à remplacer) :
- **API** `GET api/document-entities?file={doc}&scope={original|modernized|notes|all}` (lignes 168–201) → JSON `{ entities: [{id, type, label, mentions, source, certs[]}], summary }`. Endpoint : `modules/custom-api.xql`. → En statique : émettre à la génération un JSON par document (ex. `data/entities/{doc}.json`) ou injecter le JSON inline dans la page.
- **pb-panel** : détection de la sous-vue active via attributs `panels`/`active` + MutationObserver (lignes 62–148) ; **pb-document** pour retrouver le nom de fichier (lignes 44–50) ; **pb-view/shadowRoot** pour la navigation (`pbView.shadowRoot || pbView`, ligne 310). → En statique sans multi-panneaux, tout ce câblage disparaît.
- **pb-grid** : observation des panneaux clonés (lignes 340–356) — sans objet en statique.

Ce qui est copiable tel quel : la logique de rendu/filtre (labels `TYPE_LABELS` français lignes 16–26, mapping `TYPE_CSS` lignes 28–38, `renderSummary`/`renderList`/filtre texte + type, lignes 214–303), la navigation `scrollIntoView` + flash `.gs-entity-highlight` (lignes 305–333), et **tout le CSS** : `resources/css/entity-aside.css` (volet 250px, `border-left: 2px solid #9C7A3C`, transition width 0.25s, badges par type, pulse `gs-entity-pulse`) + le bloc « ENTITY PANEL CONTENT » de grand-siecle.css (lignes 997–1098 : `.gs-entity-total`, `.gs-entity-type-counts`, `.gs-entity-badge[-{type}]` bord gauche 3px, `.gs-entity-filter-tag`, `.gs-entity-search`, `.gs-entity-item/label/meta/empty`).

Réécriture conseillée (~120 lignes vanilla) : un seul volet par page document, données depuis JSON pré-généré, `querySelector` sur le light DOM. La bascule Original/Modernisé étant faite par classes CSS (§3.9), le « scope » peut se réduire à filtrer les entités visibles.

### 4.3 Autres scripts

- `resources/scripts/lang-toggle.js` : détecte les `[data-lang]` rendus, crée des boutons `.gs-toolbar-btn` (LAT/ITA/…), injecte des règles `.lang-highlight-{code} .tei-foreign[data-lang=…]` (couleurs lignes 21–28). Dépendances : `document.querySelector('pb-view')` (→ remplacer par le conteneur du texte) + événement `pb-update` (→ supprimer). **Portage trivial.**
- `resources/scripts/registers-browse.js` : moteur du browse à facettes — entièrement dépendant des API `/api/{slug}/browse`, `/api/export`, `/api/facet-source`, `/api/places/map` + `pbEvents`/`pb-leaflet-map` pour la carte. → **À réécrire** : filtrage client sur un JSON complet du registre pré-généré (les registres font quelques milliers d'entrées max) + Leaflet natif pour la carte. Réutilisables tels quels : `setupChecklist()` (facettes repliables « + N autres », lignes 179–234), le debounce, la logique de stagger `--i`.
- `resources/scripts/registers-entity.js` : lazy-load KWIC/co-occurrences (`/api/cited`, `/api/cooccur`) — pattern fetch-fragment-HTML conservable si les fragments sont pré-générés ; sinon inliner les passages et ne garder que le toggle `aria-expanded`.
- `resources/scripts/landing.js` (§2.3) : **copiable tel quel** (vanilla). `resources/scripts/header.js` : observer du `.banner-spacer` — copiable si ce markup est repris.

---

## 5. Fichiers : copiables / à adapter / à réécrire

### 5.1 Copiables tels quels
- `resources/css/grand-siecle.css` — cœur du design system (retirer si besoin les 3 petits blocs `pb-popover`, `pb-search input`, `pb-split-list`, lignes 819–823, 1179–1186).
- `resources/css/registers-theme.css` — surfaces registres (retirer `pb-split-list::part`, `pb-custom-form`, `pb-leaflet-map` lignes 30–61 ; garder `.gs-map-wrap pb-leaflet-map` → renommer vers le div Leaflet).
- `resources/css/entity-aside.css`, `resources/css/document-view.css` (retirer le bloc `body.gs-no-iiif pb-panel`, lignes 84–87), `resources/css/modernized.css`, `resources/css/notes-panel.css`, `resources/css/metadata-aside.css`, `resources/css/menu.css` (si on garde le pattern Pico `details.dropdown`).
- `resources/fonts/font.css` + les 6 `inter-v19-*.woff2`.
- `resources/scripts/ner-slider.js` (moins `pb-update`), `resources/scripts/landing.js`, `resources/scripts/lang-toggle.js` (2 retouches).
- Images : `resources/images/image-front_{1..5}.jpg`, `image-front_logo_unil.svg`, `favicon*`, `icon.svg`, `by.svg`/`cc.svg`/`sa.svg` (licence), `arrow-right.svg`.
- Markup statique : `templates/footer.html`, `templates/bottom.html`, le hero de `templates/index.html` (lignes 33–72), la légende + sidebar de `templates/register-index.html` (en retirant `pb-i18n` → texte français en dur, cf. §6).

### 5.2 À adapter
- `templates/index.html`, `templates/entities.html`, `templates/register-index.html`, `templates/entity.html`, `templates/pages/view.html` → transposer en gabarits MaX/XSLT : supprimer le front-matter JSON jinks, remplacer `[[ … ]]`/`[% … %]` par la génération XSLT, `pb-i18n` par les chaînes fr (§6), `pb-view/pb-grid/pb-panel` par le HTML rendu, `pb-leaflet-map` par Leaflet natif.
- `modules/registers-api.xql` (`rview:`) → **la référence du markup** : porter en XSLT les fonctions `rview:confidence-badge`, `rview:overview-row`, `rview:hub-overview`, `rview:detail-body`, `rview:authority-links-block`, `rview:provenance-block`, backlinks (lignes 160–200) pour générer les mêmes classes CSS.
- `resources/odd/grand_siecle.odd` → source de vérité du rendu TEI→HTML (classes `entity-*`, `choice-orig/reg`, `tei-pb`, `tei-foreign`, `gs-browse-card`) : à transposer dans les XSLT MaX en conservant les mêmes classes/`data-*`.
- `resources/scripts/registers-entity.js` (fetch → fragments statiques), `resources/scripts/browse.js`/`facets.js` (recherche → Pagefind).

### 5.3 À réécrire
- `resources/scripts/entity-panel.js` (§4.2) et `resources/scripts/registers-browse.js` (§4.3) — versions vanilla sur JSON pré-générés.
- Tout ce qui touche `pb-page/pb-login/pb-lang/pb-search/pb-paginate/pb-select-feature/pb-toggle-feature/pb-facsimile/pb-popover` : équivalents Bootstrap/vanilla (recherche → Pagefind ; facsimilé → OpenSeadragon si conservé ; popover entités → tooltip Bootstrap ou CSS).
- À ignorer : `resources/css/palette-*.css`, `jinks-*.css`, `pico-components.css`, `components.css` (thème shadow-DOM pb), `annotate.css`, `editor-styles.css` (admin), `landing-page.css` (n'en reprendre que `.label`, `.highlight-card`, `.member-card`, `.link-group` si la landing garde ces blocs).

---

## 6. Labels français officiels (i18n `resources/i18n/*/fr.json`)

### 6.1 Types d'entités — 9 registres (navigation/menu, `resources/i18n/registers/fr.json` clé `menu`)

| Type (interne) | Slug URL       | Label menu (pluriel)      | Label singulier (`app/fr.json` clé `entity`) |
|----------------|----------------|---------------------------|----------------------------------------------|
| person         | people         | **Personnes**             | Personne                                     |
| place          | places         | **Lieux**                 | Lieu                                         |
| organization   | organizations  | **Organisations**         | Organisation                                 |
| work           | works          | **Œuvres**                | Œuvre                                        |
| event          | events         | **Événements**            | Événement                                    |
| artwork        | artworks       | **Objets & œuvres d'art** | Objet (clé `object`)                         |
| material       | materials      | **Matériaux**             | Matériau                                     |
| technique      | techniques     | **Techniques**            | Technique                                    |
| date           | dates          | **Chronologie**           | Date                                         |

(Les mêmes libellés pluriels sont codés en dur côté serveur dans `rview:type-label`, registers-api.xql, et dans `TYPE_LABELS` d'entity-panel.js — qui utilise « Dates » et « Objets » pour l'usage in-document.)

### 6.2 Navigation & UI (`resources/i18n/app/fr.json` sauf mention)

- Menu : `Start` = **Parcourir** ; `entities` = **Index** (registers/fr.json) ; `home` = Accueil ; `about` = À propos ; `team` = Équipe ; `contact` = Contact ; `partners` = Partenaires ; `explore` = Explorer ; `collections` = Collections.
- Vue document : `diplomatic` = **Original** ; `modernized` = **Modernisé** ; `facsimile` = **Fac-similé** ; `notes` = **Notes marginales** ; `ner-threshold` = **Confiance NER** ; `languages` = **Langues** ; `entities` = **Entités détectées** ; `contents` = Sommaire ; `metadata-title` = **Notice** ; `add-panel` = Ajouter une vue ; `toggle-entities` = Afficher / masquer les entités ; `no-iiif` = Pas de fac-similé disponible pour ce document ; `entity.confidence` = Confiance ; `entity.view-record` = **Voir la fiche**.
- Browse : `display-mode` = Affichage ; `list`/`compact`/`grid` = Liste / Compact / Grille ; `author` = Auteur ; `title` = Titre. Recherche : placeholder **Rechercher...** ; `results` = Résultats de recherche. Toolbar : Précédent / Suivant.
- Registres (`registers/fr.json`) : `hub.title` = **Index des entités** ; `hub.reconciled` = **réconciliées** ; `register.cited-in` = **Cité dans** ; `documents` / `mentions` ; `filter.confidence` = Confiance ; `filter.authority` = **Référentiel** ; `filter.has-authority` = **Avec lien d'autorité** ; `filter.min-mentions` = **Mentions (min.)** ; `filter.period` = Période ; `filter.reset` = **Réinitialiser** ; `filter.more` = Afficher plus ; `filter.more-params` = **Afficher plus de paramètres** ; `filter.bce-hint` = Négatif = avant J.-C. (ex. −384) ; `filter.export-csv` = **Exporter (CSV)** ; `export.tei` = Exporter TEI ; `export.ris` = Exporter RIS ; `view.list`/`view.map` = **Liste / Carte** ; `map.places-shown` = lieux géolocalisés affichés ; `register.experimental` = « Registre expérimental : entités issues d'une détection automatique sur OCR brut, peu ou pas réconciliées. À utiliser avec prudence. »
- Chaînes serveur en dur à reprendre (registers-api.xql / templates) : « Référentiels d'autorité », « Formes attestées », « Provenance », « Candidats non retenus », « Réconciliation », « Chargement… », « Aucun résultat pour ces critères. », « N résultat(s) », niveaux « fiable / moyenne / incertaine / non réconciliée », intro hub : « Personnes, lieux, organisations, œuvres et autres entités identifiées dans le corpus par détection automatique (NER) puis réconciliées avec Wikidata. Chaque notice renvoie aux documents qui la citent. »

---

## Annexe — Correspondance Bootstrap 5

| GS | équivalent BS5 | garde-fou |
|----|----------------|-----------|
| `.gs-btn-primary/ghost` | `.btn` custom (PAS `.btn-primary` bleu BS) | forcer radius 2px, uppercase Cormorant |
| `details.dropdown` menubar | dropdown natif conservé | z-index 9999 (grand-siecle.css lignes 1152–1169) |
| `.gs-hub-grid` | `.row.row-cols-*` ou garder le grid CSS | garder `color-mix` du fond |
| facettes | accordéon maison (PAS `.accordion` BS) | fieldset/legend d'origine = accessible |
| tooltips entités | Popover BS ou CSS `::after` (déjà utilisé pour `.tei-w`/`.tei-foreign`, grand-siecle.css lignes 852–951) | |
| variables | mapper `--bs-body-bg: var(--gs-cream)`, `--bs-body-color: var(--gs-sepia)`, `--bs-link-color: var(--gs-blue)`, `--bs-link-hover-color: var(--gs-gold)`, `--bs-border-radius: 2px`, `--bs-font-serif: 'EB Garamond', serif` | |
