# SPEC E — Inventaire des briques statiques réutilisables du projet TEI Publisher + intégration Pagefind

> **Contexte.** Démo « Grand Siècle statique » : site généré par MaX v1 (BaseX + XSLT, Université de Caen), gelé par crawl `wget`, enrichi côté client (Pagefind, Leaflet, JS maison). Ce document inventorie ce qui existe déjà dans le dépôt TEI Publisher `/home/rayondemiel/Projet_UNIL/grand-siecle-TeiAPP` et ce qui est réutilisable tel quel, adaptable, ou à écarter.
>
> **Sources examinées** : `static/` (intégralité), `docs/claude/migration-static.md`, `docs/claude/phase4-handoff.md`, `resources/scripts/*.js`, `templates/*.html`, `package.json`, doc en ligne Pagefind (https://pagefind.app, consultée le 2026-07-02).

---

## 1. Inventaire du dossier `static/`

Le dossier `static/` du projet TP contient **6 fichiers** (aucun autre fichier caché, aucun build produit). Ce sont des artefacts du **profil Jinks `static`** de TEI Publisher, partiellement provisionné (cf. §2.1) : des templates Jinks (syntaxe `[% template %]` / `[[ $var ]]` + front-matter `---json`) destinés à être **rendus côté serveur eXist au moment du build**, pas des fichiers HTML finaux.

| Fichier | Rôle | État | Réutilisable pour la démo MaX ? |
|---|---|---|---|
| `static/templates/people.html` (56 l.) | Index paginé A→Z des personnes : boucle `[% for $doc in $content %]` → liste de liens `../[[$doc?id]]`, nav de pagination `$pagination?all` | Squelette générique Jinks, **jamais buildé en prod** (phase 1 seulement) ; ne connaît pas les 9 types ni les facettes | **Non tel quel** (syntaxe templating Jinks/eXist, incompatible XSLT MaX). Utile comme **modèle de structure** (pagination statique `../<page>/index.html`) |
| `static/templates/person.html` (33 l.) | Fiche personne : breadcrumb + `[[ $parts?default?content ]]` | Idem — coquille minimale | Non tel quel ; modèle de fiche |
| `static/templates/places.html` (73 l.) | Index lieux + carte `pb-leaflet-map` ; **injecte le GeoJSON inline** : `<script id="geodata" type="application/json">[[ serialize($geodata, map { "method": "json" }) ]]</script>` | Squelette phase 1 ; ⚠️ tile-layer **Mapbox avec token tiers en dur** (`access-token="pk.eyJ1Ijoid29sZmdhbmdtbS..."` , l. 59) à ne PAS reprendre | Non tel quel, mais **le pattern « données géo inline dans un `<script type=application/json>` » est exactement le bon pattern pour un site statique** — à reproduire côté MaX/XSLT |
| `static/templates/place.html` (46 l.) | Fiche lieu avec mini-carte `pb-leaflet-map` + `pb-geolocation` (même token Mapbox en dur, l. 38) | Squelette phase 1 | Non tel quel ; pattern fiche + carte détail |
| `static/templates/register-static-blocks.html` (29 l.) | Blocs conditionnels Jinks : injection `<script type="module" src=".../pb-leaflet-map.js">` + `registers-theme.css` selon `$context?features?register?enabled` | Plomberie Jinks pure | Non — spécifique au moteur de templates TP |
| `static/resources/scripts/map.js` (13 l.) | Lit le JSON inline `#geodata` et fait `pbEvents.emit("pb-update-map", "map", data)` après `pb-page-ready`/`pb-ready` | **Fonctionnel et déjà « statique-ready »** (zéro fetch — contrairement à ce que dit `migration-static.md` §4 qui le classe « à adapter » : la version actuelle lit le JSON inline, pas l'API) | **Oui sur le principe**, mais dépend de `pb-page`/`pb-leaflet-map`/`pbEvents` (pb-components). Pour la démo MaX sans pb-components : réécrire ~20 lignes en Leaflet natif (cf. §4) |

**Verdict `static/`** : rien n'est copiable byte-for-byte (tout est écrit dans le langage de templates Jinks ou dépend de pb-components), mais trois **patterns** sont directement transposables à MaX :
1. pagination statique en dossiers `people/<n>/index.html` ;
2. données carte **embarquées inline** dans la page (pas de fetch runtime) ;
3. blocs conditionnels « la carte ne se charge que sur les pages registres ».

---

## 2. Ce que disent les deux documents de migration

### 2.1 `docs/claude/migration-static.md` (517 l.) — le plan statique TP

Points directement utiles pour NOTRE démo :

- **Architecture cible validée** (§2-3) : HTML pré-rendu + **Pagefind** (full-text + facettes) + **DuckDB-WASM/Parquet** (données structurées registres/NER) + `timeline-index.json` léger. C'est la même architecture cible que la démo MaX — seule la brique de génération change (Jinks/eXist → MaX/BaseX-XSLT + wget).
- **Pagefind : choix justifié et paramétrage retenu** (§5.1) :
  - index chargé **par fragments** (pas de blob monolithique), facettes natives avec recomptes, multilingue natif ;
  - annotations prévues : `data-pagefind-body` sur `<main>`, `data-pagefind-meta="title"`/`"author"`, `data-pagefind-filter="genre"|"period"|"language"|"person"|"place"` **alignées sur les dimensions Lucene de `collection.xconf`** (genre, language, feature, form, period, place, person, date, author-type, text-lang, ner-type) ;
  - commande retenue : `npx pagefind --site output --output-subdir pagefind` en post-build ;
  - **seuil de vigilance** (§8 pt 7) : *« Pagefind index size : à surveiller après le premier build. Si > 20 Mo, envisager l'indexation par sous-corpus »* — c'est le seul « sharding » évoqué (Pagefind fragmente déjà nativement son index) ;
  - **normalisation pré-index** (§8 pt 8) : ligatures `ſ → s`, accents anciens, à appliquer dans la transformation (chez nous : dans les XSLT MaX ou un post-traitement du HTML crawlé) ;
  - **plan B documenté** : FlexSearch + tokenizer custom si la qualité sur le français du XVIIᵉ est insuffisante (benchmark suggéré : requêtes *peintvre*, *phisionomie*, *ſçauoir* sur 20 docs).
- **DuckDB/Parquet : PAS en place.** C'était le « chantier 3 » (5-7 j), jamais réalisé. Aucun fichier `.parquet`, aucun `duckdb-loader.js`, pas de dépendance `@duckdb/duckdb-wasm` dans `package.json`. Seul existe le **pseudo-code** du loader (§5.4) et la commande de conversion `duckdb -c "COPY (SELECT * FROM read_csv_auto(...)) TO '...parquet' (FORMAT PARQUET);"`. Le pipeline NER produit bien des JSON/CSV intermédiaires (`build/ner/`, non commités). **Pour la démo : DuckDB est optionnel, à considérer hors périmètre v1** ; Pagefind + JSON inline couvrent les besoins.
- **`facets.js` adapté ?** Non — l'adaptation est restée à l'état de **pseudo-code** (§5.2). Le doc confirme que `resources/scripts/facets.js` actuel est de la pure orchestration DOM (cascade checkboxes, sync combo-box) branchée sur `pb-custom-form`, et que l'adaptation consiste à remplacer la source de données par `search.filters` de Pagefind et `facets.submit()` par `runSearch()`. À écrire pour la démo (~80 lignes).
- **Inventaire de compatibilité** (§4) précieux tel quel : compatibles sans modif = `ner-slider.js`, tous les CSS (`grand-siecle.css`, `registers-theme.css`, palettes), i18n, `layout.js`, `header.js`, `toc.js`, `language.js`, `lang-toggle.js`, `browse.js`, `timeline.js` (⚠️ nuance §3 ci-dessous : plusieurs dépendent de `pbEvents`). À adapter = `entity-panel.js`, `registers.js`, `map.js`, recherche, facettes. Perdus (assumé) = annotation, NLP live, login.
- **Findings phase 1** (§12) — leçons transférables : le doc ALTO `LIV0326` (82 Mo, 765 pages, 25 315 zones) **doit être paginé en `view=page`** (le rendu monolithique timeout) → même contrainte pour la génération MaX ; identifiants TEI **stables** exigés pour les URL (§8 pt 3) ; polices locales (Junicode, Inter) plutôt que CDN (§8 pt 5).

### 2.2 `docs/claude/phase4-handoff.md` (178 l.) — l'état réel de l'index d'entités

Utile pour savoir **ce que la démo doit reproduire** et avec quelles données :

- Les 9 registres `data/registers/*.xml` (TEI standOff) portent tout le nécessaire **dans les données** — donc consommables par MaX sans eXist : `persName/placeName/...`, `idno[@type=wikidata|viaf|isni|gnd|bnf|lccn|geonames|aat]`, `occupation/@key`, `nationality/@key`, `country/@key`, `sex/@value`, `location/geo`, `@n` (nb mentions), `note[@type='sources']` (tokens docs `LIV0001|LIV0002a`), `note[@type='reconciliation-confidence']`.
- **Carte des lieux** (Phase 4-A, FAITE côté TP) : ~**431 lieux géolocalisés sur 2089**, endpoint `GET /api/places/all` → JSON `{latitude, longitude, label, id}`. Pour la démo : exporter ce même JSON **au build** (XSLT sur `data/registers/places.xml`, entrées avec `location/geo`). Tile-layers sans token validés : OSM `https://tile.openstreetmap.org/{z}/{x}/{y}.png` ou CARTO Positron `https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png` (celui de `templates/register-index.html:175`). Piège documenté : bug tuiles blanches Leaflet dans un panneau caché → forcer un `resize` à l'affichage (repris dans `registers-browse.js:328`).
- **Exports CSV/TEI/RIS** et **co-occurrences** : calculés serveur côté TP ; pour la démo, les précalculer au build (co-occurrence à partir de `note[@type='sources']` — l'algorithme est décrit : entités partageant le plus de docs-sources, en sautant `@n ≤ 1`).
- **Facettes en mémoire, pas Lucene** : décision TP de calculer toutes les facettes registres hors index — conforte l'approche Pagefind/JSON de la démo.
- **Timeline entités : stub assumé** (« registre dates non normalisé, pas de `@when` ») → ne pas promettre de timeline d'entités dans la démo.

---

## 3. Scripts client `resources/scripts/` — réutilisabilité pour la démo

Classement par dépendance réelle (vérifiée dans le code, pas seulement d'après `migration-static.md`) :

### 3.1 Réutilisables TELS QUELS (vanilla JS, zéro pb-components, zéro fetch)

| Fichier | Rôle | Notes |
|---|---|---|
| `resources/scripts/ner-slider.js` (45 l.) | Slider de confiance NER : lit `[data-cert]` (valeurs `high`/`mid`/`low` mappées 0.9/0.6/0.3 ou numériques), toggle la classe `entity-low-confidence` | **Copier tel quel.** Seule exigence : que les XSLT MaX posent `data-cert` sur les entités (le ODD TP le fait déjà — confirmé `migration-static.md` §5.3). L'écouteur `document.addEventListener('pb-update', ...)` est inoffensif sans pb-components (l'événement ne se produit jamais ; `DOMContentLoaded` suffit) |
| `resources/scripts/landing.js` (51 l.) | Animations landing : IntersectionObserver sur `.gs-reveal` + parallaxe `.gs-hero` | Copier tel quel si la démo reprend la landing |
| `resources/scripts/registers-entity.js` (77 l.) | Fiche d'autorité : lazy-load KWIC (« Cité dans ») via `/api/cited`, co-occurrences via `/api/cooccur` | Vanilla JS (la référence à `pb-page` ne sert qu'à lire l'attribut `endpoint`, avec fallback `''`), **mais fait 3 fetchs d'API eXist**. Réutilisable en pré-générant au build des fragments HTML statiques (`/api/cited/<id>/<doc>.html`) que le script fetch tel quel — seules les URL changent |

### 3.2 Réutilisables avec ADAPTATION LÉGÈRE (logique bonne, source de données à changer)

| Fichier | Dépendances | Adaptation démo |
|---|---|---|
| `resources/scripts/registers-browse.js` (345 l.) | `pbEvents` + `pb-leaflet-map` **uniquement pour le mode carte** ; sinon vanilla. Fetch `/api/{slug}/browse`, `/api/facet-source`, `/api/places/map` | **La pièce maîtresse.** Toute l'UX du navigateur à facettes (recherche debouncée 250 ms, checklists repliables cap à 6 + « + N autres », filtre intra-facette, tri des valeurs cochées en tête, reset, « Afficher plus » paginé, bascule Liste/Carte, export lié aux filtres) est réutilisable. Deux options : (a) brancher `fetchData()` sur l'API JS Pagefind (pour les pages entités indexées) ; (b) charger un `entities-<type>.json` généré au build et filtrer en mémoire (~11 k entrées max, trivial en JS). L'option (b) est recommandée : elle conserve les facettes exactes (occupation, nationalité, sexe, pays, confiance, mentions, années) sans dépendre du modèle « 1 page = 1 résultat » de Pagefind. Remplacer le bloc carte `pbEvents`/`pb-leaflet-map` par Leaflet natif (~30 l.) |
| `resources/scripts/facets.js` (54 l.) | `pb-custom-form`, `pb-combo-box`, `pbEvents` | Logique de cascade (décocher les `.nested .facet` sœurs) et de sync combo↔checkbox à transposer ; la réécriture Pagefind est spécifiée en pseudo-code dans `migration-static.md` §5.2 (rendu par `createElement`/`textContent`, jamais `innerHTML`) |
| `resources/scripts/lang-toggle.js` (103 l.) | Cherche `document.querySelector('pb-view')` comme conteneur + écoute `pb-update` | Changer 2 sélecteurs (`pb-view` → `main.tei-content` ou équivalent MaX) ; le reste (classes `lang-highlight-{code}`) est du DOM pur |
| `resources/scripts/toc.js` (43 l.) | `details:has(pb-link.active)`, événements `pb-collapse-open`, `pbEvents` | Le pattern `<details>`-TOC est bon ; remplacer `pb-link` par `<a>` + classe `active` posée au build (~15 l. modifiées) |
| `resources/scripts/layout.js` (~150 l.) | Quasi-vanilla (menus mobile/desktop, asides) ; touche `pb-page` et `pb-refresh` à 2 endroits (l. 64, 110) | Supprimer/neutraliser ces 2 références |
| `static/resources/scripts/map.js` (13 l.) | `pb-page`, `pb-leaflet-map`, `pbEvents` | Le **pattern** (GeoJSON inline `#geodata` → carte) est le bon ; réécrire en Leaflet natif (cf. §4) |

### 3.3 NON réutilisables (couplage fort pb-components/eXist — à écarter)

- `browse.js` (`pb-search-resubmit`, `pb-collection`, `pb-login`, `pb-upload`) — remplacé par Pagefind + pages browse pré-générées.
- `timeline.js` (52 l.) — uniquement du câblage `pb-timeline` ⇄ formulaire de facettes Lucene (`pb-timeline-date-changed` → `facets.submit()`). Sans backend `api/timeline`, sans objet.
- `language.js` (7 l.), `header.js` — plomberie `pbEvents`/i18n TP.
- `entity-panel.js` (~350 l.) — panneau d'entités par `pb-panel`/`pb-grid`, fetch `api/document-entities` ; trop couplé. Pour la démo, l'équivalent se pré-génère au build (aside d'entités par page).
- `gs-facs-detect.js`, `metadata-editor.js`, `editor.js`, `registers.js` (fetch `api/places/all` + `pb-split-list`), `resources/scripts/annotations/*` — features dynamiques abandonnées ou remplacées.

### 3.4 CSS — réutilisables tels quels

`resources/css/registers-theme.css` (**1301 l.**, tout le design system `.gs-*` de l'index d'entités : facettes, fiches, badges de confiance, KWIC, carte, co-occurrences), `grand-siecle.css`, `landing-page.css`, palettes `palette-*.css`, `timeline.css`, `toc.css`. Pur styling, aucune dépendance : **copier**. Vérifier seulement les sélecteurs ciblant des éléments custom (`pb-view`, `pb-page`) — marginaux.

---

## 4. Carte / timeline — libs existantes et récupérables

**Ce que TP utilise** : la carte passe partout par **`pb-leaflet-map`** (wrapper Web Component autour de **Leaflet** + markercluster, chargé en `extra-components` — cf. `templates/register-index.html:14` et `templates/place.html:27`), alimentée par événements `pbEvents.emit('pb-update-map', 'map', json)`. Il n'y a **aucun code Leaflet natif** dans le projet. La timeline passe par **`pb-timeline`** (composant TP) branché sur `api/timeline` — rien de récupérable côté lib, seulement l'idée du `timeline-index.json` de `migration-static.md` §3.

**Pour la démo statique** : prendre **Leaflet directement** (npm `leaflet` + `leaflet.markercluster`, en local, pas de CDN — cohérent avec le point RGPD de `TODO.md`). Récupérables :
- le **format de données** `[{latitude, longitude, label, id}]` de `/api/places/all` (à générer au build depuis `data/registers/places.xml`) ;
- le **pattern inline** de `static/templates/places.html:73` (`<script id="geodata" type="application/json">`) ;
- les **tile-layers sans token** : OSM (`phase4-handoff.md` §A) ou CARTO Positron (`templates/register-index.html:175`) ;
- les recettes UX de `registers-browse.js` `initMap()` : clic marqueur → `places/<id>`, bandeau « N sur 2089 géolocalisés », `setTimeout(() => window.dispatchEvent(new Event('resize')), 60)` à l'affichage du panneau.

Équivalent Leaflet natif du `map.js` statique (~15 lignes) :

```js
const data = JSON.parse(document.getElementById('geodata').textContent);
const map = L.map('map').setView([46.6, 2.2], 5);
L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            { maxZoom: 19, attribution: '© OpenStreetMap' }).addTo(map);
const cluster = L.markerClusterGroup();
data.forEach(p => cluster.addLayer(
    L.marker([p.latitude, p.longitude])
     .bindTooltip(p.label)
     .on('click', () => { location.href = 'places/' + p.id + '/'; })));
map.addLayer(cluster);
```

**Timeline** : ne rien reprendre (couplage Lucene). Si besoin v2 : petit histogramme des dates de publication depuis un `timeline-index.json` buildé (lib au choix : rien dans le projet à récupérer). Rappel `phase4-handoff.md` : la timeline **entités** est un stub assumé.

---

## 5. PAGEFIND — notes d'intégration (doc officielle, 2026-07)

⚠️ `pagefind` n'est **pas** dans `package.json` du projet TP (dependencies : `@teipublisher/pb-components`, `@jinntec/fore`, `@picocss/pico` ; devDependencies : cypress, ajv, fflate, glob). L'installation est entièrement à faire dans la démo : `npm install -D pagefind`.

### 5.1 Commande et fonctionnement

```bash
# après le crawl wget qui produit le site gelé dans site/
npx -y pagefind --site site            # écrit l'index dans site/pagefind/
npx -y pagefind --site site --serve    # idem + serveur de preview localhost:1414
```

Pagefind parcourt le HTML rendu, écrit un bundle fragmenté dans `<site>/pagefind/` (le « sharding » est natif : l'index est découpé en chunks chargés à la demande — aucun paramétrage requis ; seuil de vigilance projet : > 20 Mo total → indexer par sous-corpus, cf. §2.1). Config optionnelle via `pagefind.yml`/`pagefind.json` à la racine (mêmes options que la CLI : `site`, `glob`, `exclude_selectors`, `force_language`, `root_selector`…).

### 5.2 Attributs de pilotage dans le HTML (à poser dans les XSLT MaX)

- **`data-pagefind-body`** — restreint l'indexation à cet élément. **Dès qu'il existe quelque part sur le site, toute page qui ne le porte pas est exclue de l'index.** C'est le mécanisme d'exclusion global : le poser sur `<main>` des pages documents et entités exclut d'office menus, landing, mentions légales.
- **`data-pagefind-ignore`** — exclut un élément et ses enfants (valeur par défaut `index` : méta/filtres à l'intérieur restent captés ; `data-pagefind-ignore="all"` : exclusion totale, plus de détection de titre/image). À poser sur : apparat critique répété, numéros de page, nav interne, aside d'entités.
- **`data-pagefind-meta`** — trois syntaxes : contenu (`<h1 data-pagefind-meta="title">…</h1>`), attribut (`<meta data-pagefind-meta="author[content]" content="…">`), inline (`data-pagefind-meta="date:1667"`). Défauts automatiques : `title` = premier `<h1>`, `image` = premier `<img>` après le h1. Les méta sont cherchables et boostées (match dans `title` ≈ 5×).
- **`data-pagefind-filter`** — déclare une facette ; mêmes trois syntaxes : contenu (`<span data-pagefind-filter="author">Fréart de Chambray</span>`), attribut (`author[content]`), inline (`data-pagefind-filter="type:personne"`). Multi-valeurs OK (plusieurs éléments même clé). Combinables : `data-pagefind-filter="heading, tag[data-section], author:valeur"` (l'inline en dernier). Noms réservés interdits : `any`, `all`, `none`, `not`. Un filtre est capté **même à l'intérieur** d'un `data-pagefind-ignore`.
- **`data-pagefind-weight`** — pondération 0.0–10.0 (échelle quadratique : 2.0 ≈ 4× l'impact). Défauts : h1=7.0 … h6=2.0, texte=1.0. Usage démo : `data-pagefind-weight="0.5"` sur les zones OCR bruitées, `"2"` sur le texte modernisé.
- **`data-pagefind-index-attrs="title,alt"`** — indexe des attributs (utile pour les `alt` des fac-similés).

### 5.3 Français et multilingue

Pagefind lit le `lang` de `<html>` et construit **un index par langue** ; le **français est pleinement supporté** (stemming + traductions UI). Le corpus étant majoritairement `fr` avec passages latins/italiens : mettre `<html lang="fr">` partout et, si l'on veut UN seul index (recommandé pour la démo, évite qu'une page taguée `la` sorte de l'index `fr`), forcer `force_language: fr` dans `pagefind.yml`. Les graphies XVIIᵉ (ligatures `ſ`, accents anciens) ne sont pas stemmées : appliquer la **normalisation au build** (`ſ→s`, `&` typographiques) dans les XSLT MaX — recommandation reprise de `migration-static.md` §8 pt 8 ; plan B FlexSearch documenté ibid. §5.1.

### 5.4 UI

Deux options :
- **UI par défaut** — depuis Pagefind 1.5.0, la « Component UI » remplace l'ancienne `PagefindUI` : `<link href="/pagefind/pagefind-component-ui.css" rel="stylesheet"> <script src="/pagefind/pagefind-component-ui.js" type="module"></script>` puis `<pagefind-modal-trigger></pagefind-modal-trigger><pagefind-modal></pagefind-modal>` (assets générés dans `/pagefind/` au moment de l'indexation, rien à installer via npm). L'ancienne Default UI (`new PagefindUI({ element: "#search", showSubResults: true, showImages: false, translations: {...} })`, package `@pagefind/default-ui`) reste disponible et se skinne via variables CSS `--pagefind-ui-primary`, `--pagefind-ui-text`, `--pagefind-ui-background`, `--pagefind-ui-border`, `--pagefind-ui-font` — à aligner sur les variables de `resources/css/registers-theme.css`. Options utiles : `openFilters: ['Type', 'Document']`, `showEmptyFilters: false`.
- **API JS + UI maison** (recommandé pour garder l'UX `.gs-*` existante) :

```js
const pagefind = await import('/pagefind/pagefind.js');
pagefind.init();
const filters = await pagefind.filters();          // { type: {personne: 812, lieu: 431, …}, … }
const search  = await pagefind.search('peinture', {
    filters: { document: 'LIV0020', zone: ['MainZone'] }
});
for (const r of search.results.slice(0, 20)) {
    const d = await r.data();   // { url, excerpt, meta: {title,…}, sub_results, filters }
    // d.excerpt est encodé HTML par Pagefind (sûr en innerHTML, <mark> inclus)
}
// saisie au clavier : pagefind.debouncedSearch(q, {}, 300) — renvoie null si une
// recherche plus récente a été lancée
```

Le rendu des facettes réutilise la logique de `registers-browse.js` (`setupChecklist`, cap 6 + « + N autres ») branchée sur `search.filters` (recomptes après filtrage).

### 5.5 Exemples concrets pour la démo

**Page document** (sortie XSLT MaX d'une page de `LIV0020`) — filtres *document* et *type de zone* :

```html
<html lang="fr">
<body>
  <main data-pagefind-body
        data-pagefind-filter="document:LIV0020, zone:MainZone"
        data-pagefind-meta="document:LIV0020, page:42">
    <h1 data-pagefind-meta="title">Conférences de l'Académie — p. 42</h1>
    <span data-pagefind-meta="author">Félibien, André</span>
    <div class="tei-page">
      … texte transcrit …
      <span class="entity" data-cert="high"
            data-pagefind-filter="entité:personne">Poussin</span>
    </div>
    <section data-pagefind-filter="zone:MarginTextZone" data-pagefind-weight="0.5">
      … marginalia OCR bruitée …
    </section>
    <nav class="page-nav" data-pagefind-ignore="all">…</nav>
  </main>
</body>
</html>
```

Recherche filtrée : `pagefind.search(q, { filters: { document: 'LIV0020', zone: 'MainZone' } })`.
NB : les filtres étant à l'échelle de la **page indexée**, garder le découpage 1 page TEI (`tei:pb`) = 1 fichier HTML (imposé de toute façon par le finding LIV0326, §2.1) pour que le filtre `zone` reste discriminant.

**Page entité** (fiche d'autorité générée depuis `data/registers/persons.xml`) — filtre *type d'entité* :

```html
<main data-pagefind-body>
  <h1 data-pagefind-meta="title"
      data-pagefind-filter="type:personne">Nicolas Poussin</h1>
  <dl>
    <dt>Confiance</dt><dd data-pagefind-filter="confiance">high</dd>
    <dt>Occupation</dt><dd data-pagefind-filter="occupation">peintre</dd>
    <dt>Wikidata</dt><dd data-pagefind-meta="wikidata">Q41264</dd>
  </dl>
  <section class="gs-kwic" data-pagefind-ignore>
    … passages cités (déjà indexés sur les pages documents — ne pas doublonner) …
  </section>
</main>
```

Le sélecteur « Personnes / Lieux / Œuvres… » de la recherche globale devient `filters: { type: ['personne'] }` ; les compteurs viennent de `pagefind.filters()`.

---

## 6. Recommandation finale — fichiers à copier (source → destination démo)

Racine démo supposée : `/home/rayondemiel/Projet_UNIL/grand-siecle-max-statique/`. Source : `/home/rayondemiel/Projet_UNIL/grand-siecle-TeiAPP/`.

### À copier tels quels
| Source | Destination | Modif |
|---|---|---|
| `resources/scripts/ner-slider.js` | `assets/js/ner-slider.js` | aucune |
| `resources/scripts/landing.js` | `assets/js/landing.js` | aucune |
| `resources/css/registers-theme.css` | `assets/css/registers-theme.css` | purge éventuelle des sélecteurs `pb-*` |
| `resources/css/grand-siecle.css`, `landing-page.css`, `toc.css`, `palette-*.css` | `assets/css/` | aucune |
| `resources/i18n/**` (fr/en/de/pl) | `assets/i18n/` | seulement si i18n client conservée en v1 |
| `resources/fonts/**` (Junicode, Inter) | `assets/fonts/` | aucune (pas de CDN) |
| `data/registers/*.xml` (9 registres) + `data/LIV*_reconciled.tei.xml` | `data/` (entrée MaX/BaseX) | aucune — ce sont les sources |

### À copier puis adapter (effort ~1-2 j cumulés)
| Source | Destination | Adaptation |
|---|---|---|
| `resources/scripts/registers-browse.js` | `assets/js/registers-browse.js` | source de données → JSON buildé ou API Pagefind ; bloc carte → Leaflet natif |
| `resources/scripts/registers-entity.js` | `assets/js/registers-entity.js` | URLs `/api/cited`, `/api/cooccur` → fragments HTML pré-générés |
| `resources/scripts/lang-toggle.js` | `assets/js/lang-toggle.js` | sélecteur `pb-view` → conteneur MaX |
| `resources/scripts/toc.js` | `assets/js/toc.js` | `pb-link` → `<a class="active">` |
| `resources/scripts/layout.js` | `assets/js/layout.js` | retirer les 2 refs `pb-page`/`pb-refresh` |
| `static/resources/scripts/map.js` | `assets/js/map.js` | réécriture Leaflet natif (§4) en gardant le pattern `#geodata` inline |
| `templates/register-index.html` (markup sidebar facettes `.gs-*`, l. 57-183) | gabarit XSLT « index d'entités » | transposer le markup (hors `pb-i18n`) — c'est la référence visuelle/fonctionnelle |

### À créer (rien d'existant à copier)
- `assets/js/search.js` — UI Pagefind maison (API §5.4-5.5), en s'inspirant du pseudo-code `facets.js`→Pagefind de `migration-static.md` §5.2 ;
- `pagefind.yml` (`force_language: fr`, exclusions) + étape de build `npx -y pagefind --site site` après le crawl wget ;
- export build `places-all.json` + `entities-<type>.json` depuis les registres (XSLT ou XQuery BaseX) ;
- vendoring `leaflet` + `leaflet.markercluster` (npm, copie locale).

### À NE PAS reprendre
`browse.js`, `timeline.js`, `language.js`, `header.js`, `entity-panel.js`, `registers.js`, `gs-facs-detect.js`, `metadata-editor.js`, `editor.js`, `resources/scripts/annotations/*`, les 5 templates Jinks de `static/templates/` (syntaxe non transposable), tout token Mapbox (`static/templates/places.html:59`, `place.html:38`), et le CDN jsDelivr pb-components (risque RGPD/disponibilité déjà tracé dans `TODO.md`).
