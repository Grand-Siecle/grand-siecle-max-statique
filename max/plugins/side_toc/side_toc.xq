import module namespace max.toc = "pddn/max/toc" at '../../rxq/toc.xqm';

declare variable $baseURI external;
declare variable $dbPath external;
declare variable $project external;
declare variable $doc external;
declare variable $id external;

let $toc := max.toc:getDocumentTOC($project, $doc)
let $input := <input type="hidden" name="currentTocItem" value="{$project}/{$doc}/{$id}"></input>
return <div class='side-toc'>{$toc}{$input}</div>

(:<input type="hidden" name="currentEADItem" value="{$projectId}/{$docPath}/{$nodeId}"></input>:)
(:<div class='side-toc'>{max.toc:getDocumentTOC($project, $doc)}</div>:)