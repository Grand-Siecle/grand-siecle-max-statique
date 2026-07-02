/**
 * registres-browse.js — Grand Siècle sous MaX (statique)
 *
 * Enhancement client AUTONOME (vanilla, aucun CDN, aucune dépendance) des
 * pages d'index d'entités rendues par le plugin index de MaX.
 *
 * Contrat : la page contient un conteneur #index-{slug} avec
 * slug ∈ personnes, lieux, organisations, oeuvres, evenements, objets,
 * materiaux, techniques, dates. Chaque entrée de la liste contient un lien
 * vers une fiche registres/{type}/{ref}.html (ref = [a-z]+-[0-9]{6}).
 *
 * Le script charge ../ui/js/data/browse/{type}.json (généré par
 * scripts/build-entities.mjs) et ajoute :
 *   - recherche instantanée (libellé, clé de tri, variantes — insensible
 *     à la casse et aux diacritiques) ;
 *   - filtres à facettes simples par type (occupation / nationalité / sexe
 *     pour les personnes, pays pour les lieux, langue pour les œuvres…)
 *     + confiance de réconciliation pour tous ;
 *   - compteur de résultats + bouton Réinitialiser.
 * Le filtrage se fait en masquant/affichant les éléments DOM existants.
 * En cas d'échec (JSON absent, markup inattendu), la page reste intacte.
 */
(function () {
  'use strict';

  var SLUG2TYPE = {
    personnes: 'person',
    lieux: 'place',
    organisations: 'organization',
    oeuvres: 'work',
    evenements: 'event',
    objets: 'artwork',
    materiaux: 'material',
    techniques: 'technique',
    dates: 'date'
  };

  /** facettes par type : [clé JSON, libellé, extracteur → liste de labels] */
  var FACETS = {
    person: [
      ['occupation', 'Occupation', function (it) { return (it.occupations || []).map(lbl); }],
      ['nationality', 'Nationalité', function (it) { return (it.nationalities || []).map(lbl); }],
      ['sex', 'Sexe', function (it) { return it.sex ? [lbl(it.sex)] : []; }]
    ],
    place: [
      ['country', 'Pays', function (it) { return it.country ? [lbl(it.country)] : []; }]
    ],
    work: [
      ['lang', 'Langue', function (it) { return it.lang ? [lbl(it.lang)] : []; }]
    ],
    event: [
      ['place', 'Lieu', function (it) { return it.place ? [lbl(it.place)] : []; }]
    ],
    artwork: [
      ['objtype', 'Type d’objet', function (it) { return it.objectType ? [lbl(it.objectType)] : []; }]
    ]
  };

  var CONF_LABELS = { high: 'fiable', medium: 'moyenne', low: 'incertaine', none: 'non réconciliée' };

  function lbl(o) { return (o && o.label) || ''; }

  function fold(s) {
    return String(s || '')
      .toLowerCase()
      .normalize('NFD')
      .replace(/[̀-ͯ]/g, '');
  }

  function debounce(fn, ms) {
    var t;
    return function () {
      clearTimeout(t);
      var args = arguments, self = this;
      t = setTimeout(function () { fn.apply(self, args); }, ms);
    };
  }

  function findContainer() {
    for (var slug in SLUG2TYPE) {
      var el = document.getElementById('index-' + slug);
      if (el) return { el: el, slug: slug, type: SLUG2TYPE[slug] };
    }
    return null;
  }

  /** repère les entrées de la liste : plus proche ancêtre li (ou le lien) de
   *  chaque lien vers une fiche {ref}.html — un seul élément par ref. */
  function collectRows(container) {
    var links = container.querySelectorAll('a[href]');
    var rows = [];
    var seen = {};
    for (var i = 0; i < links.length; i++) {
      var href = links[i].getAttribute('href') || '';
      var m = href.match(/([a-z]+-[0-9]{6})(?:\.html|\/?)(?:[#?].*)?$/);
      if (!m) continue;
      var ref = m[1];
      var row = links[i].closest('li') || links[i].closest('.split-list-item') || links[i];
      if (!row || row === container) row = links[i];
      if (seen[ref]) continue;
      seen[ref] = true;
      rows.push({ ref: ref, el: row, text: fold(row.textContent) });
    }
    return rows;
  }

  function buildFacetOptions(items, extract) {
    var counts = {};
    items.forEach(function (it) {
      extract(it).forEach(function (v) {
        if (!v) return;
        counts[v] = (counts[v] || 0) + 1;
      });
    });
    return Object.keys(counts)
      .filter(function (v) { return counts[v] >= 2; })   // exclure les singletons (règle app)
      .sort(function (a, b) { return counts[b] - counts[a] || a.localeCompare(b, 'fr'); })
      .slice(0, 30)
      .map(function (v) { return { value: v, count: counts[v] }; });
  }

  function el(tag, attrs, children) {
    var e = document.createElement(tag);
    for (var k in (attrs || {})) {
      if (k === 'text') e.textContent = attrs[k];
      else e.setAttribute(k, attrs[k]);
    }
    (children || []).forEach(function (c) { e.appendChild(c); });
    return e;
  }

  function init() {
    var ctx = findContainer();
    if (!ctx) return;

    fetch('../ui/js/data/browse/' + ctx.type + '.json')
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(function (data) { enhance(ctx, data); })
      .catch(function (err) {
        // silencieux : la page d'index reste utilisable sans enhancement
        if (window.console) console.warn('registres-browse: JSON indisponible —', err);
      });
  }

  function enhance(ctx, data) {
    var items = (data && data.items) || [];
    if (!items.length) return;

    var byRef = {};
    items.forEach(function (it) {
      it._search = fold([it.label, it.sort, it.standard]
        .concat(it.variants || [])
        .filter(Boolean)
        .join(' '));
      byRef[it.id] = it;
    });

    var rows = collectRows(ctx.el);
    if (!rows.length) return;
    rows.forEach(function (r) { r.item = byRef[r.ref] || null; });

    /* ------ toolbar ------ */
    var toolbar = el('div', { 'class': 'gs-browse-toolbar', role: 'search' });

    var searchInput = el('input', {
      type: 'search',
      placeholder: 'Rechercher…',
      'aria-label': 'Recherche instantanée dans l’index'
    });
    toolbar.appendChild(el('div', { 'class': 'gs-browse-field' }, [
      el('label', { text: 'Recherche' }),
      searchInput
    ]));

    var selects = [];

    function addSelect(label, options, getValues) {
      if (!options.length) return;
      var sel = el('select', { 'aria-label': label });
      sel.appendChild(el('option', { value: '', text: label + ' — toutes' }));
      options.forEach(function (o) {
        sel.appendChild(el('option', { value: o.value, text: o.value + ' (' + o.count + ')' }));
      });
      toolbar.appendChild(el('div', { 'class': 'gs-browse-field' }, [
        el('label', { text: label }),
        sel
      ]));
      selects.push({ sel: sel, getValues: getValues });
      sel.addEventListener('change', apply);
    }

    (FACETS[ctx.type] || []).forEach(function (f) {
      addSelect(f[1], buildFacetOptions(items, f[2]), f[2]);
    });

    // facette universelle : confiance de réconciliation
    var confPresent = {};
    items.forEach(function (it) { confPresent[it.confidence || 'none'] = (confPresent[it.confidence || 'none'] || 0) + 1; });
    var confOpts = ['high', 'medium', 'low', 'none']
      .filter(function (c) { return confPresent[c]; })
      .map(function (c) { return { value: c, count: confPresent[c] }; });
    if (confOpts.length > 1) {
      var confSel = el('select', { 'aria-label': 'Confiance de réconciliation' });
      confSel.appendChild(el('option', { value: '', text: 'Confiance — toutes' }));
      confOpts.forEach(function (o) {
        confSel.appendChild(el('option', { value: o.value, text: CONF_LABELS[o.value] + ' (' + o.count + ')' }));
      });
      toolbar.appendChild(el('div', { 'class': 'gs-browse-field' }, [
        el('label', { text: 'Réconciliation' }),
        confSel
      ]));
      selects.push({
        sel: confSel,
        getValues: function (it) { return [it.confidence || 'none']; },
        raw: true
      });
      confSel.addEventListener('change', apply);
    }

    var resetBtn = el('button', { type: 'button', 'class': 'gs-browse-reset', text: 'Réinitialiser' });
    toolbar.appendChild(resetBtn);

    var counter = el('span', { 'class': 'gs-browse-count', 'aria-live': 'polite' });
    toolbar.appendChild(counter);

    var empty = el('p', { 'class': 'gs-browse-empty gs-browse-hidden', text: 'Aucun résultat pour ces critères.' });

    ctx.el.insertBefore(toolbar, ctx.el.firstChild);
    toolbar.parentNode.insertBefore(empty, toolbar.nextSibling);

    /* ------ filtrage ------ */
    function apply() {
      var q = fold(searchInput.value.trim());
      var visible = 0;
      rows.forEach(function (r) {
        var ok = true;
        if (q) {
          var hay = r.item ? r.item._search : r.text;
          ok = hay.indexOf(q) !== -1;
        }
        if (ok) {
          for (var i = 0; i < selects.length; i++) {
            var s = selects[i];
            if (!s.sel.value) continue;
            if (!r.item) { ok = false; break; }
            var vals = s.getValues(r.item);
            if (vals.indexOf(s.sel.value) === -1) { ok = false; break; }
          }
        }
        r.el.classList.toggle('gs-browse-hidden', !ok);
        if (ok) visible++;
      });
      counter.textContent = visible + ' / ' + rows.length + ' résultat' + (visible > 1 ? 's' : '');
      empty.classList.toggle('gs-browse-hidden', visible !== 0);
    }

    searchInput.addEventListener('input', debounce(apply, 150));
    resetBtn.addEventListener('click', function () {
      searchInput.value = '';
      selects.forEach(function (s) { s.sel.value = ''; });
      apply();
    });

    apply();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
