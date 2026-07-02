(: For conditions of distribution and use, see the accompanying legal.txt file. :)

module namespace max.config = 'pddn/max/config';
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace max.cons = 'pddn/max/cons' at 'cons.xqm';
import module namespace max.util = 'pddn/max/util' at 'util.xqm';
import module namespace max.i18n = 'pddn/max/i18n' at 'i18n.xqm';



(: CONFIGURATION file path. :)
declare variable $max.config:CONFIGURATION_FILE := "../configuration/configuration.xml";

(: DEFAULT HTML HEAD TAGS file path. :)
declare variable $max.config:DEFAULT_HTML_HEAD_TAGS := "../configuration/defaultHtmlHeadTags.xml";


(::)
declare %private function max.config:checkConfiguration($projectId){
   if(doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$projectId])
   then ()
   else
     fn:error(xs:QName("err:config"), "MaX Configuration File does not declare project '" || $projectId ||"'")
};

(:returns edition list from config file:)
declare function max.config:getEditions(){
   doc($max.config:CONFIGURATION_FILE)//edition
};

(:returns edition id list from config file:)
declare function max.config:getEditionIDs(){
   doc($max.config:CONFIGURATION_FILE)//edition/@xml:id
};

(:returns edition prettyName from config file:)
declare function max.config:getProjectPrettyName($projectId){
  let $prettyName := doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$projectId]/@prettyName
  return 
    if($prettyName)
    then string($prettyName)
    else $projectId  
};


(:returns edition prettyName from config file:)
declare function max.config:getProjectDefaultLang($projectId){
    let $lang := doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$projectId]/@lang
    return
        if($lang)
        then string($lang)
        else 'fr'
};

(:returns enabled plugin name list:)
declare function max.config:getEnabledPluginNames($projectId){
    doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$projectId]//plugin/@name
    (:    let $pluginsFolder := file:parent(file:parent(static-base-uri())) || $max.cons:PLUGIN_FOLDER_NAME:)
(:    for $f in file:list($pluginsFolder,false()):)
(:    return if(ends-with($f,'/')) then replace($f,'/','') else ():)
};


(:returns project's plugin by name:)
declare function max.config:getPluginByName($projectId, $pluginName){
   doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$projectId]//plugin[@name=$pluginName]
};

declare function max.config:getPluginParameterValue($projectId, $pluginName, $parameterKey){
    let $param := doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$projectId]//plugin[@name=$pluginName]
            //parameter[@key=$parameterKey]
    return
        if($param/@value)
        then  $param/@value/string()
        else $param
(:  doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$projectId]//plugin[@name=$pluginName]:)
(:    //parameter[@key=$parameterKey]/@value/string():)
  
};

(:Gets project dbpath:)
declare function max.config:getProjectDBPath($projectId as xs:string){
  string(doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$projectId]/@dbpath)
};

(:
Checks if a document has to be ignored
@param $docName document name to check
:)
declare function max.config:isIgnored(
  $docName as xs:string,
  $projectId as xs:string) as xs:boolean{

  count(doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$projectId]/docsToIgnore/docToIgnore[.=$docName]) > 0

};


(:
Returns URL prefix
:)
declare function max.config:getUrlPrefix() as xs:string{
   if(doc($max.config:CONFIGURATION_FILE)/configuration/urlPrefix/text())
    then doc($max.config:CONFIGURATION_FILE)/configuration/urlPrefix/text()
    else '/'


};

(:
Returns BaseX baseURI
:)
(:declare function max.config:getBaseURI() as xs:string{:)
(:   if(doc($max.config:CONFIGURATION_FILE)/configuration/baseURI/text()):)
(:    then doc($max.config:CONFIGURATION_FILE)/configuration/baseURI/text():)
(:    else rest:base-uri() || $max.cons:BASE_DIR :)

(:   :)
(:};:)




declare function max.config:getNavigationQueryFile($project){
  let $filePath:= doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$project]/navigationFragment/@xquery-file
  return if($filePath)
         then string("../" || $filePath) 
         else()
};


(:checks if a project requires pager:)
(:declare function max.config:isWithPager($project) as xs:boolean{:)
(:  if(doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$project]//plugins/plugin[@name='pager']):)
(:  then true():)
(:  else false():)
(:};:)
(:
  Checks if a route needs alignment functions
:)
declare function max.config:isAlignedRoute($routeDoc) as xs:boolean{
  count(doc($max.config:CONFIGURATION_FILE)//alignment[@document=$routeDoc]) = 1
};

(:
  Returns true if the route entries label has to be replaced with config file values
:)
declare function max.config:isTOCBindedRoute($routeDoc){
  exists(doc($max.config:CONFIGURATION_FILE)//route[@document=$routeDoc]//labelBindings)
};

declare function max.config:getRouteTOCBindings($routeDoc){
  doc($max.config:CONFIGURATION_FILE)//route[@document=$routeDoc]//labelBindings
};

(:
Returns route's first alignment prefix
:)
declare function max.config:getFirstAlignmentPrefix($routeDoc){
  string(doc($max.config:CONFIGURATION_FILE)//alignment[@document=$routeDoc]/@first-prefix)
};

(:
Returns route's second alignment prefix
:)
declare function max.config:getSecondAlignmentPrefix($routeDoc){
  string(doc($max.config:CONFIGURATION_FILE)//alignment[@document=$routeDoc]/@second-prefix)
};

declare function max.config:getTextAlignmentQueryFile($routeDoc){
  let $filePath:= doc($max.config:CONFIGURATION_FILE)//alignment[@document=$routeDoc]/@align-xquery-file
  return if($filePath)
         then string("../" || $filePath) 
         else()   
};

(:
Returns project's XML format
:)
declare function max.config:getXMLFormat($project as xs:string){
  string(doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$project]/@env)
};

(:
  Returns all required xslt addons (plugins + text hook + alignment)
:)
declare function max.config:getXSLTAddons($project, $routeDoc) as xs:string *{
  (:if route needs alignment, alignment.xsl is returned too :)
  let $alignXSL := if(max.config:isAlignedRoute($routeDoc)) then $max.cons:ALIGNMENT_XSL else()
  let $pluginsXSL := for $plugin in max.config:getEnabledPluginNames($project)
                       let $xsltFile := file:parent(file:parent(static-base-uri())) || $max.cons:PLUGIN_FOLDER_NAME || "/" || $plugin || "/" || $plugin || ".xsl"
                       return if(file:exists($xsltFile))
                                 then $xsltFile
                                 else ()
  let $textHookPath := file:parent(file:parent(static-base-uri())) || "editions/" || $project || "/ui/xsl/" || max.config:getXMLFormat($project) ||'/'|| $max.cons:TEXT_HOOK_XSL_FILENAME
  let $textHook := if(file:exists($textHookPath)) then $textHookPath else()
  return
    (
      $alignXSL, 
      $pluginsXSL,
      $textHook
    )
};

declare function max.config:getXSLTParams($project, $doc, $id){
  let $alignParams := map:merge(
    for $attr in doc($max.config:CONFIGURATION_FILE)//alignment[@document=$doc]/@*[local-name(.)='first-prefix' or local-name(.)='second-prefix'] 
    return map:entry(local-name($attr),$attr/string())
  )

  (:Plugin's xslt parameters:)
  let $pluginsParams :=  for $param in doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$project]//plugins//parameter[@xsl='true']
  return map:entry($param/@key/string(),$param/@value/string())
  
  
  return map:merge(($alignParams,
                   $pluginsParams, 
                   map{
                     'baseuri' : max.util:getRelativeRootPath($project),
                     'locale': max.i18n:getLang($project),
                     'route': if($doc) then $doc else '',
                     'id': if($id) then $id else '',
                     'project' : $project}))
};

(: Returns css class names concerned by checkbox text options:)
declare function max.config:getCheckboxTextOptions($project){
  doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$project]/textOptions/checkboxOptions/targetClass/text()
};

declare function max.config:getTextOptionsFragment($project){
  string(doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$project]/textOptions/htmlFragment/@file)
};

declare function max.config:getProjectDescription($project){
    doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$project]/description/text()
};

declare function max.config:getProjectAuthor($project){
    doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$project]/author/text()
};

(: get project data from config file :)
declare function max.config:getProjectData($project){
  map:merge(
      for $data in doc($max.config:CONFIGURATION_FILE)//edition[@xml:id=$project]/projectData/data
      return map:entry($data/@key , data($data))
  )  
};
