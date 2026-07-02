#!/usr/bin/env bash
# Installation reproductible de l'environnement de la démo (ce que `make install`
# de MaX fait, mais sans prompt interactif) :
#   BaseX 10.7 + Saxon-HE + FOP, mot de passe admin, symlinks webapp,
#   déclaration de l'édition grand-siecle, préparation et chargement des données.
# Prérequis : Java 11+, Node 18+, réseau. Corpus source attendu dans
# ../grand-siecle-TeiAPP/data (5 TEI *_reconciled + registers/).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAX="$ROOT/max"
BX="$MAX/basex/bin"
ADMIN_PW="${BASEX_ADMIN_PW:-admin}"

echo "== 1. BaseX 10.7 + Saxon-HE 10.8 + FOP =="
if [ ! -d "$MAX/basex" ]; then
  cd "$MAX"
  curl -s https://files.basex.org/releases/10.7/BaseX107.zip -o BaseX107.zip
  unzip -q BaseX107.zip && rm BaseX107.zip
  curl -s https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/10.8/Saxon-HE-10.8.jar -o basex/lib/custom/Saxon-HE-10.8.jar
  curl -s https://files.basex.org/modules/org/basex/modules/fop/FOP.jar -o basex/lib/custom/FOP.jar
  "$BX/basex" -c"PASSWORD $ADMIN_PW"
fi

echo "== 2. Initialisation MaX (npm, .ignore plugins, symlinks webapp) =="
cd "$MAX"
[ -f configuration/configuration.xml ] || cp configuration/configuration.dist.xml configuration/configuration.xml
./tools/max-dev.sh
mkdir -p basex/webapp/MaX
for l in configuration editions ui plugins max.xq rxq package.json; do
  ln -sfn "../../../$l" "basex/webapp/MaX/$l"
done

echo "== 3. Activation des plugins de l'édition =="
for p in breadcrumb search index mirador_viewer sources_export; do
  rm -f "plugins/$p/.ignore"
done

echo "== 4. Déclaration de l'édition (si absente) =="
if ! grep -q 'grand-siecle_config_inc.xml' configuration/configuration.xml; then
  cd "$MAX/tools"
  "$BX/basex" -u -b projectId=grand-siecle xq/include_project_config.xq
  cd "$MAX"
fi

echo "== 5. Préparation des données (chunking TEI + JSON) =="
cd "$ROOT"
[ -d scripts/node_modules ] || (cd scripts && npm install --no-audit --no-fund)
node scripts/prepare-tei.mjs --src ../grand-siecle-TeiAPP/data
node scripts/build-entities.mjs

echo "== 6. Chargement BaseX =="
mkdir -p "$ROOT/build"
"$BX/basexhttpstop" 2>/dev/null || true
"$BX/basexhttp" -h1234 -S
sleep 2
{
  echo "DROP DB grand-siecle"
  echo "CREATE DB grand-siecle"
  for f in "$MAX"/editions/grand-siecle/data/tei/*.xml; do
    echo "ADD TO $(basename "$f") $f"
  done
  for f in "$ROOT"/../grand-siecle-TeiAPP/data/registers/*.xml; do
    echo "ADD TO registers/$(basename "$f") $f"
  done
} > "$ROOT/build/feed.txt"
"$BX/basexclient" -p 1984 -U admin -P "$ADMIN_PW" -c "$ROOT/build/feed.txt"

echo "== 7. Invalidation du cache des index =="
rm -f "$MAX"/editions/grand-siecle/fragments/fr/index/*.frag.html

echo
echo "Site dynamique : http://localhost:1234/grand-siecle/accueil.html"
echo "Gel statique   : ./scripts/freeze.sh"
