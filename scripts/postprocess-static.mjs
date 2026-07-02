#!/usr/bin/env node
/**
 * Post-traitement du site gelé (après wget, avant Pagefind) :
 *  1. data-pagefind-body sur <main> + filtres (Type, Document) par famille de pages ;
 *  2. remplacement de la page de recherche dynamique MaX par l'UI Pagefind ;
 *  3. réécriture des liens Mirador (route dynamique morte au gel) vers le
 *     visualiseur Gallica correspondant ;
 *  4. pages index.html de redirection (racine du site et racine d'édition).
 */
import { readdirSync, readFileSync, writeFileSync, statSync } from 'node:fs';
import { dirname, join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const SITE = join(ROOT, 'static-site', 'grand-siecle');

const TYPE_FR = {
  person: 'Personnes', place: 'Lieux', organization: 'Organisations',
  work: 'Œuvres', event: 'Événements', artwork: 'Objets & œuvres d’art',
  material: 'Matériaux', technique: 'Techniques', date: 'Dates',
};

function* walk(dir) {
  for (const entry of readdirSync(dir)) {
    const p = join(dir, entry);
    const st = statSync(p, { throwIfNoEntry: false }); // symlinks morts possibles
    if (!st) continue;
    if (st.isDirectory()) yield* walk(p);
    else if (p.endsWith('.html')) yield p;
  }
}

function decodeEntities(s) {
  return s.replace(/&amp;/g, '&').replace(/&#38;/g, '&');
}

/** mirador?link=<manifest-encodé>[&canvasIndex=N] → visualiseur Gallica */
function rewriteMirador(html) {
  return html.replace(
    /href="[^"]*\/mirador\?link=([^"&]+)(?:&(?:amp;)?canvasIndex=(\d+))?"/g,
    (m, encManifest, canvas) => {
      const manifest = decodeURIComponent(decodeEntities(encManifest));
      const ark = (manifest.match(/ark:\/12148\/([a-z0-9]+)/i) || [])[1];
      if (!ark) return m;
      const url = canvas
        ? `https://gallica.bnf.fr/ark:/12148/${ark}/f${canvas}.item`
        : `https://gallica.bnf.fr/ark:/12148/${ark}`;
      return `href="${url}"`;
    });
}

const SEARCH_MAIN = `
  <div class="gs-index-page">
    <p class="gs-section-kicker">Recherche</p>
    <h1 class="gs-section-title">Rechercher dans l’édition</h1>
    <p class="gs-section-intro">Recherche plein texte statique (Pagefind) : transcriptions,
      fiches de documents et notices d’entités. La recherche dynamique BaseX du site
      d’origine a été remplacée au gel.</p>
    <link href="pagefind/pagefind-ui.css" rel="stylesheet"/>
    <div id="gs-search"></div>
    <script src="pagefind/pagefind-ui.js"></script>
    <script src="ui/js/search-page.js"></script>
  </div>
`;

let counts = { body: 0, filters: 0, mirador: 0, search: 0 };

for (const file of walk(SITE)) {
  let html = readFileSync(file, 'utf-8');
  const before = html;
  const rel = relative(SITE, file).split(sep).join('/');

  // 1. data-pagefind-body sur le <main> principal
  html = html.replace(/<main (?![^>]*data-pagefind-body)/, '<main data-pagefind-body ');

  // 2. filtres par famille de pages
  let filters = '';
  const mDoc = rel.match(/^(LIV[0-9]+[ab]?)\.xml\//);
  const mEnt = rel.match(/^registres\/([a-z]+)\//);
  if (mDoc) {
    filters = `<span hidden data-pagefind-filter="Type">Texte</span>` +
      `<span hidden data-pagefind-filter="Document">${mDoc[1]}</span>`;
  } else if (mEnt && TYPE_FR[mEnt[1]]) {
    filters = `<span hidden data-pagefind-filter="Type">Entité — ${TYPE_FR[mEnt[1]]}</span>`;
  } else if (rel.startsWith('index/')) {
    filters = `<span hidden data-pagefind-filter="Type">Index</span>`;
  } else {
    filters = `<span hidden data-pagefind-filter="Type">Pages du site</span>`;
  }
  if (!html.includes('data-pagefind-filter')) {
    html = html.replace(/(<main[^>]*>)/, `$1${filters}`);
  }

  // 3. recherche : remplacer le contenu du <main> par l'UI Pagefind
  if (rel === 'search.html') {
    html = html.replace(/(<main[^>]*>)[\s\S]*?(<\/main>)/, `$1${SEARCH_MAIN}$2`);
    counts.search++;
  }

  // 4. Mirador → Gallica
  const rewritten = rewriteMirador(html);
  if (rewritten !== html) { counts.mirador++; html = rewritten; }

  if (html !== before) {
    writeFileSync(file, html);
    if (/data-pagefind-body/.test(html)) counts.body++;
    counts.filters++;
  }
}

// 5. initialisation Pagefind (fichier séparé : aucune accolade dans les gabarits MaX,
//    mais ici on est en statique pur — séparé par propreté/CSP)
writeFileSync(join(SITE, 'ui/js/search-page.js'), `/* UI Pagefind (site gelé) */
window.addEventListener('DOMContentLoaded', function () {
  if (window.PagefindUI) {
    new window.PagefindUI({
      element: '#gs-search',
      pageSize: 10,
      showSubResults: true,
      translations: { placeholder: 'Rechercher…', zero_results: 'Aucun résultat pour « [SEARCH_TERM] »' }
    });
  }
});
`);

// 6. redirections
const redirect = (target) => `<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8"/>
<meta http-equiv="refresh" content="0; url=${target}"/>
<link rel="canonical" href="${target}"/><title>Grand Siècle</title></head>
<body><p><a href="${target}">Grand Siècle — accueil</a></p></body></html>
`;
writeFileSync(join(SITE, 'index.html'), redirect('accueil.html'));
writeFileSync(join(ROOT, 'static-site', 'index.html'), redirect('grand-siecle/accueil.html'));

console.log(JSON.stringify(counts));
