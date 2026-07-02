(: For conditions of distribution and use, see the accompanying legal.txt file. :)

module namespace max.api = 'pddn/max/max_api';

import module namespace max.util = 'pddn/max/util' at 'util.xqm';

(:Returns XML fragment identified by $id:)
declare
%rest:GET
%output:method("html")
%rest:query-param("q", "{$q}")
%rest:path("/sf/{$db}/{$id}")
function max.api:getXMLByID($db, $id, $q){
  try{
      if($q)
        then
        let $q := '(collection("'||$db||'")//*[@xml:id="'||$id||'" or @id="'||$id||'"])[1]' || $q
          return xquery:eval($q)
        else (collection($db)//*[@xml:id=$id or @id=$id])[1]  
    }
    catch *{
      <div class='error'>{'Error [' || $err:code || '/' || $err:module || '/' || $err:line-number ||']: ' || $err:description}</div>
    }
};

(:Returns XML fragment in a specified document :)
declare
%rest:GET
%output:method("html")
%rest:path("/sf/{$routeDoc=.*\.xml|.*\.svg}/{$id}")
function max.api:getXMLByIDinDOC($routeDoc, $id){
  try{
        doc($routeDoc)//*[@xml:id=$id or @id=$id][1]  
    }
    catch *{
      <div class='error'>{'Error [' || $err:code || '/' || $err:module || '/' || $err:line-number ||']: ' || $err:description}</div>
    }
};

declare function max.api:getXMLByID($db, $id){
   max.api:getXMLByID($db, $id, ())
};

(:Returns XML fragment identified by $uniqueID:)
declare
%rest:GET
%rest:path("/sf/frag/{$uniqueID}")
function max.api:getFragment($uniqueID){
  let $dbAndFrag := tokenize($uniqueID,"::")
  return max.api:getXMLByID($dbAndFrag[1],$dbAndFrag[2],())
};



(:Returns XML fragment identified by $id in specified document:)
declare
%rest:GET
%output:method("html")
%rest:path("/sf/idindoc/{$doc=.*\.xml}/{$id}")
function max.api:getXMLByIDInDoc($doc, $id){

  let $target := doc($doc)//*[@xml:id=$id or @id=$id]
  return
  if(count($target) = 1)
    then $target
  else () (:todo: error:)
  
};






