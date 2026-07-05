/**
 * Grand Siècle — carte des lieux (Leaflet vendorisé, tuiles OSM)
 * Données : ui/js/data/map.json = [{"latitude","longitude","label","id","url","mentions","country"}, …]
 * Carte de densité des citations : rayon des marqueurs ∝ √(mentions).
 */
(function () {
    'use strict';

    /* bbox Europe élargie : cadre initial (les géocodages aberrants — Viſtula
       en Indiana, Mantua dans l'Utah… — restent visibles en dézoomant) */
    var EUROPE = { latMin: 34, latMax: 62, lonMin: -11, lonMax: 33 };

    function message(container, text) {
        var p = document.createElement('p');
        p.className = 'gs-map-coverage';
        p.textContent = text;
        container.parentNode.insertBefore(p, container.nextSibling);
        return p;
    }

    /* décalage déterministe en spirale pour les coordonnées dupliquées
       (ex. « Gallia » et « Gaules » à 46.5,2.9) : quelques centaines de mètres,
       chaque marqueur redevient sélectionnable */
    function spread(lat, lon, n) {
        if (n === 0) { return [lat, lon]; }
        var angle = n * 2.399963; /* angle d'or : répartition régulière */
        var r = 0.006 * Math.sqrt(n); /* ≈ 660 m par pas */
        return [
            lat + r * Math.cos(angle),
            lon + r * Math.sin(angle) / Math.cos(lat * Math.PI / 180)
        ];
    }

    function popupContent(p, base) {
        var wrap = document.createElement('div');
        wrap.className = 'gs-map-popup';

        var badge = document.createElement('span');
        badge.className = 'gs-map-popup-type';
        badge.textContent = 'Lieu';
        wrap.appendChild(badge);

        var label = p.label || p.name || p.id || '';
        var name;
        if (p.id) {
            name = document.createElement('a');
            name.href = base + 'registres/place/' + p.id + '.html';
            name.textContent = label;
        } else {
            name = document.createElement('strong');
            name.textContent = label;
        }
        name.className = 'gs-map-popup-name';
        wrap.appendChild(name);

        var m = parseInt(p.mentions, 10);
        if (!isNaN(m) && m > 0) {
            var mentions = document.createElement('span');
            mentions.className = 'gs-map-popup-mentions';
            mentions.textContent = m + ' mention' + (m > 1 ? 's' : '') + ' dans le corpus';
            wrap.appendChild(mentions);
        }

        if (p.country) {
            var country = document.createElement('em');
            country.className = 'gs-map-popup-country';
            country.textContent = p.country;
            wrap.appendChild(country);
        }
        return wrap;
    }

    function init() {
        var container = document.getElementById('gs-map');
        if (!container) { return; }
        if (typeof L === 'undefined') {
            message(container, 'La carte n’a pas pu être chargée (composant cartographique absent).');
            return;
        }

        /* baseURI est déclarée (const) en fin de body : ne la lire qu'ici,
           une fois le document chargé — jamais au parse du script */
        var base = (typeof baseURI !== 'undefined') ? baseURI : './';

        var placeColor = (getComputedStyle(document.documentElement)
            .getPropertyValue('--gs-type-place') || '').trim() || '#3A6B4A';

        var status = message(container, 'Chargement de la carte…');

        var map = L.map('gs-map').setView([46.6, 2.2], 5);
        var tiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 18,
            attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        }).addTo(map);

        /* fond momentanément indisponible : un seul message, les données restent utilisables */
        var tileErrorShown = false;
        tiles.on('tileerror', function () {
            if (tileErrorShown) { return; }
            tileErrorShown = true;
            message(container, 'Fond de carte momentanément indisponible — les lieux restent cliquables');
        });

        fetch(base + 'ui/js/data/map.json')
            .then(function (r) {
                if (!r.ok) { throw new Error('HTTP ' + r.status); }
                return r.json();
            })
            .then(function (data) {
                var places = Array.isArray(data) ? data : (data.places || data.items || []);
                var shown = 0;
                var europeBounds = [];
                var seen = {};
                places.forEach(function (p) {
                    var lat = parseFloat(p.latitude !== undefined ? p.latitude : p.lat);
                    var lon = parseFloat(p.longitude !== undefined ? p.longitude : (p.lng !== undefined ? p.lng : p.lon));
                    if (isNaN(lat) || isNaN(lon)) { return; }

                    /* doublons de coordonnées → spirale déterministe */
                    var key = lat.toFixed(5) + ',' + lon.toFixed(5);
                    var n = seen[key] || 0;
                    seen[key] = n + 1;
                    var pos = spread(lat, lon, n);

                    var m = parseInt(p.mentions, 10);
                    if (isNaN(m) || m < 1) { m = 1; }
                    var marker = L.circleMarker(pos, {
                        radius: 5 + 2 * Math.sqrt(m),
                        fillColor: placeColor,
                        color: '#FEFCF7',
                        weight: 1.5,
                        fillOpacity: 0.85
                    }).addTo(map);
                    marker.bindPopup(popupContent(p, base));

                    /* seuls les points de la bbox Europe cadrent la vue initiale :
                       les réconciliations aberrantes ne dictent plus un planisphère */
                    if (lat >= EUROPE.latMin && lat <= EUROPE.latMax &&
                        lon >= EUROPE.lonMin && lon <= EUROPE.lonMax) {
                        europeBounds.push(pos);
                    }
                    shown += 1;
                });
                if (europeBounds.length) {
                    map.fitBounds(europeBounds, { padding: [30, 30], maxZoom: 8 });
                } else {
                    map.setView([46.6, 2.2], 5);
                }
                status.textContent = shown + ' lieux géolocalisés affichés · taille des marqueurs proportionnelle au nombre de mentions';
            })
            .catch(function (err) {
                console.error('Carte : échec du chargement de ui/js/data/map.json —', err);
                status.textContent = 'La carte n’a pas pu être chargée. Les lieux restent consultables dans ';
                var a = document.createElement('a');
                a.href = base + 'index/lieux.html';
                a.textContent = 'l’index des lieux';
                status.appendChild(a);
                status.appendChild(document.createTextNode('.'));
            });

        /* tuiles blanches si le conteneur était masqué au chargement */
        setTimeout(function () { map.invalidateSize(); }, 300);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
