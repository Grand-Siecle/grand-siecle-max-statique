/* UI Pagefind (site gelé) */
window.addEventListener('DOMContentLoaded', function () {
  if (window.PagefindUI) {
    new window.PagefindUI({
      element: '#gs-search',
      pageSize: 10,
      showSubResults: true,
      translations: { placeholder: 'Rechercher…', zero_results: 'Aucun résultat pour « [SEARCH_TERM] »' }
    });
  }
});
