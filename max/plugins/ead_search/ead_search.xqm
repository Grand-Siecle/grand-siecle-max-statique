xquery version "3.0";

module namespace max.plugin.ead_search = 'pddn/max/plugin/ead_search';
import module namespace max.config = 'pddn/max/config' at '../../rxq/config.xqm';
import module namespace max.html = 'pddn/max/html' at '../../rxq/html.xqm';
import module namespace max = 'pddn/max' at '../../max.xq';
import module namespace max.util = 'pddn/max/util' at '../../rxq/util.xqm';
import module namespace max.i18n = 'pddn/max/i18n' at '../../rxq/i18n.xqm';


declare %private function max.plugin.ead_search:getSearchConfiguration($project){
    let $p:=max.config:getPluginParameterValue($project, 'ead_search', 'searchForm')
    return if($p) then $p else doc(max.util:maxHome()||'/plugins/ead_search/default_config.xml')
};

declare
%rest:GET
%output:method("html")
%rest:path("/{$project}/rechercher.html")
function max.plugin.ead_search:searchPage($project){
    let $dbPath := max.config:getProjectDBPath($project)
    let $simpleSearch :=
    <section>
       <h3>{max.i18n:getText($project,'search.title')}</h3>
       <p>{max.i18n:getText($project,'search.label1')}</p>
       <ul>
        <li>{max.i18n:getText($project,'search.label2')}</li>
        <li>{max.i18n:getText($project,'search.label3')}</li>
       </ul>
       <p>{max.i18n:getText($project,'search.label4')}</p>

    <div id="ead-search-simple">
        <label>{max.i18n:getText($project,'search.fulltext')}</label>
        <input id="searchInput" type="text" placeholder="Texte..."/>
        <button id="boutonChercher" class="btn btn-secondary" onclick="window.eadSearch.runEadSimpleSearch();">{max.i18n:getText($project,'search.label5')}</button>
    </div>
    </section>
    let $datalists := <section id="ead-search-section" class="ead-search">
        {$simpleSearch}
        {
        for $indexTag at $tagNumber in  max.plugin.ead_search:getSearchConfiguration($project)//tag
        let $tagName := string($indexTag/@name)
        let $attr := string($indexTag/@attribute)
        let $value := string($indexTag/@value)
(:        let $queryParameters := 'if($attr) then "&amp;attr="||$attr||"&amp;value="||$value else '':)
        let $tagId := $tagName ||$tagNumber
        return
            if(count(collection($dbPath)//*[fn:local-name()=$tagName and @normal]) > 0)
            then
            <div>
                <label>{string($indexTag/@label)}</label>
                <input type="text"
                       class="ead-search-input"
                       data-indexid="{$tagId}"
                       data-index="{$tagName}"
                       data-attr="{$attr}"
                       data-value="{$value}"
                       id="{$tagId}-input"
                       list="{$tagId}"
                       multiple="multiple"></input>
                <div class="ead-search-popup-wrap">
                    <button class="iconeListe" onclick="window.eadSearch.togglePopup('{$tagId}')"></button>
                    <div class="ead-search-popup" id="ead-search-popup-{$tagId}">
                            <button class="ead-search-close-popup" onclick="window.eadSearch.togglePopup('{$tagId}')">&#215;</button>
                            <div id="ead-search-popup-{$tagId}-alphabet" class="ead-search-popup-alphabet">
                                <a onclick="window.eadSearch.fetchIndexEntriesByLetter('','{$tagId}')"
                                   class="ead-search-alpha"
                                   id="alpha-{$tagId}"
                                >
                                    Tout
                                </a> |
                               {
(:                               for $l in max.plugin.ead_search:indexFirstLetters($project, $tagName, $attr, $value):)
(:                               return <a>{$l}</a>:)
                               for $l in 1 to 26 return
                                    let $letter:= codepoints-to-string($l+64)
                                    return
                                        <a onclick="window.eadSearch.fetchIndexEntriesByLetter('{$letter}','{$tagId}')"
                                           class="ead-search-alpha"
                                           id="alpha-{$tagId}-{$letter}">
                                            {codepoints-to-string($l+64)}
                                        </a>
                                }

                            </div>
                            <div id="ead-search-popup-{$tagId}-contents"></div>
                    </div>
                </div>
                <ul id="{$tagId}-ul" class="ead-search-ul">
                </ul>
                <datalist id="{$tagId}" class="ead-index-list"></datalist>
            </div>
            else ()
        }
        <!-- par défaut on masque la recherche par date -->
            <div id="ead-search-date-wrap" style="display:none">
                <input type="checkbox" id="ead-search-date-cb"/>
                <label>Année de production</label>
                <!--<div>
                    <input type="radio" name="ead-search-radio-date" checked="checked" value="in"/>
                    <span>En</span>
                    <input type="number" id="ead-search-date-in"/>
                </div>-->
                <div>
                    <!--display none : l'option "entre" ne suffit-elle pas ? -->
                    <input style="display:none;" type="radio" name="ead-search-radio-date" checked="checked" value="interval"/>
                    <span>Entre</span>
                    <input type="number" id="ead-search-date-from" value="1000" disabled="disabled"/>
                    <span>et</span>
                    <input type="number" id="ead-search-date-to" value="2000" disabled="disabled"/>
                </div>
            </div>
            <div class="boutonSearch"><button onclick="window.eadSearch.runEadSearch()">{max.i18n:getText($project,'search.label5')}</button></div>
            <div id='searchLoading'>{max.i18n:getText($project,'search.loading')}</div>
            <div id="ead-search-results"></div>
            <script type="text/javascript" src="{max.util:getRelativeRootPath($project) ||'plugins/ead_search/ead_search_page.js'}"></script>
        </section>

    let $html := max.html:render($project, 'rechercher', $datalists)
    let $htmlWithCSS :=
        copy $c := $html
        modify insert node <link rel="stylesheet" type="text/css" href="{max.util:getRelativeRootPath($project) ||'plugins/ead_search/ead_search_page.css'}"/> into $c//*:head[1]
        return $c
    return $htmlWithCSS
};



declare
%rest:GET
%output:method("html")
%rest:query-param("indexes[]", "{$indexes}")
%rest:query-param("from", "{$from}")
%rest:query-param("to", "{$to}") (: from date A to date B :)
%rest:query-param("in", "{$in}")(:in date D:)
%rest:path("/{$project}/resultats.html")
function max.plugin.ead_search:runSearch($project as xs:string, $indexes as xs:string*, $from as xs:string?, $to as xs:string?, $in as xs:string?){

    let $dbPath := max.config:getProjectDBPath($project)
    let $queryStart := 'for $c in //*:c '
    let $subqueries := for $index at $i in $indexes
        let $p := request:parameter($index||'[]')
        return
            (: chercher aussi ds les noeuds text() ? - commenté pour le moment:)
           (:let $or := string-join(for $n in $p return '@normal="'||$n||'" or contains(./text(),"'||$n||'")',' or ' ):)
            let $or := string-join(for $n in $p return '@normal="'||$n||'"',' or ' )
            return
            if($i = 1) then ' where count($c/*[not(local-name(.)="c")]//*:'||$index||'['||$or||'])>0 '
            else ' and count($c/*[local-name(.)!="c"]//*:'||$index||'['||$or||'])>0 '

    let $joinedSubQueries := fn:string-join($subqueries,'')
    let $fullQuery := $queryStart || $joinedSubQueries || ' return $c'

    return try{
    let $matches := max.plugin.ead_search:dateFilter(
            $project,$from, $to, $in, xquery:eval($fullQuery, map { '': db:open($dbPath) }))

    let $html:= <ol class="ead-search-results">{
        for $c at $pos in $matches
        return max.plugin.ead_search:formatSearchResult($c, $pos, $project)
            (:<li>{$c/*:did/*:unitid/text()} | <em>{string($c/*:did/*:unitdate[1]/@normal)}</em></li>:)

    }
    </ol>

    return
    <section>
        <div id='searchLoading'>{max.i18n:getText($project,'search.loading')}</div>
        <h3>Résultats - {count($html/li/@id)}</h3>
        <!--<h4>XQuery = {$search} - (db = {$dbPath})</h4>-->
        {$html}
    </section>
    }
    catch * {
        max:max-error("Erreur code " || $err:code, $err:description ||'('||$fullQuery||')',$err:module, $err:line-number,  $err:additional)
    }
};

declare
%rest:GET
%output:method("html")
%rest:query-param("search", "{$search}")
%rest:path("/{$project}/resultatsSimple.html")
function max.plugin.ead_search:runSearchSimple($project,$search){
    let $dbPath := max.config:getProjectDBPath($project)
    let $matches :=
        for $c in collection($dbPath)//*:c
        where count($c/*[not(local-name(.)="c")]) > 0 and $c[.//text() contains text {$search}]
        return $c
    return try{
        let $html:= <ol class="ead-search-results">{
        for $c at $pos in $matches
        return max.plugin.ead_search:formatSearchResult($c, $pos, $project)
        }
        </ol>
        return
                <section>
                    <div id='searchLoading'>{max.i18n:getText($project,'search.loading')}</div>
                    <h3>Résultats - {count($html/li/@id)}</h3>
                    <!--<h4>XQuery = {$search} - (db = {$dbPath})</h4>-->
                    {$html}
                </section>
    }
    catch * {
        max:max-error("Erreur code " || $err:code, $err:description ||'('||$matches||')',$err:module, $err:line-number, $err:additional)
    }
};

declare %private function max.plugin.ead_search:formatSearchResult($c as node(), $n as xs:integer, $project as xs:string){
    <li class="ead-search-result" id="{$n}">{
        (: let $titles := for $i in $c/ancestor-or-self::*:c
            return (string-join($i/*:did/*:unitid/text(),''))
        return string-join($titles, " &#x25B8; ") :)
        let $dbPath := max.config:getProjectDBPath($project)
        for $i in $c
        let $id := $i/self::*:c/@*:id
        let $baseuriXml := base-uri($c)
        let $baseuri := substring-after(base-uri($id),$dbPath)
        let $xslRes := file:parent(file:parent(file:parent(static-base-uri())))||"editions/"||$project||"/ui/xsl/ead/resSearch.xsl"
        let $req := <div><a href='{max.util:getRelativeRootPath($project) }{$baseuri}/{$id}.html'>{$i/ancestor-or-self::*:c/*:did}</a><section>{$i/ancestor-or-self::*:c/*:did}</section></div>
        return
            if (file:exists($xslRes))
            then
                (xslt:transform($req, $xslRes, ()))
            else ($req)
        (: return <a href='{$baseuri}/{$id}.html'>{(string-join($i/ancestor-or-self::*:c/*:did,' &#x25B8; '))}</a>  :)

    }</li>
(:    for $c in :)
(:    <li>{$c/*:did/*:unitid/text()} | <em>{string($c/*:did/*:unitdate[1]/@normal)}</em></li>:)
};
declare %private function max.plugin.ead_search:parseDateParameter($strDate as xs:string, $format as xs:string){
    try {
         switch ($format)
            case "YYYY"
                return xs:date($strDate||'-01-01')
            case "YYYY-MM"
                return xs:date($strDate||'-01')
            default
                return xs:date($strDate)
    }
    catch * {
        admin:write-log("Wrong date entry :" || $strDate || ' format = '|| $format),
        xs:date('0001-01-01')
    }

};

(:filters ead:c according to their unitdate:)
declare %private function max.plugin.ead_search:dateFilter(
        $project as xs:string,
        $from as xs:string?,
        $to as xs:string?,
        $in as xs:string?,
        $matches){

    let $dateFormat :=string(max.plugin.ead_search:getSearchConfiguration($project)//dates/@format)
    return
    if($from and $to)
        then max.plugin.ead_search:dateIntervalFilter($from, $to, $dateFormat, $matches)
    else
        if($in) then () (:todo:)
        else $matches

};

(:fiters ead:c between $from and $to dates:)
declare %private function max.plugin.ead_search:dateIntervalFilter($from as xs:string, $to as xs:string, $dateFormat as xs:string, $matches as item()*){

    let $fromDateTime := max.plugin.ead_search:parseDateParameter($from,$dateFormat)
    let $toDateTime := max.plugin.ead_search:parseDateParameter($to,$dateFormat)

    return
    for $m in $matches
        where $m/ancestor::*:c[1][@otherlevel]//*:unitdate[1]
        (: where $m//*:unitdate[1] :)
        (: let $unitDate := string((($m//*:unitdate)[1])/@normal) :)
        let $unitDate := string((($m/ancestor::*:c[1][@otherlevel]//*:unitdate)[1])/@normal)
        return if(contains($unitDate,'/'))
            then
            let $dates := tokenize($unitDate,'/')
            let $unitFrom :=  max.plugin.ead_search:parseDateParameter($dates[1], $dateFormat)
            let $unitTo:=  max.plugin.ead_search:parseDateParameter($dates[2], $dateFormat)
            return
               if($fromDateTime <= $unitFrom and $toDateTime >= $unitTo)
               then $m
               else()
            else
                let $unitFrom :=  max.plugin.ead_search:parseDateParameter($unitDate, $dateFormat)
                return
                    if($fromDateTime <= $unitFrom) then $m else ()

};


declare
%rest:GET
%output:method("json")
%rest:query-param("attr", "{$attr}")
%rest:query-param("value", "{$value}")
%rest:query-param("q", "{$query}")
%rest:query-param("page", "{$page}",1)
%rest:path("/{$project}/search-index/{$tag}.json")
function max.plugin.ead_search:searchIndexesListAsJSON($project, $tag, $page as xs:integer,$attr as xs:string, $value as xs:string, $query as xs:string?){
    let $entries := max.plugin.ead_search:searchIndexesList($project, $tag, $page, $attr, $value, $query)
    let $jsonStr :=
            for $entry in $entries/*
            order by $entry/@normal
            where fn:string-length($entry/@normal) > 0
            return '{"normal":"' || encode-for-uri($entry/@normal) || '", "tag":"' || $tag || '", "role" :"'||$entry/@role||'"}'
    return json:parse(
            '{
                "entries" :[' || string-join($jsonStr,',') ||'],
                "total": '||$entries/@total||',
                "start" :'||$entries/@start||',
                "end" : '||$entries/@end||'
            }')
};



declare
%rest:GET
%rest:query-param("attr", "{$attr}")
%rest:query-param("value", "{$value}")
%rest:query-param("q", "{$query}")
%rest:query-param("page", "{$page}",1)
%rest:path("/{$project}/search-index/{$tag}.xml")
function max.plugin.ead_search:searchIndexesList($project, $tag, $page as xs:integer, $attr, $value, $query as xs:string?){
    let $pageLength := 10
    let $dbPath := max.config:getProjectDBPath($project)
(:    let $tagParameters := max.plugin.ead_search:getSearchConfiguration($project)//tag[@name=$tag]:)
    (:select all nodes with required tag and attributes :)
    let $allEntries :=
        for $elt in collection($dbPath)//*[fn:local-name()=$tag and @normal]
        order by $elt/@normal
        where(
            if($attr) then
                $elt/@*[local-name(.)=$attr and string(.)=$value]
            else true()
        )
        and (
            if($query)
            then  $elt/@normal[matches(., $query,'i')]
            else true()
        )
        return $elt

    (:get their normal forms:)
    let $allNormals :=
        for $e in $allEntries
        return string($e/@normal)

    (:positions computing according to page number:)
    let $start := if($page = -1) then 1 else $page * $pageLength - ($pageLength -1)
    let $end := if($page = -1) then count($allNormals) else $start + $pageLength

    (:filter : avoid doublons:)
    return
            <entries total='{count(distinct-values($allNormals))}' start='{$start}' end='{($end - 1)}'>{
                for $normal at $pos in distinct-values($allNormals)
                where $pos >= $start
                and $pos < $end
                return $allEntries[@normal=$normal][1]
            }
            </entries>



};



(:----------------------------test index-------------------------------------------:)


declare
%rest:GET
%rest:path("/{$project}/indexes.html")
function max.plugin.ead_search:allLevels($project){
    let $doc := collection(max.config:getProjectDBPath($project))
    let $topLevels := for $i in distinct-values($doc//*:controlaccess[not(ancestor::*:controlaccess)]/descendant::*:subject[1]) order by $i
    return normalize-space($i)
    return
        <root>{
            for $top in $topLevels
            return<list>
                <item>{$top}</item>
                {max.plugin.ead_search:subLevels($doc, $top)}</list>}</root>
};

declare function max.plugin.ead_search:subLevels($doc, $parent){
    let $children := for $ca in $doc//*:controlaccess where $ca/subject[text()=$parent]
    return $ca/*:controlaccess
    return if (count($children) = 0)
    then ()
    else <list>{for $child in distinct-values($children/*:subject) order by $child
        return if(normalize-space($child)="")
        then()
        else<item>{$child}{max.plugin.ead_search:subLevels($doc,$child)}</item>}</list>

};


declare function max.plugin.ead_search:indexTopLevels($project){
    let $doc := collection(max.config:getProjectDBPath($project))
    return
    if(count($doc//*:controlaccess//*:subject) = 0)
    then max.plugin.ead_search:flatIndex($doc)
    else
    let $topLevels := for $i in distinct-values($doc//*:controlaccess[not(ancestor::*:controlaccess)]/descendant::*:subject[1]) order by $i
    return
      let $trimed := normalize-space($i)
      return
        if ($doc//*:controlaccess/*:controlaccess//*:controlaccess/*:subject[text() contains text {$trimed}])
        then ()
        else $trimed
    return
      <root>{
      for $top in $topLevels
        return<list>
            <item nbchildren="{max.plugin.ead_search:countChildren($doc,$top)}">{$top}</item>
            </list>}</root>

};

declare function max.plugin.ead_search:countChildren($doc, $parent){
    let $children := for $ca in $doc//*:controlaccess where $ca/subject[text()=$parent]
    return $ca/*:controlaccess

    return count(for $child in distinct-values($children/*:subject)
    return if(normalize-space($child)="")
    then()
    else<item/>)
};



declare function max.plugin.ead_search:flatIndex($doc){
    let $types := distinct-values($doc//*:controlaccess/*:genreform/@*:type)
    return
        <ul>{
            for $type in $types
            return
                <li class="jstree-closed">{$type}
                    <ul>
                        {
                            let $entries := $doc//*:controlaccess/*:genreform[@*:type=$type]/text()
                            for $entry in distinct-values($entries)
                            return <li><span class='indexEntry'>{$entry}</span><span class='badge'>{count(for $a in $entries where $a = $entry return $a)}</span></li>
                        }
                    </ul>
                </li>
        }
        </ul>
};



(:
inutilisée - on conserve jusqu'aux tests avancés de recherche
:)
declare
%rest:GET
%output:method("html")
%rest:path("/{$project}/search-build-ftindex.html")
function max.plugin.ead_search:buildFtIndexPage($project){

    let $content := <section style="margin: 100px 50px">
        <h2>Indexation pour la recherche</h2>
        <div>
            Tags indexés :  {max.config:getPluginParameterValue($project, 'ead_search','ftIndexTags')}
        </div>
        <div>
            <button onclick='window.eadSearch.buildFtIndex()'>Lancer l'indexation</button>
        </div>
    </section>

    return max.html:render($project,'ftindex',$content)
};

(:
inutilisée - on conserve jusqu'aux tests avancés de recherche
:)
declare
%updating
%rest:POST
%output:method("html")
%rest:path("/{$project}/search-build-ftindex.html")
function max.plugin.ead_search:buildFtIndex($project){
    let $tags := max.config:getPluginParameterValue($project, 'ead_search','ftIndexTags')
    return (
        db:optimize(
                max.config:getProjectDBPath($project),
                false(),
                map {
                'ftindex': true(),
                'ftinclude': $tags }
        ),
        update:output('<html>FT index for <em>'||$tags||'</em> successfull</html>'))
};



(:
Clés d'indexation en Pleade

|:--------------------------|:----------|:---------------------|:---------------------------|
|Utilité                    |Élément    |attribut de typologie |attribut de normalisation   |
|:--------------------------|:----------|:---------------------|:---------------------------|
|Collectivité               |corpname   |@role                 |@normal                     |
|Nom de famille             |famname    |@role                 |@normal                     |
|Activité                   |function   |ø                     |@normal                     |
|Typologie documentaire     |genreform  |@type                 |@normal                     |
|Lieu                       |geogname   |@role                 |@normal                     |
|Fonction                   |occupation |ø                     |@normal                     |
|Nom                        |name       |@role                 |@normal                     |
|Personne                   |pername    |@role                 |@normal                     |
|Sujet                      |subject    |ø                     |@normal                     |
|Titre                      |title      |@type                 |@normal                     |
|:--------------------------|:----------|:---------------------|:---------------------------|
|Date                       |date       |@type                 |@normal                     |
|Date d’un c et ses enfants |unitdate   |@type                 |@normal                     |
|:--------------------------|:----------|:---------------------|:---------------------------|

:)
