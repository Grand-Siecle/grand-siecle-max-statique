/**
 * Grand Siècle — JS d'édition MaX (vanilla, sans pb-components)
 * (a) bascule Original/Modernisé  (b) toggle éléments de forme (fw)
 * (c) toggle analyse linguistique + tooltip délégué sur .w
 * (d) popover entité délégué     (e) contrôle de confiance NER (+ Masquées)
 * (f) chargement de registres-browse.js sur les pages d'index
 * (g) légende des entités        (h) repli fac-similé IIIF en erreur
 * (i) hydratation progressive des vignettes du sommaire (max 8 en vol)
 * (j) raccourcis clavier ←/→ sur les pages de lecture
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

    /* état partagé analyse linguistique (couplée à la couche, cf. setLing) */
    var lingBtn = null;
    var lingStatus = null;

    function setLingStatus(msg) {
        if (lingStatus) { lingStatus.textContent = msg || ''; }
    }

    function setLing(on) {
        document.body.classList.toggle('gs-ling-on', on);
        if (lingBtn) {
            lingBtn.classList.toggle('is-active', on);
            lingBtn.setAttribute('aria-pressed', on ? 'true' : 'false');
        }
        lsSet('ling', on ? 'on' : 'off');
        if (!on) {
            hideTooltip();
            setLingStatus('');
        }
    }

    /* les .w n'existent que dans la couche originale : si l'analyse est activée
       en couche modernisée, on bascule sur Original et on le signale */
    function ensureLingLayer() {
        if (document.documentElement.getAttribute('data-layer') === 'reg') {
            applyLayer('orig');
            lsSet(LAYER_KEY, 'orig');
            setLingStatus('affichée sur la couche originale');
        }
    }

    /* légende des types d'entités et des liserés de confiance */
    var LEGEND_TYPES = [
        ['person', 'Personne'], ['place', 'Lieu'], ['organization', 'Organisation'],
        ['work', 'Œuvre'], ['event', 'Événement'], ['technique', 'Technique'],
        ['date', 'Date'], ['artwork', 'Objet'], ['material', 'Matériau']
    ];
    var LEGEND_LINES = [
        ['gs-legend-line-solid', 'filet plein — haute'],
        ['gs-legend-line-dotted', 'pointillé — moyenne'],
        ['gs-legend-line-faded', 'pointillé estompé — faible']
    ];

    function mkLegendTitle(panel, text) {
        var t = document.createElement('div');
        t.className = 'gs-legend-title';
        t.textContent = text;
        panel.appendChild(t);
    }

    function mkLegendItem(panel, sample, label) {
        var item = document.createElement('div');
        item.className = 'gs-legend-item';
        item.appendChild(sample);
        item.appendChild(document.createTextNode(label));
        panel.appendChild(item);
    }

    function buildLegend() {
        var det = document.createElement('details');
        det.className = 'gs-legend';
        var sum = document.createElement('summary');
        sum.textContent = 'Légende';
        det.appendChild(sum);
        var panel = document.createElement('div');
        panel.className = 'gs-legend-panel';
        mkLegendTitle(panel, 'Types d’entités');
        LEGEND_TYPES.forEach(function (pair) {
            var sw = document.createElement('span');
            sw.className = 'gs-legend-swatch';
            sw.style.setProperty('--gs-type', 'var(--gs-type-' + pair[0] + ')');
            mkLegendItem(panel, sw, pair[1]);
        });
        mkLegendTitle(panel, 'Confiance de détection');
        LEGEND_LINES.forEach(function (pair) {
            var line = document.createElement('span');
            line.className = 'gs-legend-line ' + pair[0];
            mkLegendItem(panel, line, pair[1]);
        });
        det.appendChild(panel);
        return det;
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
                /* les annotations .w n'existent pas en couche modernisée :
                   retour en Modernisé = désactivation propre de l'analyse */
                if (pair[0] === 'reg' && document.body.classList.contains('gs-ling-on')) {
                    setLing(false);
                }
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

        /* (c) analyse linguistique (+ état "couche originale", aria-live) */
        var lingOn = lsGet('ling') === 'on';
        if (lingOn) { document.body.classList.add('gs-ling-on'); }
        lingBtn = mkBtn('Analyse linguistique', 'gs-ling-btn', lingOn);
        lingStatus = document.createElement('span');
        lingStatus.className = 'gs-ling-status';
        lingStatus.setAttribute('aria-live', 'polite');
        /* pas de classe CSS dédiée : style discret inline (design system intact) */
        lingStatus.style.fontStyle = 'italic';
        lingStatus.style.fontSize = '0.78rem';
        lingStatus.style.color = 'var(--gs-sepia-text)';
        lingBtn.addEventListener('click', function () {
            var on = !document.body.classList.contains('gs-ling-on');
            setLing(on);
            if (on) { ensureLingLayer(); }
        });
        bar.appendChild(lingBtn);
        bar.appendChild(lingStatus);

        /* (e) confiance NER : Toutes / Haute confiance / Masquées */
        var gNer = mkGroup('Entités');
        var sel = document.createElement('select');
        sel.className = 'gs-toolbar-select';
        sel.setAttribute('aria-label', 'Filtrer les entités par confiance NER');
        [['all', 'Toutes les entités'], ['high', 'Haute confiance'], ['off', 'Masquées']]
            .forEach(function (pair) {
                var o = document.createElement('option');
                o.value = pair[0];
                o.textContent = pair[1];
                sel.appendChild(o);
            });
        var storedNer = lsGet('ner');
        sel.value = (storedNer === 'high' || storedNer === 'off') ? storedNer : 'all';
        applyNerMode(sel.value);
        sel.addEventListener('change', function () {
            applyNerMode(sel.value);
            lsSet('ner', sel.value);
        });
        gNer.appendChild(sel);
        bar.appendChild(gNer);

        /* (g) légende */
        bar.appendChild(buildLegend());

        main.insertBefore(bar, main.firstChild);
    }

    function applyNerMode(mode) {
        document.body.classList.toggle('gs-ner-high', mode === 'high');
        document.body.classList.toggle('gs-ent-off', mode === 'off');
        if (mode !== 'all' && popover) { popover.hidden = true; }
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
        MascNeut: 'masculin/neutre', MascFem: 'masculin/féminin',
        Ind: 'indicatif', Sub: 'subjonctif', Imp: 'impératif', Inf: 'infinitif',
        Par: 'participe', Ger: 'gérondif', Adj: 'adjectif verbal', Sup: 'supin',
        SupUm: 'supin en -um',
        Pres: 'présent', Impa: 'imparfait', Fut: 'futur', Perf: 'parfait',
        Pqp: 'plus-que-parfait', PeriFut: 'futur périphrastique',
        FutAnt: 'futur antérieur',
        Act: 'actif', Pass: 'passif', Dep: 'déponent',
        Pos: 'positif', Comp: 'comparatif', Superl: 'superlatif'
    };

    /* valeurs ambiguës selon la clé (prioritaires sur les deux tables plates) :
       Case=Ind ≠ Mood=Ind, Deg=Sup ≠ Mood=Sup, GENRE=n ≠ CAS=n, etc. */
    var MSD_OVERRIDES = {
        'Case=Ind': 'indéclinable',
        'Deg=Sup': 'superlatif',
        'GENRE=n': 'neutre',
        'MODE=con': 'conditionnel',
        'PERS.=0': 'impersonnel'
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
            var label = (keys[k] || k.toLowerCase());
            if (MSD_OVERRIDES[k + '=' + v]) {
                return label + ' ' + MSD_OVERRIDES[k + '=' + v];
            }
            return label + ' ' + (values[v] || v);
        }).filter(Boolean).join(' · ');
    }

    /* lemme affichable : ni marqueur outil (@latin, @card, @unknown…), ni bruit
       sans lettre (chiffres, '_', diacritiques isolés) ; « sum1 » → « sum »
       (indice d'homographie des lemmatiseurs latins) */
    function displayLemma(lemma) {
        if (!lemma) { return ''; }
        if (lemma.charAt(0) === '@') { return ''; }
        if (!/[a-zà-öø-ÿœæ]/i.test(lemma)) { return ''; }
        return lemma.replace(/(\D)\d+$/, '$1');
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
        var lemma = displayLemma(w.getAttribute('data-lemma'));
        var pos = w.getAttribute('data-pos') || '';
        var msd = decodeMsd(w.getAttribute('data-msd'));
        var norm = w.getAttribute('data-norm') || '';
        if (!lemma && !pos && !msd && !norm) { return; }
        var tt = getTooltip();
        tt.textContent = '';
        var l1 = document.createElement('div');
        l1.className = 'gs-tt-line1';
        /* lemme bruité : on affiche la forme du mot, sans ligne lemme */
        l1.textContent = lemma || w.textContent.trim();
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

    /* entité neutralisée par le filtre courant : Masquées, ou mid/low en mode
       Haute confiance (le CSS coupe déjà pointer-events ; cette garde couvre
       le focus clavier et sert de filet de sécurité) */
    function entBlocked(ent) {
        if (document.body.classList.contains('gs-ent-off')) { return true; }
        if (document.body.classList.contains('gs-ner-high')) {
            var cert = ent.getAttribute('data-cert');
            if (cert === 'mid' || cert === 'low') { return true; }
        }
        return false;
    }

    function initDelegation() {
        document.addEventListener('mouseover', function (ev) {
            var ent = ev.target.closest ? ev.target.closest('.ent') : null;
            if (ent && !entBlocked(ent)) {
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
            if (ent) {
                if (!entBlocked(ent)) { showEntityPopover(ent); }
                return;
            }
            if (document.body.classList.contains('gs-ling-on')) {
                var w = ev.target.closest ? ev.target.closest('.w') : null;
                if (w) { showWordTooltip(w); }
            }
        });
        document.addEventListener('focusout', function () {
            hideTooltip();
            schedulePopHide();
        });
        /* clic (souris ou Entrée clavier) sur une entité filtrée : pas de navigation */
        document.addEventListener('click', function (ev) {
            var ent = ev.target.closest ? ev.target.closest('.ent') : null;
            if (ent && entBlocked(ent)) { ev.preventDefault(); }
        });
        document.addEventListener('keydown', function (ev) {
            if (ev.key === 'Escape') {
                hideTooltip();
                if (popover) { popover.hidden = true; }
            }
        });
        /* popover/tooltip fantômes après défilement */
        window.addEventListener('scroll', function () {
            hideTooltip();
            if (popover) { popover.hidden = true; }
        }, { passive: true });
    }

    /* -------------------------------------- (j) raccourcis clavier ← / → */

    function initKeyboardNav() {
        document.addEventListener('keydown', function (ev) {
            if (ev.key !== 'ArrowLeft' && ev.key !== 'ArrowRight') { return; }
            if (ev.ctrlKey || ev.metaKey || ev.altKey || ev.shiftKey) { return; }
            var t = ev.target;
            if (t && (/^(INPUT|SELECT|TEXTAREA)$/.test(t.tagName) || t.isContentEditable)) { return; }
            var link = document.querySelector(
                ev.key === 'ArrowLeft' ? 'a.gs-page-prev' : 'a.gs-page-next');
            if (link && link.href) { window.location = link.href; }
        });
    }

    /* ----------------------- (h) repli fac-similé IIIF (Gallica en erreur) */

    /* URL de la page Gallica déduite de l'URL IIIF :
       https://gallica.bnf.fr/iiif/ark:/…/bpt6k…/f19/full/,800/0/native.jpg
       → https://gallica.bnf.fr/ark:/…/bpt6k…/f19 */
    function gallicaPageURL(src) {
        var m = /^https?:\/\/gallica\.bnf\.fr\/iiif\/(ark:\/[^/]+\/[^/]+(?:\/f\d+)?)\//.exec(src || '');
        return m ? 'https://gallica.bnf.fr/' + m[1] : null;
    }

    function facsFallback(img) {
        if (img.getAttribute('data-gs-failed')) { return; }
        img.setAttribute('data-gs-failed', 'true');
        var src = img.currentSrc || img.getAttribute('src') || img.getAttribute('data-src') || '';
        if (img.classList.contains('gs-page-thumb')) {
            /* vignette du sommaire : placeholder compact, le n° de page reste */
            var ph = document.createElement('div');
            ph.className = 'gs-page-thumb';
            ph.setAttribute('aria-hidden', 'true');
            img.replaceWith(ph);
            return;
        }
        var wrap = img.closest ? img.closest('.page-facsimile') : null;
        if (!wrap) { return; }
        var fb = document.createElement('div');
        fb.className = 'gs-facs-fallback';
        fb.appendChild(document.createTextNode('Fac-similé indisponible'));
        fb.appendChild(document.createElement('br'));
        var url = gallicaPageURL(src);
        if (url) {
            var a = document.createElement('a');
            a.href = url;
            a.target = '_blank';
            a.rel = 'noopener';
            a.textContent = 'Voir sur Gallica ↗';
            fb.appendChild(a);
        }
        var anchor = img.closest('a');
        (anchor || img).replaceWith(fb);
    }

    function isFacsImg(el) {
        return el && el.tagName === 'IMG' &&
            (el.classList.contains('gs-page-thumb') ||
                (el.closest && el.closest('section.page .page-facsimile')));
    }

    function initFacsErrors() {
        /* les événements error ne remontent pas (pas de bubbling) :
           délégation en phase de capture */
        document.addEventListener('error', function (ev) {
            if (isFacsImg(ev.target)) { facsFallback(ev.target); }
        }, true);
        /* images déjà en échec avant l'attachement du listener */
        document.querySelectorAll('section.page .page-facsimile img, img.gs-page-thumb')
            .forEach(function (img) {
                if (img.getAttribute('src') && img.complete && img.naturalWidth === 0) {
                    facsFallback(img);
                }
            });
    }

    /* ------------------- (i) vignettes du sommaire : hydratation par lots */

    function initThumbQueue() {
        var thumbs = Array.prototype.slice.call(
            document.querySelectorAll('.gs-page-grid img.gs-page-thumb[src]'));
        if (thumbs.length === 0 || !('IntersectionObserver' in window)) { return; }
        var MAX_INFLIGHT = 8;
        var inflight = 0;
        var queue = [];
        /* no-JS : le src d'origine reste dans le HTML ; ici (JS actif) on le
           déporte en data-src pour hydrater progressivement */
        thumbs.forEach(function (img) {
            img.setAttribute('data-src', img.getAttribute('src'));
            img.removeAttribute('src');
        });
        function pump() {
            while (inflight < MAX_INFLIGHT && queue.length > 0) {
                hydrate(queue.shift());
            }
        }
        function hydrate(img) {
            var src = img.getAttribute('data-src');
            if (!src) { return; }
            inflight += 1;
            var done = function () {
                img.removeEventListener('load', done);
                img.removeEventListener('error', done);
                inflight -= 1;
                pump();
            };
            img.addEventListener('load', done);
            img.addEventListener('error', done);
            img.removeAttribute('data-src');
            img.src = src;
        }
        var io = new IntersectionObserver(function (entries) {
            entries.forEach(function (entry) {
                if (entry.isIntersecting) {
                    io.unobserve(entry.target);
                    queue.push(entry.target);
                }
            });
            pump();
        }, { rootMargin: '400px 0px' });
        thumbs.forEach(function (img) { io.observe(img); });
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
            /* préférences incohérentes au chargement : analyse linguistique
               active mais couche modernisée → bascule sur Original */
            if (document.body.classList.contains('gs-ling-on')) {
                ensureLingLayer();
            }
            initKeyboardNav();
        }
        initDelegation();
        initFacsErrors();
        initThumbQueue();
        initIndexPages();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
