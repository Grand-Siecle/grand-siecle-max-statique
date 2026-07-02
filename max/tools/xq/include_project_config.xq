(: Include a project config file into the main one:)
declare namespace xi="http://www.w3.org/2001/XInclude";
declare variable $projectId external;
declare option db:xinclude 'false'; (:pour ne pas résoudre les inclusions:)
let $configFilePath := '../editions/'||$projectId||'/'||$projectId||'_config_inc.xml'
let $configNode := <xi:include href="{$configFilePath}"/>
return insert node $configNode into doc("../../configuration/configuration.xml")/configuration/editions
