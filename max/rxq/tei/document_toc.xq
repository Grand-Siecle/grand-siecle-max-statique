(: For conditions of distribution and use, see the accompanying legal.txt file. :)

xquery version "3.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
import module namespace max.config = 'pddn/max/config' at '../config.xqm';
import module namespace max.util = 'pddn/max/util' at '../util.xqm';
import module namespace max.alignment = 'pddn/max/alignment' at '../alignment.xqm';

declare variable $baseURI external;
declare variable $project external;
declare variable $doc external;

declare function local:buildTEIDocumentTOC($project, $docPath){
    let $dbPath := max.config:getProjectDBPath($project)
    let $doc := doc(concat($dbPath, '/', $docPath))
    return
        <ul>
            {
                for $chapter in $doc//body/div[@type and @xml:id] where $chapter/head
                let $title := $chapter/head
                let $idPointer := $chapter/@xml:id

                let $href:= if(max.config:isAlignedRoute($docPath))
                then max.alignment:buildFragmentLinkFromID(max.util:getRelativeRootPath(()), $project, $docPath, $idPointer)
                else concat(max.util:getRelativeRootPath($project), $docPath, '/', $idPointer)

                return
                    <li id="{$idPointer}" data-href='{$href}'>
                        {$title}
                        {local:subTOC($chapter, $project, $docPath)}
                    </li>
            }
        </ul>
};

declare %private function local:subTOC($chapter, $project, $docPath){
    let $subChapters := $chapter/div[@*:id]
    return
        if (count($subChapters) > 0)
        then
            <ul>{
                for $subChapter in $chapter/div[@*:id] where $chapter/head
                return
                    let $title := $subChapter/head
                    let $idPointer := $subChapter/@xml:id
                    return
                        <li id="{$idPointer}" data-href="{concat(max.util:getRelativeRootPath($project), $docPath, '/', $idPointer)}">
                            {$title}
                            {local:subTOC($subChapter, $project, $docPath)}
                        </li>
            }
            </ul>
        else ()
};

local:buildTEIDocumentTOC($project, $doc)