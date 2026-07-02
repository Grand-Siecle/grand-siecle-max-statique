/**
 * Grand Siècle — frise chronologique maison (sans dépendance)
 * Données : ui/js/data/timeline.json = [{"id","type","label","start","end","url","sources":[…]}, …]
 * Rendu : barres horizontales (vies de personnes, événements datés) sur un axe min→max.
 */
(function () {
    'use strict';

    var BASE = (typeof baseURI !== 'undefined') ? baseURI : './';

    function el(tag, cls, text) {
        var node = document.createElement(tag);
        if (cls) { node.className = cls; }
        if (text) { node.textContent = text; }
        return node;
    }

    function render(container, items) {
        var valid = items.filter(function (it) {
            return it && it.label && (typeof it.start === 'number' || !isNaN(parseInt(it.start, 10)));
        }).map(function (it) {
            var start = parseInt(it.start, 10);
            var end = (it.end === null || it.end === undefined || it.end === '') ? start : parseInt(it.end, 10);
            if (isNaN(end)) { end = start; }
            return {
                id: it.id, type: it.type || 'person', label: it.label,
                start: start, end: Math.max(start, end), url: it.url
            };
        });

        if (!valid.length) {
            container.appendChild(el('p', 'gs-map-coverage', 'Aucune donnée chronologique disponible.'));
            return;
        }

        valid.sort(function (a, b) { return a.start - b.start; });
        var min = valid[0].start;
        var max = valid.reduce(function (m, it) { return Math.max(m, it.end); }, min);
        if (max === min) { max = min + 1; }
        var span = max - min;

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

        var list = el('div', 'gs-tl-list');
        container.appendChild(list);

        var axis = el('div', 'gs-tl-axis');
        [0, 0.25, 0.5, 0.75, 1].forEach(function (f) {
            axis.appendChild(el('span', null, String(Math.round(min + span * f))));
        });
        container.appendChild(axis);

        function draw() {
            list.textContent = '';
            var shown = 0;
            valid.forEach(function (it) {
                if (current !== 'all' && it.type !== current) { return; }
                shown += 1;
                var row = el('div', 'gs-tl-item');
                var lab = el('span', 'gs-tl-label');
                if (it.url) {
                    var a = document.createElement('a');
                    a.href = it.url.indexOf('://') > -1 || it.url.indexOf('/') === 0 ? it.url : BASE + it.url;
                    a.textContent = it.label;
                    lab.appendChild(a);
                } else {
                    lab.textContent = it.label;
                }
                lab.title = it.label + ' (' + it.start + (it.end !== it.start ? '–' + it.end : '') + ')';
                row.appendChild(lab);
                var track = el('div', 'gs-tl-track');
                var bar = el('span', 'gs-tl-bar gs-tl-' + it.type);
                bar.style.left = (((it.start - min) / span) * 100) + '%';
                bar.style.width = (Math.max(0.4, ((it.end - it.start) / span) * 100)) + '%';
                bar.title = lab.title;
                track.appendChild(bar);
                row.appendChild(track);
                list.appendChild(row);
            });
            count.textContent = shown + ' entrées · ' + min + ' → ' + max;
        }
        draw();
    }

    function init() {
        var container = document.getElementById('gs-timeline');
        if (!container) { return; }
        fetch(BASE + 'ui/js/data/timeline.json')
            .then(function (r) {
                if (!r.ok) { throw new Error('HTTP ' + r.status); }
                return r.json();
            })
            .then(function (data) {
                var items = Array.isArray(data) ? data : (data.items || data.timeline || []);
                render(container, items);
            })
            .catch(function () {
                container.appendChild(el('p', 'gs-map-coverage',
                    'Données chronologiques indisponibles (ui/js/data/timeline.json).'));
            });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
