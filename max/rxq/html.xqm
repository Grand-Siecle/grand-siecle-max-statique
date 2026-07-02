(: For conditions of distribution and use, see the accompanying legal.txt file. :)

module namespace max.html = 'pddn/max/html';

import module namespace max.config = 'pddn/max/config' at 'config.xqm';
import module namespace max.cons = 'pddn/max/cons' at 'cons.xqm';
import module namespace max.util = 'pddn/max/util' at 'util.xqm';
import module namespace max.i18n = 'pddn/max/i18n' at 'i18n.xqm';
import module namespace max.toc = 'pddn/max/toc' at 'toc.xqm';
import module namespace request = "http://exquery.org/ns/request";


(:
 : Wraps div in HTML simple template.
 : @param  $wrapped element to wrap in html
 :)
declare function max.html:render(
        $projectId as xs:string,
        $pageId as xs:string,
        $wrapped as element()+)
as element(html) {max.html:render($projectId, $pageId, $wrapped, ())};


(:
 : Wraps fragment identified div in HTML template.
 : @param  $wrapped element to wrap in html
 :)
declare function max.html:render(
        $projectId as xs:string,
        $pageId as xs:string,
        $content as element()+,
        $fragmentId as xs:string ?
) as element(html) {
    try {
        let $head := max.html:buildHTMLHead($projectId, $content)
        let $jsImports := max.html:buildJavascript($projectId, $pageId, $fragmentId)
        let $menu := max.html:buildMenu($projectId, $pageId, $fragmentId)
        let $targetId := if ($fragmentId)
            then $fragmentId
            else if(fn:starts-with($pageId,'doc/'))
                then $pageId
                else ()
        let $doc := if ($fragmentId) then $pageId else tokenize($pageId,'doc/')[last()]
        let $navigationSelect := if($targetId) then max.html:getNavbarForDocument($projectId, $doc, $targetId) else()
        let $textOptions := if ($content//*[@id=$max.cons:TEXT_ID]) then max.html:buildTextOptionsMenu($projectId) else ()

    return

            max.html:renderTemplate(doc(max.util:getProjectLayoutTemplate($projectId)),
                    map {
                    'projectId' : $projectId,
                    'prettyName' : max.config:getProjectPrettyName($projectId),
                    'data' : max.config:getProjectData($projectId),
                    'baseURI' : max.util:getRelativeRootPath($projectId),
                    'home' :  max.util:getRelativeRootPath($projectId) || 'accueil.html',
                    'menu' : $menu,
                    'navigationSelect' : $navigationSelect,
                    'textOptions' : $textOptions,
                    'head' : $head,
                    'content' : $content,
                    'footer' : max.html:getFooter($projectId),
                    'jsImports' : $jsImports
                    })
        }
        catch err:FODC0002 {
            <html>
                <p>Bad configuration for <b>{$projectId}</b> - Please check your configuration file</p>
                <p>{$err:description} -  {$err:module} - {$err:line-number}</p>
            </html>
        }
        catch file:no-dir {
            <html>
                <p>Bad configuration for <b>{$projectId}</b> - A plugin directory or file is missing : Please check your configuration file</p>
                <p>{$err:description} -  {$err:module} - {$err:line-number}</p>
            </html>
        }

};

declare function max.html:wrapInSimpleHTML(
        $projectId as xs:string,
        $wrapped as element()+)
as element(html) {

    let $head := max.html:buildHTMLHead($projectId, $wrapped)
    let $jsImports := max.html:buildJavascript($projectId, "", "")
    return <html>{$head}<body>{$wrapped}{$jsImports}</body></html>

};


declare %private function max.html:buildHTMLHead($projectId, $content){

    max.html:buildMetas($projectId, $content),
    max.html:buildCSSImports($projectId)
};


(:
Generates global js script import tags
:)
declare %private function max.html:buildJavascript($projectId, $pageId, $fragmentId){

    <script type="text/javascript">
        const baseURI="{max.util:getRelativeRootPath($projectId)}";
        const projectId="{$projectId}";
        const route ="{$pageId}";
        const fragmentId ="{$fragmentId}";
        const lang = "{max.i18n:getLang($projectId)}"
    </script>,
    max.html:buildJavascriptImports($projectId)

};


(:
Generates contextual js script import tags
:)
declare %private function max.html:buildJavascriptImports($projectId)
as element(script)*
{
    let $projectJS :=
        if (file:exists(
                file:parent(file:parent(static-base-uri())) || "/editions/" || $projectId || "/ui/js/" || $projectId || ".js"))
        then <script type="text/javascript"
        src='{max.util:getRelativeRootPath($projectId) || "ui/js/" || $projectId || ".js"}'/>
        else ()

    let $pluginsFolder := file:parent(file:parent(static-base-uri())) || $max.cons:PLUGIN_FOLDER_NAME
    let $pluginsJS :=
        for $plugin in max.config:getEnabledPluginNames($projectId)
            for $file in file:list($pluginsFolder || "/" || $plugin, true(), $plugin||".js")
            let $publicjs := max.util:getRelativeRootPath($projectId) || "plugins/" || $plugin || '/' ||
            substring-before($file, ".") || ".js"
            return
                <script  type="module"
                src="{$publicjs}"></script>

(:    let $envJS := if (max.config:getXMLFormat($projectId) = $max.cons:EAD):)
(:    then ()  :)(: TODO include Sortable.js and ead.js :)
(:    else ():)

    return ($projectJS, $pluginsJS)

};

(:
Generates contextual css stylesheet import tags
:)
declare %private function max.html:buildCSSImports($projectId)
as element(link)*
{

    let $cssProject :=
        if (file:exists(file:parent(file:parent(static-base-uri())) || '/editions/' || $projectId || "/ui/css/" || $projectId || '.css'))
        then
            <link rel="stylesheet" type="text/css"
            href="{max.util:getRelativeRootPath($projectId)|| 'ui/css/' || $projectId || '.css'}"/>
        else ()

    let $pluginsCSS :=
        for $pluginAddon in max.config:getEnabledPluginNames($projectId)
        let $pluginDirectory := $max.cons:PLUGIN_FOLDER_NAME || "/" || $pluginAddon
        let $cssFile := file:parent(file:parent(static-base-uri())) || $pluginDirectory || '/' || $pluginAddon || '.css'
        return if (file:exists($cssFile))
        then
            <link rel="stylesheet"
            type="text/css"
            href="{max.util:getRelativeRootPath($projectId)||  "plugins/" || $pluginAddon || '/' || $pluginAddon || '.css'}"/>
        else ()
    return ($pluginsCSS, $cssProject)

};


declare %private function max.html:buildMenu(
        $projectId as xs:string,
        $menuId as xs:string,
        $fragmentId as xs:string ?)
as item()+
{
    let $params := map {'projectId' : $projectId, 'selectedTarget' : $menuId||'.html', 'baseURI' : max.util:getRelativeRootPath(())}
    (:menu translation:)
    let $translatedXmlMenu :=
        copy $c := doc("../editions/" || $projectId || "/" || $max.cons:MENU_FILE)
        modify (
            for $i in $c//entry
            let $label := max.i18n:getText($projectId, "menu." || $i/id)
            return insert node <label>{$label}</label> into $i
        )
        return $c
    (:menu xslt transform:)
    let $xslMenu := max.util:getProjectMenuXSL($projectId)
    return xslt:transform($translatedXmlMenu, $xslMenu, $params),max.html:buildI8nMenu($projectId)

};

declare %private function max.html:buildI8nMenu($projectId as xs:string){
    <ul class="i18n-menu">
        {
            for $l in max.i18n:getLanguageList($projectId)
            let $class:= if(max.i18n:getLang($projectId) = $l)
            then "max-lang selected"
            else "max-lang"
            return
                <li class="{$class}"><a role="button" onclick="MAX.setLanguage('{$l}')">{$l}</a></li>
        }
    </ul>
};


(:gets a project static HTML fragment (wrapped in an html div):)
declare function max.html:getHTMLFragment($project, $fragmentName as xs:string)
as element(div){
    let $lang := max.i18n:getLang($project)
    let $fragmentPath := max.util:maxHome() || "/editions/" || $project || "/fragments/" || $lang ||'/'||$fragmentName || ".frag.html"
    (:on conserve la méthode fetch/parse html en commentaire au cas où ...:)
    (: let $content :=  fetch:xml($fragmentPath, map { 'parser': 'html','htmlparser': map { 'html': false(), 'nodefaults': true() }}) :)
    (: let $contentBody := $content//*:body/*[1] :)
    let $content := fetch:doc($fragmentPath)
    return <div>{$content}</div>
};

(:gets a project static HTML fragment (wrapped in an html div):)
declare function max.html:getHTMLFragmentFile($project, $fragmentFile as xs:string)
as element(){

    let $fragmentPath := max.util:maxHome() || '/' || $fragmentFile
    return doc($fragmentPath)/*[1]
};

(:builds and returns default MaX HTML footer:)
declare function max.html:getFooter($project){
    try {
        let $footerPath := max.util:maxHome() || "/editions/" || $project || "/" || $max.cons:EDITION_FOOTER_PATH
        let $content := fetch:doc($footerPath)
        return $content
    }
    catch * {
        <footer>
            <img id='biblissima' class='footer-logos' src='{max.util:getRelativeRootPath($project)}core/ui/images/logos/biblissima.png'/>
            <img id='invav' class='footer-logos' src='{max.util:getRelativeRootPath($project)}core/ui/images/logos/investissement-davenir.png'/>
        </footer>
    }
};



(:get text navigation bar for a specific route:)
declare function max.html:getNavbarForDocument($project, $doc, $selectedId){

    let $xml := max.toc:getDocumentTOC($project, $doc) (:max.route:getRouteNavigationEntriesAsHTML($project, $routeId):)
    let $hasTarget := $xml//ul//li[@data-target=$selectedId]
    return if (count($xml//ul/li) > 1 and $hasTarget)
    then
        xslt:transform($xml,
                max.util:getNavigationBarXSL($project),
                map {
                'selectedId' : $selectedId,
                'project' : $project,
                'baseuri' : max.util:getRelativeRootPath($project),
                'prevArrow' : $selectedId != string(($xml//ul//li/@data-target)[1]),
                'nextArrow' : $selectedId != string(($xml//ul//li/@data-target)[last()])
                }
        )/*[1]
    else ()
};


(:
Builds text options menu component
:)
declare %private function max.html:buildTextOptionsMenu($projectId){
    <div class="navbar-form navbar-left">
        <div class="dropdown">
            <button class="btn btn-default"
            type="button"
            id="txt_options"
            data-bs-toggle="dropdown"
            aria-haspopup="true"
            aria-expanded="true">
                <a class="nav-link dropdown-toggle">{max.i18n:getText($projectId,'reading-options')}</a>
            </button>
            <ul class="dropdown-menu" aria-labelledby="txt_options" id="options-list">
                {
                    for $cssClass in max.config:getCheckboxTextOptions($projectId)
                    return <li><a><input name="toggle_{$cssClass}"
                    type="checkbox"
                    class="visibility_toggle"
                    id="toggle_{$cssClass}"
                    data-option="{$cssClass}"
                    onchange="MAX.setClassVisibility('{$cssClass}')"/>{max.i18n:getText($projectId, $cssClass)}</a></li>
                }
                {
                (:adds static text options frag if specified in configuration file:)
                    let $frg := max.config:getTextOptionsFragment($projectId)
                    return if ($frg)
                    then max.html:getHTMLFragmentFile($projectId, $frg)
                    else ()
                }
            </ul>
        </div>
    </div>

};


(:
Applies bindings in an HTML document for final rendering.
HTML document in considered as an xquery-> bindings declarations needs to be
added at the beginning of the xquery
:)
declare function max.html:renderTemplate($htmlDoc as document-node(), $map as map(*)){

    let $declarations := string-join(for $var in map:keys($map)
    return "declare variable $" || $var || " external;")
    return xquery:eval($declarations || serialize($htmlDoc), $map)

};


(:
Builds metadata - html, dc and opengraph
:)
declare %private function max.html:buildMetas($projectId, $xmlFragment){

    let $f := file:parent(file:parent(static-base-uri()))
    || 'editions/'
    || $projectId
    || '/'
    || $max.cons:METADATA_TOC_QUERY_FILEPATH

    let $metadatas :=
        if (file:exists($f))
        then
            xquery:eval(xs:anyURI($f), map
            {
            'project' : $projectId,
            'requestPath' : request:path(),
            'content' : $xmlFragment
            })
        else (
            let $textTitle := if($xmlFragment//*[@id='text'])
                              then string-join(($xmlFragment//*[@id='text']//(*:h1 | *:h2 | *:h3))[1]//text(), '')
                              else string-join(($xmlFragment//(*:h1 | *:h2 | *:h3))[1]//text(), '')
            return
            <title>{max.config:getProjectPrettyName($projectId) || ' - ' || max.html:cleanValue($textTitle)}</title>,
            <meta name="author" content="{max.config:getProjectAuthor($projectId)}"/>,

            <meta property="dc:description" content="{max.config:getProjectDescription($projectId)}"/>,
            <meta property="dc:title" content="{max.html:cleanValue(string-join(($xmlFragment//*[@id='text']//(*:h1 | *:h2 | *:h13))[1]//text(), ''))}"/>,
            <meta property="dc:type" content="Web page"/>,
            <meta property="dc:relation" content="{request:path()}"/>,

            <meta property="og:description" content="{max.config:getProjectDescription($projectId)}"/>,
            <meta property="og:title" content="{max.html:cleanValue(string-join(($xmlFragment//*[@id='text']//(*:h1 | *:h2 | *:h13))[1]//text(), ''))}"/>,
            <meta property="og:type" content="page"/>,
            <meta property="og:url" content="{request:path()}"/>)

    return $metadatas

};

declare function max.html:invokePluginXQueries($project, $routeDoc, $id){
    let $dbPath := max.config:getProjectDBPath($project)
    let $pluginsHTML :=
        for $pluginName in max.config:getEnabledPluginNames($project)
        let $pluginXQ := max.util:maxHome()||'/plugins/' || $pluginName || '/'|| $pluginName ||'.xq'
        return if(file:exists($pluginXQ))
        then
            xquery:eval(xs:anyURI($pluginXQ),
                    map
                    {
                    'baseURI' : max.util:getRelativeRootPath(()),
                    'dbPath': $dbPath,
                    'project' : $project,
                    'doc' : $routeDoc,
                    'id' :$id
                    })
        else ()
    return $pluginsHTML
};

declare function max.html:cleanValue($value){
    let $value := replace($value, '&#xA;', ' ')
    let $value := replace($value, '&#x9;', ' ')
    let $value := replace($value, '\s{2,}', ' ')
    return $value
};
(: html head tags :)
declare function max.html:setHtmlHeadTags($project, $meta as map(*)*){
    let $activeHtmlHeadTags := doc($max.config:CONFIGURATION_FILE)//edition[@xml:id = $project]/htmlHeadTags

    return
        try {
        (:tri des balises metas:)
            let $keys :=
                <metas>{
                    map:for-each($meta,
                            function($k, $v){
                                if ($k != 'title')
                                then (<key>{$k}</key>)
                                else ()
                            }
                    )
                }</metas>

            let $order :=
                for $key in $keys/key
                order by $key
                return $key


            return (
                max.html:getHtmlTitle($project, $meta, $order),
                max.html:getHtmlMetas($project, $meta, $order),
                max.html:getHtmlLink($project, $meta, $order)
            (:,<test2>{json:serialize($meta)}</test2>:)
            )
        }
        catch * {}

};

(: html head tags : title :)
declare function max.html:getHtmlTitle($project, $meta as map(*)*, $order){
    if (fn:exists($meta) = xs:boolean(1) and fn:exists($meta('title')) = xs:boolean(1))
    then (<title>{$meta('title')}</title>)
    else ("")
};

(: html head tags : metas :)
declare function max.html:getHtmlMetas($project, $meta as map(*)*, $order){
    for $key in $order

    return (
        if ( fn:empty($meta) = xs:boolean(0)
                and fn:exists($meta($key)) = xs:boolean(1)
                and fn:exists($meta($key)('value')) = xs:boolean(1)
                and $meta($key)('value') != "")
        then (
            if ($meta($key)('attribute') = 'property')
            then (<meta property="{$key}" content="{$meta($key)('value')}"/>)
            else if ($meta($key)('attribute') = 'name')
            then (<meta name="{$key}" content="{$meta($key)('value')}"/>)
            else ()
        )
        else ()
    )
};

(: html head tags : link (favicon) :)
declare function max.html:getHtmlLink($project, $meta as map(*)*, $order){
    for $key in $order

    return (
        if ( fn:empty($meta) = xs:boolean(0)
                and fn:exists($meta($key)) = xs:boolean(1)
                and fn:exists($meta($key)('value')) = xs:boolean(1)
                and $meta($key)('value') != "")
        then (
            if ($meta($key)('attribute') = 'rel')
            then (<link rel="{$key}" href="{$meta($key)('value')}"/>)
            else ()
        )
        else ()
    )
};


declare function max.html:getSitemap($project){

    let $baseUri := replace(request:uri(), concat($project, '/sitemap.xml'), '')
    return

        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">

            {
                for $entry in doc("../editions/" || $project || "/" || $max.cons:MENU_FILE)//*:entry[@type = "main"]
                return
                    <url>
                        <loc>{$baseUri}{$project}/{string($entry/*:target)}</loc>
                    </url>
            }
            {
                let $toc := max.toc:getProjectTOC($project)
                return for $entry in $toc//*:li
                let $url := substring(string($entry/*:a/@*:href), 2)
                return <url><loc>{$baseUri}{$url}</loc></url>
            }

        </urlset>

};



