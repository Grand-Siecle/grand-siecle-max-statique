/* UI Pagefind (site gelé) */
window.addEventListener('DOMContentLoaded', function () {
  if (!window.PagefindUI) return;
  var ui = new window.PagefindUI({
    element: '#gs-search',
    pageSize: 10,
    showSubResults: true,
    showImages: false,
    translations: {
      placeholder: 'Rechercher…',
      clear_search: 'Effacer',
      load_more: 'Plus de résultats',
      many_results: '[COUNT] résultats pour « [SEARCH_TERM] »',
      one_result: '1 résultat pour « [SEARCH_TERM] »',
      zero_results: 'Aucun résultat pour « [SEARCH_TERM] »',
      searching: 'Recherche…',
      alt_search: 'Aucun résultat pour « [SEARCH_TERM] ». Résultats pour « [DIFFERENT_TERM] » à la place',
      filters_label: 'Filtres'
    }
  });

  // ?q= : lancer la recherche transmise dans l'URL
  var q = new URLSearchParams(location.search).get('q');
  if (q) ui.triggerSearch(q);

  // et réécrire l'URL au fil de la saisie (debounce), pour des liens partageables
  var timer = null;
  document.addEventListener('input', function (e) {
    var input = e.target;
    if (!input || !input.closest || !input.closest('#gs-search')) return;
    var value = input.value;
    clearTimeout(timer);
    timer = setTimeout(function () {
      var url = new URL(location.href);
      if (value) url.searchParams.set('q', value);
      else url.searchParams.delete('q');
      history.replaceState(null, '', url);
    }, 250);
  });
});
