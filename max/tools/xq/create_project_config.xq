(: Create new project configuration file :)

declare variable $maxPath external;
declare variable $projectId external;
declare variable $dbPath external;
declare variable $envType external;

let $config :=
    if($envType = 'ead')
    then
        <edition xml:id="{$projectId}" dbpath="{$dbPath}" env="{$envType}" prettyName="My EAD edition">
            <textOptions>
            </textOptions>

            <plugins>
                <plugin name="side_toc"/>
            </plugins>
        </edition>
    else
        <edition xml:id="{$projectId}" dbpath="{$dbPath}" env="{$envType}" prettyName="My {$envType} edition">
            <textOptions>
            </textOptions>

            <plugins>
            </plugins>

        </edition>

return file:write($maxPath || '/editions/'||$projectId||'/'||$projectId||'_config_inc.xml', $config)
