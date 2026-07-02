/**
 * Grand Siècle — JS d'édition MaX (vanilla, sans pb-components)
 * (a) bascule Original/Modernisé  (b) toggle éléments de forme (fw)
 * (c) toggle analyse linguistique + tooltip délégué sur .w
 * (d) popover entité délégué     (e) contrôle de confiance NER
 * (f) chargement de registres-browse.js sur les pages d'index
 */
(function () {
    'use strict';

    var BASE = (typeof baseURI !== 'undefined') ? baseURI : './';
    var ROUTE = (typeof route !== 'undefined') ? route : '';
    var LS = 'GdSiecle.';

    /* ---------------------------------------------------------------- utils */

    function lsGet(key) {
        try { return localStorage.getItem(LS + key); } catch (e) { return null; }
    }
    function lsSet(key, value) {
        try { localStorage.setItem(LS + key, value); } catch (e) { /* noop */ }
    }

    function docId() {
        if (/\.xml$/.test(ROUTE)) {
            return ROUTE.replace(/^.*\//, '').replace(/\.xml$/, '');
        }
        var page = document.querySelector('section.page[id]');
        if (page) { return page.id.replace(/-page-.*$/, ''); }
        return '';
    }

    function isDocumentPage() {
        return !!document.querySelector('section.page, .line-choice, .zone');
    }

    /* ------------------------------------------------ (a) couche orig / reg */

    var LAYER_KEY = 'layer.' + (docId() || 'global');

    function applyLayer(layer) {
        document.documentElement.setAttribute('data-layer', layer);
        document.querySelectorAll('.gs-layer-btn').forEach(function (btn) {
            var active = btn.getAttribute('data-value') === layer;
            btn.classList.toggle('is-active', active);
            btn.setAttribute('aria-pressed', active ? 'true' : 'false');
        });
    }

    function corpusDefaultLayer(id, cb) {
        fetch(BASE + 'ui/js/data/corpus.json')
            .then(function (r) { return r.ok ? r.json() : null; })
            .then(function (data) {
                if (!data) { return; }
                var entry = null;
                var list = Array.isArray(data) ? data : (data.documents || data.docs || null);
                if (list) {
                    entry = list.filter(function (d) {
                        return d && (d.id === id || d.doc === id);
                    })[0];
                } else if (typeof data === 'object' && data[id]) {
                    entry = data[id];
                }
                if (!entry) { return; }
                var layer = entry.defaultLayer || entry['default-layer'] ||
                    entry.default_layer || entry.layer || entry['default'];
                if (layer === 'orig' || layer === 'reg') { cb(layer); }
            })
            .catch(function () { /* base éventuellement vide : silencieux */ });
    }

    function initLayer() {
        var stored = lsGet(LAYER_KEY);
        if (stored === 'orig' || stored === 'reg') {
            applyLayer(stored);
            return;
        }
        var el = document.querySelector('[data-default-layer]');
        if (el) {
            var def = el.getAttribute('data-default-layer');
            applyLayer(def === 'orig' ? 'orig' : 'reg');
            return;
        }
        applyLayer('reg');
        var id = docId();
        if (id) { corpusDefaultLayer(id, applyLayer); }
    }

    /* --------------------------------------------------- barre d'outils doc */

    function mkBtn(label, cls, pressed) {
        var b = document.createElement('button');
        b.type = 'button';
        b.className = 'gs-toolbar-btn' + (cls ? ' ' + cls : '');
        b.textContent = label;
        b.setAttribute('aria-pressed', pressed ? 'true' : 'false');
        if (pressed) { b.classList.add('is-active'); }
        return b;
    }

    function mkGroup(labelText) {
        var g = document.createElement('span');
        g.className = 'gs-toolbar-group';
        if (labelText) {
            var l = document.createElement('span');
            l.className = 'gs-toolbar-label';
            l.textContent = labelText;
            g.appendChild(l);
        }
        return g;
    }

    function buildToolbar() {
        var main = document.getElementById('main-max-container');
        if (!main) { return; }
        var bar = document.createElement('div');
        bar.className = 'gs-doc-toolbar';
        bar.setAttribute('role', 'toolbar');
        bar.setAttribute('aria-label', 'Options d’affichage du texte');

        /* (a) couche */
        var gLayer = mkGroup('Couche');
        [['orig', 'Original'], ['reg', 'Modernisé']].forEach(function (pair) {
            var btn = mkBtn(pair[1], 'gs-layer-btn', false);
            btn.setAttribute('data-value', pair[0]);
            btn.addEventListener('click', function () {
                applyLayer(pair[0]);
                lsSet(LAYER_KEY, pair[0]);
            });
            gLayer.appendChild(btn);
        });
        bar.appendChild(gLayer);

        /* (b) éléments de forme */
        var fwOn = lsGet('fw') === 'on';
        if (fwOn) { document.body.classList.add('gs-show-fw'); }
        var fwBtn = mkBtn('Éléments de forme', 'gs-fw-btn', fwOn);
        fwBtn.addEventListener('click', function () {
            var on = document.body.classList.toggle('gs-show-fw');
            fwBtn.classList.toggle('is-active', on);
            fwBtn.setAttribute('aria-pressed', on ? 'true' : 'false');
            lsSet('fw', on ? 'on' : 'off');
        });
        bar.appendChild(fwBtn);

        /* (c) analyse linguistique */
        var lingOn = lsGet('ling') === 'on';
        if (lingOn) { document.body.classList.add('gs-ling-on'); }
        var lingBtn = mkBtn('Analyse linguistique', 'gs-ling-btn', lingOn);
        lingBtn.addEventListener('click', function () {
            var on = document.body.classList.toggle('gs-ling-on');
            lingBtn.classList.toggle('is-active', on);
            lingBtn.setAttribute('aria-pressed', on ? 'true' : 'false');
            lsSet('ling', on ? 'on' : 'off');
            if (!on) { hideTooltip(); }
        });
        bar.appendChild(lingBtn);

        /* (e) confiance NER */
        var gNer = mkGroup('Confiance NER');
        var sel = document.createElement('select');
        sel.className = 'gs-toolbar-select';
        sel.setAttribute('aria-label', 'Filtrer les entités par confiance NER');
        [['all', 'Toutes les entités'], ['high', 'Haute confiance']].forEach(function (pair) {
            var o = document.createElement('option');
            o.value = pair[0];
            o.textContent = pair[1];
            sel.appendChild(o);
        });
        sel.value = lsGet('ner') === 'high' ? 'high' : 'all';
        document.body.classList.toggle('gs-ner-high', sel.value === 'high');
        sel.addEventListener('change', function () {
            document.body.classList.toggle('gs-ner-high', sel.value === 'high');
            lsSet('ner', sel.value);
        });
        gNer.appendChild(sel);
        bar.appendChild(gNer);

        main.insertBefore(bar, main.firstChild);
    }

    /* -------------------------------------- (c) tooltip linguistique délégué */

    var POS_LABELS = {
        NOMcom: 'nom commun', NOMpro: 'nom propre',
        VER: 'verbe', VERcjg: 'verbe conjugué', VERinf: 'verbe (infinitif)',
        VERppe: 'participe passé', VERppa: 'participe présent',
        ADJqua: 'adjectif qualificatif', ADJind: 'adjectif indéfini',
        ADJcar: 'adjectif cardinal', ADJord: 'adjectif ordinal',
        ADJpos: 'adjectif possessif', ADJdem: 'adjectif démonstratif',
        ADVgen: 'adverbe', ADVneg: 'adverbe de négation', ADVint: 'adverbe interrogatif',
        PROper: 'pronom personnel', PROdem: 'pronom démonstratif',
        PROind: 'pronom indéfini', PROrel: 'pronom relatif',
        PROint: 'pronom interrogatif', PROpos: 'pronom possessif', PROimp: 'pronom impersonnel',
        DETdef: 'déterminant défini', DETndf: 'déterminant indéfini',
        DETdem: 'déterminant démonstratif', DETpos: 'déterminant possessif',
        DETind: 'déterminant indéfini', DETcar: 'déterminant cardinal',
        PRE: 'préposition', CONcoo: 'conjonction de coordination',
        CONsub: 'conjonction de subordination', INJ: 'interjection',
        ETR: 'mot étranger', ABR: 'abréviation',
        PONfbl: 'ponctuation faible', PONfrt: 'ponctuation forte'
    };

    /* tagset français (NOMB.=, GENRE=, MODE=, TEMPS=, PERS.=, CAS=) */
    var MSD_FR_KEYS = {
        'NOMB.': 'nombre', 'GENRE': 'genre', 'MODE': 'mode',
        'TEMPS': 'temps', 'PERS.': 'personne', 'CAS': 'cas'
    };
    var MSD_FR_VALUES = {
        s: 'singulier', p: 'pluriel', m: 'masculin', f: 'féminin',
        ind: 'indicatif', sub: 'subjonctif', cnd: 'conditionnel', imp: 'impératif',
        inf: 'infinitif', ppa: 'participe présent', ppe: 'participe passé',
        pst: 'présent', ipf: 'imparfait', fut: 'futur', psp: 'passé simple',
        pqp: 'plus-que-parfait', i: 'régime indirect', j: 'régime direct',
        n: 'nominatif', r: 'régime',
        '1': '1ʳᵉ pers.', '2': '2ᵉ pers.', '3': '3ᵉ pers.'
    };

    /* tagset latin (Case=, Numb=, Gend=, Mood=, Tense=, Voice=, Person=, Deg=) */
    var MSD_LAT_KEYS = {
        Case: 'cas', Numb: 'nombre', Gend: 'genre', Mood: 'mode',
        Tense: 'temps', Voice: 'voix', Person: 'personne', Deg: 'degré'
    };
    var MSD_LAT_VALUES = {
        Nom: 'nominatif', Gen: 'génitif', Dat: 'datif', Acc: 'accusatif',
        Abl: 'ablatif', Voc: 'vocatif', Loc: 'locatif',
        Sing: 'singulier', Plur: 'pluriel',
        Masc: 'masculin', Fem: 'féminin', Neut: 'neutre', Com: 'commun',
        Ind: 'indicatif', Sub: 'subjonctif', Imp: 'impératif', Inf: 'infinitif',
        Par: 'participe', Ger: 'gérondif', Adj: 'adjectif verbal', Sup: 'supin',
        Pres: 'présent', Impa: 'imparfait', Fut: 'futur', Perf: 'parfait',
        Pqp: 'plus-que-parfait', PeriFut: 'futur périphrastique',
        Act: 'actif', Pass: 'passif', Dep: 'déponent',
        Pos: 'positif', Comp: 'comparatif', Superl: 'superlatif'
    };

    function decodeMsd(msd) {
        if (!msd || msd === 'MORPH=empty' || msd === '_') { return ''; }
        var latin = msd.indexOf('Case=') > -1 || msd.indexOf('Numb=') > -1 ||
            msd.indexOf('Mood=') > -1 || msd.indexOf('Tense=') > -1 ||
            msd.indexOf('Gend=') > -1 || msd.indexOf('Voice=') > -1;
        var keys = latin ? MSD_LAT_KEYS : MSD_FR_KEYS;
        var values = latin ? MSD_LAT_VALUES : MSD_FR_VALUES;
        return msd.split('|').map(function (pair) {
            var i = pair.indexOf('=');
            if (i < 0) { return pair; }
            var k = pair.slice(0, i), v = pair.slice(i + 1);
            if (v === 'empty' || v === '_' || v === '') { return ''; }
            return (keys[k] || k.toLowerCase()) + ' ' + (values[v] || v);
        }).filter(Boolean).join(' · ');
    }

    var tooltip = null;

    function getTooltip() {
        if (!tooltip) {
            tooltip = document.createElement('div');
            tooltip.className = 'gs-tooltip';
            tooltip.setAttribute('role', 'tooltip');
            tooltip.hidden = true;
            document.body.appendChild(tooltip);
        }
        return tooltip;
    }

    function placeNear(box, target) {
        var rect = target.getBoundingClientRect();
        box.style.visibility = 'hidden';
        box.hidden = false;
        var top = rect.bottom + window.scrollY + 6;
        var left = rect.left + window.scrollX;
        if (left + box.offsetWidth > window.scrollX + document.documentElement.clientWidth - 12) {
            left = window.scrollX + document.documentElement.clientWidth - box.offsetWidth - 12;
        }
        box.style.top = top + 'px';
        box.style.left = Math.max(4, left) + 'px';
        box.style.visibility = '';
    }

    function showWordTooltip(w) {
        var lemma = w.getAttribute('data-lemma') || '';
        var pos = w.getAttribute('data-pos') || '';
        var msd = decodeMsd(w.getAttribute('data-msd'));
        var norm = w.getAttribute('data-norm') || '';
        if (!lemma && !pos && !msd && !norm) { return; }
        var tt = getTooltip();
        tt.textContent = '';
        var l1 = document.createElement('div');
        l1.className = 'gs-tt-line1';
        l1.textContent = lemma || w.textContent;
        if (pos) {
            var posSpan = document.createElement('span');
            posSpan.className = 'gs-tt-pos';
            posSpan.textContent = ' (' + (POS_LABELS[pos] || pos) + ')';
            l1.appendChild(posSpan);
        }
        tt.appendChild(l1);
        if (msd) {
            var l2 = document.createElement('div');
            l2.className = 'gs-tt-msd';
            l2.textContent = msd;
            tt.appendChild(l2);
        }
        if (norm) {
            var l3 = document.createElement('div');
            l3.className = 'gs-tt-norm';
            l3.textContent = 'forme normalisée : ' + norm;
            tt.appendChild(l3);
        }
        placeNear(tt, w);
    }

    function hideTooltip() {
        if (tooltip) { tooltip.hidden = true; }
    }

    /* ------------------------------------------- (d) popover entité délégué */

    var TYPE_LABELS = {
        person: 'Personne', place: 'Lieu', organization: 'Organisation',
        org: 'Organisation', work: 'Œuvre', event: 'Événement',
        artwork: 'Objet / œuvre d’art', object: 'Objet / œuvre d’art',
        material: 'Matériau', technique: 'Technique', date: 'Date'
    };
    var CERT_LABELS = {
        high: 'confiance haute', mid: 'confiance moyenne', low: 'confiance faible'
    };
    var REF_RX = /^[a-z]+-[0-9]{6}$/;

    var popover = null;
    var popHideTimer = null;

    function getPopover() {
        if (!popover) {
            popover = document.createElement('div');
            popover.className = 'gs-popover';
            popover.hidden = true;
            popover.addEventListener('mouseenter', function () {
                if (popHideTimer) { clearTimeout(popHideTimer); popHideTimer = null; }
            });
            popover.addEventListener('mouseleave', schedulePopHide);
            document.body.appendChild(popover);
        }
        return popover;
    }

    function schedulePopHide() {
        if (popHideTimer) { clearTimeout(popHideTimer); }
        popHideTimer = setTimeout(function () {
            if (popover) { popover.hidden = true; }
        }, 250);
    }

    function entityHref(ent, type, ref) {
        var href = ent.getAttribute('href');
        if (href) { return href; }
        if (ref && REF_RX.test(ref) && type) {
            return BASE + 'registres/' + type + '/' + ref + '.html';
        }
        return null;
    }

    function showEntityPopover(ent) {
        if (popHideTimer) { clearTimeout(popHideTimer); popHideTimer = null; }
        var type = ent.getAttribute('data-type') || '';
        var ref = (ent.getAttribute('data-ref') || '').replace(/^#/, '');
        var cert = ent.getAttribute('data-cert') || '';
        var pop = getPopover();
        pop.style.setProperty('--gs-type', 'var(--gs-type-' + (type === 'org' ? 'organization' : type) + ')');
        pop.textContent = '';
        var label = document.createElement('div');
        label.className = 'gs-pop-label';
        label.textContent = ent.textContent.trim();
        pop.appendChild(label);
        var meta = document.createElement('div');
        var typeBadge = document.createElement('span');
        typeBadge.className = 'gs-pop-type';
        typeBadge.textContent = TYPE_LABELS[type] || type || 'Entité';
        meta.appendChild(typeBadge);
        if (cert) {
            var certSpan = document.createElement('span');
            certSpan.className = 'gs-pop-cert';
            certSpan.textContent = CERT_LABELS[cert] || ('confiance : ' + cert);
            meta.appendChild(certSpan);
        }
        pop.appendChild(meta);
        var href = entityHref(ent, type, ref);
        if (href) {
            var link = document.createElement('a');
            link.className = 'gs-pop-link';
            link.href = href;
            link.textContent = 'Voir la fiche';
            pop.appendChild(link);
        } else {
            var un = document.createElement('div');
            un.className = 'gs-pop-cert';
            un.textContent = 'Entité non réconciliée (sans fiche)';
            pop.appendChild(un);
        }
        placeNear(pop, ent);
    }

    /* --------------------------------------------------- écouteurs délégués */

    function initDelegation() {
        document.addEventListener('mouseover', function (ev) {
            var ent = ev.target.closest ? ev.target.closest('.ent') : null;
            if (ent && !document.body.classList.contains('gs-ent-off')) {
                showEntityPopover(ent);
                return;
            }
            if (document.body.classList.contains('gs-ling-on')) {
                var w = ev.target.closest ? ev.target.closest('.w') : null;
                if (w) { showWordTooltip(w); return; }
            }
        });
        document.addEventListener('mouseout', function (ev) {
            if (ev.target.closest) {
                if (ev.target.closest('.ent')) { schedulePopHide(); }
                if (ev.target.closest('.w')) { hideTooltip(); }
            }
        });
        document.addEventListener('focusin', function (ev) {
            var ent = ev.target.closest ? ev.target.closest('.ent') : null;
            if (ent) { showEntityPopover(ent); return; }
            if (document.body.classList.contains('gs-ling-on')) {
                var w = ev.target.closest ? ev.target.closest('.w') : null;
                if (w) { showWordTooltip(w); }
            }
        });
        document.addEventListener('focusout', function () {
            hideTooltip();
            schedulePopHide();
        });
        document.addEventListener('keydown', function (ev) {
            if (ev.key === 'Escape') {
                hideTooltip();
                if (popover) { popover.hidden = true; }
            }
        });
    }

    /* ------------------------------- (f) pages d'index : registres-browse.js */

    var INDEX_SLUGS = ['personnes', 'lieux', 'organisations', 'oeuvres',
        'evenements', 'objets', 'materiaux', 'techniques', 'dates'];

    function initIndexPages() {
        var found = INDEX_SLUGS.some(function (slug) {
            return document.getElementById('index-' + slug);
        });
        if (!found) { return; }
        if (document.querySelector('script[data-gs="registres-browse"]')) { return; }
        var s = document.createElement('script');
        s.src = BASE + 'ui/js/registres-browse.js';
        s.defer = true;
        s.setAttribute('data-gs', 'registres-browse');
        document.body.appendChild(s);
    }

    /* ------------------------------------------------------------------ init */

    function init() {
        if (isDocumentPage()) {
            buildToolbar();
            initLayer();
        }
        initDelegation();
        initIndexPages();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
