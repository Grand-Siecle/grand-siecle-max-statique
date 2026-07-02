#!/usr/bin/env node
/**
 * Génère la liste des URLs de départ du crawl wget (scripts/freeze.sh) :
 * pages éditoriales, index, fiches documents et les 888 pages de lecture
 * (déduites de corpus.json — le sitemap MaX ne liste pas les fragments).
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const BASE = process.env.MAX_BASE_URL || 'http://localhost:1234/grand-siecle';

const corpus = JSON.parse(readFileSync(
  join(ROOT, 'max/editions/grand-siecle/ui/js/data/corpus.json'), 'utf-8'));

const urls = [
  'accueil.html', 'sommaire.html', 'search.html', 'entites.html',
  'carte.html', 'chronologie.html', 'about.html', 'sitemap.xml',
  ...['personnes', 'lieux', 'organisations', 'oeuvres', 'evenements',
    'objets', 'materiaux', 'techniques', 'dates'].map(s => `index/${s}.html`),
];

for (const [id, doc] of Object.entries(corpus.documents)) {
  urls.push(`sommaire/${id}.html`);
  for (const page of doc.pages) {
    urls.push(`${id}.xml/${id}-page-${page.n}.html`);
  }
}

const out = urls.map(u => `${BASE}/${u}`).join('\n') + '\n';
const dest = join(ROOT, 'build', 'seeds.txt');
writeFileSync(dest, out);
console.log(`${urls.length} URLs → ${dest}`);
