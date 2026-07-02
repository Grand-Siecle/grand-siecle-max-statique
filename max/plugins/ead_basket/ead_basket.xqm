module namespace max.plugin.ead_basket = "pddn/max/plugin/ead_basket";
import module namespace max.config = 'pddn/max/config' at '../../rxq/config.xqm';
import module namespace max.util = 'pddn/max/util' at '../../rxq/util.xqm';
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace max.html = 'pddn/max/html' at '../../rxq/html.xqm';
import module namespace max.api = 'pddn/max/max_api' at '../../rxq/max_api.xqm';
import module namespace max.i18n = 'pddn/max/i18n' at '../../rxq/i18n.xqm';

declare variable $max.plugin.ead_basket:PLUGIN_ID := "ead_basket";


declare function max.plugin.ead_basket:getResourceFilePath($projectId, $path){
    let $edition_path := max.util:maxHome() || "editions/" || $projectId || "/" || $path
    return
        if (file:exists($edition_path))
        then $edition_path
        else max.util:maxHome() || $path
};

declare function max.plugin.ead_basket:basketItemsForPDF($projectId, $items){
    let $dbPath := max.config:getProjectDBPath($projectId)
    let $items_list := fn:tokenize($items, ",")
    for $item in $items_list
    let $xmlDocName := fn:substring-before($item, "|")
    let $nodeId := fn:substring-after($item, "|")
    let $target := doc(concat($dbPath, '/', $xmlDocName))//*[@xml:id = $nodeId or @*:id = $nodeId][1]
    let $content := xslt:transform($target, max.plugin.ead_basket:getResourceFilePath($projectId, "ui/xsl/ead/item_porte-documents-print.html.xsl"))
    return $content
};

declare
%rest:GET
%rest:query-param("items", "{$items}")
%rest:path("/{$projectId}/ead/basket.pdf")
function max.plugin.ead_basket:basketpdf($projectId, $items){
	let $dbPath := max.config:getProjectDBPath($projectId)
    let $items_list := fn:tokenize($items, ",")
    let $routeDoc := fn:substring-before($items_list[1], '|')
    let $eadHeader := doc($dbPath || '/' || $routeDoc)//*:eadheader/node()
    let $frontmatter := doc($dbPath || '/' || $routeDoc)//*:frontmatter/node()
    let $content:=
        <ead xmlns="urn:isbn:1-931666-22-9">
            <eadheader>{$eadHeader}</eadheader>
            <frontmatter>{$frontmatter}</frontmatter>
            <archdesc>{
            	for $item in $items_list
            	let $nodeId := fn:substring-after($item, "|")
            	return max.api:getXMLByID($dbPath, $nodeId)
            }</archdesc>
        </ead>
    let $pdf := max.util:xml2pdf($content, max.util:getProjectFoXsl($projectId), $projectId,$projectId)

    return
        (<rest:response>
            <http:response status="200">
                <http:header name="content-type" value="application/pdf"/>
            </http:response>
        </rest:response>,
        $pdf)
};

declare
%rest:GET
%output:method("html")
%rest:path("/{$projectId}/ead/accueil.html")
function max.plugin.ead_basket:accueil($projectId){
    let $documents :=
        <ul>
            {
                for $doc in collection($projectId)
                return
                    <li>
                        <a href="{max.util:getRelativeRootPath($projectId)}/ead/{tokenize(base-uri($doc), '/')[last()]}/parcourir/accueil.html">
                            {$doc/*:ead/*:eadheader/*:filedesc/*:titlestmt/*:titleproper//text()}
                            –
                            {$doc/*:ead/*:eadheader/*:filedesc/*:titlestmt/*:author//text()}
                        </a>
                    </li>
            }
        </ul>
    return max.html:renderTemplate(doc(max.plugin.ead_basket:getResourceFilePath($projectId, "/plugins/ead/accueil.html")), map {"projectId" : $projectId, "documentsList" : $documents})
};

declare
%rest:GET
%output:method("html")
%rest:path("/{$projectId}/porte-documents.html")
function max.plugin.ead_basket:basket($projectId){
    max.html:render($projectId, "porte-documents", <section class="porte-documents">
    <h3>{max.i18n:getText($projectId,'basket.title')}</h3>
    <p>{max.i18n:getText($projectId,'basket.label1')}</p>
    <p>{max.i18n:getText($projectId,'basket.label2')}</p>
    <div id="porte-document-contenu">
    </div>
    <p>
        <button class="btnClearBasket">{max.i18n:getText($projectId,'basket.label3')}</button>
        <!--<button id="btnDlAllPDF">{max.i18n:getText($projectId,'basket.label4')}</button>-->
    </p>
</section>
    )
};

declare function max.plugin.ead_basket:itemPorteDocuments($projectId, $item){
    let $dbPath := max.config:getProjectDBPath($projectId)
    let $xmlDocName := fn:substring-before($item, "|")
    let $nodeId := fn:substring-after($item, "|")
    let $target := doc(concat($dbPath, '/', $xmlDocName))//*[@xml:id = $nodeId or @id = $nodeId]
    let $xsl := max.plugin.ead_basket:getResourceFilePath($projectId, "ui/xsl/ead/item_porte-documents.xsl")
    return xslt:transform($target[1],
            $xsl,
            map {
            "project" : $projectId,
            "docName" : $xmlDocName,
	        "baseuri" : max.util:getRelativeRootPath($projectId),
            "nodeId" : $nodeId})/*[1]
};


declare
%rest:path("/{$projectId}/ead/fetch_basket_data.html")
%output:method("html")
%rest:query-param("itemsList", "{$itemsListb64}")
%rest:GET
function max.plugin.ead_basket:basketData($projectId, $itemsListb64 as xs:base64Binary){
    let $itemsList := json:parse(convert:binary-to-string(xs:base64Binary($itemsListb64)))
    for $items in $itemsList/json/_
    group by $docName := fn:substring-before($items, "|")
    let $dbPath := max.config:getProjectDBPath($projectId)
    let $title := doc(concat($dbPath, '/', $docName))/*:ead/*:eadheader/*:filedesc/*:titlestmt/*:titleproper//text()
    let $result :=
    	<div class="porte-document-doc-group">
    		<h3>{$title}</h3>
    		{
    		for $item in $items
    		return max.plugin.ead_basket:itemPorteDocuments($projectId, $item)
    		}
    		<p>
    			<button class="btnMakePDF">{max.i18n:getText($projectId,'basket.label5')}</button>
    		</p>
    	</div>
    return $result
};