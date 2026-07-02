(: For conditions of distribution and use, see the accompanying legal.txt file. :)

module namespace max.plugin.search = 'pddn/max/plugin/search';
import module namespace max.config = 'pddn/max/config' at '../../rxq/config.xqm';
import module namespace max.html = 'pddn/max/html' at '../../rxq/html.xqm';
import module namespace max.cons = 'pddn/max/cons' at '../../rxq/cons.xqm';
import module namespace max.util = 'pddn/max/util' at '../../rxq/util.xqm';
import module namespace max.i18n = 'pddn/max/i18n' at '../../rxq/i18n.xqm';

declare variable $max.plugin.search:PLUGIN_ID := "search";
declare variable $max.plugin.search:ALL_TXT := "all_txt";
declare variable $max.plugin.search:SELECTION := "selection";

(:Plugin parameters  - should be defined in MAX CONFIGURATION FILE:)
declare variable $max.plugin.search:TAG_PARAMETER := "tag";
declare variable $max.plugin.search:BACK_TO_TEXT_ID_PARAMETER := "backToTextID";

declare
%rest:GET
%output:method("html")
%rest:path("/{$project}/search.html")
function max.plugin.search:searchPage($project){
  let $routeList := for $d in collection( max.config:getProjectDBPath($project)) return base-uri($d) (:max.route:HTMLRouteList($project)//a/@href :)
  let $routeSelect := <select class='form-control' id='searchSelect' multiple='true'>{
(:    <option value='{$max.plugin.search:ALL_TXT}'>Dans tous les textes</option>,:)
    for $route in $routeList
    return 
        let $docName := if(contains($route,'/page/'))(:dirty hack for pager href:)
                    then
                      tokenize(substring-before(string($route),'/page/'), $max.cons:TOC||'/')[last()]
                    else    
                      tokenize($route,'/')[last()]
    return  
      if(max.config:isIgnored($docName, $project))
        then ()
      else
        <option value="{tokenize($route, $max.cons:TOC||'/')[last()]}" selected="true">{$docName}</option>
  }
  </select>
  return
   max.html:render(
               $project,
               "search",
               <div id="searchWrap">
                 <h3>{max.i18n:getText($project,'search.label')}</h3>
                 <div id='searchForm'>
                     <div id='modeWrap'>
                      <input type="radio" onchange="window.search.searchModeChanged()" value="{$max.plugin.search:ALL_TXT}" name="searchMode" checked="checked"/>Dans tous les textes
                      <input type="radio" onchange="window.search.searchModeChanged()" value="{$max.plugin.search:SELECTION}" name="searchMode"/>Une sélection de textes
                     </div>
                     {$routeSelect}
                   <input id= 'searchInput' type='text'/>
                   <button class="btn btn-secondary" onclick="search.runSearchFromForm();">Chercher</button>
                 </div>  
                 <div id='searchLoading'>{max.i18n:getText($project,'search.loading')}</div>
                 <div id='searchResults'></div>
               </div>,
               ())
};

declare
%rest:GET
%output:method("html")
%rest:path("/{$project}/search/report.html")
function max.plugin.search:check($project){
  let $pluginConfig := max.config:getPluginByName($project, $max.plugin.search:PLUGIN_ID)
  
  let $tagReport := 
    if($pluginConfig/parameters/parameter[@key=$max.plugin.search:TAG_PARAMETER]/@value) 
    then <li>{$max.plugin.search:TAG_PARAMETER} <span class="statusOK">OK</span></li>
    else <li>{$max.plugin.search:TAG_PARAMETER} <span class="statusNOK">NOK</span></li>
  
  let $b2tIDReport := 
    if($pluginConfig/parameters/parameter[@key=$max.plugin.search:BACK_TO_TEXT_ID_PARAMETER]/@value) 
    then <li>{$max.plugin.search:BACK_TO_TEXT_ID_PARAMETER} <span class="statusOK">OK</span></li>
    else <li>{$max.plugin.search:BACK_TO_TEXT_ID_PARAMETER} <span class="statusNOK">NOK</span></li>
  
  return <div class='pluginReport'><span class='pluginReportTitle'>Search plugin report:</span><ul>{$tagReport}{$b2tIDReport}</ul></div>

};



declare
%rest:GET
%output:method("html")
%rest:query-param("search", "{$search}")
%rest:query-param("docs[]", "{$docs}")
%rest:path("/{$project}/search")
function max.plugin.search:search($project,$search, $docs as item()*){
    let $plugin := max.config:getPluginByName($project, $max.plugin.search:PLUGIN_ID)
    let $tag := string($plugin//parameter[@key = $max.plugin.search:TAG_PARAMETER]/@value)
    let $dbPath := max.config:getProjectDBPath($project)

    let $docList :=
        if (count($docs) > 0(: = $max.plugin.search:ALL_TXT:))
        then $docs
        else for $d in collection($dbPath)
        where not(max.config:isIgnored(replace(base-uri($d), ".+/([^/]+)$", "$1"), $project))
        return base-uri($d)

    for $docPath in $docList
        let $res :=
            for $h in doc($docPath)//*[local-name(.) = $tag]
            let $hits :=
                for $hit at $n in ft:mark($h[.// text () contains text {$search}])
                let $path := fn:substring-after($docPath,'/')(:replace($docPath, $dbPath || "/", ''):)
                let $b2txt := max.util:getRelativeRootPath(()) || $path || "/" || string($h/@xml:id) || '.html'
                return <div class='hit'>
                    <span class='search-b2txt'><a href='{$b2txt}'>{string($h/@xml:id)}</a></span>
                    <div>{$hit}</div>
                </div>

            return $hits

        let $xsltDoc := max.util:buildXSLTDoc(max.util:getDefaultTextXSL($project),())

        return  (admin:write-log('MaX DEBUG - SEARCH in '||$docPath||': ' ||$search),

        if ($res != '')
        then xslt:transform(
                <div class='hits'>
                    <details open="">
                        <summary>{$docPath} <span class="badge bg-secondary ms-3">{count($res)}</span></summary>
                        {$res}
                    </details>
                </div>, $xsltDoc, ())
        else ()
    )


};

(:

};
:)