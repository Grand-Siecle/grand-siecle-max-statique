# Mesures du gel statique

> Générées le 2026-07-02T21:04:05+02:00. Protocole : `scripts/freeze.sh` (wget → assets →
> fusion fiches → post-traitement → Pagefind).

| Mesure | Valeur |
|---|---|
| URLs de départ (seeds, dont 888 pages de lecture) | 910 |
| Durée du crawl wget (séquentiel, local) | 6 min 34 s |
| Fichiers téléchargés par le crawl | 932 (38 Mo) |
| Pages HTML gelées par le crawl | 910 |
| Fiches d'entités fusionnées (pré-générées hors MaX) | 666 |
| Pages HTML totales du site | 1578 |
| Indexation Pagefind (v1.5.2) | 1 577 pages, 44 193 mots, ~2 s |
| Taille de l'index Pagefind | 8.2M |
| Taille totale du site statique | 59M |
| Nombre total de fichiers | 3951 |
| Liens internes vérifiés | 58 628 (0 cassé ; 0 référence localhost) |

Rappels de contexte (comparaison avec le plan statique TEI Publisher,
`docs/claude/migration-static.md` du repo principal) :
- le crawl MaX est **séquentiel et photographique** : ~2,3 pages/s en local ;
  38 docs ou 400 docs = même mécanique, coût linéaire au nombre de pages ;
- ce qui n'existe pas côté serveur n'est pas gelé : les 665 fiches d'entités et la
  recherche ont dû être produites **hors MaX** (build Node + Pagefind) ;
- servir : `python3 -m http.server 8899 --directory static-site`
  → http://localhost:8899/grand-siecle/accueil.html
