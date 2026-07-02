# MISSION D — Registres d'entités → pages statiques (détail, index A–Z, facettes, carte, timeline)

Spec pour la reconstruction statique (MaX v1 / BaseX + XSLT, gel wget, couche client Pagefind/ItemsJS/Leaflet)
de l'index d'entités de l'application TEI Publisher « Grand Siècle ».

**Sources analysées** (dépôt `/home/rayondemiel/Projet_UNIL/grand-siecle-TeiAPP`) :

| Source | Rôle |
|---|---|
| `data/registers/*.xml` (9 fichiers, ~4,5 Mo) | Données d'autorité TEI générées par le pipeline NER→Wikidata |
| `modules/config.xqm` (l. 304–360, `$config:register-map`) | Mapping type → fichier registre / préfixe d'id |
| `modules/registers-api.xql` (1432 l., namespace `rview:`) | Rendu serveur : détail, browse, facettes, backlinks, KWIC, co-occurrences, exports |
| `modules/registers-api.json` | Les routes : `/{slug}`, `/{slug}/{id}`, `/api/{slug}/browse`, `/api/cited`, `/api/cooccur`, `/api/export`, `/api/facet-source`, `/api/places/map`, `/entities` |
| `templates/entities.html`, `templates/register-index.html`, `templates/entity.html` | Gabarits hub / index facetté / page détail |
| `resources/scripts/registers-browse.js` (344 l.), `resources/scripts/registers-entity.js` (76 l.) | Logique client : facettes live, carte, KWIC lazy, co-occurrences lazy |

Les 5 documents de la démo : **LIV0001, LIV0010, LIV0017, LIV0019, LIV0020**
(fichiers `data/LIV####_reconciled.tei.xml`).

---

## 1. Schéma par type — les 9 registres

Tous les registres partagent le même en-tête (`teiHeader` avec
`sourceDesc/p = "Pipeline NER (CamemBERT + GLiNER) + reconciliation Wikidata"`) et le même socle
par entrée : `@xml:id` (préfixe + 6 chiffres zero-paddés), `@n` (nombre total de mentions, entier),
`note[@type='mentions']` (redondant avec `@n`), `note[@type='sources']` (backlinks, cf. §2),
et optionnellement `note[@type='description']`, `note[@type='reconciliation-confidence']`
(`high|medium|low`, absent = non réconciliée), `note[@type='wikidata-candidates']` (QIDs rejetés,
séparés par `|`).

Le mapping officiel est `$config:register-map` dans `modules/config.xqm` (l. 304–360) :
`person→pb-persons/person-`, `place→pb-places/place-`, `organization→pb-organizations/org-`,
`work→pb-works/work-`, `event→pb-events/event-`, `artwork→pb-artworks/artwork-`,
`material→pb-materials/material-`, `technique→pb-techniques/technique-`, `date→pb-dates/date-`.
Le mapping type→élément/slug est `$rview:type-info` dans `modules/registers-api.xql` (l. 317–327).

### 1.1 persons.xml — 7 439 entrées (3,1 Mo)

Racine `TEI[@xml:id='pb-persons']/standOff/listPerson`, entrée `person[@xml:id='person-NNNNNN']`.

| Champ | Taux | Détail |
|---|---|---|
| `persName[@type='main']` | 100 % | Forme la plus fréquente dans le corpus |
| `persName[@type='sort']` | 100 % | Clé de tri (ex. « Augustin d'Hippone ») |
| `persName[@type='variant']` | 44 % | Variantes OCR/graphiques (0..n, jusqu'à ~15) |
| `persName[@type='standard']` | 16 % | Libellé Wikidata (présent ssi réconcilié) |
| `birth/date/@when`, `death/date/@when` | 13 % | Format ISO `0354-11-13` (toujours `@when`, jamais `@notBefore`) |
| `sex[@value]` | 16 % | `@value` = QID (`Q6581097`), texte = « masculin »/« féminin » |
| `occupation[@key]` | 14 % | 0..n (715 personnes en ont >1) ; `@key` = QID, texte = libellé FR |
| `nationality[@key]` | 11 % | QID + libellé FR (ex. `key="Q1747689"` « Rome antique ») |
| `floruit` | **0 %** | N'existe pas — ne pas prévoir |
| `idno[@type='wikidata'][@cert]` | 16 % (1 175) | `@cert` = high/medium/low |
| `idno[@type='viaf']` | 14 % | ; `gnd` 14 %, `lccn` 12 %, `isni` 11 %, `bnf` 10 %. **Pas de `ulan`** (0 dans tout le jeu) |
| `note[@type='description']` | 16 % | Description Wikidata FR |
| `note[@type='reconciliation-confidence']` | 18 % | high/medium/low |
| `note[@type='wikidata-candidates']` | 16 % | QIDs séparés par `\|` |

Exemple réel complet (`person-000001`, 1 029 mentions, 25 docs sources) :

```xml
<person xml:id="person-000001" n="1029">
  <persName type="main">Augustin</persName>
  <persName type="sort">Augustin d’Hippone</persName>
  <persName type="standard">Augustin d’Hippone</persName>
  <persName type="variant">Saint Augustin</persName> <!-- … 12 autres variantes … -->
  <birth><date when="0354-11-13"/></birth>
  <death><date when="0430-08-28"/></death>
  <sex value="Q6581097">masculin</sex>
  <occupation key="Q4964182">philosophe</occupation>
  <occupation key="Q1234713">théologien ou théologienne</occupation>
  <nationality key="Q1747689">Rome antique</nationality>
  <idno type="wikidata" cert="medium">Q8018</idno>
  <idno type="viaf">66806872</idno>
  <idno type="isni">0000000121376443</idno>
  <idno type="gnd">118505114</idno>
  <idno type="bnf">11889551s</idno>
  <idno type="lccn">n80126290</idno>
  <note type="description">théologien, philosophe chrétien et évêque d’Afrique du Nord…</note>
  <note type="mentions">1029</note>
  <note type="sources">LIV0001|LIV0002a|…|LIV0033</note>
  <note type="reconciliation-confidence">medium</note>
</person>
```

### 1.2 places.xml — 2 089 entrées (796 Ko)

Racine `standOff/listPlace`, entrée `place[@xml:id='place-NNNNNN']` (pas de `@type` sur `place`).

| Champ | Taux |
|---|---|
| `placeName[@type='main'\|'sort']` | 100 % |
| `placeName[@type='variant']` | 40 % ; `standard` 22 % |
| `location/geo` | **21 % (431)** — format `"lat lon"` séparés par espace : `<geo>41.89306 12.48278</geo>` |
| `country[@key]` | 21 % — QID + libellé FR (`<country key="Q38">Italie</country>`) |
| `region` | **0 %** — n'existe pas (le code `rview:authority-facts` le prévoit mais il est toujours vide) |
| `idno[@type='wikidata']` | 22 % ; `geonames` 17 % (362) |
| description / confidence / candidates | ~22–24 % |

### 1.3 organizations.xml — 698 entrées

Racine `standOff/listOrg`, entrée `org[@xml:id='org-NNNNNN']` (**attention : préfixe `org-`,
pas `organization-`** — cf. `$config:register-map`). Pas de `@type` sur `org`.

Champs : `orgName[@type='main'|'sort']` 100 %, `variant` 73 %, `standard` 26 % ;
`idno` : wikidata 26 %, gnd 16 %, viaf 9 %, isni 5 % ;
`event[@type='foundation']/date` 9 % (60 entrées — date de fondation) ; description 26 %.

### 1.4 works.xml — 341 entrées

Racine `standOff/listBibl[@type='work']`, entrée `bibl[@xml:id='work-NNNNNN']`.

Champs : `title[@type='main']` 100 %, `variant` 54 %, `standard` 18 % ;
`author[@key]` 9 % (QID + nom) ; `textLang[@key]` 11 % (QID + langue FR) ;
`date[@type='publication'][@when]` 6 % ; `note[@type='genre'][@key]` 14 % ;
idno wikidata 18 % ; description 18 %. La réconciliation des œuvres est bruitée
(ex. réel : `work-000001` « Remarque » réconcilié à tort avec un livre de Lénine).

### 1.5 events.xml — 376 entrées

Racine `standOff/listEvent`, entrée `event[@xml:id='event-NNNNNN']`.

Champs : `label[@type='main']` 100 %, `variant` 54 %, `standard` 17 % ;
`date` 10 % (36 entrées datées : `@when` 13, `@notBefore` 25, `@notAfter` 22 — souvent deux
éléments `date` séparés pour l'intervalle) ; `placeName[@key]` 12 % (QID + lieu) ;
`desc` 17 % (⚠ ici `desc`, pas `note[@type='description']`) ; idno wikidata 17 %.

```xml
<event xml:id="event-000001" n="248">
  <label type="main">Concile</label>
  <label type="standard">concile de Trente</label>
  <date notBefore="1545-12-13"/><date notAfter="1563-02-21"/>
  <placeName key="Q3376">Trente</placeName>
  <idno type="wikidata" cert="medium">Q172991</idno>
  <desc>concile œcuménique de l'Église catholique tenu à Trente de 1545 à 1563</desc>
  …
</event>
```

### 1.6 artworks.xml — 54 entrées (registre « expérimental »)

Racine `standOff/listObject`, entrée `object[@xml:id='artwork-NNNNNN']`.
`objectName[@type='main']` 100 %, `variant` 65 %, `standard` 26 % ;
`objectType[@key]` 17 % ; idno wikidata 26 %, **`aat`** (Getty) 26 %.
L'app le marque `exp.` (badge « Données expérimentales : OCR brut » — `rview:hub-overview`, l. 1217).

### 1.7 materials.xml — 266 entrées / 1.8 techniques.xml — 69 entrées

Structure différente : `encodingDesc/classDecl/taxonomy[@xml:id='materials'|'techniques']`,
entrée `category[@xml:id='material-NNNNNN'|'technique-NNNNNN']`. Le libellé est **imbriqué** :
`catDesc/term[@type='main']` (100 %), `term[@type='standard']` (24 % / 17 %), `term[@type='variant']`
(9 % / 4 %). idno wikidata 24 % / 17 %, `aat` 24 % / 17 %. La discrimination material/technique se
fait par le `@xml:id` de la taxonomy ancêtre (cf. `rview:entry-type`, l. 342–343).

### 1.9 dates.xml — 142 entrées (registre « expérimental »)

Racine `standOff/list[@type='chronology']`, entrée `item[@xml:id='date-NNNNNN']`.
`date` (sans type) 100 % = libellé textuel FR (« Août mille cinq cent quarante et un »),
`date[@type='variant']` 14 %. **Aucun attribut `@when`/`@notBefore`/`@notAfter` (0 %)** :
ces dates ne sont PAS machine-lisibles → inutilisables pour une timeline.

### 1.10 URLs de résolution des identifiants externes

Reprendre tel quel `rview:auth-url` (`modules/registers-api.xql`, l. 435–448) :

```
wikidata → https://www.wikidata.org/wiki/{v}        viaf → https://viaf.org/viaf/{v}
isni     → https://isni.org/isni/{v}                gnd  → https://d-nb.info/gnd/{v}
bnf      → https://catalogue.bnf.fr/ark:/12148/cb{v}   (⚠ préfixe cb à ajouter)
lccn     → https://id.loc.gov/authorities/names/{v} geonames → https://www.geonames.org/{v}
aat      → http://vocab.getty.edu/aat/{v}
```

---

## 2. Backlinks doc⇄entité

### 2.1 Format source

Chaque entrée porte un index inversé **précalculé** — aucune analyse du corpus n'est nécessaire :

- `note[@type='sources']` : **noms de base des documents séparés par `|`**, sans doublon,
  ex. `<note type="sources">LIV0002a|LIV0003|LIV0005|…|LIV0033</note>`.
  Token `T` → fichier corpus `data/T_reconciled.tei.xml` (règle codée dans `rview:backlinks`, l. 186 :
  `let $file := $src || '_reconciled.tei.xml'`). Les tokens observés couvrent 35 valeurs
  (`LIV0001` … `LIV0033`, avec suffixes `a/b` et `_t1/_t2`).
- `@n` sur l'entrée + `note[@type='mentions']` : total de mentions dans TOUT le corpus
  (pas de ventilation par document — le comptage par doc doit être refait côté corpus si voulu).

### 2.2 Sens corpus → registre

Dans les `*_reconciled.tei.xml`, chaque mention porte `@ref="#<xml:id>"` (dièse conservé).
Éléments porteurs relevés dans les 5 docs de la démo (1 250 mentions au total) :

```
795  persName  → person-      264  placeName → place-       72  title → work-
 43  orgName   → org-          27  rs[@type='event'] → event-
 21  material  → material-     15  rs[@type='technique'] → technique-
 11  date      → date-          3  objectName → artwork-
```

(plus `@resp="#ner-auto"` et `@cert="high|mid"` sur chaque mention). C'est la même table de
correspondance que le `switch` de `rview:cited` (l. 219–225).

### 2.3 Construction de l'index inversé pour la démo (5 docs)

Étape de build (script Python ou XQuery BaseX), avant la génération MaX :

1. Pour chacun des 9 registres, parser les entrées ; `sources = tokenize(note[@type='sources'], '\|')`.
2. Retenir l'entrée si `sources ∩ {LIV0001, LIV0010, LIV0017, LIV0019, LIV0020} ≠ ∅`
   (**comparaison de token EXACTE** — `LIV0001` ≠ `LIV0010`, et pas de préfixe : les tokens de la
   démo existent tous en forme exacte).
3. Émettre deux artefacts JSON :
   - `entity→docs` : `{ "person-000001": ["LIV0001", "LIV0019", "LIV0020"], … }` (sources filtrées à la démo) ;
   - `doc→entities` : `{ "LIV0019": { "person": [...], "work": [...], … }, … }` — sert aussi à la page
     document (onglet « Entités citées »).
4. Optionnel (recommandé pour les compteurs par doc et le KWIC statique, cf. §3.6) : scanner les
   5 fichiers corpus pour compter les occurrences réelles par doc
   (`grep @ref` : LIV0001=204, LIV0010=329, LIV0017=254, LIV0019=111, LIV0020=352).
5. Titre d'affichage du document : `titleStmt/title[@type='main']` du fichier corpus, fallback token
   (règle de `rview:doc-title`, l. 647–653).

---

## 3. Modèle de page détail statique (par type)

Reproduire le rendu de `rview:detail-body` (l. 1084–1136) + `rview:backlinks` (l. 156–204),
injectés par `templates/entity.html` dans la section
`<section class="gs-entity-detail gs-entity-detail-{type}">`. URL statique recommandée :
`/{slug}/{xml:id}/index.html` avec slugs identiques à l'app
(`people, places, organizations, works, events, artworks, materials, techniques, dates`).

Sections dans l'ordre, pour TOUS les types :

1. **En-tête identité** : `h1` = libellé main (règle `rview:entry-label`, l. 349–362 : `persName[@type='main']`,
   fallback premier `persName` ; idem par type ; pour material/technique `catDesc/term[@type='main']` ;
   pour date le `date` sans `@type`) + **badge de confiance** (`rview:confidence-badge`, l. 406–420) :
   `high=◆◆◆ « réconciliation fiable »`, `medium=◆◆`, `low=◆`, absent=`○ « non réconciliée »`.
   Sous-titre (`rview:authority-subhead`) : personnes = « naissance – décès » (années),
   lieux = pays.
2. **Description** : `note[@type='description']` ou `desc` (events).
3. **Formes attestées** : toutes les formes (`persName|placeName|orgName|title|label|objectName|
   catDesc/term|date`) distinctes, ≠ libellé principal, **en excluant `@type='sort'`** (l. 1089–1095).
4. **Fiche de faits** (`rview:authority-facts`, l. 993–1021), lignes clé/valeur par type :
   - person : Naissance, Décès (année seule via `rview:disp-year` ; années négatives → « av. J.-C. »),
     Occupations (join `, `), Nationalité, Sexe ;
   - place : Pays, Coordonnées (`location/geo` brut) — omettre Région (toujours vide) ;
   - work : Auteur, Langue ;
   - event : Date (`@when|@notBefore|@notAfter` → année), Lieu ;
   - artwork : Type d'objet ; material/technique/date : pas de fiche.
5. **Référentiels** (`rview:authority-links-block`, l. 1023–1050) : un lien par `idno` non vide avec
   l'URL de §1.10, libellé abrégé (`rview:auth-abbr`) + valeur + `@cert` éventuel.
6. **Provenance** (`rview:provenance-block`, l. 1052–1081) : phrase fixe « Entité détectée
   automatiquement (NER CamemBERT + GLiNER), réconciliation Wikidata : {fiable|moyenne|incertaine|
   non réconciliée} » + liste « Candidats non retenus » = liens Wikidata des tokens de
   `note[@type='wikidata-candidates']`.
7. **Exports** : lien de téléchargement du fragment TEI brut de l'entrée (fichier statique
   `/{slug}/{id}/{id}.xml`, pré-sérialisé au build — remplace `/api/export/entry?format=tei`) ;
   pour les works, un `.ris` généré au build selon `rview:entry-ris` (l. 883–896 : TY BOOK, TI, AU, PY, LA, UR wikidata, AB).
8. **« Apparaît avec » (co-occurrences)** : dans l'app c'est lazy (`/api/cooccur`,
   `registers-entity.js` l. 12–22). En statique : **précalculer au build** la liste
   (algo `rview:cooccurrences`, l. 1141–1160 : autres entités partageant ≥1 doc source, exclues
   celles avec `@n ≤ 1`, tri par nb de docs partagés puis mentions, **limite 14**) et l'inliner dans le HTML.
   Pour la démo, restreindre le calcul aux sources ∩ 5 docs.
9. **« Cité dans » (backlinks)** : titre « Cité dans N documents · M mentions » (N = tokens sources,
   M = `@n`), puis liste des docs (titre + token), triée par titre. En statique, chaque item est un
   lien vers la page du document, plus le KWIC (cf. 3.6).

### 3.6 KWIC statique (remplace `GET /api/cited`)

Dans l'app, l'expansion d'un doc appelle `/api/cited?id=&doc=` qui cherche les mentions
`//persName[@ref='#person-…']` etc., regroupe par bloc (`p|ab|head|l|item`, 1 passage/bloc,
l. 233–237), et fabrique une ligne contexte ±80 caractères avec `<mark>` (l. 271–306 ; ⚠ ne lire
qu'une couche `orig` OU `reg` pour ne pas doubler le texte, l. 275–278).

En statique : **pré-générer au build** les passages KWIC pour chaque paire (entité, doc démo) —
volume borné : 1 250 mentions au total dans les 5 docs → au plus ~1 000 passages après
dédoublonnage par bloc. Deux options : (a) inline dans la page détail sous chaque doc dans un
`<details>` (recommandé, zéro JS) ; (b) fragments JSON `/{slug}/{id}/kwic-{doc}.json` chargés par
un mini-script (reprend `registers-entity.js`). Chaque ligne est un lien vers l'ancre de la page
du document gelé (`/doc/{token}/…#{id-de-la-mention}` — les mentions portent parfois un `@xml:id`
type `ent-fe9010e0-1`, sinon ancrer sur la page/`pb` la plus proche).

---

## 4. Browse / Index A–Z / facettes

### 4.1 Ce que fait l'app (à imiter côté client statique)

- Page `/{slug}` = `templates/register-index.html` : sidebar de facettes rendue serveur
  (`rview:filter-options`, l. 712–750) + liste chargée par `registers-browse.js` via
  `GET /api/{slug}/browse` (params `search, conf, facets, authority, minMentions, yearMin, yearMax,
  limit=100, offset` — cf. `buildParams()`, l. 42–77).
- Rangée de résultat (`rview:overview-row`, l. 480–505) : libellé + **chip mentions** avec tier
  visuel (`≥50 → t4, ≥10 → t3, ≥2 → t2`), méta compacte (person : « années – occupation » ;
  place : pays ; work : auteur ; event : année), badge confiance, chips d'autorités présentes.
- **Tri A–Z** : clé = `persName|placeName|orgName[@type='sort']` (fallback `main`), en minuscules,
  collation `fr-FR` (`rview:entry-sort` l. 365–373 ; `sort($keyed, "?lang=fr-FR", …)` l. 815).
- **Recherche** : `contains()` insensible à la casse sur libellé main ET clé de tri (l. 781–784) —
  ce n'est PAS un préfixe strict ; l'A–Z par lettre initiale existe dans l'endpoint pb-split-list
  `rview:categories` (l. 925–965 : si >80 résultats, découpage par première lettre A–Z + « all »).

### 4.2 Facettes par type (source : `rview:facet-defs` l. 565–581 + pseudo-facettes l. 727–734)

| Type | Facettes spécifiques (élément / attribut-clé) | Facettes universelles |
|---|---|---|
| person | occupation (`occupation/@key`), nationality (`nationality/@key`), sex (`sex/@value`), **century** (siècle calculé de birth/death) | confiance (`high/medium/low/none`), autorité (a un QID wikidata), mentions min (`@n`), période (yearMin/yearMax), **source** (tokens de `note[@type='sources']`) |
| place | country (`country/@key`) + vue **carte** | idem |
| work | lang (`textLang/@key`) | idem |
| event | place (`placeName/@key`), **century** | idem |
| artwork | objtype (`objectType/@key`) | idem |
| organization, material, technique, date | — (aucune facette spécifique) | idem |

Règles de valeurs de facette (`rview:top-facet-el`, l. 698–709) : clé = `@key` (QID) si non vide
sinon texte normalisé ; libellé = texte de la 1re occurrence ; **exclure les valeurs singleton**
(`count >= 2`) ; cap à 80 valeurs, tri par count desc. Facette « siècle » : labels français en
chiffres romains (`XVIIe siècle`, `Ier siècle av. J.-C.` — `rview:century-label` l. 626–630).
Facette « source » : count = nb d'entités citées par doc, label = titre du doc.

### 4.3 Transposition statique (ItemsJS + Pagefind)

Une page `/{slug}/index.html` par type, embarquant (ou fetchant) `/{slug}/browse.json` (§5.1),
avec **ItemsJS** configuré ainsi (mêmes sémantiques que l'app) :

- `searchableFields: ["label", "sort", "variants"]` (améliore l'app qui ne cherche pas les variantes) ;
- `aggregations` par type selon le tableau 4.2 + `confidence`, `authority` (booléen), `sources`
  (multi-valué), `century` (multi-valué) ; filtre à seuil pour `mentions` (slider) ;
- tri par défaut : `sort` asc avec `Intl.Collator('fr')` ; tri secondaire proposé : `mentions` desc ;
- A–Z : barre de lettres qui filtre sur `sort[0].toUpperCase()` (équivalent `rview:categories`) ;
- pagination client 100/riche « Afficher plus » (identique à `gsMore`).
- L'index Pagefind global du site doit indexer les pages détail (titre + variantes + description)
  pour que les entités remontent dans la recherche générale du site.

---

## 5. Exports statiques à générer au build

### 5.1 `/{slug}/browse.json` — schéma par type pour ItemsJS

Un fichier par type. Champs communs (tous types) :

```json
{
  "id": "person-000001",
  "type": "person",
  "label": "Augustin",
  "sort": "augustin d’hippone",
  "standard": "Augustin d’Hippone",
  "variants": ["Saint Augustin", "S. Augustin"],
  "mentions": 1029,
  "tier": 4,
  "confidence": "medium",
  "authority": true,
  "idnos": {"wikidata": "Q8018", "viaf": "66806872", "gnd": "…", "bnf": "…", "isni": "…", "lccn": "…"},
  "description": "théologien, philosophe chrétien…",
  "sources": ["LIV0001", "LIV0019", "LIV0020"],
  "url": "/people/person-000001/"
}
```

Champs additionnels par type : person `birth`, `death` (année int, négatif = av. J.-C.), `centuries`
(int[]), `sex` `{key,label}`, `occupations` `[{key,label}]`, `nationalities` `[{key,label}]` ;
place `country` `{key,label}`, `geo` `[lat, lon]` (float, depuis `location/geo` split espace),
`geonames` ; work `author` `{key,label}`, `lang` `{key,label}`, `pubYear` ; event `dates`
`{when|notBefore|notAfter}`, `centuries`, `place` `{key,label}` ; artwork `objectType` ;
organization `foundation` (année). Pour la démo, `sources` est filtré aux 5 docs.

Le CSV « Exporter » peut être regénéré client-side depuis ce JSON (colonnes de l'app,
`rview:export-csv` l. 857 : `id,type,label,mentions,confidence,dates,detail,wikidata,viaf,gnd,sources`).

### 5.2 Carte Leaflet — `/places/map.json`

**Oui, les lieux ont des coordonnées natives** : `location/geo` = `"lat lon"` sur 431/2 089 lieux
(21 %) — **30 des 187 lieux de la démo**. Format identique à `rview:places-map` (l. 1320–1332) :

```json
[{"latitude": "41.89306", "longitude": "12.48278", "label": "Rome", "id": "place-000001"}]
```

Marqueur → lien `/places/{id}/`. Afficher le compteur de couverture « N lieux géolocalisés »
comme dans l'app (`$filters?geo-count`, register-index.html l. 169–177 ; fond de carte
CARTO Positron, cluster, centre 46.6/2.2 zoom 5). Pour les lieux SANS `geo` mais AVEC
`idno[@type='geonames']` (25 lieux démo, recouvrement partiel avec geo) : une passe de build
optionnelle peut résoudre lat/lon via le dump/API GeoNames (`https://www.geonames.org/{id}`),
mais gain marginal ; sinon lien externe GeoNames seulement. Utiliser Leaflet vanilla
(pas `pb-leaflet-map`, qui dépend du runtime pb-components).

### 5.3 Timeline — `/data/timeline.json`

Données réellement exploitables :

- **persons** : `birth/date/@when` / `death/date/@when` ISO — 951/949 entrées globales,
  **117 des 365 personnes de la démo** ont au moins une des deux ;
- **events** : 36/376 datés (`@when`/`@notBefore`/`@notAfter`) — **2 seulement dans la démo** ;
- **works** : `date[@type='publication']/@when` (19 entrées) ; organizations : fondation (60) ;
- **dates.xml : inutilisable** (aucun attribut normalisé, cf. §1.9) — exclure de la timeline.

Recommandation démo : une frise « vies des personnes citées » (barres naissance→décès, 117 items,
filtrable par doc source) + les 2 events datés en points. Schéma :
`{"id","type","label","start","end","url","sources":[…]}` (années int, négatives = av. J.-C. ;
gérer les années à 3 chiffres type 354).

### 5.4 Graphe de co-citation — `/data/cooccurrence.json`

**Faisable uniquement à partir de `note[@type='sources']`** (granularité document, pas paragraphe) —
c'est exactement ce que fait `rview:cooccurrences` (l. 1141–1160). ⚠ Sur 5 docs, le graphe complet
entité–entité est quasi-clique par document (~237 entités partagent LIV0010 → ~28 000 arêtes) :
inexploitable brut. Deux livrables raisonnables :

1. **Par page détail** : top 14 « Apparaît avec » précalculé (même algo/tri que l'app), inliné — cf. §3.8.
2. **Graphe global de démo** : graphe **bipartite doc⇄entité** (5 nœuds docs + 665 nœuds entités,
   1 handful d'arêtes = paires (doc, entité)), ou projeté entité–entité restreint aux entités avec
   `mentions ≥ 10` et arêtes `docs partagés ≥ 2`. Format `{"nodes":[{id,label,type,mentions}],
   "links":[{source,target,weight}]}` pour d3-force ou sigma.js.

### 5.5 Hub `/entities/index.html`

Statifier `rview:hub-overview` (l. 1207–1232) : une carte par type avec total, nb réconciliées
(`count(idno[@type='wikidata'])`), entité la plus citée (`max(@n)`), badge `exp.` pour
`date` et `artwork`. Tous ces chiffres se calculent au build.

---

## 6. Volumétrie et recommandation de périmètre

Comptage exact (tokens `note[@type='sources']`, correspondance exacte) :

| Registre | Total | Cité par ≥1 des 5 docs démo | dont geo / dates |
|---|---:|---:|---|
| persons | 7 439 | **365** (LIV0020: 126, LIV0017: 91, LIV0010: 73, LIV0001: 61, LIV0019: 44) | 117 avec birth/death |
| places | 2 089 | **187** (LIV0010: 151 — texte très géographique) | 30 avec `geo` |
| organizations | 698 | **26** | — |
| works | 341 | **40** | — |
| events | 376 | **17** | 2 datés |
| artworks | 54 | **2** | — |
| materials | 266 | **13** | — |
| techniques | 69 | **5** | — |
| dates | 142 | **10** | 0 normalisée |
| **Total** | **11 474** | **665** | |

Mentions inline dans les 5 docs : 1 250 occurrences (204 + 329 + 254 + 111 + 352).

**Recommandation : générer les pages détail UNIQUEMENT pour les 665 entités des 5 docs de la
démo** (~6 % du total). Raisons :

1. 11 474 pages détail = ~11 500 fichiers + crawl wget long, pour ~94 % de pages orphelines dans
   la démo (aucun lien entrant depuis les documents ni les backlinks — leur bloc « Cité dans »
   pointerait vers des docs absents) ;
2. la longue traîne est massivement non réconciliée (82 % des personnes sans confiance) et bruitée
   (OCR) — l'app elle-même la relègue visuellement (`gs-unrecon`, tiers de mentions) ;
3. les backlinks, KWIC, co-occurrences et la facette « source » ne sont cohérents que si l'univers
   documentaire = les 5 docs ; filtrer `sources` à la démo garde toutes les vues consistantes ;
4. 665 pages + 9 index + hub + ~6 JSON restent triviaux à générer et à crawler.

Garde-fou : dans les JSON de browse, conserver un champ `corpusMentions` (le `@n` global) à côté du
compte démo si l'on veut afficher « N mentions dans le corpus complet » sans générer les pages.

**Arborescence statique cible** :

```
/entities/index.html                     (hub, 9 cartes)
/{slug}/index.html                       (browse ItemsJS ; slug ∈ people, places, organizations,
                                          works, events, artworks, materials, techniques, dates)
/{slug}/browse.json                      (§5.1)
/{slug}/{xml:id}/index.html              (665 pages détail, §3)
/{slug}/{xml:id}/{xml:id}.xml            (export TEI ; + .ris pour works)
/places/map.json                         (§5.2)
/data/timeline.json                      (§5.3)
/data/cooccurrence.json                  (§5.4)
/data/doc-entities.json                  (index inversé doc→entités, §2.3)
```
