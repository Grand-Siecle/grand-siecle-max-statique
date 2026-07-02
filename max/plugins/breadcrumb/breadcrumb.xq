xquery version "3.0";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace max.config = 'pddn/max/config' at '../../rxq/config.xqm';
import module namespace max.util = 'pddn/max/util' at '../../rxq/util.xqm';

declare variable $baseURI external;
declare variable $dbPath external;
declare variable $project external;
declare variable $doc external;
declare variable $id external;

(:declare variable $PLUGIN_ID := "breadcrumb";:)
(:declare variable $TOP_LABEL := "topLabel";:)

(:let $projectPrettyName := max.config:getPluginParameterValue($project, $PLUGIN_ID, $TOP_LABEL):)
let $title:= max.util:getDocTitle($dbPath, $doc, max.config:getXMLFormat($project))
let $docHtml:= replace($doc,'.xml','.html')
let $xsl := max.util:getDocumentTitleTOCXSL($project)
let $transformedTitle := xslt:transform($title,$xsl)

return
    <nav id="breadcrumb" aria-label="breadcrumb">
        <ol class="breadcrumb">
            <li class="breadcrumb-item">
                <a href = "{$baseURI || $project}/sommaire.html">Sommaire</a>
            </li>
            <li class="breadcrumb-item" aria-current="page">
                <a href = "{$baseURI  ||$project}/sommaire/{replace($doc,'.xml','.html')}">{$transformedTitle}</a>
            </li>
            {
                if($id)then <li class="breadcrumb-item" aria-current="page">{
                    xslt:transform(
                            collection($dbPath)//*[@xml:id = $id],
                            file:parent(static-base-uri()) || '_breadcrumb.xsl')
                }
                </li>
                else()
            }
        </ol>
    </nav>