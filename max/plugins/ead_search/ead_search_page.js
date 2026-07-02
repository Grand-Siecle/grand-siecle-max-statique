const PAGE_LENGTH = 10;

class EadSearchPlugin  {

    constructor(name) {
        this.currentFirstLetterFilter = null;
        this.withDatesFilter = document.getElementById('ead-search-date-cb').checked;
        this.filters = {}
        if (document.getElementById('ead-search-section')) {
            document.getElementById('ead-search-date-cb').addEventListener('click', (evt) => {
                this.withDatesFilter = evt.target.checked;
                if (!this.withDatesFilter) {
                    document.getElementById('ead-search-date-from').setAttribute('disabled', true);
                    document.getElementById('ead-search-date-to').setAttribute('disabled', true);
                } else {
                    document.getElementById('ead-search-date-from').removeAttribute('disabled');
                    document.getElementById('ead-search-date-to').removeAttribute('disabled')
                }
            })
            this.bindIndexAutocompletes();
        }
    }

    bindIndexAutocompletes() {
        let indexList = document.querySelectorAll('.ead-search-input');

        indexList.forEach((e) => {
            e.addEventListener('input', (evt) => {
                let indexId = e.dataset.indexid
                let indexName = e.dataset.index;
                let q = e.value;
                if (q.trim() !== '') {
                    let url = baseURI + 'search-index/' + indexName + '.json?q=.*' + q + '.*';
                    url += e.dataset.attr ? ('&attr=' + e.dataset.attr + '&value=' + e.dataset.value) : '';

                    let datalist = document.getElementById(indexId);
                    fetch(url).then((res) => res.json()).then((json) => {
                        datalist.querySelectorAll('*').forEach(n => n.remove());
                        let entries = json.entries;
                        let options = ''
                        entries.forEach((entry) => {
                            options += '<option value="' + decodeURIComponent(entry.normal) + '"/>';
                        });
                        datalist.innerHTML = options;
                    });

                    document.getElementById(indexId + '-input').addEventListener('input', (event) => {
                        if (event.inputType === 'insertReplacementText') {
                            this.addIndexFilter(indexName, event.target.value, indexId)
                        }
                    });

                }
            })
        })

    }

    togglePopup(tagId) {
        let popupElt = document.getElementById('ead-search-popup-' + tagId);
        if (popupElt.style.display == 'block') {
            popupElt.style.display = 'none';
        } else
            this.popupIndex(tagId);
    }

    popupIndex(tagId) {
        this.currentFirstLetterFilter = null;
        document.getElementById('alpha-' + tagId).classList.toggle('selected')
        document.querySelectorAll('.ead-search-popup').forEach((p) => p.style.display = 'none')
        if (!document.getElementById('ul-' + tagId)) {//needs first fetch
            this.fetchPage(tagId, 1);
        }
        let popupElt = document.getElementById('ead-search-popup-' + tagId);
        popupElt.style.display = 'block';
    }

    fetchPage(tagId, pageNumber) {
        let popupElt = document.getElementById('ead-search-popup-' + tagId);
        let popupContent = document.getElementById('ead-search-popup-' + tagId + "-contents");
        //popupContent.innerHTML = '';
        //let url = baseURI + projectId + '/search-index/'+tagName+'.json?p='+pageNumber;
        let listTarget = document.getElementById('ul-' + tagId);
        if (!listTarget) {
            listTarget = document.createElement('ul');
            listTarget.setAttribute('id', 'ul-' + tagId);
            popupContent.appendChild(listTarget);
        }
        let inputTarget = document.getElementById(tagId + '-input');
        let tagName = inputTarget.dataset.index;
        let url = baseURI + 'search-index/' + tagName + '.json?page=' + pageNumber;
        url += inputTarget.dataset.attr ? ('&attr=' + inputTarget.dataset.attr + '&value=' + inputTarget.dataset.value) : '';
        if (this.currentFirstLetterFilter)
            url += "&q=^" + this.currentFirstLetterFilter
        fetch(url)
            .then((res) => res.json()).then((json) => {
            let entries = json.entries
            let total = json.total;
            let totalElt = document.getElementById('ead-search-nb-entries-' + tagId)
            if (!totalElt) {
                totalElt = document.createElement('h5');
                totalElt.setAttribute('id', 'ead-search-nb-entries-' + tagId)
                popupContent.appendChild(totalElt);
            }
            totalElt.innerHTML = total + (entries > 1 ? ' entrée' : ' entrées');
            listTarget.innerHTML = '';
            entries.forEach((entry, n) => {
                let li = document.createElement('li');
                let spanNumber = document.createElement('span');
                spanNumber.classList.add('ead-search-index-n');
                spanNumber.innerHTML = (PAGE_LENGTH * (pageNumber - 1) + n + 1);
                let entryText = document.createTextNode(decodeURIComponent(entry.normal));
                li.appendChild(spanNumber);
                li.appendChild(entryText);
                li.addEventListener('click', (evt) => {
                    this.addIndexFilter(tagName, decodeURIComponent(entry.normal), tagId);
                })
                listTarget.appendChild(li);
            });

            if (!document.getElementById('ead-search-index-pager-' + tagId))
                popupContent.appendChild(this.buildPager(tagId, total));
        })
    }

    fetchIndexEntriesByLetter(letter, tagId) {
        this.currentFirstLetterFilter = letter.trim() === '' ? null : letter;
        document.querySelectorAll('.ead-search-alpha.selected').forEach(e => {
            e.classList.toggle('selected')
        })
        document.getElementById("alpha-" + tagId + (this.currentFirstLetterFilter ? '-' + this.currentFirstLetterFilter : '')).classList.toggle('selected')
        this.fetchPage(tagId, 1)
    }

    addIndexFilter(filterType, filterValue, filterId) {
        if (filterValue.trim() === '')
            return;

        if (!this.filters[filterType])
            this.filters[filterType] = []
        this.filters[filterType].push(filterValue);
        let li = document.createElement('li');
        let rmBtn = document.createElement('button');
        rmBtn.innerHTML = "&times;"
        li.innerHTML = filterValue;
        li.appendChild(rmBtn);
        document.getElementById(filterId + '-ul').appendChild(li);
        document.getElementById(filterId + '-input').value = '';
        rmBtn.addEventListener('click', (evt) => {
            li.remove();
            this.filters[filterType].splice(this.filters[filterType].indexOf(filterValue), 1);
            if (this.filters[filterType].length === 0)
                delete this.filters[filterType];
        })
    }

    buildPager(tagId, total, url) {
        let nbPage = Math.floor(total / PAGE_LENGTH);
        console.log('nbPager = ' + nbPage)
        let pagerElt = document.createElement('div');

        let firstArrowElt = document.createElement('button');
        firstArrowElt.innerHTML = '<<';
        let prevArrowElt = document.createElement('button');
        prevArrowElt.innerHTML = '<';

        let lastArrowElt = document.createElement('button');
        lastArrowElt.innerHTML = '>>';
        let nextArrowElt = document.createElement('button');
        nextArrowElt.innerHTML = '>';

        let inputPageElt = document.createElement('input');
        inputPageElt.type = 'number';
        inputPageElt.value = 1;

        pagerElt.appendChild(firstArrowElt);
        pagerElt.appendChild(prevArrowElt);
        pagerElt.appendChild(inputPageElt);
        pagerElt.appendChild(nextArrowElt);
        pagerElt.appendChild(lastArrowElt);

        let gotoPage = function (n) {
            inputPageElt.value = n;
            inputPageElt.dispatchEvent(new Event('change'));
        }

        firstArrowElt.addEventListener('click', () => gotoPage(1));
        prevArrowElt.addEventListener('click', () => gotoPage(Number(inputPageElt.value) - 1));
        lastArrowElt.addEventListener('click', () => gotoPage(nbPage));
        nextArrowElt.addEventListener('click', () => gotoPage(Number(inputPageElt.value) + 1));

        inputPageElt.addEventListener('change', (evt) => {
            let pageTarget = inputPageElt.value;
            this.fetchPage(tagId, pageTarget);
        })

        pagerElt.classList.add('ead-search-index-pager');
        pagerElt.setAttribute('id', 'ead-search-index-pager-' + tagId)
        return pagerElt;
    }

    runEadSearch() {
        //pour ne pas que les résultats précédents restent affichés, on vide le contenu html
        let resultsDiv = document.querySelector("#ead-search-results");
        resultsDiv.innerHTML = '';
        let query = 'resultats.html';
        document.querySelector("#searchLoading").style.display = "block";
        let filtered = false;
        Object.keys(this.filters).forEach((k, i) => {
            query += (i === 0 ? '?' : '&') + 'indexes[]=' + k;
            console.log(this.filters[k])
            for (let j = 0; j < this.filters[k].length; j++) {
                query += '&' + k + "[]=" + encodeURIComponent(this.filters[k][j])
            }
            filtered = true;
        })

        query = baseURI + query;

        if (this.withDatesFilter) {
            //date
            let dateMode = document.querySelector('input[name=ead-search-radio-date]:checked').value
            if (dateMode === 'interval') {
                let from = document.getElementById('ead-search-date-from').value;
                let to = document.getElementById('ead-search-date-to').value;
                if (from && to)
                    query += (!filtered ? "?" : "&") + "from=" + from + "&to=" + to
            } else if (dateMode === 'in') {
                let dateIn = document.getElementById('ead-search-date-in').value;
                query += (!filtered ? "?" : "&") + "in=" + dateIn
            }
        }
        fetch(query).then(res => res.text()).then(text => {
            document.getElementById('ead-search-results').innerHTML = text
        }).then(function () {
            document.querySelector("#searchLoading").style.display = "none";
        })

    }

    runEadSimpleSearch() {
        var simpleSearch = document.querySelector('#searchInput').value;
        //pour ne pas que les résultats précédents restent affichés, on vide le contenu html
        let resultsDiv = document.querySelector("#ead-search-results");
        resultsDiv.innerHTML = '';
        if (simpleSearch.trim() === '') {
            alert('Recherche vide ou incorrecte.');
            return;
        }
        document.querySelector("#searchLoading").style.display = "block";
        let query = 'resultatsSimple.html?search=' + simpleSearch;
        query = baseURI + query;

        fetch(query).then(res => res.text()).then(text => {
            document.getElementById('ead-search-results').innerHTML = text
        }).then(function () {
            document.querySelector("#searchLoading").style.display = "none";
        })

    }

}

let eadSearch = new EadSearchPlugin('EadSearchPlugin')
window.eadSearch = eadSearch;
