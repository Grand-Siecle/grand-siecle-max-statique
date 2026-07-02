/**
 * Grand Siècle — carte des lieux (Leaflet vendorisé, tuiles OSM)
 * Données : ui/js/data/map.json = [{"latitude","longitude","label","id"}, …]
 */
(function () {
    'use strict';

    var BASE = (typeof baseURI !== 'undefined') ? baseURI : './';

    function message(container, text) {
        var p = document.createElement('p');
        p.className = 'gs-map-coverage';
        p.textContent = text;
        container.parentNode.insertBefore(p, container.nextSibling);
        return p;
    }

    function init() {
        var container = document.getElementById('gs-map');
        if (!container) { return; }
        if (typeof L === 'undefined') {
            message(container, 'Leaflet n’a pas pu être chargé (ui/js/vendor/leaflet/).');
            return;
        }

        var map = L.map('gs-map').setView([46.6, 2.2], 5);
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 18,
            attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        }).addTo(map);

        fetch(BASE + 'ui/js/data/map.json')
            .then(function (r) {
                if (!r.ok) { throw new Error('HTTP ' + r.status); }
                return r.json();
            })
            .then(function (data) {
                var places = Array.isArray(data) ? data : (data.places || data.items || []);
                var shown = 0;
                var bounds = [];
                places.forEach(function (p) {
                    var lat = parseFloat(p.latitude !== undefined ? p.latitude : p.lat);
                    var lon = parseFloat(p.longitude !== undefined ? p.longitude : (p.lng !== undefined ? p.lng : p.lon));
                    if (isNaN(lat) || isNaN(lon)) { return; }
                    var marker = L.marker([lat, lon]).addTo(map);
                    var label = p.label || p.name || p.id || '';
                    if (p.id) {
                        var a = document.createElement('a');
                        a.href = BASE + 'registres/place/' + p.id + '.html';
                        a.textContent = label;
                        marker.bindPopup(a);
                    } else {
                        marker.bindPopup(document.createTextNode(label));
                    }
                    bounds.push([lat, lon]);
                    shown += 1;
                });
                if (bounds.length > 1) { map.fitBounds(bounds, { padding: [30, 30], maxZoom: 8 }); }
                message(container, shown + ' lieux géolocalisés affichés');
            })
            .catch(function () {
                message(container, 'Données cartographiques indisponibles (ui/js/data/map.json).');
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
