xquery version "1.0-ml";

import module namespace cover="http://github.com/robwhitby/xray/coverage"
  at "src/coverage.xqy";
import module namespace xray="http://github.com/robwhitby/xray"
  at "src/xray.xqy";

(: library module path :)
declare variable $module as xs:string := xdmp:get-request-field(
  "module") ;

(: output format html|text|xml :)
declare variable $format as xs:string := xdmp:get-request-field(
  "format", "html") ;

(: wanted lines :)
declare variable $wanted as xs:integer* := xs:integer(
  xs:NMTOKENS(xdmp:get-request-field("wanted"))) ;

(: covered lines :)
declare variable $covered as xs:integer* := xs:integer(
  xs:NMTOKENS(xdmp:get-request-field("covered"))) ;

(: Set the content-type here,
 : so we can test xray:transform with any format.
 :)
if ($format eq "text") then xdmp:set-response-content-type("text/plain")
else (),

cover:module-view($module, $format, $wanted, $covered)

