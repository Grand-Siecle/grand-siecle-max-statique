xquery version "3.0";

module namespace max.plugin.metadata = 'pddn/max/plugin/metadata';
import module namespace max.config = 'pddn/max/config' at '../../rxq/config.xqm';
import module namespace max.util = 'pddn/max/util' at '../../rxq/util.xqm';
import module namespace max.html = 'pddn/max/html' at '../../rxq/html.xqm';
import module namespace max.max = 'pddn/max' at '../../max.xq';
import module namespace max.i18n = 'pddn/max/i18n' at '../../rxq/i18n.xqm';

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace ead="urn:isbn:1-931666-22-9";
declare variable $max.plugin.metadata:PLUGIN_ID := "metadata";


declare
%rest:GET
%output:method("html")
%output:html-version("5.0")
%output:indent("no")
%output:encoding("UTF-8")
%rest:query-param("search", "{$search}")
%rest:query-param("focus", "{$focus}")
%rest:path("/{$project}/{$doc=.*}/info/{$tag}.html")
function max.plugin.metadata:getMetadataDocument($project, $doc, $tag, $search as xs:string ?, $focus as xs:string ?){
    let $dbPath := max.config:getProjectDBPath($project)
    let $xml := max.plugin.metadata:getXMLByTag($project, $dbPath, $doc, $tag) 
    let $projectXSL := file:parent(file:parent(file:parent(static-base-uri())))||"editions/"||$project||"/ui/xsl/ead/" || $tag || ".xsl"
    let $maxXSL :=  max.util:maxHome() ||  "/" || "/plugins/ead_metadata/" || $tag || ".xsl"
    let $xsl := if (file:exists($projectXSL))
                then $projectXSL
                else $maxXSL
    let $html := max.html:render(
            $project, $doc,
            <div>
                <div class="plugins-wrapper">{max.html:invokePluginXQueries($project, $doc, $tag)}</div>
                <div id='text'>
                  {xslt:transform(
                    $xml, 
                    $xsl,
                    map {
                        'project' : $project,
                        'locale': max.i18n:getLang($project)
                        })}  
                </div>
            </div>)
            return $html 
};

declare function max.plugin.metadata:getXMLByTag($project, $dbPath, $doc, $tag){
        switch ($tag)
        case "archdesc" return
            try{
                
                    let $queryArchdesc := '<div>{doc("'||$dbPath || '/' || $doc ||'")/*:ead/*:archdesc/* except doc("'|| $dbPath || '/' || $doc ||'")/*:ead/*:archdesc/*:dsc}</div>'
                    return 
                    xquery:eval($queryArchdesc,map
                        {
                        'project':$project,
                        'locale': max.i18n:getLang($project)
                        })
                }
                catch *{
                <div class='error'>{'Error [' || $err:code || '/' || $err:module || '/' || $err:line-number ||']: ' || $err:description}</div>
                }
         case "fonds" return
            try{
                
                    let $queryFonds := '<div>{doc("'||$dbPath || '/' || $doc ||'")/*:ead/*:archdesc/*:dsc/*:c/* except doc("'|| $dbPath || '/' || $doc ||'")/*:ead/*:archdesc/*:dsc/*:c/*:c}</div>'
                    return 
                    xquery:eval($queryFonds,map
                        {
                        'project':$project,
                        'locale': max.i18n:getLang($project)
                        })
                }
                catch *{
                <div class='error'>{'Error [' || $err:code || '/' || $err:module || '/' || $err:line-number ||']: ' || $err:description}</div>
                }
        default return
            try{
                    let $queryHeader := 'doc("'||$dbPath || '/' || $doc ||'")//*:ead/*:'|| $tag
                    return 
                    xquery:eval($queryHeader,map
                        {
                        'project':$project,
                        'locale': max.i18n:getLang($project)
                        })
                }
            catch *{
                <div class='error'>"{'Error [' || $err:code || '/' || $err:module || '/' || $err:line-number ||']: ' || $err:description}""MaX - Erreur = Vérifier l'URL"</div>
                }

};