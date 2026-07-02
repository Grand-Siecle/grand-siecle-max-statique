#!/usr/bin/env node
/**
 * prepare-tei.mjs — Mission C (§3 de docs/specs/C-tei-rendu.md)
 *
 * Prépare les 5 TEI « SegmOnto depuis ALTO » pour MaX/BaseX :
 *  1. extrait le mapping fac-similé (sourceDoc/surface) → ui/js/data/facs/{ID}.json
 *  2. extrait les métadonnées teiHeader (§1.2)          → ui/js/data/corpus.json
 *  3. chunke le body en <div xml:id="{ID}-page-{n}" type="page" n="{n}"
 *     corresp="#{facsId}" facs="{URL IIIF full/,1200/0/native.jpg}">  (contrat :
 *     xml:id PRÉFIXÉ par l'ID du doc — résolution de fragment MaX globale à la base)
 *  4. supprime sourceDoc (−68 %)                        → data/tei/{ID}.xml
 *
 * Contrôles (§3.2.7) : 888 pages au total, 0 pb restant, 0 sourceDoc, @facs non
 * vides, XML re-parsable, unicité GLOBALE des xml:id de pages, comptage des
 * xml:id s_/w_ dupliqués entre docs (avertissement seulement).
 *
 * Usage : node prepare-tei.mjs [--src <dir-des-TEI-sources>]
 */

import { DOMParser, XMLSerializer } from '@xmldom/xmldom';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(__dirname, '..');

const TEI_NS = 'http://www.tei-c.org/ns/1.0';
const XML_NS = 'http://www.w3.org/XML/1998/namespace';

const DOC_IDS = ['LIV0001', 'LIV0010', 'LIV0017', 'LIV0019', 'LIV0020'];

// --- chemins -----------------------------------------------------------------
const argv = process.argv.slice(2);
let srcDir = '/home/rayondemiel/Projet_UNIL/grand-siecle-TeiAPP/data';
const iSrc = argv.indexOf('--src');
if (iSrc !== -1) srcDir = path.resolve(argv[iSrc + 1]);

const EDITION = path.join(REPO, 'max/editions/grand-siecle');
const OUT_TEI = path.join(EDITION, 'data/tei');
const OUT_DATA = path.join(EDITION, 'ui/js/data');
const OUT_FACS = path.join(OUT_DATA, 'facs');
for (const d of [OUT_TEI, OUT_FACS]) fs.mkdirSync(d, { recursive: true });

// --- overrides (§1.1 pièges) --------------------------------------------------
const AUTHOR_NAME_OVERRIDES = { LIV0001: 'Judocus Andries' };
const FILTERED_STRINGS = new Set(['Information not available.']);
const DEFAULT_LAYER = (id) => (id === 'LIV0010' ? 'orig' : 'reg');

// --- helpers DOM ---------------------------------------------------------------
const isEl = (n) => n.nodeType === 1;
const kids = (el, name) =>
  Array.from(el.childNodes).filter((n) => isEl(n) && n.localName === name);
const kid = (el, name) => kids(el, name)[0] ?? null;
const walk = (el, ...names) => {
  let cur = el;
  for (const name of names) {
    if (!cur) return null;
    cur = kid(cur, name);
  }
  return cur;
};
const attr = (el, name) => (el && el.getAttribute(name)) || null;
const txt = (el) => {
  if (!el) return null;
  const t = el.textContent.replace(/\s+/g, ' ').trim();
  if (!t || FILTERED_STRINGS.has(t)) return null;
  return t;
};

let hadError = false;
const fail = (msg) => {
  console.error(`ERREUR: ${msg}`);
  hadError = true;
};
const assertOrDie = (cond, msg) => {
  if (!cond) {
    console.error(`ERREUR FATALE: ${msg}`);
    process.exit(1);
  }
};

// --- extraction métadonnées (§1.2) ---------------------------------------------
function extractPerson(personEl) {
  const p = {
    id: personEl.getAttributeNS(XML_NS, 'id') || attr(personEl, 'xml:id'),
    name: null,
    forename: null,
    surname: null,
    birth: null,
    death: null,
    occupation: null,
    isni: null,
    ark: null,
  };
  const pn = kid(personEl, 'persName');
  if (pn) {
    p.forename = txt(kid(pn, 'forename'));
    p.surname = txt(kid(pn, 'surname'));
    p.name = [p.forename, p.surname].filter(Boolean).join(' ') || txt(pn);
  }
  const birth = kid(personEl, 'birth');
  const death = kid(personEl, 'death');
  if (birth) p.birth = attr(birth, 'when') || txt(kid(birth, 'date'));
  if (death) p.death = attr(death, 'when') || txt(kid(death, 'date'));
  p.occupation = txt(kid(personEl, 'occupation'));
  for (const idno of kids(personEl, 'idno')) {
    const t = attr(idno, 'type');
    if (t === 'isni') p.isni = txt(idno);
    if (t === 'ark') p.ark = txt(idno);
  }
  return p;
}

function extractMetadata(doc, ID) {
  const tei = doc.documentElement;
  const header = kid(tei, 'teiHeader');
  assertOrDie(header, `${ID}: teiHeader introuvable`);
  const fileDesc = kid(header, 'fileDesc');
  const titleStmt = kid(fileDesc, 'titleStmt');
  const sourceDesc = kid(fileDesc, 'sourceDesc');
  const profileDesc = kid(header, 'profileDesc');

  const meta = { id: ID };
  meta.title = txt(kid(titleStmt, 'title'));

  // auteur
  const authorEl = kid(titleStmt, 'author');
  const author = { name: null, ref: null, birth: null, death: null, ark: null, isni: null };
  if (authorEl) {
    author.ref = (attr(authorEl, 'ref') || '').replace(/^#/, '') || null;
    const pn = kid(authorEl, 'persName');
    if (pn) {
      const fore = txt(kid(pn, 'forename'));
      const sur = txt(kid(pn, 'surname'));
      author.name = [fore, sur].filter(Boolean).join(' ') || txt(pn);
      for (const ptr of kids(pn, 'ptr')) {
        const t = attr(ptr, 'type');
        if (t === 'ark') author.ark = attr(ptr, 'target');
        if (t === 'isni') author.isni = attr(ptr, 'target');
      }
    }
    const birth = kid(authorEl, 'birth');
    const death = kid(authorEl, 'death');
    if (birth)
      author.birth = { when: attr(birth, 'when'), place: txt(kid(birth, 'placeName')) };
    if (death)
      author.death = { when: attr(death, 'when'), place: txt(kid(death, 'placeName')) };
  }
  if (AUTHOR_NAME_OVERRIDES[ID]) {
    author.rawName = author.name;
    author.name = AUTHOR_NAME_OVERRIDES[ID];
  }
  meta.author = author;

  // sourceDesc/bibl
  const bibl = kid(sourceDesc, 'bibl');
  meta.pubDate = bibl ? attr(kid(bibl, 'date'), 'when') || txt(kid(bibl, 'date')) : null;
  meta.pubPlace = bibl ? txt(kid(bibl, 'pubPlace')) : null;
  meta.printers = [];
  if (bibl) {
    for (const rs of kids(bibl, 'respStmt')) {
      const pn = kid(rs, 'persName');
      const fore = pn ? txt(kid(pn, 'forename')) : null;
      const sur = pn ? txt(kid(pn, 'surname')) : null;
      meta.printers.push({
        role: txt(kid(rs, 'resp')),
        ref: pn ? (attr(pn, 'ref') || '').replace(/^#/, '') || null : null,
        name: [fore, sur].filter(Boolean).join(' ') || (pn ? txt(pn) : null),
      });
    }
  }

  // msIdentifier
  const msId = walk(sourceDesc, 'msDesc', 'msIdentifier');
  meta.shelfmark = null;
  meta.arkNotice = null;
  meta.iiifManifest = null;
  let internalId = null;
  if (msId) {
    for (const idno of kids(msId, 'idno')) {
      const t = attr(idno, 'type');
      if (!t) meta.shelfmark = txt(idno);
      else if (t === 'ark') meta.arkNotice = txt(idno);
      else if (t === 'iiif') meta.iiifManifest = txt(idno);
    }
    const alt = kid(msId, 'altIdentifier');
    if (alt) {
      for (const idno of kids(alt, 'idno')) {
        if (attr(idno, 'type') === 'internal') internalId = txt(idno);
      }
    }
  }
  if (internalId && internalId !== ID)
    fail(`${ID}: idno[@type='internal'] = ${internalId} ≠ ${ID}`);

  // ark images (POINT CRUCIAL §1.2 : depuis idno iiif, PAS l'ark notice)
  meta.arkImages = null;
  if (meta.iiifManifest && meta.iiifManifest.includes('ark:/12148/')) {
    meta.arkImages = meta.iiifManifest
      .split('ark:/12148/')[1]
      .split('/manifest.json')[0]
      .replace(/\/$/, '');
  }
  if (!meta.arkImages) fail(`${ID}: ark images introuvable dans idno[@type='iiif']`);

  // extent
  const measure = walk(fileDesc, 'extent', 'measure');
  meta.nbImages =
    measure && attr(measure, 'unit') === 'images' ? Number(attr(measure, 'n')) : null;

  // langues
  meta.languages = [];
  const langUsage = profileDesc ? kid(profileDesc, 'langUsage') : null;
  if (langUsage) {
    for (const lang of kids(langUsage, 'language')) {
      meta.languages.push({ ident: attr(lang, 'ident'), usage: Number(attr(lang, 'usage')) });
    }
  }

  // personnes du header (auteur + libraires, notices BnF)
  meta.persons = [];
  const listPerson = profileDesc ? walk(profileDesc, 'particDesc', 'listPerson') : null;
  if (listPerson) for (const p of kids(listPerson, 'person')) meta.persons.push(extractPerson(p));

  meta.defaultLayer = DEFAULT_LAYER(ID);
  return meta;
}

// --- extraction fac-similés (§3.2.2) --------------------------------------------
function extractFacs(doc, ID, arkImages) {
  const tei = doc.documentElement;
  const sourceDoc = kid(tei, 'sourceDoc');
  assertOrDie(sourceDoc, `${ID}: sourceDoc introuvable`);
  const surfaces = [];
  const byId = new Map();
  for (const surface of kids(sourceDoc, 'surface')) {
    const id = surface.getAttributeNS(XML_NS, 'id') || attr(surface, 'xml:id');
    const graphic = kid(surface, 'graphic');
    const url = graphic ? attr(graphic, 'url') : null;
    if (!id) fail(`${ID}: surface sans xml:id`);
    if (!url) fail(`${ID}: surface ${id} sans graphic/@url`);
    if (url) {
      if (!url.startsWith('https://gallica.bnf.fr/iiif/ark:/12148/'))
        fail(`${ID}: URL IIIF inattendue: ${url}`);
      if (url.includes('_reconciled')) fail(`${ID}: URL cassée (@source ?) : ${url}`);
      if (!url.includes('full/full/0/native')) fail(`${ID}: motif full/full absent: ${url}`);
      if (arkImages && !url.includes(`/${arkImages}/`))
        fail(`${ID}: URL surface ${id} n'utilise pas l'ark images ${arkImages}: ${url}`);
    }
    // motif fN-M de LIV0010 : M = numéro de page imprimé ('np' = non paginée)
    let printed = null;
    const m = id && id.match(/^f\d+-(.+)$/);
    if (m && m[1] !== 'np') printed = m[1];
    const entry = {
      id,
      n: attr(surface, 'n') !== null ? Number(attr(surface, 'n')) : null,
      printed,
      url,
      view: url ? url.replace('full/full/0/native', 'full/,1200/0/native') : null,
      thumb: url ? url.replace('full/full/0/native', 'full/,300/0/native') : null,
      w: Number(attr(surface, 'lrx')),
      h: Number(attr(surface, 'lry')),
      pb: false, // repassé à true au chunking si un pb le référence
    };
    surfaces.push(entry);
    byId.set(id, entry);
  }
  return { surfaces, byId };
}

// --- chunking du body (§3.2.4) ---------------------------------------------------
function chunkBody(doc, ID, facsById) {
  const tei = doc.documentElement;
  const body = walk(tei, 'text', 'body');
  assertOrDie(body, `${ID}: text/body introuvable`);
  const divs = kids(body, 'div');
  assertOrDie(divs.length === 1, `${ID}: body doit avoir un div unique (trouvé ${divs.length})`);
  const div = divs[0];

  const pages = []; // { el, n, facsId, printed }
  let pageDiv = null;
  let pageSeq = 0;
  let pbCount = 0;
  const moved = { ab: 0, fw: 0, note: 0 };

  const makePage = (facsId, facsUrl) => {
    pageSeq += 1;
    const el = doc.createElementNS(TEI_NS, 'div');
    el.setAttributeNS(XML_NS, 'xml:id', `${ID}-page-${pageSeq}`); // CONTRAT : préfixe doc
    el.setAttribute('type', 'page');
    el.setAttribute('n', String(pageSeq));
    if (facsId) el.setAttribute('corresp', `#${facsId}`);
    if (facsUrl) el.setAttribute('facs', facsUrl);
    pages.push({ el, n: pageSeq, facsId });
    return el;
  };

  for (const node of Array.from(div.childNodes)) {
    if (!isEl(node)) {
      if (node.nodeType === 3 && node.data.trim() !== '')
        fail(`${ID}: texte inattendu sous body/div: "${node.data.trim().slice(0, 40)}"`);
      continue; // blancs d'indentation : abandonnés
    }
    const name = node.localName;
    if (name === 'pb') {
      assertOrDie(node.parentNode === div, `${ID}: pb non enfant direct du div (§2.2)`); // invariant
      pbCount += 1;
      const corresp = attr(node, 'corresp');
      assertOrDie(corresp && corresp.startsWith('#'), `${ID}: pb sans @corresp exploitable`);
      const facsId = corresp.slice(1);
      const surf = facsById.get(facsId);
      if (!surf) fail(`${ID}: pb @corresp=${corresp} sans surface correspondante`);
      else surf.pb = true;
      pageDiv = makePage(facsId, surf ? surf.view : null); // @facs = variante full/,1200 (contrat)
      // le pb n'est PAS recopié : remplacé par le div de page
    } else if (name === 'ab' || name === 'fw' || name === 'note') {
      if (pageDiv === null) {
        fail(`${ID}: ${name} avant le premier pb — page-0 de garde créée (non observé, §3.2.4)`);
        pageDiv = makePage(null, null);
      }
      pageDiv.appendChild(doc.createTextNode('\n'));
      pageDiv.appendChild(node); // déplacement (retire du div source)
      moved[name] += 1;
    } else {
      fail(`${ID}: enfant de div inattendu: <${name}> (attendu pb|ab|fw|note)`);
    }
  }

  // vider le div racine puis y insérer les divs de page
  while (div.firstChild) div.removeChild(div.firstChild);
  for (const p of pages) {
    p.el.appendChild(doc.createTextNode('\n'));
    div.appendChild(doc.createTextNode('\n'));
    div.appendChild(p.el);
  }
  div.appendChild(doc.createTextNode('\n'));

  // numéro imprimé par page : motif fN-M (LIV0010) sinon 1er fw[@type='NumberingZone']
  for (const p of pages) {
    let printed = null;
    const surf = p.facsId ? facsById.get(p.facsId) : null;
    if (surf && surf.printed) printed = surf.printed;
    else {
      const numFw = kids(p.el, 'fw').find((f) => attr(f, 'type') === 'NumberingZone');
      if (numFw) printed = txt(numFw);
    }
    p.printed = printed;
  }

  return { div, pages, pbCount, moved };
}

// --- contrôles de sortie (§3.2.7) -------------------------------------------------
function verifyOutput(xmlString, ID, expectedPages) {
  let reparsed;
  try {
    reparsed = new DOMParser().parseFromString(xmlString, 'text/xml');
  } catch (e) {
    fail(`${ID}: sortie non re-parsable: ${e.message}`);
    return;
  }
  const all = reparsed.getElementsByTagName('*');
  let nPages = 0,
    nPb = 0,
    nSourceDoc = 0,
    nFacsEmpty = 0,
    strayInRoot = 0;
  for (let i = 0; i < all.length; i++) {
    const el = all.item(i);
    const ln = el.localName;
    if (ln === 'div' && el.getAttribute('type') === 'page') {
      nPages += 1;
      if (!el.getAttribute('facs')) nFacsEmpty += 1;
    } else if (ln === 'pb') nPb += 1;
    else if (ln === 'sourceDoc') nSourceDoc += 1;
    if (
      (ln === 'ab' || ln === 'fw') &&
      el.parentNode.localName === 'div' &&
      el.parentNode.getAttribute('type') !== 'page' &&
      el.parentNode.parentNode.localName === 'body'
    )
      strayInRoot += 1;
  }
  if (nPages !== expectedPages)
    fail(`${ID}: ${nPages} div[@type='page'] re-parsés ≠ ${expectedPages} pb source`);
  if (nPb !== 0) fail(`${ID}: ${nPb} pb restants`);
  if (nSourceDoc !== 0) fail(`${ID}: sourceDoc restant`);
  if (nFacsEmpty !== 0) fail(`${ID}: ${nFacsEmpty} pages avec @facs vide`);
  if (strayInRoot !== 0) fail(`${ID}: ${strayInRoot} ab|fw restés hors page dans le div racine`);
  return { nPages, nPb, nSourceDoc };
}

// --- traitement d'un document ------------------------------------------------------
function processDoc(ID) {
  const srcPath = path.join(srcDir, `${ID}_reconciled.tei.xml`);
  console.log(`\n=== ${ID} — ${srcPath}`);
  const xml = fs.readFileSync(srcPath, 'utf8');
  const doc = new DOMParser().parseFromString(xml, 'text/xml');
  const tei = doc.documentElement;
  const rootId = tei.getAttributeNS(XML_NS, 'id') || attr(tei, 'xml:id');
  const expectedRootId = `ark_12148_${ID}_reconciled`;
  if (rootId !== expectedRootId)
    fail(`${ID}: TEI/@xml:id = ${rootId} ≠ ${expectedRootId}`);

  // 1. métadonnées (avant élagage)
  const meta = extractMetadata(doc, ID);

  // 2. mapping fac-similé (avant suppression du sourceDoc)
  const { surfaces, byId } = extractFacs(doc, ID, meta.arkImages);
  if (meta.nbImages !== null && surfaces.length !== meta.nbImages)
    fail(`${ID}: ${surfaces.length} surfaces ≠ extent/measure/@n=${meta.nbImages}`);

  // 3. chunking
  const { pages, pbCount, moved } = chunkBody(doc, ID, byId);
  if (pages.length !== pbCount)
    fail(`${ID}: ${pages.length} pages ≠ ${pbCount} pb source`);

  // 4. élagage : suppression du sourceDoc entier (teiHeader + standOff conservés)
  const sourceDoc = kid(tei, 'sourceDoc');
  sourceDoc.parentNode.removeChild(sourceDoc);

  // 5. sérialisation avec déclaration XML d'origine
  const decl = xml.match(/^<\?xml[^?]*\?>/)?.[0] ?? '<?xml version="1.0" encoding="UTF-8"?>';
  const serialized = decl + '\n' + new XMLSerializer().serializeToString(doc.documentElement);
  const outTei = path.join(OUT_TEI, `${ID}.xml`);
  fs.writeFileSync(outTei, serialized, 'utf8');

  // 6. contrôles de sortie
  verifyOutput(serialized, ID, pbCount);

  // 7. facs/{ID}.json
  const facsJson = { ark: meta.arkImages, surfaces };
  fs.writeFileSync(path.join(OUT_FACS, `${ID}.json`), JSON.stringify(facsJson, null, 1), 'utf8');

  const surfNoPb = surfaces.filter((s) => !s.pb).length;
  meta.pageCount = pages.length;
  meta.pages = pages.map((p) => ({ n: p.n, facsId: p.facsId, printed: p.printed ?? null }));

  console.log(
    `  pages: ${pages.length} (pb=${pbCount}) | déplacés: ab=${moved.ab} fw=${moved.fw} note=${moved.note}` +
      ` | surfaces: ${surfaces.length} (sans pb: ${surfNoPb}) | sortie: ${(serialized.length / 1e6).toFixed(2)} Mo`
  );

  // ids s_/w_ et ids de pages pour contrôles globaux
  const swIds = new Set();
  for (const m of serialized.matchAll(/xml:id="([sw]_[^"]+)"/g)) swIds.add(m[1]);
  const pageIds = pages.map((p) => `${ID}-page-${p.n}`);

  return { meta, pageCount: pages.length, swIds, pageIds };
}

// --- main -------------------------------------------------------------------------
const corpus = { generated: new Date().toISOString(), documents: {} };
let totalPages = 0;
const allPageIds = new Map(); // id -> doc
const swByDoc = new Map();

for (const ID of DOC_IDS) {
  const r = processDoc(ID);
  corpus.documents[ID] = r.meta;
  totalPages += r.pageCount;
  swByDoc.set(ID, r.swIds);
  for (const pid of r.pageIds) {
    if (allPageIds.has(pid))
      fail(`xml:id de page dupliqué GLOBALEMENT: ${pid} (${allPageIds.get(pid)} et ${ID})`);
    else allPageIds.set(pid, ID);
  }
}

fs.writeFileSync(path.join(OUT_DATA, 'corpus.json'), JSON.stringify(corpus, null, 1), 'utf8');

console.log(`\n=== Contrôles globaux`);
console.log(`  total pages: ${totalPages} (attendu 888)`);
if (totalPages !== 888) fail(`total pages = ${totalPages} ≠ 888 (§3.2.7)`);
console.log(`  xml:id de pages: ${allPageIds.size}, tous globalement uniques (préfixe doc)`);

// s_/w_ dupliqués entre docs — AVERTISSEMENT seulement
let dupSW = 0;
const ids = [...swByDoc.entries()];
for (let i = 0; i < ids.length; i++)
  for (let j = i + 1; j < ids.length; j++) {
    let inter = 0;
    for (const id of ids[i][1]) if (ids[j][1].has(id)) inter++;
    if (inter > 0) {
      console.warn(`  AVERTISSEMENT: ${inter} xml:id s_/w_ communs entre ${ids[i][0]} et ${ids[j][0]}`);
      dupSW += inter;
    }
  }
if (dupSW === 0) console.log(`  xml:id s_/w_: aucun dupliqué entre docs`);

if (hadError) {
  console.error('\nÉCHEC: des contrôles ont échoué (voir ERREUR ci-dessus).');
  process.exit(1);
}
console.log('\nOK: 5 TEI préparés, facs/{ID}.json et corpus.json écrits.');
