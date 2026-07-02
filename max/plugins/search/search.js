import {Plugin} from '../../core/ui/js/Plugin.js';

const ALL_TXT_SEARCH = 'all_txt';


class SearchPlugin extends Plugin{
    constructor(name) {
     super(name);
     if(document.querySelector('input[name="searchMode"]'))
        this.searchModeChanged();
  }
  
  
  runSearch(search, docs, divToFeed){
        let url = window.MAX.getBaseURL() + "/search?search="+search;
        docs.forEach(d => {
            url += "&docs[]=" + d
        });
        fetch(url)
            .then(response =>  response.text())
            .then(data => {
                    divToFeed.innerHTML = data;
                    this.updateHitsInfo(docs)
                })
   }

   searchModeChanged(){
        this.searchMode = document.querySelector('input[name="searchMode"]:checked').value;
        if(this.searchMode === ALL_TXT_SEARCH){
            document.getElementById('searchSelect').classList.add('d-none');
        }
        else {
            document.getElementById('searchSelect').classList.remove('d-none');
        }
   }
   
   
   
  /*
  Performs search according to form parameters
  */
  runSearchFromForm(){
    let search = document.getElementById('searchInput').value;
    if(search.trim() === ''){
      window.alert('Recherche vide ou incorrecte.');
      return;
    }
    document.getElementById('searchLoading').style.display = 'block';

    let options = document.getElementById('searchSelect').selectedOptions;
    let docs = Array.from(options).map(({ value }) => value);

    this.runSearch(search,  docs, document.getElementById("searchResults"));
    
  }


  updateHitsInfo(){
      document.querySelectorAll(".manchette_droite").forEach(e => e.remove());
      let index = 1;
      document.querySelectorAll(".hit").forEach((hit) => {
          let rangeNode = document.createElement('span');
          rangeNode.classList.add('hit_range');
          rangeNode.innerHTML = index;
          index++;
          hit.prepend(rangeNode);
          //$(this).prepend("<span class='hit_range'></span>")
      });

    let totalNode = document.createElement("h3");
    totalNode.classList.add('n-search-result');
    totalNode.innerHTML = index - 1 + " résultat(s)";
    document.getElementById('searchResults').prepend(totalNode);
    document.getElementById('searchLoading').style.display = 'none';


  }
}

let plugin = new SearchPlugin('Search');
window.MAX.addPlugin(plugin);
window.search = plugin