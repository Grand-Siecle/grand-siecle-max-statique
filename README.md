# Grand Siècle × MaX — démonstrateur statique

Projet de test **parallèle** à l'application TEI Publisher du projet
[Grand Siècle](../grand-siecle-TeiAPP) : reconstruire le maximum de ses
fonctionnalités et de son esthétique avec **MaX v1.1** (Moteur d'Affichage XML,
CERTIC / Pôle Document Numérique, Université de Caen), puis **geler le site en
statique** par crawl wget et redonner côté client ce qui meurt au gel
(recherche → Pagefind, browse d'entités → JSON + JS).

> Cadrage et protocole : `../grand-siecle-TeiAPP/docs/claude/test-max-statique.md` ;
> verdict de fond : `.../analyse-max-vs-teipublisher.md` (rester sur TEI Publisher —
> ce dépôt en éclaire le coût relatif, il ne remet pas ce verdict en cause).

## Résultat en bref

- **Corpus** : les 5 plus petits TEI du corpus (LIV0001, LIV0010, LIV0017, LIV0019,
  LIV0020 — 49,8 Mo), découpés en **888 pages** de lecture, fac-similés IIIF Gallica.
- **Entités** : **665 fiches d'autorité** (sur les 11 474 des 9 registres — celles
  citées par les 5 docs), 9 index A–Z servis par le plugin `index` de MaX, backlinks
  doc⇄entité, KWIC, identifiants Wikidata/VIAF/ISNI/GND/BnF/GeoNames.
- **Esthétique** : reprise du design system Grand Siècle (palette `--gs-*`,
  Cormorant/EB Garamond, couleurs par type d'entité, badges de confiance NER).
- **Statique intégral** : `static-site/` est servable par n'importe quel serveur
  HTTP (mesures : `docs/mesures-gel.md`).

```bash
# site gelé (aucune dépendance) :
python3 -m http.server 8899 --directory static-site
# → http://localhost:8899/grand-siecle/accueil.html
```

## Reconstruire de zéro

```bash
./scripts/install.sh    # BaseX embarqué + édition + préparation + chargement
./scripts/freeze.sh     # crawl wget + fusion fiches + Pagefind + mesures
```

Le site **dynamique** (avant gel) tourne sur http://localhost:1234/grand-siecle/
(`./max/basex/bin/basexhttp -h1234 -S` pour le relancer).

## Architecture

```
../grand-siecle-TeiAPP/data/*.tei.xml ─┐
                                       ├─ scripts/prepare-tei.mjs ──► TEI chunkés par page
../grand-siecle-TeiAPP/data/registers ─┤       (sourceDoc élagué : −68 %)  + facs/corpus JSON
                                       └─ scripts/build-entities.mjs ► 665 fiches HTML + JSON
                                                                        (browse, carte, frise,
                                                                         co-occurrences)
BaseX 10.7 + MaX v1.1 (max/) ◄── chargement (install.sh)
  └─ editions/grand-siecle/   TOUTES les surcharges (zéro modification du cœur) :
       text_hook.xsl          rendu TEI (couches orig/reg, entités NER, tokens w/pc)
       xq/…  ui/xsl/…         sommaires, fiche document, navbar, métadonnées, 9 index
       ui/css  ui/js  i18n    thème Grand Siècle, toolbar (couches, NER, linguistique)
       fragments/fr/          accueil, hub entités, carte (Leaflet), chronologie, à propos

scripts/freeze.sh :  wget --recursive  ─►  static-site/grand-siecle/
                     + fusion build/site-extra/registres/ (fiches hors MaX)
                     + postprocess (Pagefind attrs, recherche, Mirador→Gallica)
                     + npx pagefind (index + UI de recherche statique)
```

## Ce qui survit au gel / ce qui meurt (constat du test)

| Fonction | Dynamique (MaX/BaseX) | Après gel wget | Remplacement statique |
|---|---|---|---|
| Rendu TEI, couches orig/mod, entités, fac-similés | ✔ XSLT serveur | **survit tel quel** | — |
| Sommaires, fiche document, navigation de pages | ✔ | **survit** | — |
| Index d'entités A–Z (plugin `index`) | ✔ (cache fichier) | **survit** | + facettes/recherche instantanée client (`registres-browse.js`) |
| Fiches d'entités | ✘ n'existe pas dans MaX | — | **665 pages pré-générées** hors MaX (`build-entities.mjs`) |
| Recherche plein texte | ✔ mais rudimentaire (couche `orig` seule, ni tri ni pagination) | **morte** (endpoint BaseX) | **Pagefind** (+ filtres Type/Document) |
| Mirador (IIIF) | ✔ (route dynamique) | **morte** | liens réécrits vers le visualiseur Gallica |
| Carte / chronologie | déjà client (Leaflet + JSON) | **survit** | — |
| Bascule de langue (`setlang`, session serveur) | ✔ | **morte** | site monolingue fr (assumé) |
| Exports PDF / zip sources | possibles (FOP) | **morts** | pré-générables au besoin (non fait) |
| Slider de confiance NER, tooltips linguistiques | déjà client (`data-cert`, `data-lemma`) | **survit tel quel** | — |

## Ce qu'il a fallu écrire (l'argument central de la comparaison)

Côté TEI Publisher, tout ceci **existe nativement ou par profil Jinks** ; côté MaX
il a fallu l'écrire (tout est dans ce dépôt, aucune modification du cœur MaX) :

| Brique | Fichier(s) | Volume |
|---|---|---|
| Rendu TEI complet (le « ODD » de MaX) | `ui/xsl/tei/text_hook.xsl` | ~230 l. XSLT |
| Sommaire corpus riche + fiche document + navbar | `xq/toc.xq`, `xq/document_toc.xq`, 3 XSL | ~350 l. |
| 9 index d'entités (plugin `index` : « tout à écrire ») | `xq/index/*.xq` + `ui/xsl/index/*.xsl` | 18 fichiers |
| Fiches d'entités, backlinks, KWIC, exports JSON | `scripts/build-entities.mjs` | ~900 l. Node |
| Chunking par page + fac-similés (MaX ne pagine pas) | `scripts/prepare-tei.mjs` | ~400 l. Node |
| Thème Grand Siècle sur Bootstrap 5 | `ui/css/grand-siecle.css` + `registres.css` | ~1 700 l. CSS |
| Toolbar lecture (couches, NER, linguistique), popovers | `ui/js/grand-siecle.js` + `registres-browse.js` | ~800 l. JS |
| Gel + post-traitement + Pagefind | `scripts/freeze.sh`, `gen-seeds.mjs`, `postprocess-static.mjs` | ~300 l. |

Limites connues du démonstrateur : la recherche dynamique MaX ne voyait que la
couche originale (`tag=s`) — illustration de sa granularité limitée ; les entités
non réconciliées (UUID) n'ont pas de fiche (spans `ent-unresolved`) ; Google Fonts
est chargé depuis le CDN (à auto-héberger pour un déploiement réel) ; l'alignement
de témoins et le PDF (atouts propres de MaX) n'ont pas été exercés, le corpus ne
s'y prêtant pas.

## Mesures

Voir **`docs/mesures-gel.md`** (généré par `freeze.sh` : durée de crawl, tailles,
pages indexées) et les specs d'analyse dans **`docs/specs/`** (A : mécanique MaX,
B : design system, C : corpus TEI, D : registres, E : briques statiques).

## Licences / crédits

MaX (CeCILL-B) © Université de Caen Normandie — CERTIC / PDN.
Corpus et registres : Projet Grand Siècle (UNIL / UNIGE), CC BY 4.0.
Images : Gallica / BnF.
