# SPEC A — Mécanique complète de MaX v1 : créer l'édition « grand-siecle » par surcharge, sans toucher au cœur

> Sources analysées (code réel, prioritaire sur la doc en ligne) :
> - Cœur MaX : `/home/rayondemiel/Projet_UNIL/grand-siecle-max-statique/max/` (`max.xq`, `rxq/`, `ui/`, `plugins/`, `configuration/`, `tools/`)
> - Édition de démo TEI : `/tmp/claude-1000/-home-rayondemiel-Projet-UNIL-grand-siecle-TeiAPP/14e34141-b8ac-4efa-a049-54cc603fc859/scratchpad/max-tei-demo/`
> - Documentation : https://pdn-certic.pages.unicaen.fr/max-documentation/ (pages `config/`, `script/`, `overriding/`, `text/`, `plugins/`, `static_pages/`, `metadata/`)
>
> Version MaX : 1.1.0 (`max/package.json`). BaseX 10.7 + Saxon-HE 10.8 (`max/Makefile`, cible `install-basex`).

---

## 0. Architecture d'exécution (à comprendre avant tout)

MaX est une **webapp RESTXQ BaseX**. Le `Makefile` (cible `install`) crée `basex/webapp/MaX/` avec des **symlinks** vers la racine du dépôt :

```
basex/webapp/MaX/configuration -> ../../../configuration
basex/webapp/MaX/editions      -> ../../../editions
basex/webapp/MaX/ui            -> ../../../ui
basex/webapp/MaX/plugins       -> ../../../plugins
basex/webapp/MaX/max.xq        -> ../../../max.xq
basex/webapp/MaX/rxq           -> ../../../rxq
basex/webapp/MaX/package.json  -> ../../../package.json
```

BaseX (`basex/.basex` : `WEBPATH = .../max/basex/webapp`, `RESTXQPATH` vide = WEBPATH) scanne **tous** les `.xq`/`.xqm` sous `webapp/` et publie les fonctions annotées `%rest:path`. **Un répertoire contenant un fichier `.ignore` est ignoré par le scan RESTXQ** — c'est le mécanisme d'activation des plugins (§6) et la raison du `touch node_modules/.ignore` dans `tools/max-dev.sh`.

Une « édition » = un dossier `editions/<id>/` (contenus surchargeables) + une base BaseX (les XML TEI) + un fichier de conf inclus par XInclude dans `configuration/configuration.xml`. **On ne modifie jamais `max.xq`, `rxq/`, `ui/`, `plugins/`** : tout se surcharge depuis `editions/<id>/`.

---

## 1. Configuration : `configuration.xml` et fichier de conf d'édition

### 1.1 `configuration/configuration.dist.xml` (et `.xml`)

Fichier quasi vide, les éditions y sont **déclarées par XInclude** :

```xml
<?xml version="1.0"?>
<configuration xmlns:xi="http://www.w3.org/2001/XInclude">
  <editions>
    <!-- inséré par tools/xq/include_project_config.xq : -->
    <!-- <xi:include href="../editions/grand-siecle/grand-siecle_config_inc.xml"/> -->
  </editions>
</configuration>
```

`tools/max.sh` copie `configuration.dist.xml` → `configuration.xml` s'il n'existe pas (lignes 86-90). Le module `rxq/config.xqm` lit ce fichier via `$max.config:CONFIGURATION_FILE := "../configuration/configuration.xml"` (chemin relatif à `rxq/`, donc résolu à travers les symlinks webapp). Toutes les fonctions font `doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$projectId]/...` — les XInclude sont résolus à la lecture.

Élément racine optionnel : `<urlPrefix>` (lu par `max.config:getUrlPrefix`, défaut `/`) — non utilisé ailleurs dans le code actuel.

### 1.2 Gabarit `tools/edition_conf_tmpl.xml`

```xml
 <edition xml:id="%ID%" dbpath="%DB%" env="%ENV%" prettyName="My edition">
    <textOptions>
    </textOptions>
    <plugins>
    </plugins>
 </edition>
```

(En pratique c'est `tools/xq/create_project_config.xq` qui génère le fichier, pas ce gabarit — voir §2.)

### 1.3 Fichier de conf d'édition — référence complète des paramètres

Exemple réel de la démo, `max-tei-demo/max_tei_demo_config_inc.xml` :

```xml
<edition xml:id="max_tei_demo" dbpath="max_tei_demo" env="tei" prettyName="Démo Lorem">
  <description>Édition Demo Lorem - Démonstrateur du moteur d'affichage XML MaX.</description>
  <author>Certic / Pôle Document Numérique / Université de Caen</author>
  <textOptions>
    <checkboxOptions>
      <targetClass>pb</targetClass>
    </checkboxOptions>
  </textOptions>
  <alignment document="demo_align_fr.xml" first-prefix="fr" second-prefix="lat"/>
  <plugins>
    <plugin name="normalisation"/>
    <plugin name="correction"/>
    <plugin name="abreviation"/>
    <plugin name="ajout"/>
    <plugin name="apparat_critique"/>
    <plugin name="tei_pdf"/>
    <plugin name="search">
      <parameters>
        <parameter key="tag" value="p"/>
        <parameter key="backToTextID" value="(./ancestor::*:div[@*:type])[1]/@xml:id"/>
      </parameters>
    </plugin>
    <plugin name="img_viewer">
      <parameters>
        <parameter key="imagesRepository" value="ui/images/" xsl="true"/>
      </parameters>
    </plugin>
    <plugin name="breadcrumb">
      <parameters>
        <parameter key="topLabel" value="Démo. Max [TEI]"/>
      </parameters>
    </plugin>
  </plugins>
</edition>
```

Sémantique de chaque paramètre (fonctions dans `rxq/config.xqm`) :

| Paramètre | Fonction lectrice | Effet |
|---|---|---|
| `@xml:id` | partout | Identifiant de l'édition = **préfixe d'URL** (`/<id>/accueil.html`) et nom du dossier `editions/<id>/`. |
| `@dbpath` | `getProjectDBPath` (l.82) | Nom de la base BaseX (peut contenir un sous-chemin `db/collection` ; `max.util:dbNameFromCollection` prend le 1er segment). |
| `@env` | `getXMLFormat` (l.180) | Grammaire : `tei` ou `ead`. Détermine XSL par défaut (`ui/xsl/tei/tei.xsl`), gabarit HTML par défaut (`ui/templates/tei.html`), requêtes `rxq/tei/*.xq`. |
| `@prettyName` | `getProjectPrettyName` (l.37) | Titre affiché (bandeau, `<title>`, PDF). Défaut = `xml:id`. |
| `@lang` | `getProjectDefaultLang` (l.47) | Langue par défaut i18n (défaut `fr`). |
| `<description>` / `<author>` | `getProjectDescription` / `getProjectAuthor` | Injectés dans les `<meta>` DC/OpenGraph par défaut (`rxq/html.xqm:buildMetas`). |
| `<projectData><data key="k">v</data></projectData>` | `getProjectData` (l.244) | Map libre exposée au gabarit HTML comme variable `$data`. |
| `<textOptions><checkboxOptions><targetClass>pb</targetClass>...` | `getCheckboxTextOptions` (l.227) | Cases à cocher « Options de lecture » : chaque `targetClass` = classe CSS togglée (localStorage) ; libellé i18n = clé du même nom (`<entry key="pb">Afficher les sauts de page</entry>` dans `ui/i18n/i18n-fr.xml`). |
| `<textOptions><htmlFragment file="..."/>` | `getTextOptionsFragment` (l.231) | Fragment HTML statique ajouté au menu d'options. |
| `<alignment document="X.xml" first-prefix="fr" second-prefix="lat" align-xquery-file="..."/>` | `isAlignedRoute`, `getFirst/SecondAlignmentPrefix`, `getTextAlignmentQueryFile` (l.141-175) | Active la route bi-texte `/<id>/<doc>.xml/<id1>/<id2>.html` (`rxq/alignment.xqm`) + import auto de `ui/xsl/tei/alignment.xsl`. |
| `<docsToIgnore><docToIgnore>x.xml</docToIgnore></docsToIgnore>` | `isIgnored` (l.90) | Exclut des documents de la recherche (plugin search). |
| `<template file="editions/<id>/ui/templates/mon_template.html"/>` | `max.util:getProjectLayoutTemplate` (`rxq/util.xqm` l.336-344) | Gabarit HTML alternatif. **Attention** : le code lit `edition/template/@file`, alors que le commentaire de la démo montre `<layout template="..."/>` (et le XSD `tools/configuration.xsd` déclare `<layout @template>`) — **seul `<template file="…">` fonctionne** ; le plus sûr est de nommer son gabarit `editions/<id>/ui/templates/template.html` (priorité 1, voir §4). |
| `<plugins><plugin name="..."><parameters><parameter key="k" value="v" [xsl="true"]/>...` | `getEnabledPluginNames`, `getPluginByName`, `getPluginParameterValue` (l.56-79) | Active un plugin ; un `parameter` avec `xsl="true"` est aussi passé **en paramètre XSLT** à la transformation du texte (`getXSLTParams` l.212). |
| `<htmlHeadTags>` | `max.html:setHtmlHeadTags` (`rxq/html.xqm` l.391) | Balises head personnalisées (utilisable depuis un `xq/metadata.xq` d'édition). |
| `<navigationFragment @xquery-file>`, `<routeList>`, `labelBindings` | `getNavigationQueryFile` etc. | **Vestigiaux** — aucune utilisation dans le code actuel (vérifié par grep) ; ne pas s'en servir. |

---

## 2. Création d'édition NON-INTERACTIVE (reproduire `max.sh -n` sans prompts)

### 2.1 Ce que font les scripts XQuery de `tools/xq/`

- **`create_project_config.xq`** — bindings externes `maxPath`, `projectId`, `dbPath`, `envType`. Écrit `editions/<projectId>/<projectId>_config_inc.xml` :
  ```xquery
  <edition xml:id="{$projectId}" dbpath="{$dbPath}" env="{$envType}" prettyName="My {$envType} edition">
      <textOptions></textOptions>
      <plugins></plugins>
  </edition>
  (: → file:write($maxPath || '/editions/'||$projectId||'/'||$projectId||'_config_inc.xml', $config) :)
  ```
  (variante `ead` : plugin `side_toc` pré-inséré).
- **`include_project_config.xq`** — binding `projectId`. Insère dans `configuration/configuration.xml` (avec `declare option db:xinclude 'false';` pour ne pas résoudre les inclusions existantes) :
  ```xquery
  insert node <xi:include href="../editions/{$projectId}/{$projectId}_config_inc.xml"/>
    into doc("../../configuration/configuration.xml")/configuration/editions
  ```
  ⚠️ chemins `doc()` relatifs **au fichier .xq** (`tools/xq/`) : exécuter avec BaseX depuis `tools/` et **avec `-u`** pour persister la mise à jour sur disque.
- **`check_config_exists.xq`** — bindings `maxPath`, `projectId` ; renvoie `0` si l'édition est déjà déclarée, `-1` sinon.
- **`insert_plugin_config.xq`** / **`remove_plugin_config.xq`** — bindings `projectId`, `pluginId` ; ajoute/retire `<plugin name="…"/>` dans `editions/<id>/<id>_config_inc.xml` (idempotent). À exécuter avec `-u`.

### 2.2 Structure de dossiers attendue dans `editions/<id>/` (cf. `deploy_new_edition`, `tools/max.sh` l.305-353)

```
editions/grand-siecle/
├── grand-siecle_config_inc.xml     # généré par create_project_config.xq
├── menu.xml                        # copie de tools/menu_default.xml, à adapter
├── fragments/
│   └── fr/                         # 1 dossier par langue (la liste des langues = ces dossiers !)
│       ├── accueil.frag.html       # page d'accueil (sinon fallback sommaire)
│       ├── about.frag.html         # généré depuis tools/about.frag_tmpl.html
│       └── index/                  # cache du plugin index (à créer si plugin index)
│   └── footer.frag.html            # optionnel : footer custom
├── xq/                             # toc.xq, document_toc.xq, text_hook.xq, metadata.xq, index/index_*.xq
└── ui/
    ├── css/grand-siecle.css        # auto-inclus s'il existe (nom = id d'édition)
    ├── js/grand-siecle.js          # auto-inclus s'il existe
    ├── fonts/  images/
    ├── i18n/                       # i18n-fr.xml … (surcharges de labels)
    ├── templates/                  # template.html (surcharge du layout)
    └── xsl/                        # core/menu.xsl, core/toc.xsl, tei/text_hook.xsl,
                                    # tei/document_toc.xsl, tei/nav_bar.xsl, index/index_*.xsl
```

### 2.3 Séquence bash exacte, zéro prompt

```bash
#!/usr/bin/env bash
set -euo pipefail
MAX=/home/rayondemiel/Projet_UNIL/grand-siecle-max-statique/max
ID=grand-siecle            # xml:id de l'édition (⚠ la route "page" n'accepte que [a-zA-Z0-9_] : voir §9.7)
DB=grand_siecle            # nom de base BaseX (pas d'accents/espaces/tirets de préférence)
ENV=tei
DATA=/chemin/vers/les/sources/tei/   # dossier des XML à charger
BX=$MAX/basex/bin

cd "$MAX/tools"

# 0. fichier de conf principal (comme max.sh l.86-90)
[ -f ../configuration/configuration.xml ] || \
  cp ../configuration/configuration.dist.xml ../configuration/configuration.xml

# 1. garde-fou : édition pas déjà déclarée (renvoie -1 si absente)
[ "$("$BX/basex" -b projectId=$ID -b maxPath="$MAX" xq/check_config_exists.xq)" = "-1" ]

# 2. dossier + conf d'édition + XInclude (équiv. new_edition_build, max.sh l.360-369)
mkdir -p "$MAX/editions/$ID"
"$BX/basex" -b projectId=$ID -b dbPath=$DB -b envType=$ENV -b maxPath="$MAX" xq/create_project_config.xq
"$BX/basex" -u -b projectId=$ID xq/include_project_config.xq   # -u = persiste sur disque

# 3. CREATE DATABASE + ADD via basexclient (équiv. db_project_feed, max.sh l.204-225)
#    Le serveur BaseX doit tourner (basexhttp lance aussi le serveur client sur 1984).
"$BX/basexhttpstop" 2>/dev/null || true
"$BX/basexhttp" -S
printf 'CREATE DATABASE %s\nADD %s\n' "$DB" "$DATA" > feed.txt
"$BX/basexclient" -p 1984 -U admin -P admin -c feed.txt        # -U/-P : supprime le prompt login
rm feed.txt
# (max.sh arrête ensuite le serveur : "$BX/basexhttpstop" ; le relancer pour servir le site)

# 4. arborescence de l'édition (max.sh l.327-342)
mkdir -p "$MAX/editions/$ID"/fragments/fr "$MAX/editions/$ID"/xq \
         "$MAX/editions/$ID"/ui/{css,fonts,i18n,images,js,templates,xsl}
touch "$MAX/editions/$ID/ui/css/$ID.css"
sed "s/\$project_id/$ID/g" about.frag_tmpl.html > "$MAX/editions/$ID/fragments/fr/about.frag.html"
cp menu_default.xml "$MAX/editions/$ID/menu.xml"

# 5. activation de plugins = insertion en conf + suppression du .ignore
#    (équiv. enable_plugin, max.sh l.152-179)
for p in breadcrumb side_toc index search tei_pdf img_viewer; do
  rm -f "$MAX/plugins/$p/.ignore"
  "$BX/basex" -u -b pluginId=$p -b projectId=$ID xq/insert_plugin_config.xq
done

# 6. lancer le serveur : le site répond sur http://localhost:1234/grand-siecle/
"$BX/basexhttp" -h1234 &
```

Remarques :
- `ADD <dossier>` charge récursivement tout le dossier ; le mot de passe admin doit avoir été défini une fois (`basex -c'PASSWORD'`, fait par `max.sh` au premier run, l.121-129 — non-interactif : `"$BX/basex" -c'PASSWORD admin'`).
- L'installation de la démo (`max.sh --d-tei`) suit exactement le même pipeline : unzip du dépôt `max-tei-demo` dans `editions/max_tei_demo/`, `db_project_feed max_tei_demo editions/max_tei_demo/dataset/`, `include_project_config`, puis `enable_plugin` pour chaque `<plugin>` déjà listé dans la conf.
- Rechargement des données sans recréer l'édition : `basexclient -U admin -P admin -c "DROP DATABASE $DB; CREATE DATABASE $DB; ADD $DATA"`.

---

## 3. Routage `rxq/` : inventaire complet des routes

Module principal : `max.xq` (module `pddn/max`). Toutes les URL sont relatives à la racine BaseX (ex. `http://localhost:1234/`).

### 3.1 Routes du cœur

| Route (annotation `%rest:path`) | Fonction | Fichier | Produit |
|---|---|---|---|
| `/max.html` | `max:home` | `max.xq` l.13 | Page d'info moteur (dev seulement — 404 si pas de `package.json`). |
| `/favicon.ico` | `max:favicon` | `max.xq` l.44 | `ui/images/favicon.ico`. |
| `/{$project}` | `max:projectHome` | `max.xq` l.53 | **Redirection 302** vers `…/accueil.html` (`web:redirect`). |
| `/{$project}/{$page=[a-zA-Z0-9_]+}.html` | `max:page` | `max.xq` l.71 | Pages « nommées » : `sommaire` → TOC projet (`max.toc:getProjectTOC`) ; `accueil` → fragment `fragments/<lang>/accueil.frag.html` (fallback TOC si absent/mal formé) ; toute autre valeur → fragment statique `fragments/<lang>/<page>.frag.html` (404 sinon). ⚠ regex **sans tiret ni point**. |
| `/{$project}/sommaire/{$doc=.*}.html` | `max:documentTOC` | `max.xq` l.129 | Sommaire d'un document (`max.toc:getDocumentTOC($project, $doc || '.xml')`). |
| `/{$project}/{$routeDoc=.*\.xml}/{$id}.html` `?search=&focus=` | `max:fragmentToHTMLPage` | `max.xq` l.143 | **Page fragment** (l'unité de lecture) : `<div id="wrap-{id}">{text_hook.xq}{fragment}</div>` transformé XSLT, + `div.plugins-wrapper` (sorties des `<plugin>.xq`), le tout dans le layout. `?search=x` marque les occurrences (`ft:mark`), `?focus=id` ajoute `class="target"` (autoscroll JS). |
| `/{$project}/doc/{$doc=.*}.html` `?search=&focus=` | `max:getFullDocument` | `max.xq` l.179 | **Document complet** : `<div id='text'>{text_hook.xq}{racine du doc}</div>` transformé + plugins + layout. |
| `/{$project}/fragment/{$id}.html` | `max:getXMLByID` | `max.xq` l.231 | Fragment **XML brut** (non transformé). |
| `/{$project}/fragment_html/{$id}.html` `?xsl=&xslparams=&wrap=` | `max:getHTMLByID` | `max.xq` l.243 | Fragment transformé **hors layout** (`<div class='standalone-html' id="wrap-{id}">`) ; `xsl=` ajoute une XSL de `editions/<id>/ui/xsl/`, `xslparams=nom:valeur`, `wrap=true` enveloppe dans un HTML minimal. |
| `/{$project}/sitemap.xml` | `max:buildSitemap` | `max.xq` l.329 | Sitemap XML : entrées `menu.xml[@type='main']` + liens du TOC projet. **Point d'amorçage idéal pour wget.** |
| `/{$project}/{$doc=.*xml}/{$id1}/{$id2}.html` | `max.alignment:alignedHTML` | `rxq/alignment.xqm` l.12 | Vue alignée bi-texte (si `<alignment>` en conf). |
| `/{$projectId}/setlang/{$lang}` | `max.i18n:setLang` | `rxq/i18n.xqm` l.7 | Change la langue **en session serveur** (`session:set`). |
| `/{$project}/ui/{$filePath=.*}` | `max.file:projectUIFile` | `rxq/file.xqm` l.11 | Statiques de l'édition (`editions/<id>/ui/…`). |
| `/{$project}/core/ui/{$filePath=.*}` | `max.file:UIFile` | `rxq/file.xqm` l.27 | Statiques du cœur (`ui/…`) : bootstrap, `tei.css`, `MaxTEI.js`… |
| `/{$project}/plugins/{$filePath=.*}` | `max.file:pluginUIFile` | `rxq/file.xqm` l.42 | Statiques des plugins (`plugins/…`), avec header `expires` 2222. |
| `/sf/{$db}/{$id}` `?q=` | `max.api:getXMLByID` | `rxq/max_api.xqm` l.8 | API brute : 1er élément `@xml:id|@id = $id` de la collection ; `?q=` concatène une XQuery (**eval — à ne pas exposer en prod**). |
| `/sf/{$routeDoc=.*\.xml|.*\.svg}/{$id}` | `max.api:getXMLByIDinDOC` | `rxq/max_api.xqm` l.27 | Idem, ciblé sur un document. |
| `/sf/frag/{$uniqueID}` | `max.api:getFragment` | `rxq/max_api.xqm` l.45 | `db::id` séparés par `::`. |
| `/sf/idindoc/{$doc=.*\.xml}/{$id}` | `max.api:getXMLByIDInDoc` | `rxq/max_api.xqm` l.55 | Variante stricte (unicité). |

### 3.2 Routes apportées par les plugins (si `.ignore` supprimé)

| Route | Fichier |
|---|---|
| `/{$project}/search.html`, `/{$project}/search?search=&docs[]=`, `/{$project}/search/report.html` | `plugins/search/search.xqm` |
| `/{$project}/index/{$type}.html?focus=` | `plugins/index/index.xqm` |
| `/{$project}/{$route=.*\.xml}/page/{$n}.html`, `…/page/{$n}/{$id}.html`, `/{$project}/{$routeDoc}/{$id}/page`, `/{$project}/pager/report` | `plugins/pager/pager.xqm` |
| `/{$project}/mirador?link=&canvasId=&canvasIndex=` | `plugins/mirador_viewer/mirador_viewer.xqm` |
| `/{$project}/{$id}.pdf` | `plugins/tei_pdf/tei2pdf.xqm` (FOP) |
| `/{$project}/{$archive}.zip?indent=` | `plugins/sources_export/sources_export.xqm` |

### 3.3 Comment le HTML est produit : `max.html:render` + gabarit évalué par `xquery:eval`

`rxq/html.xqm:render` (l.28-78) construit une map de variables puis appelle `renderTemplate` :

```xquery
max.html:renderTemplate(doc(max.util:getProjectLayoutTemplate($projectId)),
        map {
        'projectId' : $projectId,
        'prettyName' : max.config:getProjectPrettyName($projectId),
        'data' : max.config:getProjectData($projectId),
        'baseURI' : max.util:getRelativeRootPath($projectId),
        'home' :  max.util:getRelativeRootPath($projectId) || 'accueil.html',
        'menu' : $menu,
        'navigationSelect' : $navigationSelect,
        'textOptions' : $textOptions,
        'head' : $head,
        'content' : $content,
        'footer' : max.html:getFooter($projectId),
        'jsImports' : $jsImports
        })
```

et `renderTemplate` (l.313-319) **transforme le gabarit HTML en XQuery** :

```xquery
declare function max.html:renderTemplate($htmlDoc as document-node(), $map as map(*)){
    let $declarations := string-join(for $var in map:keys($map)
    return "declare variable $" || $var || " external;")
    return xquery:eval($declarations || serialize($htmlDoc), $map)
};
```

→ le gabarit est du **XML bien formé contenant des expressions XQuery `{$var}`**. Ce sont les 12 variables ci-dessus qui sont disponibles (ni plus, ni moins — sauf `$data` qui permet d'en passer d'autres via `<projectData>`).

`$baseURI` est **relatif** : `max.util:getRelativeRootPath` (`rxq/util.xqm` l.29-36) compte les segments de `rest:uri()` et renvoie une chaîne `../../…/<project>/` — tout le site fonctionne en URLs relatives (excellent pour le gel wget).

---

## 4. Gabarits / layout

### 4.1 Résolution du gabarit (`rxq/util.xqm:getProjectLayoutTemplate`, l.336-344)

1. `editions/<id>/ui/templates/template.html` (nom imposé : `$max.cons:HTML_TEMPLATE := "template.html"`) ;
2. sinon `<template file="…"/>` dans la conf d'édition (chemin relatif à `editions/`) ;
3. sinon le défaut du cœur : `ui/templates/tei.html` (via `@env`).

### 4.2 Gabarit TEI par défaut, `ui/templates/tei.html` (structure de référence)

```html
<!DOCTYPE html>
<html lang="en">
  <head>
       <meta charset="UTF-8"/>
       <link rel="icon" href="{$baseURI}favicon.ico" />
       <link rel="stylesheet" href="{$baseURI}core/ui/lib/bootstrap.min.css"/>
       <link rel="stylesheet" type="text/css" href="{$baseURI}core/ui/css/tei.css"/>
       <link rel="stylesheet" type="text/css" href="{$baseURI}core/ui/css/alignment.css"/>
      {$head}
  </head>
  <body>
    <header id="topbar" class="navbar fixed-top navbar-light bg-light">
      <a class="navbar-brand" href="{$home}">{$prettyName}</a>
      <div id="menu">{$menu}</div>
      <div id="navigation-wrap">{$navigationSelect}</div>
      <div>{$textOptions}</div>
    </header>
    <main id="main-max-container" class="container px-5">{$content}</main>
    {$footer}
    <script type="text/javascript" src="{$baseURI}core/ui/lib/bootstrap.bundle.min.js"/>
    <script type="module" src="{$baseURI}core/ui/js/MaxTEI.js"/>
    {$jsImports}
  </body>
</html>
```

La démo fournit une variante « menu à gauche » : `max-tei-demo/ui/templates/template_left.html` (body `class="max-menu-left"`, `<nav id="leftbar">{$menu}</nav>`) — **mais** nommée `template_left.html` elle n'est PAS prise automatiquement ; pour l'activer il faut la renommer `template.html` (le commentaire `<layout template="…"/>` de la conf démo ne correspond pas au code, cf. §1.3).

### 4.3 Menu : `menu.xml` → XSLT

`editions/<id>/menu.xml` (copié de `tools/menu_default.xml`) :

```xml
<menu>
  <entry type="main" default="true"><id>home</id><target>accueil.html</target></entry>
  <entry type="main"><id>sommaire</id><target>sommaire.html</target></entry>
  <entry type="main"><id>project</id><target>projet.html</target>
    <entry><id>about</id><target>about.html</target></entry>      <!-- sous-menu = dropdown -->
  </entry>
</menu>
```

`rxq/html.xqm:buildMenu` (l.176-196) : (1) injecte dans chaque `entry` un `<label>` = i18n de la clé **`menu.<id>`** ; (2) transforme par la XSL retournée par `max.util:getProjectMenuXSL` = `editions/<id>/ui/xsl/core/menu.xsl` si présent, sinon `ui/xsl/core/menu.xsl` (navbar Bootstrap, dropdowns pour les `entry` imbriqués, classe `active` sur l'entrée courante via `$selectedTarget`). Paramètres XSL : `baseURI`, `selectedTarget` (= `<pageId>.html`), `projectId`. Exemple de surcharge complète : `max-tei-demo/ui/xsl/core/menu_left.xsl`. Un sélecteur de langue (`ul.i18n-menu`, `onclick="MAX.setLanguage('en')"`) est concaténé après le menu.

### 4.4 Inclusion automatique des CSS/JS d'édition et de plugins

`rxq/html.xqm` :
- `buildCSSImports` (l.150-173) : ajoute `<link href="{base}/ui/css/<id>.css">` **si le fichier `editions/<id>/ui/css/<id>.css` existe** (nom = id d'édition, obligatoire) + un `<link>` par plugin activé possédant `plugins/<p>/<p>.css`.
- `buildJavascript` (l.102-113) : injecte un bloc inline définissant les globales JS `baseURI`, `projectId`, `route`, `fragmentId`, `lang`, puis `<script src=".../ui/js/<id>.js">` si `editions/<id>/ui/js/<id>.js` existe, + `<script type="module">` par plugin ayant `plugins/<p>/<p>.js`.
- `getFooter` (l.233-245) : `editions/<id>/fragments/footer.frag.html` si présent, sinon footer par défaut (logos Biblissima).
- `buildMetas` (l.325-361) : si `editions/<id>/xq/metadata.xq` existe, l'évalue (bindings `project`, `requestPath`, `content`) et injecte son retour dans `<head>` ; sinon métas par défaut (`<title>{prettyName} - {1er h1/h2/h3 du contenu}</title>`, DC + OpenGraph depuis `<description>`/`<author>`).

### 4.5 Barre de navigation intra-document

`max.html:getNavbarForDocument` (l.250-267) : reprend le TOC du document, et si l'id courant y figure, applique `nav_bar.xsl` (résolution : `editions/<id>/ui/xsl/tei/nav_bar.xsl` sinon `ui/xsl/tei/nav_bar.xsl`) → dropdown Bootstrap + flèches précédent/suivant (`#nav_previous`/`#nav_next`, câblées par `MaxTEI.js:bindNavigationTool`).

---

## 5. Rendu TEI

### 5.1 XSL par défaut et assemblage dynamique

- XSL principale : `max.util:getDefaultTextXSL` → **`ui/xsl/<env>/<env>.xsl`** = `ui/xsl/tei/tei.xsl`, qui ne fait qu'importer **`ui/xsl/tei/tei_core.xsl`**.
- Templates de `tei_core.xsl` (liste réelle) : identité (`node()|@*`) ; racines `/tei:div | /tei:body | /div | /tei:list` → `<div id='text' class="col-sm-8">…<div id='bas_de_page'>` ; `tei:text|tei:body` → `div` ; `tei:div[parent::*]` → `div[@id=xml:id]` ; `tei:head` → `h2.subpart` ; `tei:p` → `p[@id=xml:id]` ; `tei:note[@place='footer']` → appel de note + template nommé `bas_de_page` ; `tei:note[@type='marginalia']` → manchettes gauche/droite ; `tei:figure`/`tei:graphic` → `div.figure`/`img` (src = `concat($baseuri,'/ui/images/',@url)`) ; `tei:pb` → `<a class="pb" name="{xml:id}">{@n}</a>` ; `tei:lb` → `br` ; `tei:hi` → `span[@class=@rend]` ; `tei:table/row/cell` ; `tei:quote` → `blockquote` ; `tei:bibl/author/title/date/publisher` → spans classés ; `tei:teiHeader|fileDesc` → transparent, `titleStmt` → `h1` ; `tei:back|front|sourceDesc` → **supprimés** ; `tei:TEI` → `div`.
- **Assemblage** (`max:transformEditionFragment`, `max.xq` l.278-284 + `rxq/util.xqm:buildXSLTDoc` l.49-58) : la XSL réellement exécutée est `tei.xsl` dans laquelle sont **insérés des `<xsl:import>` en dernière position** pour chaque « addon » retourné par `max.config:getXSLTAddons` (`rxq/config.xqm` l.187-203), dans l'ordre :
  1. `ui/xsl/tei/alignment.xsl` (si route alignée),
  2. `plugins/<p>/<p>.xsl` pour chaque plugin activé possédant une XSL,
  3. **`editions/<id>/ui/xsl/<env>/text_hook.xsl`** s'il existe.

  En XSLT, **le dernier import a la précédence la plus haute** → `text_hook.xsl` (édition) > XSL de plugins > `tei_core.xsl`. C'est LE mécanisme de surcharge du rendu : recopier dans `text_hook.xsl` uniquement les templates à modifier/ajouter.
- **Paramètres XSLT** (`getXSLTParams` l.205-224) : `baseuri` (relatif, se termine par `<id>/`), `locale`, `route` (nom du doc), `id` (fragment), `project`, + tout `parameter[@xsl='true']` des plugins, + `first-prefix`/`second-prefix` d'alignement.

Squelette minimal de `text_hook.xsl` (celui de la démo, `max-tei-demo/ui/xsl/tei/text_hook.xsl`) :

```xml
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0" exclude-result-prefixes="tei xsl">
  <xsl:output method="xml" encoding="utf-8"/>
  <xsl:template match="/"><xsl:apply-templates/></xsl:template>
</xsl:stylesheet>
```

⚠️ Ce `match="/"` de la démo **court-circuite** le template racine de `tei_core.xsl` — dans une vraie surcharge, ne PAS redéfinir `/` sauf à reproduire la génération de `<div id='text'>` (des tas de comportements JS — notes de marge, options de texte, contexte fragment — testent `document.getElementById("text")`, cf. `ui/js/AbstractMax.js:isInFragmentContext`).

### 5.2 Document complet vs fragment par `xml:id`

- **Fragment** `/{p}/<doc>.xml/<id>.html` (`max:fragmentToHTMLPage`) : le fragment est retrouvé par `max.api:getXMLByID($dbPath, $id)` = `(collection($db)//*[@xml:id=$id or @id=$id])[1]` — **recherche dans TOUTE la collection, premier trouvé** ; le `<doc>.xml` de l'URL ne sert qu'au contexte (fil d'Ariane, navbar, plugins). D'où l'exigence d'**unicité des `xml:id` sur toute la base** (§9.4). Le XML passé à la XSL est :
  ```xquery
  <div id="wrap-{$id}">
      {max.util:getTextHookFragment($project, $routeDoc, $id)}   (: sortie de xq/text_hook.xq :)
      {max.api:getXMLByID($dbPath, $id)}
  </div>
  ```
- **Document complet** `/{p}/doc/<doc>.html` (`max:getFullDocument`) : `(doc($dbPath || "/" || $docName)/*)[1]` enveloppé dans `<div id='text'>` + `text_hook.xq`.
- **Hook XQuery** `editions/<id>/xq/text_hook.xq` (`rxq/util.xqm:getTextHookFragment` l.236-254) : évalué avant le texte avec bindings `project`, `baseURI`, `dbPath`, `doc`, `$fragmentId` (sic, avec le `$` dans la clé — utiliser `$fragmentId` avec précaution) ; son XML de sortie est concaténé au fragment et transformé par la même XSL. Usage type : injecter du contexte (titre courant, liens facsimilé…).

### 5.3 Sommaires (TOC)

**TOC projet** (`sommaire.html`, `rxq/toc.xqm:getProjectTOC` l.10-35) :
1. XQuery : `editions/<id>/xq/toc.xq` si présent (bindings `project`, `baseURI`, `dbPath`, `locale`) ; sinon défaut `max.util:list-db-resources` (l.153-191) qui liste récursivement la base et produit des `<li data-href='{base}{id}/sommaire/{doc}'>` dont le libellé est le **titre du document** ;
2. Titre du document extrait par `rxq/tei/document_title.xq` :
   ```xquery
   doc($documentPath)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt
   ```
   (branche `teiCorpus` gérée). Champs teiHeader exploités par le cœur : **uniquement `titleStmt`** (le rendu `document_title.xsl` garde `title`, supprime `author`, `editor`, `note`) — tout autre champ (dates, resp…) doit venir d'un `toc.xq`/`metadata.xq` d'édition ;
3. XSL : `ui/xsl/core/toc.xsl` (surchargeable `editions/<id>/ui/xsl/core/toc.xsl`) — remplace `xml` par `html` dans `data-href` (⚠ `replace(@data-href,'xml','html')` : remplace la **première** occurrence de la chaîne `xml` où qu'elle soit, gare aux noms de fichiers contenant « xml »).

**TOC document** (`sommaire/<doc>.html`, `rxq/toc.xqm:getDocumentTOC` l.41-77) :
1. XQuery : `editions/<id>/xq/document_toc.xq` si présent, sinon défaut **`rxq/tei/document_toc.xq`** qui itère :
   ```xquery
   for $chapter in $doc//body/div[@type and @xml:id] where $chapter/head
   ```
   → `<li id="{xml:id}" data-href="{base}<id>/<doc>.xml/{xml:id}">{head}</li>` + sous-`div[@*:id]` récursifs. **Contrat TEI : des `div` avec `@type`, `@xml:id` ET un `head`** sous `body`, sinon sommaire vide ;
2. XSL : `ui/xsl/tei/document_toc.xsl` (surchargeable `editions/<id>/ui/xsl/tei/document_toc.xsl`) → `<div id="document-toc"><ul><li data-target="{id}"><a href="{data-href}.html">…` ;
3. Titre : `document_title.xq` + `document_title.xsl`, renommé en `<h1>`.
La démo fournit un gabarit d'exemple commenté : `max-tei-demo/xq/_document_toc.xq` (préfixé `_` pour rester inactif ; bindings documentés `baseURI`, `dbPath`, `project`, `doc`).

---

## 6. Plugins : inventaire et fonctionnement

### 6.1 Mécanique générale

Un plugin = dossier `plugins/<nom>/` pouvant contenir, chacun optionnel, découvert par convention de nommage :

| Fichier | Rôle | Mécanisme |
|---|---|---|
| `<nom>.xsl` | Surcharge du rendu TEI | importé automatiquement dans la XSL principale (`getXSLTAddons`) si le plugin est dans la conf. |
| `<nom>.xq` | **Fragment HTML contextuel** affiché dans `div.plugins-wrapper` en tête de chaque page texte | évalué par `max.html:invokePluginXQueries` (`rxq/html.xqm` l.364-382) avec bindings `baseURI`, `dbPath`, `project`, `doc`, `id`. |
| `<nom>.xqm` | **Nouvelles routes RESTXQ** | scanné par BaseX ssi pas de `.ignore` dans le dossier. |
| `<nom>.css` / `<nom>.js` | Assets | inclus automatiquement dans le layout (§4.4) ; le JS est un module qui s'enregistre via `window.MAX.addPlugin(new XPlugin(...))` (`ui/js/Plugin.js`). |

**Activation pour une édition** = 2 actions (faites par `max.sh --enable-plugin <p> <edition>`) :
1. `basex -u -b pluginId=<p> -b projectId=<ed> tools/xq/insert_plugin_config.xq` → `<plugin name="p"/>` dans `editions/<ed>/<ed>_config_inc.xml` ;
2. `rm plugins/<p>/.ignore` (sinon les routes `.xqm` restent mortes).
Désactivation : `remove_plugin_config.xq` puis, si plus aucune édition ne l'utilise, `touch plugins/<p>/.ignore`.

### 6.2 Famille « états du texte » (XSL pures + toggle JS)

Toutes fonctionnent sur le même modèle : la XSL rend les deux états en `<span class="…">`, le JS/CSS n'en montre qu'un, un bouton dans la barre du haut permute (état mémorisé en localStorage).

| Plugin | TEI attendu | Sortie |
|---|---|---|
| `normalisation` | `tei:choice/(tei:orig\|tei:reg)` | `span.orig` / `span.reg` |
| `correction` | `tei:choice/(tei:sic\|tei:corr)` | `span.sic` / `span.corr` |
| `abreviation` | `tei:am`/`tei:ex`, `tei:abbr`/`tei:expan` | `span.am` / `span.ex` |
| `ajout` | `tei:add` / `tei:del` | `span.add` / `span.del` |
| `diplomatique` | union des 3 premiers (sic/corr + orig/reg + am/ex) | **ne pas cumuler** avec normalisation/correction/abreviation (le commentaire de la conf démo le rappelle : « le plugin diplomatique rassemble les plugins normalisation/correction et abréviation »). |

Rien à écrire côté édition, hormis du CSS éventuel.

### 6.3 `apparat_critique`

- `apparat_critique.xq` : panneau radio « témoins » construit depuis `doc($dbPath||'/'||$doc)//tei:listWit//tei:witness[@xml:id]` (→ **exige `sourceDesc/listWit/witness[@xml:id]` dans le teiHeader**) ;
- `apparat_critique.xsl` : `tei:app` transparent, `tei:lem` → `span.lem.apparat.{@wit sans #}` avec `data-witnesses`, `tei:rdg` → `span.{wit}.apparat`, gestion `lacunaStart/lacunaEnd` (`@synch`, `@wit`, `@xml:id`) ;
- `apparat_critique.js` : bascule l'affichage par témoin (`apparat.showWitness('w1')`).
À écrire soi-même : rien, si le balisage `app/lem/rdg[@wit]` est standard.

### 6.4 `search` — LE point dynamique (à remplacer par Pagefind en statique)

`plugins/search/search.xqm` :
- **`GET /{project}/search.html`** : page-formulaire (rendue dans le layout) — liste `<select id='searchSelect'>` de tous les documents de la collection (moins les `docsToIgnore`), radio « tous les textes / sélection », champ texte, bouton `search.runSearchFromForm()`.
- **`GET /{project}/search?search=<texte>&docs[]=<doc.xml>&docs[]=…`** : l'API AJAX (appelée en `fetch` par `search.js:runSearch`). Pour chaque document : itère sur les éléments dont `local-name()` = paramètre **`tag`** (conf), applique `ft:mark($h[.//text() contains text {$search}])` (recherche plein texte BaseX, insensible casse/diacritiques selon l'index), rend chaque hit :
  ```xquery
  <div class='hit'>
      <span class='search-b2txt'><a href='{$b2txt}'>{string($h/@xml:id)}</a></span>
      <div>{$hit}</div>
  </div>
  ```
  où `$b2txt = {base}/<doc path>/<@xml:id du tag>.html` — **le tag porteur doit donc avoir un `@xml:id`** pour le lien retour. Le tout est transformé par la XSL TEI par défaut et groupé par document dans `<div class='hits'><details open=""><summary>{doc} <span class="badge …">{count}</span></summary>…</details></div>`. Sortie = fragments HTML **hors layout** (injectés dans `#searchResults`).
- **`GET /{project}/search/report.html`** : autodiagnostic de la conf.
- Paramètres de conf : `tag` (élément de granularité des hits, ex. `p`) et `backToTextID` (XPath, présent dans la conf démo mais **non lu par le code actuel** — seul `tag` est utilisé, `backToTextID` n'apparaît que dans le report).
- Le lien retour ajoute côté client `?search=…&focus=…` → re-marquage serveur sur la page fragment (`max:applySearchMarkup`, `max.xq` l.208-227).

### 6.5 `index` — index thématiques avec cache fichier (à détailler pour grand-siecle)

`plugins/index/index.xqm` — route **`GET /{project}/index/{type}.html`** :

1. Si le **cache** `editions/<id>/fragments/<lang>/index/index_<type>.frag.html` existe → il est lu (`fetch:doc`), enveloppé `<div id='content'>` et rendu dans le layout. `?focus=<id>` ajoute `class="target"` (autoscroll).
2. Sinon `generateIndex` : exige **les deux** fichiers d'édition
   - `editions/<id>/xq/index/index_<type>.xq` — bindings `project`, `baseURI`, `dbPath` ; retourne un XML libre (convention du readme : `<index type="…"><marker id="…" role="…"><entry>…</entry><value>…</value><baseuri>…</baseuri><initiale>…</initiale></marker>…</index>`) ;
   - `editions/<id>/ui/xsl/index/index_<type>.xsl` — paramètres `project`, `locale` ; transforme en HTML (le readme `plugins/index/readme.md` donne un exemple complet : groupement par `@role` puis initiale puis valeur, liens `{baseuri}/{@id}.html`) ;
   sinon la page affiche littéralement `"XQ and/or XSL file not found"`.
3. Le HTML produit est **écrit sur disque** (`file:write($indexFilePath, $HTMLIndex)`) puis la fonction se rappelle → sert le cache.

**Invalidation du cache : supprimer le fichier** `editions/<id>/fragments/<lang>/index/index_<type>.frag.html` (readme : « Pour générer à nouveau la page d'index il suffit de supprimer le fichier »). Le cache est **par langue** (la langue de session au moment du premier hit). Prérequis d'arborescence (readme) : créer les dossiers `fragments/<lang>/index/`, `xq/index/`, `ui/xsl/index/` dans l'édition. `index.js` gère les ancres `#entrée` (filtrage client de l'index).

Pour grand-siecle : prévoir p.ex. `index_personnes.xq/xsl`, `index_lieux.xq/xsl`, `index_oeuvres.xq/xsl` construits sur les `@ref="#person-NNNNNN"` du corpus + les registres TEI chargés dans la même base.

### 6.6 `breadcrumb`

`breadcrumb.xq` (fragment contextuel) : `<nav id="breadcrumb"><ol class="breadcrumb">` avec `Sommaire` → `sommaire/<doc>.html` → titre du fragment courant (via `collection($dbPath)//*[@xml:id=$id]` transformé par `plugins/breadcrumb/_breadcrumb.xsl`). Paramètre `topLabel` déclaré dans la conf démo mais **le code actuel ne le lit plus** (lignes commentées). Aucun fichier à écrire.

### 6.7 `side_toc`

`side_toc.xq` : ré-injecte le TOC du document (`max.toc:getDocumentTOC`) dans un `<div class='side-toc'>` sur chaque page fragment + `input[name=currentTocItem]` (`<project>/<doc>/<id>`) pour le highlight JS. Dépend donc de `document_toc.xq/xsl` (surcharges comprises).

### 6.8 `pager`

Routes `…/<doc>.xml/page/<n>.html` (+ variante `/page/<n>/<id>.html`). Paramètres de conf obligatoires : `nbBlocks` (items/page), `nbLinks` (liens de pagination), `itemsPath` (XPath des items, le code pagine `//*:list/*:item` en dur pour le découpage réel). Conçu pour de très gros documents en listes ; peu pertinent pour grand-siecle (préférer un fragment par `div`).

### 6.9 `mirador_viewer` / `img_viewer`

- `mirador_viewer` : route `GET /{project}/mirador?link=<manifestIIIF>&canvasId=&canvasIndex=` → page autonome chargeant `plugins/mirador_viewer/max-mirador/MaxMirador.js`. Déclencheur TEI (readme) : **`<pb rend='iiif_manifest' n='linkToIIIFManifest'/>`** (ancre `#15` ou `#idCanvas` pour cibler une vue). La XSL `mirador_viewer.xsl` génère les liens.
- `img_viewer` : OpenSeadragon en dialogue. Paramètre de conf **`imagesRepository`** (avec `xsl="true"` pour être passé à la XSL). `img_viewer.xsl` surcharge `tei:pb[@facs]` (→ lien `MAX.plugins['img_viewer'].openImageInDialog(...)` ; `@facs` http absolu ou relatif à `{$baseuri}{imagesRepository}`) et `tei:graphic[@url]` (→ `img.viewable`).

### 6.10 `tei_pdf` / `sources_export` / `equations`

- `tei_pdf` : `tei_pdf.xq` affiche le bouton (lien `/{project}/{id}.pdf`) ; `tei2pdf.xqm` reconstruit un `<TEI>` (teiHeader + fragment) et le passe à `max.util:xml2pdf` → XSL FO `ui/xsl/tei/tei2fo.xsl` (surchargeable `editions/<id>/ui/xsl/tei/tei2fo.xsl` via `getProjectFoXsl`) + **FOP.jar requis** dans `basex/lib/custom/`.
- `sources_export` : `GET /{project}/{project}.zip` — exporte la base en zip (bouton « télécharger les sources »). En statique : pré-générer le zip une fois et le déposer tel quel.
- `equations` : `tei:formula[@notation='TeX']` → `span.tex` rendu par MathJax (`equations.js`). Exclu des releases officielles (`tools/build.sh` le supprime).

---

## 7. i18n

- **Labels du cœur** : `ui/i18n/i18n-fr.xml`, `ui/i18n/i18n-en.xml` — format :
  ```xml
  <properties>
    <entry key="menu.home">Accueil</entry>
    <entry key="menu.sommaire">Sommaire</entry>
    <entry key="search.label">Recherche</entry>
    <entry key="pb">Afficher les sauts de page</entry>
    <entry key="reading-options">Options de lecture</entry>
    ...
  </properties>
  ```
- **Surcharge par édition** : `editions/<id>/ui/i18n/i18n-<locale>.xml`, même format ; `max.i18n:getText` (`rxq/i18n.xqm` l.19-41) cherche d'abord dans le fichier d'édition, puis dans le cœur, puis renvoie **la clé brute** (donc toute entrée de menu custom `<id>xyz</id>` exige `<entry key="menu.xyz">` sous peine d'afficher `menu.xyz`). La démo surcharge une seule clé : `max-tei-demo/ui/i18n/i18n-fr.xml` → `<entry key="menu.project">Le projet</entry>`.
- **Côté XSL** : fonction `max:i18n($project,$key,$locale)` définie dans `ui/xsl/core/i18n.xsl` (même cascade édition > cœur > clé) — à importer dans les XSL d'index (`<xsl:import href="../../../../ui/xsl/core/i18n.xsl"/>` depuis `editions/<id>/ui/xsl/index/`).
- **Langue courante** : stockée en **session serveur** (`session:get/set`, clé `<id>-lang`), changée par la route `/{id}/setlang/{lang}` (appelée par `MAX.setLanguage` puis reload). Défaut = `@lang` de la conf, sinon `fr`.
- **Liste des langues proposées** = les sous-dossiers de `editions/<id>/fragments/` (`max.i18n:getLanguageList`, l.43-51). Pour un site monolingue : ne créer que `fragments/fr/` (le menu de langues n'affichera que `fr`).

---

## 8. Pages statiques éditoriales `*.frag.html`

- **Emplacement** : `editions/<id>/fragments/<locale>/<nom>.frag.html` (ex. démo : `fragments/fr/accueil.frag.html`, `projet.frag.html`, `contacts.frag.html`, `about.frag.html`, dupliqués dans `fragments/en/`).
- **Format** : un fichier XML **bien formé** commençant directement par un unique élément (typiquement `<div>`), sans DOCTYPE (`max.html:getHTMLFragment`, `rxq/html.xqm` l.213-222, fait `fetch:doc` puis enveloppe dans `<div>`). Exemple réel (`fragments/fr/accueil.frag.html`) :
  ```html
  <div id="demo_presentation">
    <h3>Édition de démonstration [XML-TEI]</h3>
    <p>Texte de présentation ...</p>
    <div class="container">…<a href="./demo_lorem.xml/c1.html">MaX</a>…</div>
  </div>
  ```
- **Routage** : servi par la route générique `/{project}/{page}.html` (`max:page`, `max.xq` l.71) — l'URL est le nom du fichier **sans** `.frag`. Cas particuliers : `accueil` (fallback TOC si absent) et `sommaire` (réservé au TOC). Regex `[a-zA-Z0-9_]+` → **pas de tiret ni de point dans les noms de fragments**.
- **Menu** : ajouter `<entry><id>projet</id><target>projet.html</target></entry>` dans `menu.xml` + clé i18n `menu.projet`.
- Le fragment est injecté tel quel dans le layout (pas de transformation XSLT) — HTML Bootstrap 5 autorisé.

---

## 9. Pièges connus (à intégrer au plan grand-siecle)

1. **Les gabarits HTML sont évalués comme du XQuery** (`xquery:eval(serialize($htmlDoc))`, `rxq/html.xqm` l.313-319). Conséquences : le gabarit doit être du XML bien formé (balises auto-fermées, `&amp;`) ; **toute accolade `{ }` est une expression XQuery** — un `<script>` ou un `style` inline contenant `{` casse la page (échapper `{{` `}}` ou externaliser le JS/CSS) ; seule les 12 variables du §3.3 existent (`$data` pour le reste) ; une variable non déclarée dans la map → erreur `err:XPQST0008`-like au premier rendu.
2. **Cache du plugin index** : le HTML est écrit dans `editions/<id>/fragments/<lang>/index/index_<type>.frag.html` au premier hit et **jamais régénéré automatiquement** — après tout changement de données ou d'XSL, supprimer ces fichiers (et penser au cache par langue). Si `xq/index/` ou `ui/xsl/index/` manquent → page « XQ and/or XSL file not found ». Le dossier `fragments/<lang>/index/` doit exister avant le premier hit (sinon `file:write` échoue selon les versions).
3. **`.ignore`** : BaseX RESTXQ saute tout dossier contenant un fichier `.ignore`. Tous les plugins en ont un par défaut (`tools/max-dev.sh`, `tools/build.sh`) ; activer un plugin en éditant seulement la conf **ne suffit pas** pour ses routes `.xqm` (search, index, pager, tei_pdf, mirador, sources_export). Inversement `ui/.ignore` et `node_modules/.ignore` ne doivent pas être supprimés.
4. **Sensibilité aux `xml:id`** : la résolution de fragment est `(collection($db)//*[@xml:id=$id or @id=$id])[1]` — **globale à la base, premier trouvé** ; des ids dupliqués entre documents (fréquent après OCR/NER) rendent des fragments silencieusement faux. De plus le TOC par défaut exige `body/div[@type][@xml:id]/head` et la recherche exige un `@xml:id` sur le `tag` configuré (`p` → tous les `<p>` doivent être identifiés pour le lien retour). Vérifier l'unicité AVANT chargement.
5. **Langue en session serveur** : `/setlang/` + `session:` — invisible pour un crawl wget (le crawler verra toujours la langue par défaut). Pour un gel multilingue il faudrait un crawl par langue avec cookie de session, ou s'en tenir à `fr`.
6. **Recherche = endpoint dynamique** (`/{p}/search?search=…` appelé en fetch) et marquage `?search=&focus=` sur les pages textes : en statique, exclure ces URLs du crawl (`--reject-regex '[?](search|focus)='`) et remplacer par Pagefind ; la page `search.html` sera à substituer.
7. **Regex de routes** : pages nommées limitées à `[a-zA-Z0-9_]` (pas de `-`) ; les routes fragments exigent `<doc>` finissant par `.xml` ; la route alignement `/{p}/{doc}/{id1}/{id2}.html` peut **capturer par erreur** des URLs à 2 niveaux ; l'id d'édition avec tiret (`grand-siecle`) est OK pour `/{$project}/…` (segment libre) mais tester tôt.
8. **`<template file>` vs `<layout template>`** : le XSD et le commentaire de la démo montrent `<layout template="…"/>`, le code lit `edition/template/@file` — utiliser le nom magique `editions/<id>/ui/templates/template.html`, c'est le seul chemin sans ambiguïté.
9. **Ordre d'import XSLT** : text_hook > plugins > tei_core ; deux plugins qui matchent le même élément (ex. `img_viewer` et `tei_core` sur `tei:pb`/`tei:graphic`) se départagent par ordre d'import (le dernier de `getEnabledPluginNames`, i.e. l'ordre des `<plugin>` dans la conf, gagne). Ne pas activer `diplomatique` avec normalisation/correction/abreviation.
10. **`accueil` avale les erreurs** : si `accueil.frag.html` est mal formé, MaX affiche le sommaire sans message (log INFO seulement) — contrôler `basex/.logs`.
11. **Chemins relatifs partout** (`getRelativeRootPath` compte les segments de l'URL) : bon pour wget, mais toute URL à profondeur inhabituelle (ex. `?focus` sur route alignée, `sommaire/<sous-dossier>/<doc>.html`) doit être vérifiée ; la racine `/{project}` est une **redirection 302** vers `accueil.html` (wget la suit, mais prévoir un `index.html` de redirection dans le gel).
12. **Métadonnées par défaut fragiles** : `buildMetas` prend le premier `h1|h2|h3` du contenu ; fournir `editions/<id>/xq/metadata.xq` (bindings `project`, `requestPath`, `content`) pour des `<title>`/DC/OG propres.
13. **`/sf/…` et `fragment_html?xsl=…&xslparams=…`** : endpoints d'API qui évaluent des XQuery arbitraires (`?q=`) — ne jamais exposer le BaseX dynamique en production ; le gel statique les neutralise de fait (les exclure du crawl).
14. **`sitemap.xml`** : construit sur `menu.xml` + TOC projet — c'est la graine de crawl idéale, mais il n'inclut ni les pages fragments (`<doc>.xml/<id>.html`) ni les index : ajouter `sommaire/<doc>.html` de chaque doc dans la liste wget.
15. **Titres TEI** : seul `teiHeader/fileDesc/titleStmt` est exploité (title gardé, author/editor/note supprimés) ; les teiHeader riches de grand-siecle (`LIV####_reconciled.tei.xml`) devront être exposés via `toc.xq` / `metadata.xq` custom.

---

## 10. Récapitulatif : fichiers à créer pour l'édition `grand-siecle` (aucune modification du cœur)

| Fichier | Rôle | Obligatoire |
|---|---|---|
| `editions/grand-siecle/grand-siecle_config_inc.xml` | conf (généré §2.3, puis enrichi : prettyName, description, author, plugins, textOptions) | ✔ |
| `editions/grand-siecle/menu.xml` | navigation | ✔ |
| `editions/grand-siecle/fragments/fr/accueil.frag.html` (+ `projet`, `about`, `contacts`, `footer.frag.html`) | pages éditoriales | ✔ (accueil) |
| `editions/grand-siecle/ui/css/grand-siecle.css`, `ui/js/grand-siecle.js` | thème/JS (auto-inclus) | ✔ / ○ |
| `editions/grand-siecle/ui/templates/template.html` | layout custom | ○ |
| `editions/grand-siecle/ui/xsl/tei/text_hook.xsl` | surcharges de rendu TEI (rs/persName/@ref, notes, pb IIIF…) | ✔ |
| `editions/grand-siecle/xq/text_hook.xq` | contexte injecté avant le texte | ○ |
| `editions/grand-siecle/xq/toc.xq` + `ui/xsl/core/toc.xsl` | sommaire projet riche (métadonnées teiHeader) | recommandé |
| `editions/grand-siecle/xq/document_toc.xq` + `ui/xsl/tei/document_toc.xsl` | sommaire par document | ○ (si défaut insuffisant) |
| `editions/grand-siecle/xq/metadata.xq` | `<title>`/DC/OG | recommandé |
| `editions/grand-siecle/xq/index/index_<type>.xq` + `ui/xsl/index/index_<type>.xsl` + dossier `fragments/fr/index/` | index personnes/lieux/œuvres (plugin index) | ✔ pour les registres |
| `editions/grand-siecle/ui/i18n/i18n-fr.xml` | labels custom (`menu.*`, clés textOptions…) | ✔ |
