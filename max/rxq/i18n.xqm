(: For conditions of distribution and use, see the accompanying legal.txt file. :)

module namespace max.i18n = 'pddn/max/i18n';
import module namespace max.util = 'pddn/max/util' at 'util.xqm';
import module namespace max.config = 'pddn/max/config' at 'config.xqm';

declare
%rest:GET
%rest:path("/{$projectId}/setlang/{$lang}")
function max.i18n:setLang($projectId, $lang){
    session:set($projectId || '-lang', $lang)
};

declare function max.i18n:getLang($projectId){
    session:get($projectId || '-lang', max.config:getProjectDefaultLang($projectId))
};


declare function max.i18n:getText($projectId as xs:string, $key as xs:string){
    max.i18n:getText($projectId, $key, session:get($projectId || '-lang', max.config:getProjectDefaultLang($projectId)))
};

declare function max.i18n:getText($projectId as xs:string, $key as xs:string, $locale as xs:string ?)
{

    let $i18nResourceFile := max.util:maxHome() || "/ui/i18n/i18n-" || $locale || ".xml"
    let $projectI18nFile := max.util:maxHome() || "/editions/" || $projectId || "/ui/i18n/i18n-" || $locale || ".xml"
    return
        try {
            if (doc($projectI18nFile)//entry[@key = $key])
            then doc($projectI18nFile)//entry[@key = $key]/text()
            else if (doc($i18nResourceFile)//entry[@key = $key])
            then doc($i18nResourceFile)//entry[@key = $key]/text()
            else $key
        }
        catch * {
            if (doc($i18nResourceFile)//entry[@key = $key])
            then doc($i18nResourceFile)//entry[@key = $key]/text()
            else $key
        }
};

declare function max.i18n:getLanguageList($projectId){
    try {
        let $defaults := file:list(max.util:maxHome() || '/editions/' || $projectId || '/fragments')
        for $l in $defaults
        where $l != '.ignore'
        return fn:substring-before($l, '/')
    }
    catch * {'fr'}
};
