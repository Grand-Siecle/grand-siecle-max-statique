/**
 * Grand Siècle — frise chronologique maison (sans dépendance)
 * Données : ui/js/data/timeline.json = [{"id","type","label","start","end","url","sources":[…]}, …]
 * Rendu : barres horizontales (vies de personnes, événements datés) sur un axe min→max,
 * graduations « rondes » par siècles, axe dupliqué sticky en haut, bandes d'époques.
 */
(function () {
    'use strict';

    /* périodisation classique pour les bandes d'arrière-plan */
    var EPOCHS = [
        { label: 'Antiquité', from: -Infinity, to: 476 },
        { label: 'Moyen Âge', from: 476, to: 1492 },
        { label: 'Époque moderne', from: 1492, to: Infinity }
    ];

    function el(tag, cls, text) {
        var node = document.createElement(tag);
        if (cls) { node.className = cls; }
        if (text) { node.textContent = text; }
        return node;
    }

    /* « 500 av. J.-C. », « an 1 », « 1650 » */
    function fmtYear(y) {
        if (y === 0) { return 'an 1'; }
        return y < 0 ? Math.abs(y) + ' av. J.-C.' : String(y);
    }

    function fmtRange(start, end) {
        if (start === end) { return fmtYear(start); }
        if (start < 0 && end < 0) { return Math.abs(start) + '–' + Math.abs(end) + ' av. J.-C.'; }
        return fmtYear(start) + '–' + fmtYear(end);
    }

    /* graduations « rondes » : multiples de siècles, pas adapté au span */
    function niceTicks(min, max) {
        var span = max - min;
        var step;
        if (span > 2000) { step = 500; }
        else if (span > 1000) { step = 250; }
        else if (span > 300) { step = 100; }
        else if (span > 120) { step = 50; }
        else if (span > 60) { step = 25; }
        else { step = 10; }
        var ticks = [];
        for (var t = Math.ceil(min / step) * step; t <= max; t += step) {
            ticks.push(t);
        }
        return ticks;
    }

    function render(container, items) {
        var undatedByType = {};
        var undatedTotal = 0;
        var valid = [];
        items.forEach(function (it) {
            if (!it || !it.label) { return; }
            var start = parseInt(it.start, 10);
            if (isNaN(start)) {
                var t = it.type || 'person';
                undatedByType[t] = (undatedByType[t] || 0) + 1;
                undatedTotal += 1;
                return;
            }
            var end = (it.end === null || it.end === undefined || it.end === '') ? start : parseInt(it.end, 10);
            if (isNaN(end)) { end = start; }
            valid.push({
                id: it.id, type: it.type || 'person', label: it.label,
                start: start, end: Math.max(start, end), url: it.url
            });
        });

        if (!valid.length) {
            container.appendChild(el('p', 'gs-map-coverage', 'Aucune donnée chronologique disponible.'));
            return;
        }

        valid.sort(function (a, b) { return a.start - b.start; });

        /* filtre par type */
        var types = [];
        valid.forEach(function (it) {
            if (types.indexOf(it.type) < 0) { types.push(it.type); }
        });
        var current = 'all';
        var filters = el('div', 'gs-tl-filters');
        var count = el('span', 'gs-map-coverage', '');
        if (types.length > 1) {
            var label = el('span', 'gs-toolbar-label', 'Type');
            filters.appendChild(label);
            var sel = document.createElement('select');
            sel.className = 'gs-toolbar-select';
            sel.setAttribute('aria-label', 'Filtrer la frise par type d’entité');
            var optAll = el('option', null, 'Tous');
            optAll.value = 'all';
            sel.appendChild(optAll);
            var typeNames = {
                person: 'Personnes', event: 'Événements', work: 'Œuvres',
                organization: 'Organisations', place: 'Lieux'
            };
            types.forEach(function (t) {
                var o = el('option', null, typeNames[t] || t);
                o.value = t;
                sel.appendChild(o);
            });
            sel.addEventListener('change', function () {
                current = sel.value;
                draw();
            });
            filters.appendChild(sel);
        }
        filters.appendChild(count);
        container.appendChild(filters);

        /* axe dupliqué en haut, sticky (nouvelle classe : .gs-tl-axis intouchée) */
        var axisTopWrap = el('div', 'gs-tl-axis-sticky');
        var axisTop = el('div', 'gs-tl-axis gs-tl-scale');
        axisTopWrap.appendChild(axisTop);
        container.appendChild(axisTopWrap);

        var list = el('div', 'gs-tl-list');
        container.appendChild(list);

        var axisBottom = el('div', 'gs-tl-axis gs-tl-scale');
        container.appendChild(axisBottom);

        var base = (typeof baseURI !== 'undefined') ? baseURI : './';

        function renderAxis(axis, ticks, min, span) {
            axis.textContent = '';
            ticks.forEach(function (t) {
                var s = el('span', null, fmtYear(t));
                s.style.left = (((t - min) / span) * 100) + '%';
                axis.appendChild(s);
            });
        }

        /* bandes d'époques + grille séculaire, en décor absolu derrière les barres */
        function renderDeco(ticks, min, max, span) {
            var deco = el('div', 'gs-tl-deco');
            deco.setAttribute('aria-hidden', 'true');
            var visible = EPOCHS.filter(function (e) { return e.from < max && e.to > min; });
            if (visible.length > 1) {
                list.classList.add('gs-tl-has-epochs');
                visible.forEach(function (e) {
                    var from = Math.max(e.from, min);
                    var to = Math.min(e.to, max);
                    var band = el('div', 'gs-tl-epoch' +
                        (EPOCHS.indexOf(e) % 2 === 0 ? ' gs-tl-epoch-alt' : ''));
                    band.style.left = (((from - min) / span) * 100) + '%';
                    band.style.width = (((to - from) / span) * 100) + '%';
                    band.appendChild(el('span', 'gs-tl-epoch-label', e.label));
                    deco.appendChild(band);
                });
            } else {
                /* une seule époque couverte : pas de bandes */
                list.classList.remove('gs-tl-has-epochs');
            }
            ticks.forEach(function (t) {
                var line = el('span', 'gs-tl-gridline');
                line.style.left = (((t - min) / span) * 100) + '%';
                deco.appendChild(line);
            });
            list.appendChild(deco);
        }

        function draw() {
            list.textContent = '';
            var subset = valid.filter(function (it) {
                return current === 'all' || it.type === current;
            });
            var undated = (current === 'all') ? undatedTotal : (undatedByType[current] || 0);

            if (!subset.length) {
                axisTop.textContent = '';
                axisBottom.textContent = '';
                count.textContent = '0 entrée' +
                    (undated > 0 ? ' · + ' + undated + ' non datée' + (undated > 1 ? 's' : '') : '');
                return;
            }

            /* bornes et graduations recalculées sur le sous-ensemble filtré */
            var min = subset[0].start;
            var max = subset.reduce(function (m, it) { return Math.max(m, it.end); }, min);
            if (max === min) { max = min + 1; }
            var span = max - min;
            var ticks = niceTicks(min, max);

            renderAxis(axisTop, ticks, min, span);
            renderAxis(axisBottom, ticks, min, span);
            renderDeco(ticks, min, max, span);

            subset.forEach(function (it) {
                var row = el('div', 'gs-tl-item');
                var lab = el('span', 'gs-tl-label');
                var name;
                if (it.url) {
                    name = document.createElement('a');
                    name.href = it.url.indexOf('://') > -1 || it.url.indexOf('/') === 0 ? it.url : base + it.url;
                    name.textContent = it.label;
                } else {
                    name = el('span', null, it.label);
                }
                name.className = (name.className ? name.className + ' ' : '') + 'gs-tl-name';
                lab.appendChild(name);
                lab.appendChild(el('span', 'gs-tl-year', fmtRange(it.start, it.end)));
                lab.title = it.label + ' (' + it.start + (it.end !== it.start ? '–' + it.end : '') + ')';
                row.appendChild(lab);
                var track = el('div', 'gs-tl-track');
                var bar = el('span', 'gs-tl-bar gs-tl-' + it.type);
                bar.style.left = (((it.start - min) / span) * 100) + '%';
                bar.style.width = (Math.max(0.4, ((it.end - it.start) / span) * 100)) + '%';
                bar.title = lab.title;
                bar.setAttribute('aria-hidden', 'true'); /* décorative : l'info est dans le texte */
                track.appendChild(bar);
                row.appendChild(track);
                list.appendChild(row);
            });

            count.textContent = subset.length + ' entrée' + (subset.length > 1 ? 's' : '') +
                ' · ' + fmtYear(min) + ' → ' + fmtYear(max) +
                (undated > 0 ? ' · + ' + undated + ' non datée' + (undated > 1 ? 's' : '') : '');
        }
        draw();
    }

    function init() {
        var container = document.getElementById('gs-timeline');
        if (!container) { return; }

        /* baseURI est déclarée (const) en fin de body : ne la lire qu'ici,
           une fois le document chargé — jamais au parse du script */
        var base = (typeof baseURI !== 'undefined') ? baseURI : './';

        var status = el('p', 'gs-map-coverage', 'Chargement de la frise chronologique…');
        container.appendChild(status);

        fetch(base + 'ui/js/data/timeline.json')
            .then(function (r) {
                if (!r.ok) { throw new Error('HTTP ' + r.status); }
                return r.json();
            })
            .then(function (data) {
                var items = Array.isArray(data) ? data : (data.items || data.timeline || []);
                container.removeChild(status);
                render(container, items);
            })
            .catch(function (err) {
                console.error('Chronologie : échec du chargement de ui/js/data/timeline.json —', err);
                status.textContent = 'La frise n’a pas pu être chargée. Les personnes et événements restent consultables dans ';
                var a = document.createElement('a');
                a.href = base + 'index/personnes.html';
                a.textContent = 'l’index des entités';
                status.appendChild(a);
                status.appendChild(document.createTextNode('.'));
            });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
