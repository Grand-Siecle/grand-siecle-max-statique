(: Insert plugin's config section for a specific project :)

declare variable $projectId external;
declare variable $pluginId external;

let $configDoc := doc('../../editions/'||$projectId||'/'||$projectId||"_config_inc.xml")
let $plugins := $configDoc/edition/plugins

return
    if($plugins/plugin[@name=$pluginId])
    then () (:plugin already enabled:)
    else
        let $pluginNode := <plugin name="{$pluginId}"/>
        return insert node $pluginNode into $plugins
