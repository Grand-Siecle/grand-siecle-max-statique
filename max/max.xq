(: For conditions of distribution and use, see the accompanying legal.txt file. :)

module namespace max = 'pddn/max';
import module namespace max.config = 'pddn/max/config' at 'rxq/config.xqm';
import module namespace max.util = 'pddn/max/util' at 'rxq/util.xqm';
import module namespace max.html = 'pddn/max/html' at 'rxq/html.xqm';
import module namespace max.toc = 'pddn/max/toc' at 'rxq/toc.xqm';
import module namespace max.api = 'pddn/max/max_api' at 'rxq/max_api.xqm';
import module namespace request = "http://exquery.org/ns/request";


(:MaX Home:)
declare
%rest:GET
%output:method("html")
%output:html-version("5.0")
%output:encoding("UTF-8")
%rest:path( "/max.html")
function max:home(){
    let $jsonFile := file:parent(static-base-uri()) ||'package.json'
    return if(not(file:exists($jsonFile)))
        then max.util:error404() (:no max.html in production env.:)
    else
        let $json := file:read-text($jsonFile)
        let $version := json:parse($json)//version
        return
            <html>
                <head>
                    <title>MaX - Moteur d'affichage XML</title>
                </head>
                <body class='maxhome'>
                    <h1>MaX - Moteur d'affichage XML</h1>
                    <div>
                        <ul>
                            <li>Version : {$version}</li>
                            <li>Processeur XSLT : {xslt:processor()}</li>
                        </ul>
                    </div>
                </body>
            </html>
};

(:MaX Home:)
declare
%rest:GET
%rest:path( "/favicon.ico")
function max:favicon(){
    max.util:rawFile(file:parent(static-base-uri()) || 'ui/images/favicon.ico')
};


(:Project's home:)
declare
%rest:GET
%output:method("html")
%output:html-version("5.0")
%output:encoding("UTF-8")
%rest:path( "/{$project}")
function max:projectHome($project){
    let $redirection :=
        if (ends-with(request:uri(), '/'))
        then
            request:uri() || 'accueil.html'
        else
            request:uri() || '/accueil.html'
    return
        web:redirect($redirection)
};

(:gets a project's HTML page:)
declare
%rest:GET
%output:method("html")
%output:html-version("5.0")
%output:indent("no")
%output:encoding("UTF-8")
%rest:path( "/{$project}/{$page=[a-zA-Z0-9_]+}.html")
function max:page($project, $page){
    let $dbPath := max.config:getProjectDBPath($project)
    return

        if (not($dbPath))
        then max:max-error(
                ' Configuration manquante pour le projet "'||$project||'" (fichier configuration/configuration.xml)',
                (), (), (), ())

        else
        if (not(db:exists(max.util:dbNameFromCollection($dbPath))))
            then max:max-error(
                    "Oups... La base '"|| $dbPath ||"' n'existe pas !",
                    (), (), (), ())
        else
            try {
                switch ($page)
                    case "sommaire"
                        return
                            let $content := max.toc:getProjectTOC($project)
                            return max.html:render($project, $page, $content, ())
                    case "accueil"
                    (:if 'accueil' frag does not exists -> display route list by default:)
                        return
                            try {
                                let $content := max.html:getHTMLFragment($project, $page)
                                return max.html:render($project, $page, $content, ())
                            }
                            catch * {
                                admin:write-log('Page/fragment "' || $page || '" introuvable ou mal formé', 'INFO'),
                                let $content := max.toc:getProjectTOC($project)
                                return max.html:render($project, $page, $content, ())
                            }

                    default return
                        try {
                            let $content := max.html:getHTMLFragment($project, $page)
                            return max.html:render($project, $page, $content, ())
                        }
                        catch *{
                            admin:write-log('Page/fragment "' || $page || '" introuvable ou mal formé', 'ERROR'),
                            max.util:error404()
                        }
            }
            catch err:config {max:max-error('', $err:description, $err:module, $err:line-number, $err:additional)}
            catch err:FODC0002 {max:max-error('', $err:description, $err:module, $err:line-number, $err:additional)}
            catch err:FODC0007 {max:max-error('Édition inconnue - Veuillez vérifier votre fichier de configuration.', $err:description, $err:module, $err:line-number, $err:additional)}
            catch err:XPTY0004 {max:max-error('Configuration dupliquée - Veuillez vérifier votre fichier de configuration.', $err:description, $err:module, $err:line-number, $err:additional)}
};


declare
%rest:GET
%output:method("html")
%output:html-version("5.0")
%output:indent("no")
%output:encoding("UTF-8")
%rest:path("/{$project}/sommaire/{$doc=.*}.html")
function max:documentTOC($project, $doc){
    let $content := max.toc:getDocumentTOC($project, $doc || '.xml')
    return max.html:render($project, "sommaire", $content, ())
};

(:gets a project's XML fragment + a navigation bar(wrapped in an html skeleton):)
declare
%rest:GET
%output:method("html")
%output:html-version("5.0")
%output:indent("no")
%output:encoding("UTF-8")
%rest:query-param("search", "{$search}")
%rest:query-param("focus", "{$focus}")
%rest:path("/{$project}/{$routeDoc=.*\.xml}/{$id}.html")
function max:fragmentToHTMLPage($project, $routeDoc, $id, $search as xs:string ?, $focus as xs:string ?){
    let $dbPath := max.config:getProjectDBPath($project)
    return
        let $xml :=
            <div id="wrap-{$id}">
                {max.util:getTextHookFragment($project, $routeDoc, $id)}
                {max.api:getXMLByID($dbPath, $id)}
            </div>
        let $txml := max:transformEditionFragment($project, $xml, $routeDoc)
        return
            try {
                let $html := max.html:render(
                        $project, $routeDoc,
                        <div>
                            <div class="plugins-wrapper">
                                {max.html:invokePluginXQueries($project, $routeDoc, $id)}
                            </div>
                            {$txml}
                        </div>, $id)
                return max:applySearchMarkup($html, $search, $focus)
            }
            catch * {
                max:max-error("Erreur code " || $err:code, $err:description, $err:module, $err:line-number, $err:additional)
            }
};


(:returns transformed full document:)
declare
%rest:GET
%output:method("html")
%output:html-version("5.0")
%output:indent("no")
%output:encoding("UTF-8")
%rest:query-param("search", "{$search}")
%rest:query-param("focus", "{$focus}")
%rest:path("/{$project}/doc/{$doc=.*}.html")
function max:getFullDocument($project, $doc, $search as xs:string ?, $focus as xs:string ?){
    let $docName := $doc || ".xml"
    let $xmlDoc := (doc(max.config:getProjectDBPath($project) || "/" || $docName)/*)[1]
    let $id := $xmlDoc/@xml:id
    let $xml := 
    	<div id='text'>
        	{max.util:getTextHookFragment($project, $docName, $id)}
            {$xmlDoc}
        </div>
    let $txml := max:transformEditionFragment($project, $xml, $doc)
    let $html := max.html:render(
            $project, "doc/" || $docName,
            <div>
                <div>{max.html:invokePluginXQueries($project, $docName, $id)}</div>
                {$txml}
            </div>)
    return max:applySearchMarkup($html, $search, $focus)
};

(: marks searched txt + adds html class for auto scroll on $focusTarget id:)
declare %private function max:applySearchMarkup($html as node(), $search as xs:string ?, $focusTarget as xs:string ?){
    try {
        let $markedHtml :=
            if ($search)
            then
                max.util:markSearchedText($html, $search, $focusTarget)
            else
                $html
        let $focusedHtml :=
            if ($focusTarget)
            then
                max.util:addHTMLClass($markedHtml, $focusTarget, 'target')
            else
                $markedHtml
        return $focusedHtml
    }
    catch err:XUDY0027 {
        $html
    }
};


(:Returns XML fragment identified by $id:)
declare
%rest:GET
%output:method("html")
%output:html-version("5.0")
%output:indent("no")
%output:encoding("UTF-8")
%rest:path("/{$project}/fragment/{$id}.html")
function max:getXMLByID($project, $id){
    max.api:getXMLByID(max.config:getProjectDBPath($project), $id)
};

(:Returns XML fragment identified by $id in its HTML version:)
declare
%rest:GET
%output:method("html")
%output:html-version("5.0")
%output:indent("no")
%output:encoding("UTF-8")
%rest:query-param("xsl", "{$xsl}")
%rest:query-param("xslparams", "{$xslparams}")
%rest:query-param("wrap", "{$wrap}")
%rest:path("/{$project}/fragment_html/{$id}.html")
function max:getHTMLByID($project, $id, $xsl, $xslparams as xs:string *, $wrap as xs:string ?) as element(){
    let $xml := max.api:getXMLByID(max.config:getProjectDBPath($project), $id)
    let $xslAddons := (max.config:getXSLTAddons($project, ()), if ($xsl) then file:parent(static-base-uri()) || string("editions/" || $project || "/ui/xsl/" || $xsl) else ())
    let $xsltDoc := max.util:buildXSLTDoc(
            max.util:getDefaultTextXSL($project),
            $xslAddons
    )

    let $xslrURLParams := for $param in $xslparams
    let $paramName := substring-before($param, ':')
    let $paramValue := substring-after($param, ':')
    return map:entry($paramName, $paramValue)
    (:Merge all xsl parameters: from url + project:)
    let $xsltParams := map:merge((max.config:getXSLTParams($project, (), $id), $xslrURLParams))

    let $html := <div class='standalone-html' id="wrap-{$id}">
        {xslt:transform($xml, $xsltDoc, $xsltParams)}
    </div>
    return
        if ($wrap and $wrap = 'true')
        then max.html:wrapInSimpleHTML($project, $html)
        else $html
};


declare function max:transformEditionFragment($project, $xml, $route){
    let $xsltDoc := max.util:buildXSLTDoc(
            max.util:getDefaultTextXSL($project),
            max.config:getXSLTAddons($project, $route))
    let $xsltParams := max.config:getXSLTParams($project, $route, ())
    return xslt:transform($xml, $xsltDoc, $xsltParams)
};

declare
%rest:error("err:max")
%output:method("html")
%output:html-version("5.0")
%output:indent("no")
%output:encoding("UTF-8")
%rest:error-param("message", "{$message}")
%rest:error-param("desc", "{$desc}")
%rest:error-param("module", "{$module}")
%rest:error-param("line", "{$line}")
%rest:error-param("stacktrace", "{$stacktrace}")
function max:max-error($message, $desc, $module, $line, $stacktrace)
{
    admin:write-log('MaX error - ' || $message),
    <html>
        <head>
            <title>MaX - ERROR</title>
        </head>
        <body>
            <h1>Erreur MAX</h1>
            <div class='error'>
                <div>
                    {if ($message) then $message else 'MaX - Erreur'}
                </div>
                {
                    if ($desc or $module or $line)
                    then
                        <div><h2>Trace BaseX</h2>
                            <ul>
                                {if ($desc) then <li>Description : <span>{$desc}</span></li> else ()}
                                {if ($module) then <li>Module : <span>{$module}</span></li> else ()}
                                {if ($line) then <li>Line : <span>{$line}</span></li> else ()}
                                {if ($stacktrace) then <li>stacktrace : <span>{$stacktrace}</span></li> else ()}
                            </ul>
                        </div>
                    else ()
                }
            </div>
        </body>
    </html>
};


declare
%rest:GET
%output:method("xml")
%output:encoding("UTF-8")
%output:omit-xml-declaration("no")
%rest:path("/{$project}/sitemap.xml")
function max:buildSitemap($project){
    max.html:getSitemap($project)
};


declare %private function max:invokePluginXQueries($project, $routeDoc, $id){
    try {
        let $dbPath := max.config:getProjectDBPath($project)
        let $pluginsHTML :=
            for $pluginName in max.config:getEnabledPluginNames($project)
            let $pluginXQ := file:parent(static-base-uri()) || '/plugins/' || $pluginName || '/' || $pluginName || '.xq'
            return if (file:exists($pluginXQ))
            then
                xquery:eval($pluginXQ,
                        map
                        {
                        'baseURI' : max.util:getRelativeRootPath($project),
                        'dbPath' : $dbPath,
                        'project' : $project,
                        'doc' : $routeDoc,
                        'id' : $id
                        })
            else ()
        return $pluginsHTML
    }
    catch * {max:max-error("Erreur code " || $err:code, $err:description, $err:module, $err:line-number, $err:additional)}
};