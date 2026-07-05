#!/usr/bin/env node
/**
 * Post-traitement du site gelé (après wget, avant Pagefind) :
 *  1. filet de sécurité : <!DOCTYPE html> si absent (search.html gelée sort
 *     en mode quirks sinon) ;
 *  2. data-pagefind-body sur <main> + filtres (Type, Document) par famille de
 *     pages — sauf search.html (la page de recherche ne doit pas s'auto-indexer) ;
 *  3. remplacement de la page de recherche dynamique MaX par l'UI Pagefind
 *     (gestion de ?q=, showImages:false, i18n complète — cf. section 5) ;
 *  4. réécriture des liens Mirador (route dynamique morte au gel) vers le
 *     visualiseur Gallica correspondant, libellé compris (« ouvrir dans
 *     Mirador » → « voir sur Gallica ») ;
 *  5. data-pagefind-ignore sur les badges de confiance (class="gs-conf…")
 *     pour qu'ils ne polluent pas les titres de résultats ;
 *  6. suppression du bouton de langue fantôme MAX.setLanguage('') ;
 *  7. liens internes racine-serveur (/grand-siecle/… — footer) → relatifs
 *     selon la profondeur de la page ;
 *  8. meta description par famille de pages (elles étaient toutes identiques) ;
 *  9. <title> d'about.html (« Grand Siècle » → « À propos | Grand Siècle ») ;
 * 10. pages index.html : copie canonique d'accueil.html à la racine d'édition,
 *     stub meta-refresh à la racine du site seulement.
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

/* type de registre → libellé singulier (meta description des fiches) */
const TYPE_SING_FR = {
  person: 'personne', place: 'lieu', organization: 'organisation',
  work: 'œuvre', event: 'événement', artwork: 'objet ou œuvre d’art',
  material: 'matériau', technique: 'technique', date: 'date',
};

/* fichier d'index → libellé pluriel accordé (meta description des index) */
const INDEX_PLUR_FR = {
  personnes: 'personnes citées', lieux: 'lieux cités',
  organisations: 'organisations citées', oeuvres: 'œuvres citées',
  evenements: 'événements cités', objets: 'objets et œuvres d’art cités',
  materiaux: 'matériaux cités', techniques: 'techniques citées',
  dates: 'dates citées',
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

/** meta description propre à la famille de pages (null : on ne touche pas) */
function metaDescriptionFor(rel) {
  const mPage = rel.match(/^(LIV[0-9]+[ab]?)\.xml\/\1-page-([0-9]+)\.html$/);
  if (mPage) return `${mPage[1]} — page ${mPage[2]}. Transcription et fac-similé.`;
  const mReg = rel.match(/^registres\/([a-z]+)\//);
  if (mReg) {
    const t = TYPE_SING_FR[mReg[1]];
    return t ? `Fiche d’autorité — ${t}.` : 'Fiche d’autorité.';
  }
  const mIdx = rel.match(/^index\/([a-z]+)\.html$/);
  if (mIdx && INDEX_PLUR_FR[mIdx[1]]) {
    return `Index alphabétique des ${INDEX_PLUR_FR[mIdx[1]]} dans le corpus.`;
  }
  if (rel === 'accueil.html' || rel === 'index.html') {
    return 'Cinq discours français sur la peinture au XVIIe siècle : transcriptions, entités, carte et chronologie.';
  }
  if (rel === 'sommaire.html' || rel.startsWith('sommaire/')) {
    return 'Les cinq imprimés parisiens (1630-1662) de la démonstration, avec pages et langues.';
  }
  if (rel === 'search.html') return 'Recherche plein texte dans les transcriptions, les fiches de documents et les notices d’entités.';
  if (rel === 'about.html') return 'La démonstration Grand Siècle : sources TEI, publication MaX, registres d’autorité et gel statique.';
  if (rel === 'carte.html') return 'Les lieux cités dans le corpus, géolocalisés sur une carte interactive.';
  if (rel === 'chronologie.html') return 'Frise chronologique des personnes et des événements cités dans le corpus.';
  if (rel === 'entites.html') return 'Neuf registres d’entités — personnes, lieux, œuvres… — issus de la NER, réconciliés avec Wikidata.';
  return null;
}

/** remplace la meta description (et og:description) ou l'injecte après <title> */
function setMetaDescription(html, desc) {
  const escaped = desc.replace(/&/g, '&amp;').replace(/"/g, '&quot;');
  if (/<meta name="description"/.test(html)) {
    html = html.replace(/(<meta name="description" content=")[^"]*(")/,
      (m, a, b) => a + escaped + b);
  } else {
    html = html.replace(/<\/title>/,
      () => `</title><meta name="description" content="${escaped}"/>`);
  }
  html = html.replace(/(<meta property="og:description" content=")[^"]*(")/,
    (m, a, b) => a + escaped + b);
  return html;
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

let counts = {
  doctype: 0, body: 0, filters: 0, mirador: 0, miradorLabel: 0,
  search: 0, badges: 0, langBtn: 0, rootLinks: 0, meta: 0,
};

for (const file of walk(SITE)) {
  let html = readFileSync(file, 'utf-8');
  const before = html;
  const rel = relative(SITE, file).split(sep).join('/');

  // 1. filet de sécurité : DOCTYPE (search.html gelée n'en a pas → mode quirks)
  if (!/^\s*<!doctype/i.test(html)) {
    html = '<!DOCTYPE html>\n' + html;
    counts.doctype++;
  }

  // 2. data-pagefind-body + filtres — pas sur search.html (auto-indexation)
  if (rel !== 'search.html') {
    html = html.replace(/<main (?![^>]*data-pagefind-body)/, '<main data-pagefind-body ');

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
  }

  // 3. recherche : remplacer le contenu du <main> par l'UI Pagefind
  if (rel === 'search.html') {
    html = html.replace(/(<main[^>]*>)[\s\S]*?(<\/main>)/, `$1${SEARCH_MAIN}$2`);
    counts.search++;
  }

  // 4. Mirador → Gallica (href, puis libellé : le lien ne doit plus mentir)
  const rewritten = rewriteMirador(html);
  if (rewritten !== html) { counts.mirador++; html = rewritten; }
  const relabeled = html
    .replace(/>ouvrir dans Mirador</g, '>voir sur Gallica<')
    .replace(/>Mirador</g, '>voir sur Gallica<');
  if (relabeled !== html) { counts.miradorLabel++; html = relabeled; }

  // 5. badges de confiance hors index Pagefind (sinon « toile ◆◆◆réconciliation… »
  //    dans les titres de résultats)
  const badged = html.replace(/<(\w+) class="gs-conf/g,
    '<$1 data-pagefind-ignore class="gs-conf');
  if (badged !== html) { counts.badges++; html = badged; }

  // 6. bouton de langue fantôme du chrome MaX (édition monolingue)
  const unLang = html.replace(
    /<li class="max-lang"><a role="button" onclick="MAX\.setLanguage\(''\)"><\/a><\/li>/g, '');
  if (unLang !== html) { counts.langBtn++; html = unLang; }

  // 7. liens internes racine-serveur (footer) → relatifs selon la profondeur
  const depth = rel.split('/').length - 1;
  const prefix = '../'.repeat(depth);
  const rerooted = html.replace(/(href|src)="\/grand-siecle\//g, `$1="${prefix}`);
  if (rerooted !== html) { counts.rootLinks++; html = rerooted; }

  // 8. meta description par famille de pages
  const desc = metaDescriptionFor(rel);
  if (desc) {
    const described = setMetaDescription(html, desc);
    if (described !== html) { counts.meta++; html = described; }
  }

  // 9. <title> d'about.html (construit hors périmètre côté dynamique)
  if (rel === 'about.html') {
    html = html
      .replace(/<title>Grand Siècle<\/title>/, '<title>À propos | Grand Siècle</title>')
      .replace(/(<meta name="DC.title" content=")Grand Siècle(")/, '$1À propos | Grand Siècle$2')
      .replace(/(<meta property="og:title" content=")Grand Siècle(")/, '$1À propos | Grand Siècle$2');
  }

  if (html !== before) {
    writeFileSync(file, html);
    if (/data-pagefind-body/.test(html)) counts.body++;
    counts.filters++;
  }
}

// 5bis. initialisation Pagefind (fichier séparé : aucune accolade dans les gabarits
//       MaX, mais ici on est en statique pur — séparé par propreté/CSP)
writeFileSync(join(SITE, 'ui/js/search-page.js'), `/* UI Pagefind (site gelé) */
window.addEventListener('DOMContentLoaded', function () {
  if (!window.PagefindUI) return;
  var ui = new window.PagefindUI({
    element: '#gs-search',
    pageSize: 10,
    showSubResults: true,
    showImages: false,
    translations: {
      placeholder: 'Rechercher…',
      clear_search: 'Effacer',
      load_more: 'Plus de résultats',
      many_results: '[COUNT] résultats pour « [SEARCH_TERM] »',
      one_result: '1 résultat pour « [SEARCH_TERM] »',
      zero_results: 'Aucun résultat pour « [SEARCH_TERM] »',
      searching: 'Recherche…',
      alt_search: 'Aucun résultat pour « [SEARCH_TERM] ». Résultats pour « [DIFFERENT_TERM] » à la place',
      filters_label: 'Filtres'
    }
  });

  // ?q= : lancer la recherche transmise dans l'URL
  var q = new URLSearchParams(location.search).get('q');
  if (q) ui.triggerSearch(q);

  // et réécrire l'URL au fil de la saisie (debounce), pour des liens partageables
  var timer = null;
  document.addEventListener('input', function (e) {
    var input = e.target;
    if (!input || !input.closest || !input.closest('#gs-search')) return;
    var value = input.value;
    clearTimeout(timer);
    timer = setTimeout(function () {
      var url = new URL(location.href);
      if (value) url.searchParams.set('q', value);
      else url.searchParams.delete('q');
      history.replaceState(null, '', url);
    }, 250);
  });
});
`);

// 6. pages index.html
//    Racine d'édition : copie du contenu d'accueil.html (post-traité) avec
//    canonical, sans data-pagefind-body (pas de doublon dans l'index Pagefind).
const accueil = readFileSync(join(SITE, 'accueil.html'), 'utf-8');
const editionIndex = accueil
  .replace(/<head>/, '<head><link rel="canonical" href="accueil.html"/>')
  .replace(/<main data-pagefind-body /, '<main ');
writeFileSync(join(SITE, 'index.html'), editionIndex);

//    Racine du site : simple stub meta-refresh.
writeFileSync(join(ROOT, 'static-site', 'index.html'), `<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8"/>
<meta http-equiv="refresh" content="0; url=grand-siecle/accueil.html"/>
<link rel="canonical" href="grand-siecle/accueil.html"/><title>Grand Siècle</title></head>
<body><p><a href="grand-siecle/accueil.html">Grand Siècle — accueil</a></p></body></html>
`);

console.log(JSON.stringify(counts));
