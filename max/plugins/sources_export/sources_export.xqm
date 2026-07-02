xquery version "3.0";

module namespace max.plugin.sources_export = 'pddn/max/plugin/sources_export';
import module namespace max.config = 'pddn/max/config' at '../../rxq/config.xqm';


declare
%rest:GET
%output:media-type("application/octet-stream")
%rest:query-param("indent", "{$indent}", 'false')
%rest:path("/{$project}/{$archive}.zip")
function max.plugin.sources_export:export($project, $archive, $indent){
    if($project != $archive)
    then
        fn:error(xs:QName("err:sources_export"), "Archive does not exist :  '" || $archive||".zip'")
    else
        let $db := max.config:getProjectDBPath($project)
        let $zipName := $project||'.zip'
        let $tmpDir := file:create-temp-dir('max-export',$project)
        let $dest := $tmpDir ||'/'||$zipName
        return (
                db:export($db, $tmpDir, map { 'indent': if($indent='true') then true() else false()}),
                max.plugin.sources_export:makeZip($project,$tmpDir, $dest),
                (<rest:response>
                    <http:response status="200">
                        <http:header name="content-type" value="application/octet-stream"/>
                        <http:header name="Content-Disposition" value="attachment; filename={$zipName}"/>
                    </http:response>
                </rest:response>,
                file:read-binary($dest)
                ),
                file:delete($tmpDir,true())
            )

};

declare %private function max.plugin.sources_export:makeZip($project,$directory, $dest){
    let $files := file:list($directory, true(), '*.xml')
    let $zip   := archive:create($files,
            for $file in $files
            return file:read-binary($directory || $file)
    )
    return file:write-binary($dest, $zip)
};