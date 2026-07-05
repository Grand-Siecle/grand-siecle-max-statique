#!/usr/bin/env node
/**
 * build-entities.mjs — Grand Siècle sous MaX (statique)
 *
 * Lit les 9 registres TEI d'autorité (grand-siecle-TeiAPP/data/registers/*.xml)
 * et les 5 TEI de la démo (LIV0001, LIV0010, LIV0017, LIV0019, LIV0020),
 * puis génère :
 *   - max/editions/grand-siecle/ui/js/data/browse/{type}.json  (9 fichiers, spec D §5.1)
 *   - max/editions/grand-siecle/ui/js/data/map.json            (spec D §5.2)
 *   - max/editions/grand-siecle/ui/js/data/timeline.json       (spec D §5.3)
 *   - max/editions/grand-siecle/ui/js/data/cooccurrence.json   (spec D §5.4, bipartite doc⇄entité)
 *   - max/editions/grand-siecle/ui/js/data/doc-entities.json   (index inversé doc→entités, spec D §2.3)
 *   - build/site-extra/registres/{type}/{ref}.html             (~665 pages détail, spec D §3)
 *   - build/site-extra/registres/{type}/{ref}.xml               (export TEI de l'entrée)
 *   - build/site-extra/registres/index.html                    (hub « Entités », spec D §5.5)
 *
 * Périmètre (spec D §6) : union (sources ∩ 5 docs) ∪ (refs présents dans les 5 docs).
 * Aucune dépendance externe — Node ≥ 18, parsing par regex (XML généré, régulier).
 */

import fs from 'node:fs';
import path from 'node:path';

/* ------------------------------------------------------------------ */
/* Configuration                                                       */
/* ------------------------------------------------------------------ */

const TEIAPP_DATA = '/home/rayondemiel/Projet_UNIL/grand-siecle-TeiAPP/data';
const REGISTERS = path.join(TEIAPP_DATA, 'registers');
const ROOT = '/home/rayondemiel/Projet_UNIL/grand-siecle-max-statique';
const EDITION = path.join(ROOT, 'max/editions/grand-siecle');
const DATA_OUT = path.join(EDITION, 'ui/js/data');
const SITE_EXTRA = path.join(ROOT, 'build/site-extra/registres');

const DEMO_DOCS = ['LIV0001', 'LIV0010', 'LIV0017', 'LIV0019', 'LIV0020'];

/** type → tout ce qu'il faut savoir (fichier, élément, préfixe id, slug index MaX FR, libellés) */
const TYPES = {
  person:       { file: 'persons.xml',       tag: 'person',   prefix: 'person-',    indexSlug: 'personnes',    label: 'Personnes',              singular: 'Personne',     backLabel: 'Toutes les personnes' },
  place:        { file: 'places.xml',        tag: 'place',    prefix: 'place-',     indexSlug: 'lieux',        label: 'Lieux',                  singular: 'Lieu',         backLabel: 'Tous les lieux' },
  organization: { file: 'organizations.xml', tag: 'org',      prefix: 'org-',       indexSlug: 'organisations',label: 'Organisations',          singular: 'Organisation', backLabel: 'Toutes les organisations' },
  work:         { file: 'works.xml',         tag: 'bibl',     prefix: 'work-',      indexSlug: 'oeuvres',      label: 'Œuvres',                 singular: 'Œuvre',        backLabel: 'Toutes les œuvres' },
  event:        { file: 'events.xml',        tag: 'event',    prefix: 'event-',     indexSlug: 'evenements',   label: 'Événements',             singular: 'Événement',    backLabel: 'Tous les événements' },
  artwork:      { file: 'artworks.xml',      tag: 'object',   prefix: 'artwork-',   indexSlug: 'objets',       label: 'Objets & œuvres d’art',  singular: 'Objet', exp: true, backLabel: 'Tous les objets' },
  material:     { file: 'materials.xml',     tag: 'category', prefix: 'material-',  indexSlug: 'materiaux',    label: 'Matériaux',              singular: 'Matériau',     backLabel: 'Tous les matériaux' },
  technique:    { file: 'techniques.xml',    tag: 'category', prefix: 'technique-', indexSlug: 'techniques',   label: 'Techniques',             singular: 'Technique',    backLabel: 'Toutes les techniques' },
  date:         { file: 'dates.xml',         tag: 'item',     prefix: 'date-',      indexSlug: 'dates',        label: 'Chronologie',            singular: 'Date', exp: true, backLabel: 'Toutes les dates' },
};

/** préfixe d'@xml:id → type */
const PREFIX2TYPE = {
  person: 'person', place: 'place', org: 'organization', work: 'work', event: 'event',
  artwork: 'artwork', material: 'material', technique: 'technique', date: 'date',
};

/** Référentiels externes — rview:auth-url (spec D §1.10) */
const AUTH = {
  wikidata: { abbr: 'Wikidata',  host: 'wikidata.org',      url: v => `https://www.wikidata.org/wiki/${v}` },
  viaf:     { abbr: 'VIAF',      host: 'viaf.org',          url: v => `https://viaf.org/viaf/${v}` },
  isni:     { abbr: 'ISNI',      host: 'isni.org',          url: v => `https://isni.org/isni/${v}` },
  gnd:      { abbr: 'GND',       host: 'd-nb.info',         url: v => `https://d-nb.info/gnd/${v}` },
  bnf:      { abbr: 'BnF',       host: 'catalogue.bnf.fr',  url: v => `https://catalogue.bnf.fr/ark:/12148/cb${v}` },
  lccn:     { abbr: 'LCCN',      host: 'id.loc.gov',        url: v => `https://id.loc.gov/authorities/names/${v}` },
  geonames: { abbr: 'GeoNames',  host: 'geonames.org',      url: v => `https://www.geonames.org/${v}` },
  aat:      { abbr: 'Getty AAT', host: 'vocab.getty.edu',   url: v => `http://vocab.getty.edu/aat/${v}` },
};

const CONF_FR = { high: 'confiance forte', medium: 'confiance moyenne', low: 'confiance faible', none: 'non réconciliée' };
const CONF_GLYPH = { high: '◆◆◆', medium: '◆◆', low: '◆', none: '○' };
const CONF_TITLE = {
  high: 'réconciliation automatique — confiance forte',
  medium: 'réconciliation automatique — confiance moyenne',
  low: 'réconciliation automatique — confiance faible',
  none: 'non réconciliée',
};
const EXP_TITLE = 'Registre expérimental : extraction automatique en cours de validation';

/* ------------------------------------------------------------------ */
/* Petits utilitaires XML / texte                                      */
/* ------------------------------------------------------------------ */

const NAMED_ENT = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'" };

function decodeEntities(s) {
  return s
    .replace(/&#x([0-9a-fA-F]+);/g, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(parseInt(d, 10)))
    .replace(/&(amp|lt|gt|quot|apos);/g, (_, n) => NAMED_ENT[n]);
}

function stripTags(s) {
  return decodeEntities(s.replace(/<[^>]*>/g, ' ')).replace(/\s+/g, ' ').trim();
}

function escapeHtml(s) {
  return String(s ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function parseAttrs(str) {
  const out = {};
  for (const m of str.matchAll(/([\w:.-]+)="([^"]*)"/g)) out[m[1]] = decodeEntities(m[2]);
  return out;
}

/** Tous les éléments <tag …>…</tag> ou <tag …/> du fragment (non récursif sur tag identique imbriqué) */
function els(xml, tag) {
  const out = [];
  const re = new RegExp(`<${tag}\\b([^>]*?)(?:/>|>([\\s\\S]*?)</${tag}>)`, 'g');
  for (const m of xml.matchAll(re)) {
    out.push({ attrs: parseAttrs(m[1] || ''), text: m[2] != null ? stripTags(m[2]) : '', raw: m[2] ?? '' });
  }
  return out;
}

function firstEl(xml, tag) { return els(xml, tag)[0] || null; }

function noteOf(body, type) {
  const n = els(body, 'note').find(n => n.attrs.type === type);
  return n ? n.text : '';
}

/** année entière depuis une date ISO éventuellement négative ("0354-11-13", "-0043") */
function isoYear(v) {
  if (!v) return null;
  const m = String(v).match(/^(-?)0*(\d{1,4})/);
  if (!m) return null;
  const y = parseInt(m[2], 10);
  return m[1] === '-' ? -y : y;
}

function centuryOf(year) {
  if (year == null) return null;
  if (year > 0) return Math.floor((year - 1) / 100) + 1;
  return -(Math.floor((-year - 1) / 100) + 1);
}

const ROMAN = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX', 'XXI'];
function centuryLabel(c) {
  if (c == null) return '';
  const abs = Math.abs(c);
  const r = ROMAN[abs] || String(abs);
  const suff = abs === 1 ? 'er' : 'e';
  return `${r}${suff === 'er' ? 'ᵉʳ' : 'ᵉ'} siècle${c < 0 ? ' av. J.-C.' : ''}`;
}

function dispYear(y) {
  if (y == null) return '';
  return y < 0 ? `${-y} av. J.-C.` : String(y);
}

/* ------------------------------------------------------------------ */
/* 1. Parsing des 9 registres                                          */
/* ------------------------------------------------------------------ */

function parseRegisters() {
  /** Map id → entity */
  const entities = new Map();
  const totals = {}; // type → total corpus

  for (const [type, info] of Object.entries(TYPES)) {
    const xml = fs.readFileSync(path.join(REGISTERS, info.file), 'utf8');
    const re = new RegExp(`<${info.tag}\\b([^>]*xml:id="${info.prefix}\\d{6}"[^>]*)>([\\s\\S]*?)</${info.tag}>`, 'g');
    let count = 0;
    for (const m of xml.matchAll(re)) {
      const attrs = parseAttrs(m[1]);
      const id = attrs['xml:id'];
      const body = m[2];
      count++;
      const e = {
        id, type,
        n: parseInt(attrs.n || '0', 10) || 0,
        raw: `<${info.tag} ${m[1].trim()}>${body}</${info.tag}>`,
        sources: noteOf(body, 'sources').split('|').map(s => s.trim()).filter(Boolean),
        confidence: noteOf(body, 'reconciliation-confidence') || 'none',
        description: noteOf(body, 'description'),
        candidates: noteOf(body, 'wikidata-candidates').split('|').map(s => s.trim()).filter(Boolean),
        idnos: {},
        variants: [], standard: '', label: '', sortKey: '',
      };
      for (const idno of els(body, 'idno')) {
        if (idno.attrs.type && idno.text) {
          e.idnos[idno.attrs.type] = idno.text;
          if (idno.attrs.type === 'wikidata' && idno.attrs.cert) e.wikidataCert = idno.attrs.cert;
        }
      }
      parseTypeFields(type, body, e);
      if (!e.sortKey) e.sortKey = e.label;
      e.sortKey = e.sortKey.toLowerCase();
      entities.set(id, e);
    }
    totals[type] = count;
  }
  return { entities, totals };
}

function namesOf(body, tag) {
  const all = els(body, tag);
  const get = t => all.filter(x => x.attrs.type === t).map(x => x.text).filter(Boolean);
  return {
    main: get('main')[0] || (all[0] ? all[0].text : ''),
    sort: get('sort')[0] || '',
    standard: get('standard')[0] || '',
    variants: get('variant'),
  };
}

function kv(el) { return el ? { key: el.attrs.key || el.attrs.value || '', label: el.text } : null; }

function parseTypeFields(type, body, e) {
  switch (type) {
    case 'person': {
      const n = namesOf(body, 'persName');
      Object.assign(e, { label: n.main, sortKey: n.sort, standard: n.standard, variants: n.variants });
      const birthBlock = body.match(/<birth>([\s\S]*?)<\/birth>/);
      const deathBlock = body.match(/<death>([\s\S]*?)<\/death>/);
      const birth = birthBlock && birthBlock[1].match(/<date[^>]*when="([^"]*)"/);
      const death = deathBlock && deathBlock[1].match(/<date[^>]*when="([^"]*)"/);
      e.birth = birth ? isoYear(birth[1]) : null;
      e.death = death ? isoYear(death[1]) : null;
      e.sex = kv(firstEl(body, 'sex'));
      e.occupations = els(body, 'occupation').map(kv);
      e.nationalities = els(body, 'nationality').map(kv);
      e.centuries = [...new Set([centuryOf(e.birth), centuryOf(e.death)].filter(c => c != null))];
      break;
    }
    case 'place': {
      const n = namesOf(body, 'placeName');
      Object.assign(e, { label: n.main, sortKey: n.sort, standard: n.standard, variants: n.variants });
      const geo = body.match(/<geo>([^<]*)<\/geo>/);
      if (geo) {
        const [lat, lon] = geo[1].trim().split(/\s+/).map(Number);
        if (Number.isFinite(lat) && Number.isFinite(lon)) e.geo = [lat, lon];
      }
      e.country = kv(firstEl(body, 'country'));
      break;
    }
    case 'organization': {
      const n = namesOf(body, 'orgName');
      Object.assign(e, { label: n.main, sortKey: n.sort, standard: n.standard, variants: n.variants });
      const fBlock = body.match(/<event[^>]*type="foundation"[^>]*>([\s\S]*?)<\/event>/);
      if (fBlock) {
        const fd = firstEl(fBlock[1], 'date');
        if (fd) e.foundation = isoYear(fd.attrs.when || fd.attrs.notBefore || fd.text);
      }
      break;
    }
    case 'work': {
      const n = namesOf(body, 'title');
      Object.assign(e, { label: n.main, sortKey: n.sort || n.main, standard: n.standard, variants: n.variants });
      e.author = kv(firstEl(body, 'author'));
      e.lang = kv(firstEl(body, 'textLang'));
      const pub = body.match(/<date[^>]*type="publication"[^>]*when="([^"]*)"/) || body.match(/<date[^>]*when="([^"]*)"[^>]*type="publication"/);
      e.pubYear = pub ? isoYear(pub[1]) : null;
      const genre = els(body, 'note').find(x => x.attrs.type === 'genre');
      if (genre) e.genre = { key: genre.attrs.key || '', label: genre.text };
      break;
    }
    case 'event': {
      const n = namesOf(body, 'label');
      Object.assign(e, { label: n.main, sortKey: n.sort || n.main, standard: n.standard, variants: n.variants });
      const dates = { when: null, notBefore: null, notAfter: null };
      for (const d of els(body, 'date')) {
        if (d.attrs.when) dates.when = isoYear(d.attrs.when);
        if (d.attrs.notBefore) dates.notBefore = isoYear(d.attrs.notBefore);
        if (d.attrs.notAfter) dates.notAfter = isoYear(d.attrs.notAfter);
      }
      e.dates = dates;
      e.place = kv(els(body, 'placeName').find(p => p.attrs.key) || firstEl(body, 'placeName'));
      const desc = firstEl(body, 'desc');
      if (desc && !e.description) e.description = desc.text;
      e.centuries = [...new Set([dates.when, dates.notBefore, dates.notAfter].map(centuryOf).filter(c => c != null))];
      break;
    }
    case 'artwork': {
      const n = namesOf(body, 'objectName');
      Object.assign(e, { label: n.main, sortKey: n.sort || n.main, standard: n.standard, variants: n.variants });
      e.objectType = kv(firstEl(body, 'objectType'));
      break;
    }
    case 'material':
    case 'technique': {
      const cat = body.match(/<catDesc>([\s\S]*?)<\/catDesc>/);
      const n = namesOf(cat ? cat[1] : body, 'term');
      Object.assign(e, { label: n.main, sortKey: n.sort || n.main, standard: n.standard, variants: n.variants });
      break;
    }
    case 'date': {
      const all = els(body, 'date');
      const main = all.find(d => !d.attrs.type) || all[0];
      e.label = main ? main.text : '';
      e.sortKey = e.label;
      e.variants = all.filter(d => d.attrs.type === 'variant').map(d => d.text);
      break;
    }
  }
}

/* ------------------------------------------------------------------ */
/* 2. Scan des 5 TEI de la démo : mentions, pages, KWIC                */
/* ------------------------------------------------------------------ */

const MENTION_RE = /<(persName|placeName|orgName|title|rs|material|date|objectName)\b[^>]*?\bref="#([a-z]+)-(\d{6})"[^>]*>/g;

function scanDoc(docId) {
  const file = path.join(TEIAPP_DATA, `${docId}_reconciled.tei.xml`);
  const xml = fs.readFileSync(file, 'utf8');

  // titre : title[@type='main'] du titleStmt, sinon premier title du titleStmt
  const tsM = xml.match(/<titleStmt>([\s\S]*?)<\/titleStmt>/);
  const ts = tsM ? tsM[1] : xml;
  const title = (ts.match(/<title[^>]*type="main"[^>]*>([\s\S]*?)<\/title>/) || ts.match(/<title[^>]*>([\s\S]*?)<\/title>/) || [null, docId])[1];

  const textStart = xml.indexOf('<text');
  const from = textStart >= 0 ? textStart : 0;

  // positions des <pb> (ordre de document, dans <text>) → page n = index 1-based
  const pbOffsets = [];
  for (const m of xml.slice(from).matchAll(/<pb\b[^>]*>/g)) pbOffsets.push(from + m.index);

  const pageOf = (off) => {
    let lo = 0, hi = pbOffsets.length - 1, ans = 0;
    while (lo <= hi) {
      const mid = (lo + hi) >> 1;
      if (pbOffsets[mid] <= off) { ans = mid + 1; lo = mid + 1; } else hi = mid - 1;
    }
    return Math.max(1, ans);
  };

  // mentions
  const mentions = [];
  MENTION_RE.lastIndex = 0;
  for (const m of xml.slice(from).matchAll(MENTION_RE)) {
    const type = PREFIX2TYPE[m[2]];
    if (!type) continue;
    const id = `${m[2]}-${m[3]}`;
    const off = from + m.index;
    mentions.push({ id, type, el: m[1], off, tagLen: m[0].length, page: pageOf(off) });
  }

  // blocs (ab|p|head|item|l) pour le regroupement KWIC
  const blocks = [];
  for (const m of xml.slice(from).matchAll(/<(ab|p|head|item|l)\b[^>]*>[\s\S]*?<\/\1>/g)) {
    blocks.push({ start: from + m.index, end: from + m.index + m[0].length });
  }
  blocks.sort((a, b) => a.start - b.start);
  const blockOf = (off) => {
    let lo = 0, hi = blocks.length - 1, ans = -1;
    while (lo <= hi) {
      const mid = (lo + hi) >> 1;
      if (blocks[mid].start <= off) { ans = mid; lo = mid + 1; } else hi = mid - 1;
    }
    return ans >= 0 && off < blocks[ans].end ? ans : -1;
  };

  return { docId, title: stripTags(title), xml, mentions, blocks, blockOf, npb: pbOffsets.length };
}

/** Plie un token de bord pour comparaison : minuscules, sans diacritiques,
 *  sans ponctuation. */
function foldToken(t) {
  return String(t || '').toLowerCase().normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^\p{L}\p{N}]+/gu, '');
}

/** Distance d'édition (Levenshtein) ≤ max — petites chaînes uniquement. */
function editDistanceLE(a, b, max) {
  if (Math.abs(a.length - b.length) > max) return false;
  const dp = Array.from({ length: a.length + 1 }, (_, i) => i);
  for (let j = 1; j <= b.length; j++) {
    let prev = dp[0];
    dp[0] = j;
    let rowMin = dp[0];
    for (let i = 1; i <= a.length; i++) {
      const tmp = dp[i];
      dp[i] = Math.min(dp[i] + 1, dp[i - 1] + 1, prev + (a[i - 1] === b[j - 1] ? 0 : 1));
      prev = tmp;
      if (dp[i] < rowMin) rowMin = dp[i];
    }
    if (rowMin > max) return false;
  }
  return dp[a.length] <= max;
}

/** Deux tokens de bord représentent-ils le même mot recollé ? (insensible à
 *  la casse/diacritiques ; tolère 1–2 coquilles de modernisation, p. ex.
 *  « Rhétorique » / « Rhhétorique ») */
function sameEdgeToken(a, b) {
  const fa = foldToken(a), fb = foldToken(b);
  if (!fa || !fb) return false;
  if (fa === fb) return true;
  const min = Math.min(fa.length, fb.length);
  return min >= 4 && editDistanceLE(fa, fb, min >= 6 ? 2 : 1);
}

/** Texte KWIC : bloc du document, couche reg préférée (sinon orig),
 *  sauf pour le choice contenant la mention (couche qui la contient —
 *  jamais orig + reg côte à côte).
 *  Les <choice> sont alignés ligne à ligne : un mot coupé en fin de ligne
 *  réapparaît ENTIER au début de la couche reg de la ligne suivante (dont
 *  la couche orig commence par <w part="F">). On dédoublonne donc le
 *  chevauchement entre fin de ligne n et début de ligne n+1 en comparant
 *  les tokens de bord, en conservant la copie qui porte la mention. */
function kwicFor(doc, mention) {
  const bi = doc.blockOf(mention.off);
  const S = '', E = '';           // sentinelles de la mention
  const SEG = '', SEGDUP = '';    // frontières de ligne (DUP = mot recollé en tête)
  let raw, rel;
  if (bi >= 0) {
    const b = doc.blocks[bi];
    raw = doc.xml.slice(b.start, b.end);
    rel = mention.off - b.start;
  } else {
    const start = Math.max(0, mention.off - 1500);
    raw = doc.xml.slice(start, mention.off + 2000);
    rel = mention.off - start;
  }
  // 1. baliser la mention : contenu entre fin du tag ouvrant et tag fermant correspondant
  const openEnd = rel + mention.tagLen;
  const closeRe = new RegExp(`</${mention.el}>`, 'g');
  closeRe.lastIndex = openEnd;
  const cm = closeRe.exec(raw);
  if (!cm) return null;
  raw = raw.slice(0, openEnd) + S + raw.slice(openEnd, cm.index) + E + raw.slice(cm.index);

  // 2. résolution des <choice> : reg sinon orig ; couche de la mention si sentinelle
  //    dedans (une SEULE couche, jamais orig + reg côte à côte). Chaque choice émet
  //    une frontière de ligne : SEGDUP si sa couche orig commence par un <w part="F">
  //    (mot coupé recollé en tête → doublon avec la fin de la ligne précédente).
  const resolved = raw.replace(/<choice>([\s\S]*?)<\/choice>/g, (_, inner) => {
    const reg = inner.match(/<reg\b[^>]*>([\s\S]*?)<\/reg>/);
    const orig = inner.match(/<orig\b[^>]*>([\s\S]*?)<\/orig>/);
    const firstW = orig && orig[1].match(/<w\b([^>]*)>/);
    const mark = firstW && /\bpart="F"/.test(firstW[1]) ? SEGDUP : SEG;
    let layer;
    if (inner.includes(S)) {
      if (reg && reg[1].includes(S)) layer = reg[1];
      else if (orig && orig[1].includes(S)) layer = orig[1];
      else layer = orig ? inner.replace(orig[0], ' ') : inner;
    } else {
      layer = reg ? reg[1] : orig ? orig[1] : inner;
    }
    return ` ${mark}${layer} `;
  });

  // 3. aplatir puis dédoublonner les chevauchements aux frontières de ligne
  const flatRaw = decodeEntities(resolved.replace(/<[^>]*>/g, ' ')).replace(/\s+/g, ' ').trim();
  const tokens = [];
  for (let part of flatRaw.split(new RegExp(`(?=[${SEG}${SEGDUP}])`))) {
    const dup = part.charAt(0) === SEGDUP;
    part = part.replace(new RegExp(`^[${SEG}${SEGDUP}]\\s*`), '').trim();
    if (!part) continue;
    const words = part.split(' ');
    if (dup && tokens.length && words.length) {
      const prev = tokens[tokens.length - 1], cur = words[0];
      if (sameEdgeToken(prev, cur)) {
        // conserver la copie qui porte la mention ; sinon la première
        if (cur.includes(S) || cur.includes(E)) tokens.pop();
        else words.shift();
      }
    }
    for (const w of words) if (w) tokens.push(w);
  }
  const flat = tokens.join(' ');
  const i = flat.indexOf(S), j = flat.indexOf(E);
  if (i < 0 || j < 0 || j <= i) return null;
  const kw = flat.slice(i + 1, j).trim();
  if (!kw) return null;
  let left = flat.slice(0, i).trimEnd();
  let right = flat.slice(j + 1).trimStart();
  if (left.length > 80) left = '…' + left.slice(-80).replace(/^\S*\s/, '');
  if (right.length > 80) right = right.slice(0, 80).replace(/\s\S*$/, '') + '…';
  return { left, kw, right, page: mention.page };
}

/* ------------------------------------------------------------------ */
/* 3. Construction du périmètre + agrégats                             */
/* ------------------------------------------------------------------ */

function main() {
  console.log('— Parsing des registres…');
  const { entities, totals } = parseRegisters();
  console.log('  totaux corpus :', Object.entries(totals).map(([t, n]) => `${t}=${n}`).join(' '));

  console.log('— Scan des 5 TEI de la démo…');
  const docs = {};
  let totalMentions = 0;
  for (const d of DEMO_DOCS) {
    docs[d] = scanDoc(d);
    totalMentions += docs[d].mentions.length;
    console.log(`  ${d}: ${docs[d].mentions.length} mentions, ${docs[d].npb} pb, "${docs[d].title}"`);
  }
  console.log(`  total mentions inline: ${totalMentions}`);

  // occurrences par entité : id → { doc → [mentions] }
  const occ = new Map();
  const orphanRefs = new Set();
  for (const d of DEMO_DOCS) {
    for (const m of docs[d].mentions) {
      if (!entities.has(m.id)) { orphanRefs.add(m.id); continue; }
      if (!occ.has(m.id)) occ.set(m.id, {});
      (occ.get(m.id)[d] ??= []).push(m);
    }
  }
  if (orphanRefs.size) console.log(`  ⚠ refs sans entrée de registre (ignorés): ${orphanRefs.size}`, [...orphanRefs].slice(0, 10));

  // périmètre = (sources ∩ démo) ∪ (refs présents)
  const demoSet = new Set(DEMO_DOCS);
  const perimeter = new Map(); // id → enriched entity
  for (const [id, e] of entities) {
    const srcDemo = e.sources.filter(s => demoSet.has(s));
    const hasRefs = occ.has(id);
    if (!srcDemo.length && !hasRefs) continue;
    const docsCited = [...new Set([...srcDemo, ...Object.keys(occ.get(id) || {})])].sort();
    const perDoc = {};
    let demoMentions = 0;
    for (const d of docsCited) {
      const n = (occ.get(id)?.[d] || []).length;
      perDoc[d] = n;
      demoMentions += n;
    }
    perimeter.set(id, { ...e, docsCited, perDoc, demoMentions });
  }
  const byType = {};
  for (const e of perimeter.values()) (byType[e.type] ??= []).push(e);
  for (const t of Object.keys(TYPES)) (byType[t] ??= []);
  const collator = new Intl.Collator('fr');
  for (const t of Object.keys(byType)) byType[t].sort((a, b) => collator.compare(a.sortKey, b.sortKey));
  console.log('— Périmètre démo :', Object.entries(byType).map(([t, l]) => `${t}=${l.length}`).join(' '),
    '→ total', perimeter.size);

  // co-occurrences (algo rview:cooccurrences restreint démo) : partage de docs, n>1, tri, limite 14
  const docEntityIds = {};
  for (const d of DEMO_DOCS) docEntityIds[d] = [];
  for (const e of perimeter.values()) for (const d of e.docsCited) docEntityIds[d].push(e.id);
  const cooccurOf = (e) => {
    const shared = new Map();
    for (const d of e.docsCited) for (const oid of docEntityIds[d]) {
      if (oid !== e.id) shared.set(oid, (shared.get(oid) || 0) + 1);
    }
    return [...shared.entries()]
      .map(([oid, nd]) => ({ e: perimeter.get(oid), nd }))
      .filter(x => x.e.n > 1)
      .sort((a, b) => b.nd - a.nd || b.e.n - a.e.n || collator.compare(a.e.sortKey, b.e.sortKey))
      .slice(0, 14);
  };

  /* ------------------------------------------------------------------ */
  /* 4. Sorties JSON                                                     */
  /* ------------------------------------------------------------------ */

  console.log('— Écriture des JSON…');
  fs.mkdirSync(path.join(DATA_OUT, 'browse'), { recursive: true });

  const tierOf = n => (n >= 50 ? 4 : n >= 10 ? 3 : n >= 2 ? 2 : 1);
  const urlOf = e => `registres/${e.type}/${e.id}.html`;

  // 4a. browse/{type}.json
  for (const [type, info] of Object.entries(TYPES)) {
    const items = byType[type].map(e => {
      const it = {
        id: e.id, type, label: e.label, sort: e.sortKey,
        standard: e.standard || undefined,
        variants: e.variants,
        mentions: e.demoMentions,
        corpusMentions: e.n,
        tier: tierOf(e.demoMentions || e.n),
        confidence: e.confidence,
        authority: Boolean(e.idnos.wikidata),
        idnos: e.idnos,
        description: e.description || undefined,
        sources: e.docsCited,
        perDoc: e.perDoc,
        url: urlOf(e),
      };
      if (type === 'person') Object.assign(it, {
        birth: e.birth, death: e.death, centuries: e.centuries,
        sex: e.sex || undefined,
        occupations: e.occupations?.filter(Boolean) || [],
        nationalities: e.nationalities?.filter(Boolean) || [],
      });
      if (type === 'place') Object.assign(it, {
        country: e.country || undefined, geo: e.geo || undefined,
        geonames: e.idnos.geonames || undefined, hasGeo: Boolean(e.geo),
      });
      if (type === 'work') Object.assign(it, {
        author: e.author || undefined, lang: e.lang || undefined,
        pubYear: e.pubYear ?? undefined, genre: e.genre || undefined,
      });
      if (type === 'event') Object.assign(it, {
        dates: e.dates, centuries: e.centuries, place: e.place || undefined,
      });
      if (type === 'artwork') it.objectType = e.objectType || undefined;
      if (type === 'organization') it.foundation = e.foundation ?? undefined;
      return it;
    });
    const out = {
      type, slug: info.indexSlug, label: info.label,
      total: totals[type], count: items.length,
      experimental: Boolean(info.exp),
      items,
    };
    fs.writeFileSync(path.join(DATA_OUT, 'browse', `${type}.json`), JSON.stringify(out));
  }

  // 4b. map.json — lieux du périmètre avec geo (format rview:places-map + extras)
  const mapJson = byType.place.filter(e => e.geo).map(e => ({
    latitude: String(e.geo[0]), longitude: String(e.geo[1]),
    label: e.label, id: e.id, url: urlOf(e),
    mentions: e.demoMentions, country: e.country?.label || undefined,
  }));
  fs.writeFileSync(path.join(DATA_OUT, 'map.json'), JSON.stringify(mapJson));

  // 4c. timeline.json — vies des personnes + events datés + works/orgs datés
  const timeline = [];
  for (const e of byType.person) {
    if (e.birth != null || e.death != null) {
      timeline.push({ id: e.id, type: 'person', label: e.label, start: e.birth, end: e.death, url: urlOf(e), sources: e.docsCited });
    }
  }
  for (const e of byType.event) {
    const start = e.dates.when ?? e.dates.notBefore;
    const end = e.dates.when ?? e.dates.notAfter;
    if (start != null || end != null) {
      timeline.push({ id: e.id, type: 'event', label: e.label, start, end, url: urlOf(e), sources: e.docsCited });
    }
  }
  for (const e of byType.work) if (e.pubYear != null) {
    timeline.push({ id: e.id, type: 'work', label: e.label, start: e.pubYear, end: e.pubYear, url: urlOf(e), sources: e.docsCited });
  }
  for (const e of byType.organization) if (e.foundation != null) {
    timeline.push({ id: e.id, type: 'organization', label: e.label, start: e.foundation, end: e.foundation, url: urlOf(e), sources: e.docsCited });
  }
  timeline.sort((a, b) => (a.start ?? a.end ?? 0) - (b.start ?? b.end ?? 0));
  fs.writeFileSync(path.join(DATA_OUT, 'timeline.json'), JSON.stringify(timeline));

  // 4d. cooccurrence.json — graphe bipartite doc⇄entité (spec D §5.4, livrable 2)
  const coNodes = DEMO_DOCS.map(d => ({ id: d, label: docs[d].title, type: 'doc' }));
  for (const e of perimeter.values()) coNodes.push({ id: e.id, label: e.label, type: e.type, mentions: e.demoMentions });
  const coLinks = [];
  for (const e of perimeter.values()) for (const d of e.docsCited) {
    coLinks.push({ source: d, target: e.id, weight: e.perDoc[d] || 1 });
  }
  fs.writeFileSync(path.join(DATA_OUT, 'cooccurrence.json'), JSON.stringify({ nodes: coNodes, links: coLinks }));

  // 4e. doc-entities.json — index inversé doc → entités (avec comptes)
  const docEnt = {};
  for (const d of DEMO_DOCS) {
    const types = {};
    for (const t of Object.keys(TYPES)) types[t] = [];
    for (const e of perimeter.values()) {
      if (e.docsCited.includes(d)) types[e.type].push({ id: e.id, label: e.label, mentions: e.perDoc[d] || 0 });
    }
    for (const t of Object.keys(types)) types[t].sort((a, b) => b.mentions - a.mentions || collator.compare(a.label, b.label));
    docEnt[d] = {
      title: docs[d].title,
      total: docs[d].mentions.length,
      types,
    };
  }
  fs.writeFileSync(path.join(DATA_OUT, 'doc-entities.json'), JSON.stringify(docEnt));

  /* ------------------------------------------------------------------ */
  /* 5. Pages détail statiques + exports TEI                             */
  /* ------------------------------------------------------------------ */

  console.log('— Génération des pages détail…');
  // Wikidata QID → entité person du périmètre (liens auteur → fiche, spec #16)
  const wikidata2person = new Map();
  for (const e of byType.person) if (e.idnos.wikidata) wikidata2person.set(e.idnos.wikidata, e);
  let pageCount = 0;
  for (const [type] of Object.entries(TYPES)) {
    const dir = path.join(SITE_EXTRA, type);
    fs.mkdirSync(dir, { recursive: true });
    for (const e of byType[type]) {
      fs.writeFileSync(path.join(dir, `${e.id}.html`), detailPage(e, docs, cooccurOf(e), wikidata2person));
      const teiFrag = e.raw.replace(/^<(\w+)\s/, '<$1 xmlns="http://www.tei-c.org/ns/1.0" ');
      fs.writeFileSync(path.join(dir, `${e.id}.xml`), `<?xml version="1.0" encoding="UTF-8"?>\n` + teiFrag + '\n');
      pageCount++;
    }
  }
  console.log(`  ${pageCount} pages détail générées`);

  // hub
  fs.writeFileSync(path.join(SITE_EXTRA, 'index.html'), hubPage(byType, totals, perimeter));
  console.log('  hub registres/index.html généré');

  console.log('— Terminé.');
  console.log(JSON.stringify({
    perimeter: Object.fromEntries(Object.entries(byType).map(([t, l]) => [t, l.length])),
    total: perimeter.size, pages: pageCount, mentions: totalMentions,
    map: mapJson.length, timeline: timeline.length,
    orphanRefs: [...orphanRefs],
  }, null, 1));
}

/* ------------------------------------------------------------------ */
/* 6. Gabarits HTML                                                    */
/* ------------------------------------------------------------------ */

/** header/nav simplifié cohérent charte GS — depth = 1 (hub) ou 2 (fiche) */
function pageShell({ depth, title, bodyClass, content }) {
  const up = '../'.repeat(depth);
  const navIndex = Object.entries(TYPES)
    .map(([t, i]) => `<li><a href="${up}index/${i.indexSlug}.html">${escapeHtml(i.label)}</a></li>`)
    .join('\n              ');
  return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>${escapeHtml(title)} — Grand Siècle</title>
  <link rel="preconnect" href="https://fonts.googleapis.com"/>
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"/>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=EB+Garamond:ital,wght@0,400;0,500;0,600;0,700;1,400;1,500&amp;family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;0,600;0,700;1,300;1,400;1,500&amp;display=swap"/>
  <link rel="stylesheet" href="${up}ui/css/grand-siecle.css"/>
  <link rel="stylesheet" href="${up}ui/css/registres.css"/>
</head>
<body class="${bodyClass}">
  <a class="gs-skip-link" href="#gs-registres-main">Aller au contenu</a>
  <header class="gs-page-header">
    <nav class="gs-menubar">
      <ul class="gs-menubar-left">
        <li class="gs-brand"><a href="${up}accueil.html">Grand Siècle</a></li>
        <li><a href="${up}accueil.html">Accueil</a></li>
        <li><a href="${up}sommaire.html">Corpus</a></li>
        <li><a href="${up}search.html">Recherche</a></li>
        <li>
          <details class="gs-nav-dropdown">
            <summary>Index</summary>
            <ul>
              <li><a href="${depth === 1 ? 'index.html' : '../index.html'}">Toutes les entités</a></li>
              ${navIndex}
            </ul>
          </details>
        </li>
        <li><a href="${up}carte.html">Carte</a></li>
        <li><a href="${up}chronologie.html">Chronologie</a></li>
        <li><a href="${up}about.html">À propos</a></li>
      </ul>
    </nav>
  </header>
  <main class="gs-main" id="gs-registres-main">
${content}
  </main>
  <footer class="gs-footer">
    <div>
      <span class="gs-footer-title">Grand Siècle</span>
      <span class="gs-footer-sep">|</span>
      <span>Universités de Lausanne (UNIL) et de Genève (UNIGE)</span>
    </div>
    <div class="gs-footer-line">
      <span>Textes et données sous licence
        <a href="https://creativecommons.org/licenses/by/4.0/deed.fr" rel="license">CC BY 4.0</a></span>
      <span class="gs-footer-sep">|</span>
      <span>Édition réalisée avec
        <a href="https://pdn-certic.pages.unicaen.fr/max-documentation/">MaX</a>
        — Certic, Université de Caen Normandie</span>
    </div>
  </footer>
</body>
</html>
`;
}

function confBadge(conf) {
  const c = CONF_GLYPH[conf] ? conf : 'none';
  return `<span class="gs-conf gs-conf-${c}" title="${CONF_TITLE[c]}" data-pagefind-ignore><span class="gs-conf-glyph">${CONF_GLYPH[c]}</span><span class="gs-conf-text">${CONF_TITLE[c]}</span></span>`;
}

/** rows : [clé, valeur, isHtml?] — valeur déjà échappée quand isHtml */
function factsRows(e, wikidata2person) {
  const rows = [];
  const add = (k, v, isHtml) => { if (v) rows.push([k, v, Boolean(isHtml)]); };
  switch (e.type) {
    case 'person':
      add('Naissance', dispYear(e.birth));
      add('Décès', dispYear(e.death));
      add('Occupations', (e.occupations || []).filter(Boolean).map(o => o.label).join(', '));
      add('Nationalité', (e.nationalities || []).filter(Boolean).map(o => o.label).join(', '));
      add('Sexe', e.sex?.label);
      break;
    case 'place':
      add('Pays', e.country?.label);
      if (e.geo) {
        const [lat, lon] = e.geo;
        const osm = `https://www.openstreetmap.org/?mlat=${lat}&amp;mlon=${lon}#map=6/${lat}/${lon}`;
        add('Coordonnées',
          `${escapeHtml(`${lat} ${lon}`)} · <a href="../../carte.html">voir sur la carte</a> · ` +
          `<a href="${osm}" rel="external noopener" target="_blank" title="Ouvre openstreetmap.org dans un nouvel onglet">OpenStreetMap</a>`,
          true);
      }
      break;
    case 'work': {
      const authorPerson = e.author?.key && wikidata2person ? wikidata2person.get(e.author.key) : null;
      if (authorPerson) {
        add('Auteur', `<a href="../person/${authorPerson.id}.html">${escapeHtml(e.author.label)}</a>`, true);
      } else {
        add('Auteur', e.author?.label);
      }
      add('Langue', e.lang?.label);
      add('Publication', dispYear(e.pubYear));
      break;
    }
    case 'event': {
      const d = e.dates || {};
      const dv = d.when != null ? dispYear(d.when)
        : [d.notBefore != null ? dispYear(d.notBefore) : '', d.notAfter != null ? dispYear(d.notAfter) : ''].filter(Boolean).join(' – ');
      add('Date', dv);
      add('Lieu', e.place?.label);
      break;
    }
    case 'artwork':
      add('Type d’objet', e.objectType?.label);
      break;
    case 'organization':
      add('Fondation', dispYear(e.foundation));
      break;
  }
  return rows;
}

/** intervalle d'années : un seul « av. J.-C. » final quand les deux bornes sont négatives */
function yearRange(a, b, sep = ' – ') {
  if (a != null && b != null && a < 0 && b < 0) return `${-a}${sep}${-b} av. J.-C.`;
  return `${a != null ? dispYear(a) : '?'}${sep}${b != null ? dispYear(b) : '?'}`;
}

function subhead(e) {
  if (e.type === 'person' && (e.birth != null || e.death != null)) {
    return yearRange(e.birth, e.death);
  }
  if (e.type === 'place' && e.country?.label) return e.country.label;
  return '';
}

function detailPage(e, docs, cooccur, wikidata2person) {
  const info = TYPES[e.type];
  const forms = [...new Set([e.standard, ...(e.variants || [])])]
    .filter(f => f && f !== e.label);

  const sh = subhead(e);
  const facts = factsRows(e, wikidata2person);
  const idnoLinks = Object.entries(e.idnos)
    .filter(([k, v]) => AUTH[k] && v)
    .map(([k, v]) => {
      const certFr = e.wikidataCert ? (CONF_FR[e.wikidataCert] || e.wikidataCert) : '';
      const cert = k === 'wikidata' && certFr ? ` <span class="gs-idno-cert">(${escapeHtml(certFr)})</span>` : '';
      return `<li><a class="gs-auth-link" href="${AUTH[k].url(encodeURIComponent(v).replace(/%2F/g, '/'))}" rel="external noopener" target="_blank" title="Ouvre ${AUTH[k].host} dans un nouvel onglet"><span class="gs-auth-chip gs-auth-${k}">${AUTH[k].abbr}</span> <span class="gs-auth-val">${escapeHtml(v)}</span></a>${cert}</li>`;
    });

  // Cité dans
  const backItems = e.docsCited.map(d => {
    const doc = docs[d];
    const ms = (e.perDoc[d] || 0);
    const mentionsInDoc = (docsMentions(docs, d, e.id));
    const firstPage = mentionsInDoc.length ? mentionsInDoc[0].page : 1;
    const readHref = `../../${d}.xml/${d}-page-${firstPage}.html`;
    // KWIC : max 5 par doc, dédoublonnés par bloc
    const seen = new Set();
    const lines = [];
    let truncated = false;
    for (const m of mentionsInDoc) {
      const bi = doc.blockOf(m.off);
      const key = bi >= 0 ? `b${bi}` : `o${m.off}`;
      if (seen.has(key)) continue;
      seen.add(key);
      const k = kwicFor(doc, m);
      if (!k) continue;
      if (lines.length >= 5) { truncated = true; break; }
      lines.push(`<div class="gs-kwic-line"><a href="../../${d}.xml/${d}-page-${k.page}.html">${escapeHtml(k.left)} <mark>${escapeHtml(k.kw)}</mark> ${escapeHtml(k.right)} <span class="gs-kwic-page">p.&nbsp;${k.page}</span></a></div>`);
    }
    const summaryLabel = truncated ? `Extraits (${lines.length} premiers)` : `Extraits (${lines.length})`;
    const moreLine = truncated
      ? `\n<div class="gs-kwic-line"><a href="${readHref}">Toutes les occurrences dans le document →</a></div>`
      : '';
    const kwicBlock = lines.length
      ? `\n      <details class="gs-kwic-details"><summary>${summaryLabel}</summary><div class="gs-kwic-panel">${lines.join('\n')}${moreLine}</div></details>`
      : '';
    return `    <li class="gs-backlinks-item">
      <div class="gs-backlinks-row"><a class="gs-backlinks-doc" href="${readHref}">${escapeHtml(doc.title)}</a> <a class="gs-backlinks-id" href="../../sommaire/${d}.html" title="${escapeHtml(doc.title)}">${d}</a>${ms ? ` <span class="gs-backlinks-n">${ms} mention${ms > 1 ? 's' : ''}</span>` : ''}</div>${kwicBlock}
    </li>`;
  });

  const coBlock = cooccur.length ? `
  <section class="gs-cooccur">
    <h2 class="gs-cooccur-title">Cité dans les mêmes documents</h2>
    <ul class="gs-cooccur-list">
${cooccur.map(({ e: o, nd }) => `      <li><a class="gs-cooccur-item gs-cooccur-${o.type}" href="../${o.type}/${o.id}.html">${escapeHtml(o.label)} <span class="gs-cooccur-meta">${TYPES[o.type].singular} · ${nd} doc${nd > 1 ? 's' : ''}</span></a></li>`).join('\n')}
    </ul>
  </section>` : '';

  const candBlock = e.candidates.length ? `
      <p class="gs-candidates">Candidats non retenus : ${e.candidates.map(q => `<a href="https://www.wikidata.org/wiki/${escapeHtml(q)}" rel="external noopener" target="_blank">${escapeHtml(q)}</a>`).join(' · ')}</p>` : '';

  // compteurs : masquer les zéros (fiche pauvre = id seul, pas de « 0 mention »)
  const metaParts = [`<span class="gs-entity-id">${e.id}</span>`];
  if (e.demoMentions > 0) metaParts.push(`<span class="gs-entity-mentions" title="mentions dans les documents de la démo">${e.demoMentions} mention${e.demoMentions > 1 ? 's' : ''} (démo)</span>`);
  if (e.n > 0) metaParts.push(`<span title="mentions dans le corpus complet">${e.n} dans le corpus</span>`);

  const content = `  <article class="gs-entity-detail gs-entity-detail-${e.type}">
    <p class="gs-entity-kicker"><a href="../index.html">Entités</a> · <a href="../../index/${info.indexSlug}.html">${escapeHtml(info.label)}</a>${info.exp ? ` <span class="gs-exp-badge" title="${EXP_TITLE}">exp.</span>` : ''} · <a href="../../index/${info.indexSlug}.html">← ${escapeHtml(info.backLabel)}</a></p>
    <header class="gs-authority-head">
      <h1 class="gs-authority-title"><span data-pagefind-meta="title" data-pagefind-weight="7">${escapeHtml(e.label)}</span> ${confBadge(e.confidence)}</h1>
      ${sh ? `<p class="gs-authority-sub">${escapeHtml(sh)}</p>` : ''}
      <p class="gs-authority-meta">${metaParts.join(' · ')}</p>
    </header>
${e.description ? `    <p class="gs-authority-desc">${escapeHtml(e.description)}</p>\n` : ''}${forms.length ? `    <section class="gs-forms">
      <h2>Formes attestées</h2>
      <p class="gs-variants">${forms.map(f => `<span class="gs-variant">${escapeHtml(f)}</span>`).join(' ')}</p>
    </section>\n` : ''}${facts.length ? `    <section class="gs-facts">
      <h2>Informations</h2>
      <dl class="gs-meta-rows">
${facts.map(([k, v, isHtml]) => `        <div class="gs-meta-row"><dt>${escapeHtml(k)}</dt><dd>${isHtml ? v : escapeHtml(v)}</dd></div>`).join('\n')}
      </dl>
    </section>\n` : ''}${idnoLinks.length ? `    <aside class="gs-authority-ids">
      <h2>Référentiels</h2>
      <ul>
${idnoLinks.map(l => '        ' + l).join('\n')}
      </ul>
    </aside>\n` : ''}    <section class="gs-provenance">
      <p>Entité détectée automatiquement (NER CamemBERT + GLiNER), réconciliation Wikidata : <strong>${CONF_FR[e.confidence] || CONF_FR.none}</strong>.</p>${e.demoMentions === 0 && e.docsCited.length ? `
      <p>Relevée dans le registre de ${e.docsCited.map(d => `<a href="../../sommaire/${d}.html">${escapeHtml(docs[d].title)}</a>`).join(' et de ')}, sans occurrence localisable dans la transcription.</p>` : ''}${candBlock}
      <p class="gs-export-actions"><a class="gs-export-link" href="${e.id}.xml" download>↓ Exporter TEI</a> <a class="gs-export-link" href="../../about.html">Signaler une erreur d’identification</a></p>
    </section>
${coBlock}
  <section class="gs-backlinks">
    <h2 class="gs-backlinks-title">Cité dans <span class="gs-backlinks-count">${e.docsCited.length}</span> document${e.docsCited.length > 1 ? 's' : ''}${e.demoMentions ? ` <span class="gs-backlinks-sep">·</span> <span class="gs-backlinks-mentions">${e.demoMentions}</span> mention${e.demoMentions > 1 ? 's' : ''}` : ''}</h2>
    <ul class="gs-backlinks-list">
${backItems.join('\n')}
    </ul>
  </section>
  </article>`;

  return pageShell({ depth: 2, title: e.label, bodyClass: `gs-entity-page gs-entity-page-${e.type}`, content });
}

function docsMentions(docs, d, id) {
  return docs[d].mentions.filter(m => m.id === id);
}

function hubPage(byType, totals, perimeter) {
  const cards = Object.entries(TYPES).map(([type, info]) => {
    const list = byType[type];
    const recon = list.filter(e => e.idnos.wikidata).length;
    const top = [...list].sort((a, b) => b.demoMentions - a.demoMentions)[0];
    return `      <a class="gs-hub-card gs-hub-card-${type}" href="../index/${info.indexSlug}.html">
        <span class="gs-hub-type">${escapeHtml(info.label)}${info.exp ? ` <span class="gs-exp-badge" title="${EXP_TITLE}">exp.</span>` : ''}</span>
        <span class="gs-hub-total">${list.length}</span>
        <span class="gs-hub-stats">
          <span class="gs-hub-recon">${recon} réconciliée${recon > 1 ? 's' : ''}</span>
          <span class="gs-hub-corpus">${totals[type]} dans le corpus complet</span>
          ${top && top.demoMentions ? `<span class="gs-hub-top">${escapeHtml(top.label)} · ${top.demoMentions} mentions</span>` : ''}
        </span>
      </a>`;
  }).join('\n');

  const content = `  <section class="gs-hub">
    <p class="gs-section-marker">Référentiels d’autorité</p>
    <h1 class="gs-hub-title">Index des entités</h1>
    <p class="gs-hub-intro">Personnes, lieux, organisations, œuvres et autres entités identifiées dans le corpus par
      détection automatique (NER) puis réconciliées avec Wikidata. Chaque notice renvoie aux documents qui la citent.
      Les registres marqués <span class="gs-exp-badge" title="${EXP_TITLE}">exp.</span> sont expérimentaux :
      leur extraction automatique est encore en cours de validation.
      Démo : ${perimeter.size} entités citées dans les cinq documents présentés.</p>
    <div class="gs-hub-grid">
${cards}
    </div>
  </section>`;
  return pageShell({ depth: 1, title: 'Index des entités', bodyClass: 'gs-hub-page', content });
}

main();
