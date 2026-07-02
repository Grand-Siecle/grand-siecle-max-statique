(: Remove plugin's config section for a specific project :)

declare variable $projectId external;
declare variable $pluginId external;

let $configDoc := doc('../../editions/'||$projectId||'/'||$projectId||"_config_inc.xml")
let $pluginNode := $configDoc/edition/plugins/plugin[@name=$pluginId]

return
    if($pluginNode)
    then  delete node $pluginNode
    else ()
