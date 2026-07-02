(: For conditions of distribution and use, see the accompanying legal.txt file. :)

module namespace max.util = 'pddn/max/util';
declare namespace xsl = "http://www.w3.org/1999/XSL/Transform";
import module namespace max.config = 'pddn/max/config' at 'config.xqm';
import module namespace max.cons = 'pddn/max/cons' at 'cons.xqm';
import module namespace fop = 'org.basex.modules.fop.FOP';
import module namespace max.i18n = 'pddn/max/i18n' at 'i18n.xqm';

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace ead="urn:isbn:1-931666-22-9";
(:
: Returns binary-file
:)
declare function max.util:rawFile($path) as item()+{
    web:response-header(map { 'media-type': web:content-type($path) }),
    file:read-binary($path)
      
};

declare function max.util:query($query, $bindings){
  xquery:eval($query, $bindings)
};

declare function max.util:dbNameFromCollection($collection){
  tokenize($collection,'/')[1]
};

declare function max.util:getRelativeRootPath($projectId as xs:string ?){
(:    let $urlPrefix := max.config:getUrlPrefix():)
    (:let $nbUrlPrefixParts := count(tokenize($urlPrefix,'/')) - 2 :)(: 2 = due to first and last slash:)
    let $nbParts := count(tokenize(rest:uri(),'/'))(: 2 = due to first and last slash:)
    let $tab := for $i in 1 to ($nbParts - 2 (:- $nbUrlPrefixParts:))
        return '../'
    return if ($projectId) then fn:string-join($tab) || $projectId || '/' else fn:string-join($tab)
};


(:XQueriyng + XSLT transformation:)
declare function max.util:queryAndTransform($query, $bindings, $xsltDoc as node() ?, $xsltParams as map(*)){
  let $xml := <div>{max.util:query($query, $bindings)}</div>
  return 
    if($xsltDoc)
    then xslt:transform($xml, $xsltDoc, $xsltParams)
    else $xml
};

(:adds xsl addons import to a main xsl one:)
declare function max.util:buildXSLTDoc($xsltMain as xs:string, $xsltAddons as xs:string *){

  copy $mainXSL := doc($xsltMain)
  modify(
    for $addon in $xsltAddons
       return insert node <xsl:import href="{$addon}"/> as last into $mainXSL/xsl:stylesheet

  )
  return $mainXSL
};

declare function max.util:markSearchedText($node as node(), $search as xs:string,  $targetId as xs:string ?){
    let $target := if($targetId) then $targetId else 'text'
    let $marked := ft:mark($node//*[@*:id=$target][.//text() contains text {$search}])
    return if($marked)
        then
        copy $c := $node
        modify (
            replace node $c/descendant-or-self::*[@*:id = $target] with $marked
        )
        return  $c
    else $node

};

declare function max.util:addHTMLClass($htmlNode as node(), $targetId as xs:string, $className as xs:string){
    copy $c := $htmlNode
    modify (
    (:replace value of node $c/descendant-or-self::*[@*:id = $targetId]/@*:id with $className:)

        let $attr:= $c/descendant-or-self::*[@*:id = $targetId]/@*:class
        return if(exists($attr))
        then
            replace value of node $c/descendant-or-self::*[@*:id = $targetId]/@*:class with string($attr)||' '||$className
        else
            insert node (attribute {'class'} {$className}) into $c/descendant-or-self::*[@*:id = $targetId]

    )
    return  $c
};


(:xml 2 fo 2 pdf:)
declare function max.util:xml2pdf($xml as element(), $xsl as xs:string, $project as xs:string, $id){
let $projectPrettyName := max.config:getProjectPrettyName($project)
let $baseURI:= max.util:getRelativeRootPath($project)
let $host := substring-before(request:uri(),request:path())
let $xsl := xslt:transform($xml, $xsl,
        map{
        "prettyName":$projectPrettyName,
        "idProject":$id,
	"host":$host,
        "project" : $project,
        "locale": max.i18n:getLang($project)
        })
let $pdf := fop:transform($xsl)
return $pdf
(: return file:write-binary('fop.pdf', $pdf):)
};

(: XML DB Resources LISTING functions:)
(:
lists collection' sub collections 
:)
declare function max.util:children-collection($dbName, $collection){
  let $dbAndColl:= if(contains($dbName,'/'))
    then (substring-before($dbName,'/')[1],substring-after($dbName,'/'))
    else ($dbName,$collection)
  
  
  let $path := if($collection = '') then '' else $dbAndColl[2] || "/"
  return distinct-values(
    for $doc in db:list($dbAndColl[1]) where starts-with($doc, $path)
    let $subCollection := substring-before(substring-after($doc, $path), "/")
    return  
     if(normalize-space($subCollection) = '')
     then ()
     else $subCollection 
  )
};



(:
Lists collection 's document (not recursive)
:)
declare function max.util:doc-in-collection($dbName, $collection){
   let $dbAndColl:= if(contains($dbName,'/'))
    then (substring-before($dbName,'/')[1],substring-after($dbName,'/'))
    else ($dbName,$collection)
    
  for $doc in db:list($dbAndColl[1], $dbAndColl[2])
  let $path := if($dbAndColl[2]='') then '' else $dbAndColl[2] || '/'
  return if(($path || file:name($doc)) = $doc)
  then $doc
  else () 
  
};



(:
Lists all DB resources (recursively)
:)
declare function max.util:list-db-resources($project){
    let $dbName := max.config:getProjectDBPath($project)
    let $xmlns:= max.config:getXMLFormat($project)
    let $baseURI:= max.util:getRelativeRootPath(())
    return
    <ul>
        {max.util:list-db-resources($project, $dbName, $baseURI, $xmlns,'')}
    </ul>

};



(:
Lists all DB resources (recursively) + add href prefix on each hyperlinks
:)

declare function max.util:list-db-resources($projectId, $dbName, $baseURI, $xmlns, $dir){
    for $d in db:dir($dbName, $dir)
    let $subDirs := max.util:list-db-resources($projectId, $dbName, $baseURI, $xmlns,$dir||'/'||$d)
    let $depth := count(string-to-codepoints($dir)[.=string-to-codepoints('/')])
    order by $d/text() 
    return
        let $fullPath := substring-after($dir || '/' || $d/text(),'/')
        return
            if(ends-with($d/text(),'.xml'))
            then
                <li data-depth='{$depth}' data-href='{$baseURI}{$projectId}/sommaire/{$fullPath}'>
                    {
                        max.util:getDocTitle($dbName, $fullPath, $xmlns)
                    }
                </li>
            else
                <li data-dir='true' data-depth='{$depth}'>{$d/text()}
                    <ul>
                        {max.util:list-db-resources($projectId, $dbName, $baseURI, $xmlns,$dir||'/'||$d)}
                    </ul>
                </li>
};



declare function max.util:getDocTitle($dbName, $docPath, $xmlFormat){
    let $docTitleQueryFile :=  max.util:getDocumentTitleXQueryFile($xmlFormat)
    return
        xquery:eval(xs:anyURI($docTitleQueryFile),map {'documentPath': $dbName ||'/'|| $docPath})
};


declare function max.util:maxHome(){
  file:resolve-path(file:parent(file:parent(static-base-uri())))
};

(:
    Returns resource file path from the edition folder if exists, from the max default one if not.
:)
declare function max.util:getResourceFilePath($projectId, $path){
    let $editionFilePath := max.util:maxHome()  || "editions/" || $projectId || "/" || $path
    return
        if(file:exists($editionFilePath))
        then $editionFilePath
        else max.util:maxHome() || $path
};


(:---------------------------------------------------------------------------------:)

(:debug / help:)
declare function max.util:listContextFunction(){
  let $context := inspect:context()
  return 
  <ul>{
    for $f in $context//function
      return <li>NAME = {string($f/@name)} / URI = {string($f/@uri)}</li>
    }
  </ul>
  
};


(:----------------------------------------------------------------------------------:)


declare function max.util:getTextHookFragment($projectId, $doc, $fragmentId){
    let $xqueryFile := max.util:maxHome()  || "editions/" || $projectId || "/" || $max.cons:TEXT_HOOK_XQUERY_FILEPATH
    return
        if(file:exists($xqueryFile))
        then
             xquery:eval(
                     xs:anyURI($xqueryFile),
                     map
                        { 'project':$projectId,
                        'baseURI': max.util:getRelativeRootPath($projectId),
                        'dbPath':max.config:getProjectDBPath($projectId),
                        'doc': $doc,
                        '$fragmentId' : $fragmentId
                        }
             )

        else
            ()
};

(:
 Returns project's menu xsl
:)
declare function max.util:getProjectMenuXSL($projectId) {
    max.util:getResourceFilePath($projectId, $max.cons:MENU_XSL_FILEPATH )
};

(:
 Returns project's TOC xsl
:)
declare function max.util:getProjectTOCXSL($projectId) {

    let $xmlFormat:=max.config:getXMLFormat($projectId)
    let $targetFile := max.util:getResourceFilePath($projectId, "ui/xsl/core/"|| $max.cons:TOC_XSL_FILENAME)
    return  if(file:exists($targetFile)) then $targetFile else ()
};

(:
 Returns document's TOC xsl
:)
declare function max.util:getDocumentTitleTOCXSL($projectId) {
    let $xmlFormat:=max.config:getXMLFormat($projectId)
    let $targetFile := max.util:getResourceFilePath($projectId, "ui/xsl/" || $xmlFormat ||'/'|| $max.cons:DOCUMENT_TITLE_XSL_FILEPATH)
    return  if(file:exists($targetFile)) then $targetFile else ()

};

(:
 Returns project's nav bar xsl
:)
declare function max.util:getNavigationBarXSL($projectId) {
    let $xsltFile := file:parent(file:parent(static-base-uri())) || "editions/" || $projectId || "/ui/xsl/"|| max.config:getXMLFormat($projectId) ||'/'|| $max.cons:NAV_BAR_XSL_FILEPATH
    return if(file:exists($xsltFile))
    then $xsltFile
    else file:parent(file:parent(static-base-uri())) || "ui/xsl/"|| max.config:getXMLFormat($projectId) ||'/'|| $max.cons:NAV_BAR_XSL_FILEPATH

};

(:
 Returns project's FO xsl
:)
declare function max.util:getProjectFoXsl($projectId as xs:string) {

    let $xmlFormat:=max.config:getXMLFormat($projectId)
    return max.util:getResourceFilePath($projectId, "ui/xsl/" || $xmlFormat ||'/'|| $xmlFormat || $max.cons:FO_XSL_FILEPATH)
};

(:
 Returns project's doc toc XQuery File
:)
declare function max.util:getDocumentTOCXQueryFile($projectId){
    let $xqueryFile := file:parent(file:parent(static-base-uri())) || "editions/" || $projectId || "/" || $max.cons:DOCUMENT_TOC_QUERY_FILEPATH
    return
        if(file:exists($xqueryFile))
        then $xqueryFile
        else
            let $xmlFormat:=max.config:getXMLFormat($projectId)
            return
                file:parent(file:parent(static-base-uri())) || "rxq/"|| $xmlFormat || "/" || $max.cons:DOCUMENT_TOC_QUERY_FILENAME
};


(:
Returns document title xquery (according to xml format)
:)
declare function max.util:getDocumentTitleXQueryFile($xmlFormat as xs:string){
     max.util:maxHome() || "/rxq/" || $xmlFormat || "/" || $max.cons:DOCUMENT_TITLE_QUERY_FILENAME
};

(:
 Returns project's doc toc XSL
:)
declare function max.util:getProjectDocumentTOCXSL($projectId){
    let $xsltFile := file:parent(file:parent(static-base-uri())) || "editions/" || $projectId || "/ui/xsl/"  || max.config:getXMLFormat($projectId) ||'/'|| $max.cons:DOCUMENT_TOC_XSL_FILENAME
    return if(file:exists($xsltFile))
    then $xsltFile
    else file:parent(file:parent(static-base-uri())) || "ui/xsl/" || max.config:getXMLFormat($projectId) ||'/'|| $max.cons:DOCUMENT_TOC_XSL_FILENAME
};


declare function max.util:getProjectLayoutTemplate($projectId) {
    let $customTemplate := file:parent(file:parent(static-base-uri())) || "editions/" || $projectId || "/ui/templates/" || $max.cons:HTML_TEMPLATE
    return
        if(file:exists($customTemplate))
        then $customTemplate
        else if (doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$projectId]/template)
        then file:parent(file:parent(static-base-uri())) || "editions/" || doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$projectId]/template/@file 
        else "../ui/templates/"||max.config:getXMLFormat($projectId) ||".html"
};


(:
Returns project's default XSLT to apply on text
:)
declare function max.util:getDefaultTextXSL($project as xs:string) as xs:string{
    let $env := max.config:getXMLFormat($project)
    return max.util:maxHome() || "/ui/xsl/" || $env || "/" || $env || ".xsl"
};

(:
Returns 404 response
:)
declare %output:method("text") function max.util:error404() {
    <rest:response>
        <http:response status="404">
            <http:header name="Content-Language" value="en"/>
            <http:header name="Content-Type" value="text/plain; charset=utf-8"/>
        </http:response>
    </rest:response>,
    "MaX - 404 - The requested resource is not available."
};


