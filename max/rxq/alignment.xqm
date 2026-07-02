(: For conditions of distribution and use, see the accompanying legal.txt file. :)

module namespace max.alignment = 'pddn/max/alignment';

import module namespace max.config = 'pddn/max/config' at 'config.xqm';
import module namespace max.html = 'pddn/max/html' at 'html.xqm';
import module namespace max.util = 'pddn/max/util' at 'util.xqm';

(:
  returns 2 identified fragments in an aligned layout
:)
declare
%rest:GET
%output:method("html")
%output:indent("no")
%output:html-version("5.0")
%output:doctype-system("html")
%rest:path("/{$project}/{$doc=.*xml}/{$id1}/{$id2}.html")
function max.alignment:alignedHTML($project, $doc, $id1, $id2){
   let $dbPath := max.config:getProjectDBPath($project)
   let $xsltDoc := max.util:buildXSLTDoc(
                                     max.util:getDefaultTextXSL($project),
                                     max.config:getXSLTAddons($project, $doc))                               
                                     
   let $xsltParams := max.config:getXSLTParams($project, $doc,())
   let $xml := max.alignment:runAlignmentQuery($project, $doc, $id1, $id2)

   let $html:=  <div>
                    <div class="plugins-wrapper">
                    {max.html:invokePluginXQueries($project, $doc, $id1)}
                    </div>
                    <div>{xslt:transform($xml, $xsltDoc, $xsltParams)}</div>
                </div>
                         
   (: return <div>{$xsltParams}</div> :)
   return  max.html:render($project,$doc, $html , $id1) 

};

(:
  Runs xquery to get 2 identified fragments
:)
declare function max.alignment:runAlignmentQuery($project, $routeId, $id1 as xs:string, $id2 as xs:string){
    let $queryFile := max.config:getTextAlignmentQueryFile($routeId)
    return
      if($queryFile)
        then xquery:eval(
            xs:anyURI($queryFile),
            map{
                'fragmentId':$id1,
                'firstPrefix': max.config:getFirstAlignmentPrefix($routeId),
                'secondPrefix': max.config:getSecondAlignmentPrefix($routeId),
                'project':$project,
                'baseURI': max.util:getRelativeRootPath($project),
                'dbPath': max.config:getProjectDBPath($project),
                'document': $routeId
                }
                       
          )
        else max.alignment:runDefaultAlignmentQuery($project, $id1, $id2)

};

(:
  Runs default alignment xquery
:)
declare function max.alignment:runDefaultAlignmentQuery($project, $id1 as xs:string, $id2 as xs:string){
  let $dbPath := max.config:getProjectDBPath($project)
  return 
  <align>
        {
          (collection($dbPath)//*[@xml:id=$id1])[1]
        }
        {
          (collection($dbPath)//*[@xml:id=$id2])[1]
        }
  </align>
};

(:
  Builds html hyperlink from a fragment id:
  The resulting link will be different if current route is aligned or not
:)
declare function max.alignment:buildFragmentLinkFromID($base, $project, $routeId, $fragmentID){
  let $isAligned := max.config:isAlignedRoute($routeId)
  return 
  if(not($isAligned))
  then 
    $base  || $project || "/" || $routeId || "/" || $fragmentID
  else
        let $firstPrefix := max.config:getFirstAlignmentPrefix($routeId)
        let $secondPrefix := max.config:getSecondAlignmentPrefix($routeId)
        let $idPointer2 := $secondPrefix || substring-after($fragmentID, $firstPrefix)  
        return $base ||  $project || "/" || $routeId  || "/" || $fragmentID || "/" ||  $idPointer2 
};