(: Check if a project is already declared in the main configuration file:)
declare variable $maxPath external;
declare variable $projectId external;

let $config:= doc($maxPath||'/configuration/configuration.xml')
return
    if($config//edition[@xml:id=$projectId])
    then 0
    else -1
