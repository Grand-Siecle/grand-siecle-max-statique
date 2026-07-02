# MISSION C — Rendu et préparation des 5 documents TEI de la démo

Spec pour la reconstruction statique (MaX v1 / BaseX + XSLT, gel wget, couche client Pagefind/JS)
des 5 documents TEI retenus. Tous les constats ci-dessous sont issus d'une analyse programmatique
exhaustive (ElementTree, comptes complets, pas d'échantillonnage partiel) des fichiers :

```
/home/rayondemiel/Projet_UNIL/grand-siecle-TeiAPP/data/LIV0001_reconciled.tei.xml  (11 773 713 o)
/home/rayondemiel/Projet_UNIL/grand-siecle-TeiAPP/data/LIV0010_reconciled.tei.xml  ( 6 775 094 o)
/home/rayondemiel/Projet_UNIL/grand-siecle-TeiAPP/data/LIV0017_reconciled.tei.xml  ( 9 821 534 o)
/home/rayondemiel/Projet_UNIL/grand-siecle-TeiAPP/data/LIV0019_reconciled.tei.xml  ( 7 427 727 o)
/home/rayondemiel/Projet_UNIL/grand-siecle-TeiAPP/data/LIV0020_reconciled.tei.xml  (14 046 548 o)
```

**Attention** : ces 5 fichiers suivent le pipeline « SegmOnto depuis ALTO » (Kraken + YALTAi + PyHellen
+ NER CamemBERT/GLiNER, documenté dans leur propre `encodingDesc/editorialDecl`), **pas** la structure
`div/head/p` classique des autres docs du corpus. Il n'y a **aucun `<head>`, `<quote>`, `<list>`,
`<hi>`, `<figure>`** dans les 5 body : la navigation ne peut être que **par page**, pas par chapitre.

Architecture cible (dépôt `/home/rayondemiel/Projet_UNIL/grand-siecle-max-statique`) :
- édition MaX : `max/editions/grand-siecle/` (config `grand-siecle_config_inc.xml`, XSLT dans `ui/xsl/`)
- script de préparation : `scripts/prepare-tei.mjs` (à créer, cf. §3)
- specs sœurs : `docs/specs/D-registres.md` (registres), `docs/specs/E-briques-statiques.md`

---

## 1. Métadonnées des 5 documents

### 1.1 Tableau récapitulatif (valeurs extraites, vérifiées)

| | LIV0001 | LIV0010 | LIV0017 | LIV0019 | LIV0020 |
|---|---|---|---|---|---|
| **Titre** | La Perpétuelle croix | Itinerarium | Dialogue des causes de la corruption de l'éloquence | Lettres touchant... la langue françoise | Considérations sur l'éloquence françoise de ce tems |
| **Auteur** | « s Andries » *(sic, = Judocus Andries)* | Louis-Henri de Loménie | Tacite *(trad. Louis Giry)* | François de La Mothe Le Vayer | François de La Mothe Le Vayer |
| **@ref auteur** | `#PERS0023` | `#PERS0037` | `#PERS0054` | `#PERS0016` | `#PERS0016` |
| **Vie** | 1588/04/15 – 1658/12/21 | 1635 – ? (Château-Landon) | 55 – ? | 1588/08/01 – 1672/05/09 | idem LIV0019 |
| **Date publ.** | 1659 | 1662 | 1630 | 1647 | 1638 |
| **Lieu** | Paris | Paris | Paris | Paris | Paris |
| **Libraire(s)/Éd.** | Florentin Lambert (`#PERS0022`), Hermann Weyer (`#PERS0024`) | Claude Cramoisy (`#PERS0038`), Jean du Bray (`#PERS0129`), éd. Charles Patin (`#PERS0128`) | Jean Camusat (`#PERS0013`), éd. Louis Giry (`#PERS0012`) | Nicolas (`#PERS0017`) et Jean (`#PERS0018`) de La Coste | Sébastien Cramoisy (`#PERS0019`) |
| **Cote BnF** | 8-Z LE SENNE-6243 | G-10903 | X-342 | 8-BL-1605 | X-18566 |
| **ark notice** | ark:/12148/cb31721367g | ark:/12148/cb30829649b | ark:/12148/cb31165844z | ark:/12148/cb39326672h | ark:/12148/cb307298680 |
| **ark images Gallica** | `bpt6k8597163` | `bpt6k1065194` | `btv1b8620790x` | `bpt6k1043573t` | `bpt6k87018271` |
| **Images** (`extent/measure/@n`) | 259 | 124 | 166 | 137 | 236 |
| **Langues** (`@ident` / `@usage`) | fra 510, lat 47, grc 10 | **lat 196**, fra 72 | fra 323, lat 76 | fra 325, lat 37 | fra 486, lat 53 |

Pièges de qualité de données à absorber tel quel :
- LIV0001 : `<forename>s</forename>` (prénom tronqué) — afficher « Andries » seul ou corriger via une table d'overrides dans le script.
- LIV0017 : l'auteur déclaré est **Tacite** (l'œuvre est la traduction Giry) ; `death` absent.
- LIV0010 : `death/@when` absent (seul le lieu est donné) ; `settlement` = « Information not available. » à filtrer.
- `language/@usage` n'est **pas** un pourcentage (lat 196 + fra 72 = 268 pour LIV0010) : c'est un compte de zones/lignes. À afficher comme proportion relative seulement.

### 1.2 XPaths teiHeader fiables (identiques dans les 5 docs) pour le sommaire

```xpath
titre        : /TEI/teiHeader/fileDesc/titleStmt/title[1]
auteur       : /TEI/teiHeader/fileDesc/titleStmt/author
               → persName/(forename, surname), @ref, persName/ptr[@type=('ark','isni')]/@target
vie          : author/birth/@when, author/birth/placeName, author/death/@when, author/death/placeName
date publ.   : /TEI/teiHeader/fileDesc/sourceDesc/bibl/date
lieu         : /TEI/teiHeader/fileDesc/sourceDesc/bibl/pubPlace
imprimeurs   : /TEI/teiHeader/fileDesc/sourceDesc/bibl/respStmt   (resp = 'Libraire'|'Éditeur',
               persName/@ref = #PERSnnnn, prénom/nom en enfants)
cote         : sourceDesc/msDesc/msIdentifier/idno[not(@type)]
id interne   : sourceDesc/msDesc/msIdentifier/altIdentifier/idno[@type='internal']   (= LIV0001…)
ark notice   : sourceDesc/msDesc/msIdentifier/idno[@type='ark']
manifest IIIF: sourceDesc/msDesc/msIdentifier/idno[@type='iiif']
nb images    : fileDesc/extent/measure[@unit='images']/@n
langues      : profileDesc/langUsage/language (@ident, @usage)
bio auteur/libraires : profileDesc/particDesc/listPerson/person[@xml:id='PERSnnnn']
               (persName, birth/death/@when, occupation = notice BnF longue, idno[@type='isni'|'ark'])
```

**Point crucial** : l'ark des **images** Gallica (`bpt6k…`/`btv1b…`) ne figure que dans
`idno[@type='iiif']` — l'`idno[@type='ark']` (`cb…`) est l'ark de la **notice catalogue**, inutilisable
pour les images. Extraction : `substring-before(substring-after(idno-iiif, 'ark:/12148/'), '/manifest.json')`.

Les `@ref="#PERSnnnn"` du header se résolvent **localement** dans
`profileDesc/particDesc/listPerson/person[@xml:id]` du même fichier (notices BnF riches :
occupation, isni, ark) — pas dans les registres externes.

---

## 2. Structure du corps

### 2.1 Inventaire complet des éléments du `body` (comptes exacts)

Chaque body = `body > div` **unique, sans attribut**. Les seuls enfants du `div` sont
`pb | ab | fw | note` (aucun autre, vérifié sur les 5 docs).

| Élément | LIV0001 | LIV0010 | LIV0017 | LIV0019 | LIV0020 |
|---|---:|---:|---:|---:|---:|
| `pb` | 246 | 124 | 163 | 129 | 226 |
| `ab` | 166 | 118 | 147 | 125 | 219 |
| `fw` | 333 | 148 | 255 | 218 | 195 |
| `note` | 56 | 0 | 1 | 4 | 112 |
| `lb` | 4 055 | 2 464 | 3 546 | 2 763 | 5 313 |
| `choice` = `orig` = `reg` | 3 041 | 2 108 | 3 222 | 2 281 | 4 478 |
| `s` | 4 386 | 2 944 | 3 691 | 2 967 | 5 655 |
| `w` | 21 551 | 13 612 | 24 227 | 16 248 | 31 410 |
| `pc` | 5 003 | 3 258 | 3 749 | 2 471 | 4 342 |
| `foreign` | 67 | 3 | 3 | 74 | 64 |
| `persName` | 175 | 107 | 200 | 70 | 251 |
| `placeName` | 20 | 222 | 11 | 6 | 18 |
| `orgName` | 3 | 0 | 16 | 2 | 22 |
| `rs` | 2 | 6 | 14 | 6 | 14 |
| `title` (œuvres NER) | 3 | 2 | 8 | 21 | 38 |
| `objectName` | 0 | 0 | 0 | 3 | 0 |
| `material` | 1 | 4 | 4 | 5 | 7 |
| `date` (NER) | 0 | 12 | 1 | 0 | 2 |

Absents partout : `head`, `p`, `quote`, `q`, `list`, `item`, `hi`, `figure`, `graphic`, `unclear`,
`gap`, `supplied`, `lg`, `l`, `seg`, `milestone`, `table`.

### 2.2 Les `<pb>` — RÉPONSE FERME : tous enfants directs du `<div>`

**Comptage exhaustif : 888 `pb` sur les 5 documents, 888 ont pour parent `div`, 0 apparaissent
dans un `ab`** (`pb_parent_tags = {'div': N}` pour chacun des 5 fichiers). Aucune zone n'est à
cheval sur deux pages : chaque `ab` est une zone de mise en page ALTO, par construction propre à
une seule image.

Vérification complémentaire : les chaînes `s[@next]` (12 776 fragments) et `w[@next]` (4 506 mots
coupés) ont été suivies — **0 chaîne ne franchit une frontière de page**. Les phrases et mots coupés
se recollent uniquement de ligne à ligne *à l'intérieur* d'un même `ab`.

→ **Algorithme de découpage trivial et sûr** : itérer les enfants du `div` en ordre de document ;
chaque `pb` ouvre une page ; tout `ab|fw|note` qui suit appartient à la page courante, jusqu'au `pb`
suivant. Pas de gestion de zones à cheval. Le script doit néanmoins **asserter** `pb[parent::div]`
et échouer bruyamment si un autre doc du corpus violait l'invariant.

Séquence type (début de LIV0010) : `pb, pb, pb, pb, ab, pb, ab, pb, ab, fw, pb, ab…` — plusieurs
`pb` consécutifs = pages **sans transcription** (pages de titre, gravures, gardes) : produire quand
même une page (fac-similé seul).

### 2.3 Mapping page → image IIIF Gallica

Forme réelle : `<pb corresp="#f0-np"/>` (**seul attribut : `@corresp`**, jamais `@n` ni `@facs`).

Motifs des `@corresp`, tous résolus vers un `surface/@xml:id` du `sourceDoc` (vérifié : 100 % de
correspondance sur 888 pb) :

| Doc | Motif | Exemples |
|---|---|---|
| LIV0010 | `#fN-np` (28, non paginées) puis `#fN-M` (96, M = **numéro de page imprimé**) | `#f0-np`, `#f100-75` |
| Les 4 autres | `#fN` | LIV0019 commence à `#f4` ; LIV0001 saute (`#f2, #f3, #f9, #f11…`) |

Structure côté `sourceDoc` :

```xml
<surface xml:id="f0-np" n="0" ulx="0" uly="0" lrx="1762" lry="2500">
  <graphic url="https://gallica.bnf.fr/iiif/ark:/12148/bpt6k1065194/f1/full/full/0/native.jpg"/>
  <zone type="GraphicZone" …>…</zone>
</surface>
```

**Algorithme exact** (le seul fiable) :
1. `id = substring-after(pb/@corresp, '#')`
2. `surface = sourceDoc/surface[@xml:id = id]`
3. `url = surface/graphic/@url` → c'est l'URL IIIF Image API de la page, motif
   `https://gallica.bnf.fr/iiif/ark:/12148/{arkImages}/f{i}/full/full/0/native.jpg`.
4. Dimensions : `surface/@lrx` × `surface/@lry` (ratio d'aspect pour réserver l'espace en CSS).

**Ne jamais recalculer l'index Gallica `f{i}` depuis `@n`** : LIV0010 est 0-basé avec décalage
(`surface n="0"` → `…/f1/…`) alors que les 4 autres sont 1-basés (`surface f1 n="1"` → `…/f1/…`).
Toujours lire `graphic/@url`.

**Piège majeur** : les `zone/@source` (6 025 URLs dans LIV0020) sont **cassés** — ils pointent vers
un faux ark construit sur l'id interne : `https://gallica.bnf.fr/iiif/ark:/12148/LIV0020_reconciled/ff2/353.0,256.0,…`.
À ignorer totalement. Pour un crop de ligne éventuel, reconstruire :
`https://gallica.bnf.fr/iiif/ark:/12148/{arkImages}/f{i}/{ulx},{uly},{lrx-ulx},{lry-uly}/full/0/native.jpg`
à partir des coordonnées de la `zone` et de l'ark réel.

Variantes de taille recommandées pour la démo (syntaxe IIIF Gallica) : remplacer `full/full/0/native.jpg`
par `full/,1200/0/native.jpg` (affichage) et `full/,300/0/native.jpg` (vignettes) — à générer dans
le JSON de mapping, pas à la volée côté XSLT.

**Surfaces sans `pb`** (images numérisées non transcrites — plats, gardes, feuillets sautés) :
LIV0001 : 13 (`f1, f4, f5, f10, f12, f18, f253–258…`) · LIV0010 : 0 · LIV0017 : 3 (`f15, f160, f164`) ·
LIV0019 : 8 (`f1–f3, f132–f136`) · LIV0020 : 10 (`f1, f3–f5, f18, f230–236…`). Le JSON de mapping
(§3) les conserve avec `"pb": false` ; le viewer peut les proposer en mode « feuilleter » mais elles
n'ont pas de page de texte.

### 2.4 `<fw>` — pièces de forme (1 149 au total)

Forme : `<fw corresp="#zone_…" type="…" xml:lang="fra"><lb corresp="#zoneLine_…"/>texte</fw>`,
toujours enfant du `div` (jamais dans `ab`). **Pas d'attribut `@place`.** Trois types SegmOnto :

| `@type` | LIV0001 | LIV0010 | LIV0017 | LIV0019 | LIV0020 | Sens |
|---|---:|---:|---:|---:|---:|---|
| `RunningTitleZone` | 123 | 81 | 139 | 124 | 2 | Titre courant |
| `NumberingZone` | 151 | 34 | 58 | 65 | 137 | Numéro de page imprimé |
| `QuireMarksZone` | 59 | 33 | 58 | 29 | 56 | Signature de cahier (« A ij », « ã ») — pas de réclames identifiées comme telles |

Rendu (§4) : masqués par défaut (bruit OCR fréquent), affichables via toggle « éléments de forme » ;
exception : `NumberingZone` sert d'étiquette de pagination imprimée dans le coin du bloc page.

### 2.5 `<ab type="…">` — zones SegmOnto

**Un seul type dans les 5 body : `MainZone`** (775 `ab`, 100 %). Attributs constants :
`@corresp` (→ `zone` du sourceDoc), `@type`, `@xml:lang` (LIV0010 : 117 lat + 1 fra ;
LIV0001 : 163 fra + 3 lat ; les autres 100 % fra). Aucun texte directement sous `ab`
(`ab_with_direct_text = 0` partout) : contenu = suite de `lb`, `choice`, `s`, `foreign`.

Les autres zones SegmOnto existent mais **hors `ab`** : `MarginTextZone` → `<note>` (§2.8),
`RunningTitleZone|NumberingZone|QuireMarksZone` → `<fw>`, `TitlePageZone|GraphicZone|StampZone|TextBlock|DefaultLine`
→ **uniquement dans `sourceDoc`** (les pages de titre ne sont *pas* transcrites dans le body ;
elles apparaissent comme des `pb` consécutifs sans `ab`). Le rendu n'a donc à traiter que `MainZone`,
mais l'XSLT prévoira un gabarit générique `ab[@type]` → `div.zone.zone-{type}` pour les autres docs
du corpus.

### 2.6 `<choice><orig>/<reg>` — la double couche, structure exacte

Le motif est **par ligne d'impression** : chaque ligne modernisable est encodée

```xml
<lb corresp="#zoneLine_541563c5f974487983868c8a6bb10584"/>
<choice>
  <orig>
    <s xml:id="s_b800ad1aff36_7" part="M" next="#s_b800ad1aff36_8" prev="#s_b800ad1aff36_6">
      <w lemma="contenir" pos="VERcjg" msd="MODE=ind|TEMPS=pst|PERS.=3|NOMB.=s">Contient</w>
      <w lemma="en" pos="ADVgen" msd="MORPH=empty">en</w>
      <w lemma="se" pos="PROper" msd="PERS.=3|NOMB.=s|CAS=i">soy</w>
      …
    </s>
  </orig>
  <reg type="modernized">Contient en soi ce que <persName resp="#ner-auto" cert="mid"
       ref="#person-000116">Quintilien</persName></reg>
</choice>
```
*(extrait réel, LIV0020 l. 25470–25483)*

Constats fermes (comptes sur les 5 docs) :
- `choice` a **toujours** exactement les enfants `(orig, reg)` ; `reg` porte **toujours**
  `@type="modernized"` ; `orig` ne contient **que** des `s` (1..n).
- **`s` hors `choice` = lignes non modernisées** : 336 (LIV0001 : 827, LIV0010 : 336, LIV0017 : 163,
  LIV0019 : 323, LIV0020 : 483) directement sous `ab`, plus quelques-uns sous `note`. C'est documenté
  dans l'`editorialDecl` de chaque fichier : *« Lines whose modernized form diverges too far from the
  original (word-count ratio or character-level similarity after normalization below 0.8) are left
  unmodified. »* → le rendu doit afficher ces `s` dans **les deux couches** (fallback orig).
- `s/@part` = `I|M|F` + `@next/@prev` : chaîne d'une **phrase** répartie sur plusieurs lignes
  (ex. LIV0010 : 569 I / 1 447 M / 569 F / 359 sans @part = phrase entière sur une ligne).
  Les chaînes ne traversent jamais une page (§2.2).
- `w` : `@lemma`, `@pos`, `@msd` à ~100 % (LIV0001 : 9 `w` sans lemma, 68 sans msd — grec OCR) ;
  `@norm` épisodique (LIV0010 : 4 598, LIV0019 : 1 084 — forme normalisée du token) ;
  mots coupés en fin de ligne : `@xml:id="w_9c4a6d2fe51b_0" part="I" next="#w_9c4a6d2fe51b_1"`
  (684 à 1 422 paires par doc). **Deux tagsets `@msd`** : latin (`Case=|Numb=|Gend=|Mood=|Tense=|Voice=`)
  et français (`NOMB.=|GENRE=|MODE=|TEMPS=|PERS.=|CAS=`) ; `@pos` : `NOMcom, NOMpro, VER/VERcjg,
  ADJqua, PROper, DETpos…` (PyHellen).
- `pc` : ponctuation ; `@join="left"` majoritaire (coller au mot précédent, pas d'espace avant :
  2 006–4 023 par doc), `@join="right"` rare (1–31), sans `@join` (439–949, ex. `<pc>&amp;</pc>`)
  = token autonome espacé des deux côtés.
- La couche `reg` est du **texte brut de la ligne** (plus les entités inline, cf. §2.7) — pas de `w`.
- **LIV0010 (latin)** : les `reg type="modernized"` existent (2 108) mais sont produits par le modèle
  de modernisation *du français* → qualité douteuse (« J libellum à me malo furto subrepVtum »).
  Recommandation : couche par défaut = `orig` pour LIV0010, `reg` pour les 4 autres (drapeau par doc
  dans le JSON de config, §3).

### 2.7 Entités nommées inline — inventaire complet

Combinaisons élément + `@type` + préfixe de `@ref` (comptes exacts) :

| Élément[@type] | Préfixe @ref | LIV0001 | LIV0010 | LIV0017 | LIV0019 | LIV0020 |
|---|---|---:|---:|---:|---:|---:|
| `persName` | `#person-NNNNNN` | 175 | 99 | 200 | 70 | 251 |
| `persName` | *(sans @ref)* | — | 8 | — | — | — |
| `placeName` | `#place-NNNNNN` | 20 | 210 | 10 | 6 | 18 |
| `placeName` | *(sans @ref)* | — | 12 | — | — | — |
| `placeName` | `#person-NNNNNN` (**anomalie**) | — | — | 1 | — | — |
| `orgName` | `#org-NNNNNN` | 3 | — | 16 | 2 | 22 |
| `rs[@type='event']` | `#event-NNNNNN` | 2 | 6 | 12 | 1 | 4 |
| `rs[@type='event']` | `#event-<uuid>` (**non réconcilié**) | — | — | — | 2 | — |
| `rs[@type='technique']` | `#technique-NNNNNN` | — | — | 2 | 3 | 10 |
| `title` | `#work-NNNNNN` | 3 | 2 | 8 | 21 | 38 |
| `objectName` | `#artwork-NNNNNN` | — | — | — | 3 | — |
| `material` | `#material-NNNNNN` | 1 | 4 | 4 | 5 | 7 |
| `date` | `#date-NNNNNN` | — | 8 | 1 | — | 2 |
| `date` | *(sans @ref)* | — | 4 | — | — | — |

- Les ids `#type-NNNNNN` (6 chiffres) résolvent dans les registres
  (`data/registers/persons.xml` : `person-000116` ✓, `places.xml` : `place-001965` ✓,
  `works.xml` : `work-000114` ✓ — vérifié). Cf. `docs/specs/D-registres.md` pour les pages cibles.
- Les refs `#…-<uuid>` résolvent **localement** : `standOff/listBibl/bibl[@xml:id='work-<uuid>']`,
  `standOff/listEvent/event`, `profileDesc/settingDesc/listPlace/place` — entités NER non
  réconciliées ; **pas de lien registre**, rendre le span sans `href` avec `data-unresolved="true"`.
- `@resp="#ner-auto"` sur 100 % des entités (347/87/242/200/307 par doc) — pointe vers
  `editionStmt/respStmt[@xml:id='ner-auto']` (« NER Pipeline (CamemBERT + GLiNER) »).
- `@cert` : uniquement `mid` et `high` dans ces 5 docs (**aucun `low`**, seuils documentés :
  low < 0.6, mid 0.6–0.85, high > 0.85). Distribution : LIV0001 pers 78 high/97 mid ;
  LIV0010 pers 16/91, lieux 27/195 ; LIV0017 pers 111/89 ; LIV0019 pers 37/33 ; LIV0020 pers 142/109.
- Entités coupées sur deux lignes : `@xml:id="ent-805bdfc9-0" next="#ent-805bdfc9-1"` (7–14 par doc) —
  rendre chaque fragment comme span, relier via `data-next` (pas de fusion nécessaire pour la démo).

**Asymétrie de couche, décisive pour le rendu** (parent des entités) :
- **LIV0010** : entités dans la couche `orig`, *à l'intérieur des `s`*, enveloppant des `<w>`
  (105 persName dans `s`, 2 dans `reg`) :
  `<persName resp="#ner-auto" cert="mid" ref="#person-004299"><w lemma="Eugenius" …>Eugenium</w></persName>`.
- **LIV0017 / LIV0019 / LIV0020** : entités dans la couche `reg` (texte brut) à ~100 %.
- **LIV0001** : `reg` (172) + 3 dans `s`.
→ L'XSLT doit traiter `persName|placeName|…` **dans les deux contextes** (enfant de `s` avec des `w`
dedans, ou mixte dans `reg`), et le toggle orig/reg ne doit pas faire disparaître les entités du doc
latin (encore une raison de défaut = `orig` pour LIV0010).

### 2.8 `<foreign>`, notes, autres

- `foreign` : toujours **dans un `s`** (couche orig), avec `@xml:lang` (`lat` dans les docs français,
  `fra`/`grc` ailleurs ; LIV0001 : 67 dont grec à l'OCR très dégradé), contenant des `w` (avec le
  tagset de la langue). Rendu : `<span class="foreign" lang="…">` en italique.
- `note` : **toutes** de la forme `<note corresp="#zone_…" type="MarginTextZone" xml:lang="…">`
  avec `lb` + (`choice` | `s` | texte) — ce sont les **manchettes/notes marginales** (0/0/1/4/112 +
  LIV0001 : 56). Enfants du `div`, positionnées dans le flux de leur page. Rendu : `<aside
  class="marginal-note">` dans une colonne de marge CSS. NB : dans les notes (et parfois `foreign`),
  les `lb` sont *à l'intérieur* des `s` (LIV0020 : 109 `lb` dans `s`) — l'XSLT doit accepter `lb` à
  toute profondeur.
- `head`, `quote`, listes : **absents** (§2.1). Pas de sommaire interne possible ; le « sommaire »
  d'un doc = grille de pages (vignettes IIIF + n° imprimé si connu).
- `standOff` (après `text`) : `listBibl` + `listEvent` d'entités NER non réconciliées (labels bruts) —
  **à conserver** (cibles des refs UUID, §2.7), poids négligeable (~75 lignes).
- `profileDesc` : `settingDesc/listPlace` (UUID, jusqu'à 151 places pour LIV0010),
  `particDesc/listPerson` (`PERS####`, notices BnF) — à conserver (résolution header + refs UUID).

### 2.9 `sourceDoc` : contenu, poids — verdict : ÉLAGUER

Contenu : `surface` (× nb images) > `graphic` (URL IIIF) + arbre de `zone` typées SegmOnto
(`MainZone`, `TextBlock`, `TitlePageZone`, `GraphicZone`, `StampZone`, `MarginTextZone`,
`RunningTitleZone`, `NumberingZone`, `QuireMarksZone`, et une `zone type="DefaultLine"` **par ligne**)
contenant chacune `path[@points]` (polygone) + `line` (texte OCR brut, redondant avec le body).

| Doc | Total | teiHeader | sourceDoc | `text` | Part sourceDoc |
|---|---:|---:|---:|---:|---:|
| LIV0001 | 11 773 713 | 20 598 | 8 524 571 | 3 227 814 | **72,4 %** |
| LIV0010 | 6 775 094 | 41 227 | 4 370 826 | 2 362 088 | **64,5 %** |
| LIV0017 | 9 821 534 | 25 299 | 6 380 276 | 3 413 985 | **65,0 %** |
| LIV0019 | 7 427 727 | 19 910 | 5 030 733 | 2 374 476 | **67,7 %** |
| LIV0020 | 14 046 548 | 34 372 | 9 430 729 | 4 578 607 | **67,1 %** |
| **Total** | **49,84 Mo** | 0,14 Mo | **33,74 Mo (67,7 %)** | 15,96 Mo | |

Le seul contenu de `sourceDoc` utile à la démo est le triplet `surface/@xml:id → graphic/@url +
dimensions`. Les polygones (`path/@points`, `zone/@points` — des centaines de coordonnées par ligne)
et le texte OCR `line` ne servent à rien côté statique (pas de surlignage image-texte prévu), et les
URLs de crop `zone/@source` sont cassées (§2.3). **Décision : extraire le mapping en JSON puis
supprimer `sourceDoc` du TEI servi à BaseX.** Gain : −67,7 % (49,8 → 16,1 Mo pour 5 docs).

---

## 3. Spec du script de préparation (Node.js)

### 3.1 Fiche

- **Fichier** : `/home/rayondemiel/Projet_UNIL/grand-siecle-max-statique/scripts/prepare-tei.mjs`
- **Entrée** : `../grand-siecle-TeiAPP/data/{LIV0001,LIV0010,LIV0017,LIV0019,LIV0020}_reconciled.tei.xml`
  (chemin source passé en argument `--src`).
- **Sorties** :
  - `max/editions/grand-siecle/data/tei/{ID}.xml` — TEI chunké (chargé dans la base BaseX
    `dbpath="grand-siecle"` déclarée dans `max/editions/grand-siecle/grand-siecle_config_inc.xml`) ;
  - `max/editions/grand-siecle/ui/js/data/facs/{ID}.json` — mapping page → image (consommé côté client) ;
  - `max/editions/grand-siecle/ui/js/data/corpus.json` — métadonnées des 5 docs (sommaire, §1.2).
- **Dépendances** : `@xmldom/xmldom` (DOM) ou `saxes` (streaming). À 14 Mo max le DOM est
  acceptable (~10× en RAM, < 400 Mo) ; DOM recommandé pour la simplicité et parce qu'on réordonne
  des nœuds. Aucune regex sur le XML.

### 3.2 Algorithme (par document)

1. **Parser** le fichier ; vérifier `TEI/@xml:id` (`ark_12148_{ID}_reconciled`).
2. **Extraire le mapping fac-similé** avant toute suppression :
   ```js
   // pour chaque sourceDoc/surface
   { "id": "f0-np", "n": 0, "printed": null | "75",     // depuis le motif fN-M de LIV0010
     "url": graphic.getAttribute('url'),                 // …/full/full/0/native.jpg
     "view": url.replace('full/full/0/native', 'full/,1200/0/native'),
     "thumb": url.replace('full/full/0/native', 'full/,300/0/native'),
     "w": +surface.lrx, "h": +surface.lry,
     "pb": <true si un pb @corresp le référence> }
   ```
   Écrire `facs/{ID}.json` : `{ "ark": "bpt6k1065194", "surfaces": [ … ] }` (ark extrait de
   `idno[@type='iiif']`, cf. §1.2).
3. **Extraire les métadonnées** (XPaths §1.2) → entrée dans `corpus.json`, avec
   `"defaultLayer": "orig"` pour LIV0010, `"reg"` sinon, et la table d'overrides
   (auteur LIV0001 → « Judocus Andries »).
4. **Chunker le body** : remplacer le contenu du `div` unique par des divs de page.
   ```
   pageSeq = 0 ; pageDiv = null
   pour chaque enfant E de body/div (ordre de document) :
     si E est <pb> :
        assert(E.parentNode === div)            # invariant §2.2
        pageSeq += 1 ; facsId = substring-after(E@corresp, '#')
        pageDiv = <div xml:id="page-{pageSeq}" type="page" n="{pageSeq}"
                       corresp="#{facsId}" facs="{facs[facsId].url}"/>
        (le pb lui-même n'est PAS recopié : il est remplacé par le div)
     sinon (ab | fw | note) :
        si pageDiv == null : créer page-0 de garde (non observé sur les 5 docs — les body
                             commencent tous par un pb) ;
        déplacer E dans pageDiv
   ```
   Le numéro **imprimé** (LIV0010 `fN-M`, sinon 1er `fw[@type='NumberingZone']` de la page) est
   ajouté en `@corresp` secondaire ? Non — le garder uniquement dans `facs/{ID}.json` (`printed`)
   pour ne pas surcharger le TEI ; MaX le lira côté client.
5. **Élaguer** : supprimer le nœud `sourceDoc` entier. Conserver intégralement `teiHeader`
   (avec `particDesc`/`settingDesc`) et `standOff`.
6. **Sérialiser** avec la déclaration XML d'origine ; pretty-print inutile (les fichiers sources
   sont déjà indentés ; ne pas ré-indenter pour ne pas altérer le texte mixte de `reg`).
7. **Contrôles de sortie** (le script échoue si faux) :
   - `count(//div[@type='page']) == count(pb source)` ;
   - aucun `pb` restant ; aucun `sourceDoc` ;
   - tous les `@facs` non vides ; tous les `ab|fw|note` déplacés (div racine vide de tout sauf pages) ;
   - XML re-parsable.

### 3.3 Gestion des cas identifiés

| Cas | Traitement |
|---|---|
| `pb` consécutifs (pages non transcrites) | div de page vide (fac-similé seul) — le gabarit affiche l'image + mention « page non transcrite » |
| Surfaces sans `pb` (34 au total) | absentes du TEI, présentes dans `facs/{ID}.json` avec `"pb": false` (mode feuilletage) |
| `ab` à cheval sur deux pages | **n'existe pas** (0/888, §2.2) ; assert de garde uniquement |
| Refs UUID (`#event-<uuid>`…) | inchangées ; résolues à la XSLT contre `standOff`/`profileDesc` du même fichier |
| `zone/@source` cassés | supprimés avec `sourceDoc` |

### 3.4 Estimation de la taille résultante

Taille ≈ `teiHeader + standOff + text` + ~90 o par page de wrapper div (négligeable) :

| Doc | Avant | Après (estimé) | Pages (`div[@type='page']`) | Moy./page |
|---|---:|---:|---:|---:|
| LIV0001 | 11,77 Mo | **≈ 3,26 Mo** | 246 | ~13,3 Ko |
| LIV0010 | 6,78 Mo | **≈ 2,41 Mo** | 124 | ~19,4 Ko |
| LIV0017 | 9,82 Mo | **≈ 3,44 Mo** | 163 | ~21,1 Ko |
| LIV0019 | 7,43 Mo | **≈ 2,40 Mo** | 129 | ~18,6 Ko |
| LIV0020 | 14,05 Mo | **≈ 4,62 Mo** | 226 | ~20,4 Ko |
| **Total** | **49,84 Mo** | **≈ 16,13 Mo (−68 %)** | 888 | |

Pour le gel wget, chaque page HTML rendue pèsera l'équivalent d'un div de page transformé
(~20 Ko de TEI → ~30–45 Ko de HTML avec les `data-*`) : 888 pages ≈ **30–40 Mo de HTML**, tout à
fait crawlables ; BaseX ne rendra jamais un body de 4 Mo d'un coup si MaX pagine sur
`//div[@type='page']`.

---

## 4. Règles de rendu XSLT

XSLT à placer dans `max/editions/grand-siecle/ui/xsl/` (surcharge des templates MaX, `mode="tei"`).
Namespace TEI partout. Cible : HTML5, aucune dépendance JS obligatoire pour la lecture (le toggle
et les tooltips sont progressifs).

### 4.1 Table élément → HTML

| TEI | HTML cible |
|---|---|
| `div[@type='page']` | `<section class="page" id="{@xml:id}" data-n="{@n}" data-facs="{@facs}">` — deux colonnes : fac-similé (`<img src="{view}" loading="lazy" width="{w}" height="{h}">` depuis `facs/{ID}.json`) + transcription |
| `ab[@type='MainZone']` | `<div class="zone zone-mainzone" lang="{@xml:lang}">` (gabarit générique `zone-{lower(@type)}` pour extension) |
| `lb` | `<br class="lb"/>` **avant** le contenu de la ligne (sauter le 1er `lb` d'un bloc pour éviter la ligne vide). Accepter `lb` à toute profondeur (dans `s`, `note`, `foreign` — §2.8) |
| `choice` | `<span class="line-choice">` contenant **les deux couches** rendues (§4.2) |
| `orig` | `<span class="layer layer-orig">` |
| `reg[@type='modernized']` | `<span class="layer layer-reg">` |
| `s` | `<span class="s" id="{@xml:id}" data-part="{@part}">` ; les `s` hors `choice` (non modernisés, §2.6) sont enveloppés `<span class="line-choice line-unmodernized">` et **dupliqués visuellement dans les deux couches** (classe `layer-both`, jamais masquée) |
| `w` | `<span class="w" data-lemma="{@lemma}" data-pos="{@pos}" data-msd="{@msd}" data-norm="{@norm}">texte</span>` — pas de `title=` natif : tooltip unique délégué en JS (lecture des `data-*`), pour un HTML plus léger et un rendu i18n des deux tagsets msd (latin/français, §2.6) |
| `w[@part='I']` | ajouter `data-next="{@next}"` ; CSS `.w[data-next]::after{content:'\2011'}` optionnel pour matérialiser la césure |
| `pc` | `<span class="pc" data-join="{@join}">` ; règle d'espacement **dans l'XSLT** : émettre `' '` entre tokens sauf avant `pc[@join='left']` et après `pc[@join='right']` |
| `fw` | `<div class="fw fw-{lower(@type)}" hidden>` sauf `NumberingZone` → `<span class="fw fw-numbering">` affiché en coin de page ; toggle global « éléments de forme » retire `hidden` |
| `note[@type='MarginTextZone']` | `<aside class="marginal-note" lang="{@xml:lang}">` — flottée dans la marge (CSS grid : colonne notes), contenu rendu avec les mêmes règles (`choice`, `s`, `lb`) |
| `foreign` | `<span class="foreign" lang="{@xml:lang}">` (italique CSS `[lang='lat'], [lang='grc']`) |
| entités (§4.3) | `<a>`/`<span>` avec `data-ref/data-cert/data-type` |
| `pb` | n'existe plus après chunking (remplacé par `section.page`) ; template de garde : ignorer |
| `standOff`, `teiHeader` | jamais rendus dans le flux ; lus par les templates de métadonnées (fiche doc) et par la résolution d'entités UUID |

### 4.2 Double couche orig/reg basculable

Chaque `choice` produit les **deux** couches dans le HTML ; la bascule est purement CSS :

```css
html[data-layer='reg']  .layer-orig { display:none }
html[data-layer='orig'] .layer-reg  { display:none }
.line-choice.line-unmodernized .layer-both { display:inline } /* toujours visible */
```

- Bouton toggle (JS ~10 lignes) : `document.documentElement.dataset.layer = 'orig'|'reg'`,
  persisté en `localStorage`.
- **Défaut par document** : `data-layer` initial injecté par MaX depuis `corpus.json`
  (`orig` pour LIV0010 — entités et fiabilité dans la couche originale, §2.6/§2.7 ; `reg` sinon).
- Coût accepté : ~2× le texte des lignes modernisées dans le HTML (justifie le chunking par page).

### 4.3 Entités : spans `data-*`

Règle commune à `persName | placeName | orgName | rs[@type] | title[@ref] | objectName | material |
date[@ref]`, valable dans les **deux** contextes (enfant de `reg`, ou de `s` autour de `w` — §2.7) :

```xml
<!-- @ref = #person-000116 (résolu registre) -->
<a class="ent ent-person" href="{base}/registres/person/person-000116.html"
   data-ref="person-000116" data-type="person" data-cert="mid" data-resp="ner-auto">Quintilien</a>

<!-- @ref UUID ou absent (non résolu) -->
<span class="ent ent-event ent-unresolved" data-ref="event-c1695b57-…" data-type="event"
      data-cert="mid">Les</span>
```

- Mapping élément→`data-type` : `persName→person`, `placeName→place`, `orgName→organization`,
  `rs[@type='event']→event`, `rs[@type='technique']→technique`, `title→work`,
  `objectName→artwork`, `material→material`, `date→date` (aligné sur les slugs de
  `docs/specs/D-registres.md`).
- Lien ssi `matches(@ref, '^#[a-z]+-[0-9]{6}$')` ; sinon span `ent-unresolved` (2 UUID event
  LIV0019, 24 sans @ref LIV0010, 1 anomalie `placeName→#person-…` LIV0017 : typer selon le
  **préfixe du ref**, pas selon l'élément).
- `@cert` → `data-cert` (`mid|high` seulement dans ces docs) : liseré CSS
  (`.ent[data-cert='mid']{border-bottom-style:dotted}`), badge dans le popover.
- Popover entité (JS délégué, même mécanique que le tooltip `w`) : label + type + cert + lien registre.
- Entités fragmentées (`@xml:id="ent-…-0"/@next`) : reporter `id` et `data-next` ; pas de fusion.

### 4.4 Tooltip linguistique sur `w`

Un unique écouteur délégué (`mouseover`/`focusin` sur `.zone`) lit `data-lemma/pos/msd/norm` et
affiche un tooltip : ligne 1 `lemme (pos traduit)`, ligne 2 msd décodé — deux tables de décodage
(tagset latin `Case=…`, tagset français `NOMB.=…`), `MORPH=empty` → rien ; `data-norm` affiché comme
« forme normalisée ». Activable/désactivable (toggle « analyse linguistique ») car 31 410 `w` sur
LIV0020 : ne **jamais** générer un tooltip DOM par mot.

### 4.5 Navigation de page

- `section.page` = unité de rendu MaX (pagination BaseX sur `//div[@type='page']`) et une page
  HTML gelée par wget : `documents/{ID}/page-{n}.html` + `prev/next` + `<select>` de pages
  (n° séquentiel + n° imprimé depuis `facs/{ID}.json`).
- Sommaire du document = fiche métadonnées (§1.2) + grille de vignettes (`thumb`) incluant les
  surfaces `"pb": false` (étiquetées « non transcrite »).

---

## Checklist de validation de la mission C

1. `prepare-tei.mjs` produit 5 TEI (~16 Mo cumulés), 888 `div[@type='page']`, 0 `sourceDoc`, 0 `pb`.
2. `facs/{ID}.json` : 922 surfaces au total (888 avec pb + 34 sans), 100 % avec URL `gallica.bnf.fr/iiif/ark:/12148/{bpt6k…|btv1b…}`.
3. Rendu XSLT d'une page témoin par doc : LIV0020 page contenant `person-000116` (couches + entité liée), LIV0010 une page latine (entités dans `orig`), LIV0001 une page à `marginal-note`.
4. Toggle orig/reg : lignes non modernisées toujours visibles ; défaut `orig` sur LIV0010.
5. Aucune requête vers `ark:/12148/LIV00NN_reconciled` (URLs cassées éliminées).
