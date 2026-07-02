(: For conditions of distribution and use, see the accompanying legal.txt file. :)
xquery version "3.0";

module namespace max.plugin.index = 'pddn/max/plugin/index'; 
import module namespace max.config = 'pddn/max/config' at '../../rxq/config.xqm';
import module namespace max.html = 'pddn/max/html' at '../../rxq/html.xqm';
import module namespace max = 'pddn/max' at '../../max.xq';
import module namespace max.util = 'pddn/max/util' at '../../rxq/util.xqm';
import module namespace max.i18n = 'pddn/max/i18n' at '../../rxq/i18n.xqm';

declare variable $max.plugin.index:PLUGIN_ID := "index";

(:
returns index fragment if exists (already generated)
returns a new generated one if not
:)
declare
%rest:GET
%output:method("html")
%output:html-version("5.0")
%output:indent("no")
%output:encoding("UTF-8")
%rest:query-param("focus", "{$focus}")
%rest:path("/{$project}/index/{$type}.html")
function max.plugin.index:index($project,$type, $focus as xs:string?){
	let $projectLang := max.i18n:getLang($project)
	let $indexFilePath := file:parent(file:parent(file:parent(static-base-uri()))) || '/editions/'||$project||'/fragments/'||$projectLang||'/index/index_'||$type||'.frag.html'
	return
		if(file:exists($indexFilePath))
		then 
			let $content := fetch:doc($indexFilePath)
			let $content := <div id='content'>{$content}</div> 
			let $html := max.html:render($project, 'index/'||$type, $content)
			return if($focus)
				then(max.util:addHTMLClass($html, $focus, 'target'))
				else($html)
		else max.plugin.index:generateIndex($project,$type,$projectLang)
};

declare function max.plugin.index:generateIndex($project,$type,$lang){  
	let $indexFilePath := file:parent(file:parent(file:parent(static-base-uri()))) || '/editions/'||$project||'/fragments/'||$lang||'/index/index_'||$type||'.frag.html'
	let $custXQ := file:parent(file:parent(file:parent(static-base-uri())))||"editions/"||$project||"/xq/index/index_"||$type||".xq"
	let $custXSL := file:parent(file:parent(file:parent(static-base-uri())))||"editions/"||$project||"/ui/xsl/index/index_"||$type||".xsl"

	let $HTMLIndex :=
		if (file:exists($custXQ) and file:exists($custXSL))
		then max.plugin.index:loadIndex($project,$type,$custXQ,$custXSL,$lang)
		else "error" 
              
	let $res :=
		switch ($HTMLIndex)
			case "error"
				return "XQ and/or XSL file not found"
			default
				return file:write($indexFilePath, $HTMLIndex)
           
	return
		if (file:exists($indexFilePath))
		then max.plugin.index:index($project,$type, ())
		else $res
};

declare function max.plugin.index:loadIndex($edition,$type,$xq,$xsl,$lang) {
	let $dbPath := max.config:getProjectDBPath($edition)
	let $projectIndex :=
		xquery:eval(xs:anyURI($xq),map{
			'project':$edition,
            'baseURI': max.util:getRelativeRootPath($edition),
            'dbPath':$dbPath
        })
    (:let $filePath := file:parent(file:parent(file:parent(static-base-uri()))) || '/editions/projets_ead_pdn/fragments/'||$lang||'/index/pre_index_'||$type||'.frag.html'
    return file:write($filePath, $projectIndex):)
	let $HTMLProjectIndex := xslt:transform($projectIndex, $xsl, ( map {'project' : $edition, 'locale' : $lang})) 
	return $HTMLProjectIndex
};
