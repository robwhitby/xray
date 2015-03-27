xquery version "1.0-ml";

module namespace xray-json = "http://github.com/robwhitby/xray/json";
import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace xray = "http://github.com/robwhitby/xray";
declare namespace test = "http://github.com/robwhitby/xray/test";

declare variable $VERSION := xs:integer(
  substring-before(xdmp:version(), ".")) ;

declare function to-json(
  $node as node()
) as xs:string
{
  let $custom :=
    let $config := json:config("custom")
    return (
      map:put($config, "array-element-names", (
        "module", 
        "test", 
        "assert", 
        fn:QName("http://marklogic.com/xdmp/error", "frame"))),
      map:put($config, "element-namespace", "http://github.com/robwhitby/xray"),
      $config)
  let $json := json:transform-to-json($node, $custom)
  return
    if ($VERSION ge 8) then xdmp:quote($json)
    else $json
};

