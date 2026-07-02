(: For conditions of distribution and use, see the accompanying legal.txt file. :)

module namespace max.plugin.mirador = 'pddn/max/plugin/mirador';
import module namespace max.util = 'pddn/max/util' at '../../rxq/util.xqm';

declare variable $max.plugin.mirador:PLUGIN_ID := "mirador_viewer";

(:
returns html page with mirador loaded
:)

declare
%rest:GET
%output:method("html")
%rest:query-param("link", "{$link}")
%rest:query-param("canvasId", "{$canvasId}")
%rest:query-param("canvasIndex", "{$canvasIndex}")
%rest:path("/{$project}/mirador")
function max.plugin.mirador:loadViewer($project, $link, $canvasId, $canvasIndex){
let $libJs := max.util:getRelativeRootPath($project)|| 'plugins/mirador_viewer/max-mirador/MaxMirador.js'
let $options := map{ 'id':'mirador-viewer','windows': [map{'loadedManifest': $link,'canvasIndex': $canvasIndex, 'canvasId': $canvasId}]}
let $htmlPage := <html>
  <head>
    <script type='text/javascript' src='{$libJs}'></script>
  </head>
  <pre>
  </pre>
  <body onload='MaxMirador.open({json:serialize($options)})'>
    <div id='mirador-viewer'/>
  </body>
</html>
return $htmlPage
  };