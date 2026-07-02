(:
For conditions of distribution and use, see the accompanying legal.txt file.
:)

module namespace max.plugin.pager = 'pddn/max/plugin/pager';

import module namespace max.config = 'pddn/max/config' at '../../rxq/config.xqm';
import module namespace max.html = 'pddn/max/html' at '../../rxq/html.xqm';
import module namespace max.util = 'pddn/max/util' at '../../rxq/util.xqm';

declare variable $max.plugin.pager:PLUGIN_ID := "pager";
declare variable $max.plugin.pager:NB_BLOCKS := "nbBlocks";
declare variable $max.plugin.pager:NB_LINKS := "nbLinks";
declare variable $max.plugin.pager:ITEMS_PATH := "itemsPath";

declare
%rest:GET
%output:method("html")
%output:indent("no")
%rest:path("/{$project}/{$route=.*\.xml}/page/{$n}.html")
function max.plugin.pager:paginate($project as xs:string, $route as xs:string, $n as xs:integer){
   let $routeDoc := if(starts-with($route,'doc/'))
                    then tokenize($route, 'doc/')[last()]
                    else $route
   let $dbName:=max.config:getProjectDBPath($project)                              
   let $xmlAndNavlinks :=
          max.plugin.pager:paginateNodes($project, $routeDoc, $n, $dbName)
   let $xml :=  $xmlAndNavlinks[1]
   let $navLinks :=  $xmlAndNavlinks[2]  
   let $title:= max.util:getDocTitle($dbName, $route, max.config:getXMLFormat($project))
   let $xsl := max.util:getDocumentTitleTOCXSL($project)
   let $transformedTitle := xslt:transform($title,$xsl)

   let $xsltDoc := max.util:buildXSLTDoc(
                                     max.util:getDefaultTextXSL($project),
                                     max.config:getXSLTAddons($project, $route))   
   let $xsltParams := max.config:getXSLTParams($project, $route, ())
  
   let $html := xslt:transform($xml, $xsltDoc, $xsltParams)    
   (:return max.config:getXSLTAddons($project, $route):)
   let $res := <div id='text'>
                <div id='pagerBlocks'>
                 <h2 class="subpart titreVolume">{$transformedTitle}</h2>
                {$navLinks}
                {$html}
         </div></div>
   return max.html:render($project, $route, $res)
   
};

declare
%rest:GET
%output:method("html")
%rest:path("/{$project}/{$route=.*\.xml}/page/{$n}/{$id}.html")
function max.plugin.pager:paginateWithTarget($project as xs:string, $route as xs:string, $n as xs:integer, $id){
  let $html := max.plugin.pager:paginate($project, $route, $n)
  return copy $c := $html
    modify (
      replace value of node $c/descendant-or-self::*[@*:id=$id]/@*:id with "scrollfocus",
      for $a in  $c//*:div[@*:id='pagerNav']//*:a return replace value of node $a/@*:href with '../'||$a/@*:href
    )
    return $c
};

declare function max.plugin.pager:paginateNodes(
   $project as xs:string,
   $routeDoc as xs:string,
   $currentPage as xs:integer,
   $context as xs:string){
  
  (:gets plugin's parameters from config file:)     
  let $plugin := max.config:getPluginByName($project, $max.plugin.pager:PLUGIN_ID)
  let $nbPerPage := $plugin//parameter[@key=$max.plugin.pager:NB_BLOCKS]/@value
  let $nbLinks := $plugin//parameter[@key=$max.plugin.pager:NB_LINKS]/@value
  let $itemsPath := $plugin//parameter[@key=$max.plugin.pager:ITEMS_PATH]/@value

  (:computes start and end page links:)
  let $beforeRange:= ceiling($nbLinks div 2)
  let $targetDoc:= $context  || '/' || $routeDoc
  let $dbname := max.util:dbNameFromCollection($context)
  let $count := xquery:eval("count(doc('" ||$targetDoc|| "')"||$itemsPath||")",map{'' : db:open($dbname)})
  let $nbPages := ceiling($count div $nbPerPage)
  let $startPage := if(($currentPage - $beforeRange) < 0)
                      then 1
                      else ($currentPage - $beforeRange) + 1
  let $afterRange := if(($currentPage - $beforeRange) < 0) 
                      then $beforeRange + abs($currentPage - $beforeRange) 
                      else $beforeRange              
  let $endPage :=  if(($currentPage + $afterRange) > $nbPages)
                      then $nbPages
                      else ($currentPage + $afterRange)
  let $hrefPrefixPath := ''(: if($withTarget)
                           then '../'
                           else '' :) 
  let $navLinks := <div id="pagerNav">
                    {if($startPage = 1) (:adds first page link if needed:)
                      then ()
                      else <a id="firstPage" href="{$hrefPrefixPath || '1'}.html">&lt;&lt;</a>
                    }
                    {for $i in (xs:integer($startPage) to xs:integer($endPage))
                     return <a 
                            href="{$hrefPrefixPath || $i}.html"
                            class="{if($i=$currentPage) then 'curPageLink' else 'pageLink'}">{$i}</a>}
                    { if($endPage = $nbPages) (:adds last page link if needed:)
                       then ()       
                       else <a id="lastPage" href="{$hrefPrefixPath || $nbPages}.html">&gt;&gt;</a>
                    }        
                   </div>
  (:queries current page's blocks:)
  let $startPosition := (($currentPage - 1) * $nbPerPage) +1
  (:On calcule la position de la balise qui se trouve juste après l'item précédent, sauf pour le premier item :)
	let $realStart := if($startPosition = 1)
		then 1
		else (xquery:eval("count(doc('" ||$targetDoc|| "')//*:list/*:item[" ||$startPosition|| " -1]/preceding-sibling::*) +2",map{'' : db:open($dbname)}))

  let $endPosition := xquery:eval("count(doc('" ||$targetDoc|| "')//*:list/*:item[(" ||$startPosition|| " + " ||$nbPerPage|| ")-1]/preceding-sibling::*) +1",map{'' : db:open($dbname)})
  (:=pour la dernière page, on calcule la position de la dernière balise :)
  let $realEndPosition:= xquery:eval("count(doc('" ||$targetDoc|| "')//*:list/*)",map{'' : db:open($dbname)})
  let $realEnd := if($endPosition = 1)
		then $realEndPosition
		else ($endPosition)

  let $blocks := xquery:eval(
                    "doc('" ||$targetDoc|| "')//*:list/*[fn:position()=("|| $realStart||" to "||$realEnd ||")]", map{'' : db:open($dbname)})
         
   (:then add blocks to a new element with the same qname of their parent one:)                 
   let $parent:=$blocks[1]/..
  let $ns:=namespace-uri($parent)

  (:returns a sequence of 2 elements: blocks + navLinks:)
  return (element{QName($ns,$parent/name())}{$blocks}, $navLinks, <div>{$startPosition}</div>)
};

(:
declare function max.plugin.pager:getPageForID($project, $id){
 
  let $plugin := max.config:getPluginByName($project, $max.plugin.pager:PLUGIN_ID)
  let $nbPerPage := $plugin//parameter[@key=$max.plugin.pager:NB_BLOCKS]/@value
  let $nbLinks := $plugin//parameter[@key=$max.plugin.pager:NB_LINKS]/@value
  let $itemsPath := $plugin//parameter[@key=$max.plugin.pager:ITEMS_PATH]/@value
  let $dbPath :=  max.config:getProjectDBPath($project)
  let $nbElements := xquery:invoke("count(collection('" ||$dbPath || "')" || $itemsPath ||")") 
  return $nbElements 
};
:)


(:Returns page number for a specified fragment ID:)  
declare
%rest:GET
%output:method("html")
%rest:path("/{$project}/{$routeDoc=.*\.xml}/{$id}/page")
function max.plugin.pager:getFragmentPage($project,$routeDoc,$id){
   let $context := max.config:getProjectDBPath($project)
   (:gets plugin's parameters from config file:)     
   let $plugin := max.config:getPluginByName($project, $max.plugin.pager:PLUGIN_ID)
   let $nbPerPage := $plugin//parameter[@key=$max.plugin.pager:NB_BLOCKS]/@value
   let $itemsPath := $plugin//parameter[@key=$max.plugin.pager:ITEMS_PATH]/@value
   let $dbName := db:name(doc($context || "/" ||$routeDoc))
   let $items := xquery:eval("doc('"|| $context || "/" ||$routeDoc ||"')"||$itemsPath||"/@*:id" ,map{'' : db:open($dbName)})
   let $index:=index-of($items,$id)
   return ceiling($index div $nbPerPage)
};


declare function max.plugin.pager:getBackToTxtURL($project,$routeDoc,$id){
 let $page := max.plugin.pager:getFragmentPage($project,$routeDoc,$id)
 return max.util:getRelativeRootPath($project) || $routeDoc || "/page/"||$page ||"/"||$id
};

declare
%rest:GET
%output:method("html")
%rest:path("/{$project}/pager/report")
function max.plugin.pager:check($project){
  let $pluginConfig := max.config:getPluginByName($project, $max.plugin.pager:PLUGIN_ID)
    
  let $itemPathsReport := 
    if($pluginConfig/parameters/parameter[@key=$max.plugin.pager:ITEMS_PATH]/@value) 
    then <li>{$max.plugin.pager:ITEMS_PATH} <span class="statusOK">OK</span></li>
    else <li>{$max.plugin.pager:ITEMS_PATH} <span class="statusNOK">NOK</span></li>
  
  let $nbBlocksReport := 
    if($pluginConfig/parameters/parameter[@key=$max.plugin.pager:NB_BLOCKS]/@value) 
    then <li>{$max.plugin.pager:NB_BLOCKS} <span class="statusOK">OK</span></li>
    else <li>{$max.plugin.pager:NB_BLOCKS} <span class="statusNOK">NOK</span></li>
    
  let $nbLinksReport := 
    if($pluginConfig/parameters/parameter[@key=$max.plugin.pager:NB_LINKS]/@value) 
    then <li>{$max.plugin.pager:NB_LINKS} <span class="statusOK">OK</span></li>
    else <li>{$max.plugin.pager:NB_LINKS} <span class="statusNOK">NOK</span></li>
    
  return <div class='pluginReport'><span class='pluginReportTitle'>Search plugin report:</span>
            <ul>{$itemPathsReport}{$nbBlocksReport}{$nbLinksReport}</ul>
         </div>
    
};
   
   
   