(: For conditions of distribution and use, see the accompanying legal.txt file. :)

import module namespace max.config = 'pddn/max/config' at '../config.xqm';


declare variable $baseURI external;
declare variable $project external;
declare variable $doc external;


declare function local:buildEADDocumentTOC($projectId, $docPath){
    let $dbPath := concat(max.config:getProjectDBPath($projectId), "/", $docPath)
    let $target := doc($dbPath)

    return
        <nav id="{$target/*:ead//*:eadheader/*:eadid}">
            {
                for $c in $target/*:ead/*:archdesc/*:dsc
                return
                    <details id="details_{$c/ancestor::*:archdesc/@level}" level="archdesc" open="">
                        <summary>
                        <a href="{$baseURI}{$projectId}/{$docPath}/{$c/ancestor::*:archdesc/@id}.html">
                            {$c/ancestor::*:archdesc/*:did/node()}
                            {$c/*:did/node()}
                            </a>
                        </summary>
                        {local:childrenToc($c, $projectId, $docPath)}
                    </details>
            }
        </nav>
};

declare function local:childrenToc($component, $projectId, $docPath){
    for $c in $component/child::*:c
    return
       if($c/*:c)
        then
        <details  id="details_{$c/@id}" otherlevel="{$c/@otherlevel}">
            <summary>
                <a href="{$baseURI}{$projectId}/{$docPath}/{$c/@id}.html">
                    {$c/@id}
                    {$c/*:did/node()}
                </a>
            </summary>
            {local:childrenToc($c, $projectId, $docPath)}
        </details>
        (: else local:childrenToc($c, $projectId, $docPath) :)
         else (
          <div class="detail" id="details_{$c/@id}">
          <a href="{$baseURI}{$projectId}/{$docPath}/{$c/@id}.html">
                    {$c/*:did/node()}
                </a>
              </div>)
};

local:buildEADDocumentTOC($project, $doc)
