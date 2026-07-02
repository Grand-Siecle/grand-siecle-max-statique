#!/usr/bin/env bash
# Gel statique de l'édition MaX grand-siecle :
#   wget (crawl du site dynamique) → assets → fusion des fiches d'entités
#   pré-générées → post-traitement → index Pagefind → mesures.
# Prérequis : serveur MaX actif sur :1234, build/site-extra/ généré
# (scripts/build-entities.mjs), corpus.json présent (scripts/prepare-tei.mjs).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$ROOT/static-site"
MES="$ROOT/docs/mesures-gel.md"
cd "$ROOT"

echo "== 1. Graines de crawl =="
node scripts/gen-seeds.mjs
NB_SEEDS=$(wc -l < build/seeds.txt)

echo "== 2. Crawl wget =="
rm -rf "$SITE"
T0=$(date +%s)
wget --recursive --level=inf --no-host-directories \
     --directory-prefix="$SITE" \
     -e robots=off --no-verbose \
     --reject-regex '(/sf/|/mirador|/setlang/|/doc/|/registres/|[?&](search|focus|q)=|\.zip$)' \
     --input-file=build/seeds.txt \
     2> build/wget.log || true   # wget sort en erreur sur les 404 attendus
T1=$(date +%s)
CRAWL_S=$((T1 - T0))
NB_CRAWLED=$(find "$SITE" -name '*.html' | wc -l)

echo "== 3. Assets (UI cœur + édition + plugins : les imports JS/manifestes que wget ne voit pas) =="
mkdir -p "$SITE/grand-siecle/core/ui" "$SITE/grand-siecle/ui" "$SITE/grand-siecle/plugins"
# -L : max/ui/lib contient des symlinks vers node_modules (bootstrap…) — copier les cibles
rsync -aL --exclude="xsl" --exclude="templates" max/ui/ "$SITE/grand-siecle/core/ui/"
rsync -aL --exclude='xsl' max/editions/grand-siecle/ui/ "$SITE/grand-siecle/ui/"
for p in breadcrumb search index mirador_viewer; do
  [ -d "max/plugins/$p" ] && rsync -a --include='*.css' --include='*.js' --exclude='*' "max/plugins/$p/" "$SITE/grand-siecle/plugins/$p/"
done

echo "== 4. Fusion des fiches d'entités pré-générées =="
rsync -a build/site-extra/registres/ "$SITE/grand-siecle/registres/"
NB_ENTITES=$(find "$SITE/grand-siecle/registres" -name '*.html' | wc -l)

echo "== 5. Post-traitement (Pagefind attrs, recherche, Mirador→Gallica, redirections) =="
node scripts/postprocess-static.mjs

echo "== 6. Index Pagefind =="
T2=$(date +%s)
npx -y pagefind --site "$SITE/grand-siecle" --output-subdir pagefind > build/pagefind.log 2>&1
T3=$(date +%s)
PF_S=$((T3 - T2))
PF_PAGES=$(grep -o 'Indexed [0-9]* page' build/pagefind.log | grep -o '[0-9]*' || echo '?')
PF_SIZE=$(du -sh "$SITE/grand-siecle/pagefind" | cut -f1)

echo "== 7. Mesures =="
SITE_SIZE=$(du -sh "$SITE" | cut -f1)
SITE_FILES=$(find "$SITE" -type f | wc -l)
cat > "$MES" <<EOF
# Mesures du gel statique (générées par scripts/freeze.sh)

> Date : $(date -Iseconds)

| Mesure | Valeur |
|---|---|
| URLs de départ (seeds) | $NB_SEEDS |
| Durée du crawl wget | ${CRAWL_S} s |
| Pages HTML gelées (crawl) | $NB_CRAWLED |
| Fiches d'entités fusionnées (pré-générées hors MaX) | $NB_ENTITES |
| Durée d'indexation Pagefind | ${PF_S} s |
| Pages indexées par Pagefind | $PF_PAGES |
| Taille de l'index Pagefind | $PF_SIZE |
| Taille totale du site statique | $SITE_SIZE |
| Nombre total de fichiers | $SITE_FILES |

Servir localement : \`python3 -m http.server 8899 --directory static-site\`
puis http://localhost:8899/grand-siecle/accueil.html
EOF
cat "$MES"
echo "== GEL TERMINÉ =="
