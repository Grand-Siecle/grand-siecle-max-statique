(: For conditions of distribution and use, see the accompanying legal.txt file. :)

module namespace max.plugins.ead2pdf = 'pddn/max/plugins/ead2pdf.xqm';

import module namespace max.config = 'pddn/max/config' at '../../rxq/config.xqm';
import module namespace max.api = 'pddn/max/max_api' at '../../rxq/max_api.xqm';
import module namespace max.util = 'pddn/max/util' at '../../rxq/util.xqm';


declare
%rest:GET
%rest:produces("application/pdf")
%rest:path("/{$project}/{$routeDoc=.*\.xml}/ead/{$id}.pdf")
function max.plugins.ead2pdf:fragmentToPDF($project, $routeDoc, $id){
    let $dbPath := max.config:getProjectDBPath($project)
    let $eadHeader := doc($dbPath || '/' || $routeDoc)//*:eadheader/node()
    let $frontmatter := doc($dbPath || '/' || $routeDoc)//*:frontmatter/node()
    let $content:=
        <ead xmlns="urn:isbn:1-931666-22-9">
            <eadheader>{$eadHeader}</eadheader>
            <frontmatter>{$frontmatter}</frontmatter>
            <archdesc>{max.api:getXMLByID($dbPath, $id)}</archdesc>
        </ead>
    (: return $content :)
    let $pdf := max.util:xml2pdf($content, max.util:getProjectFoXsl($project), $project,$id)
    return
        (<rest:response>
            <http:response status="200">
                <http:header name="content-type" value="application/pdf"/>
            </http:response>
        </rest:response>,
        $pdf)
};