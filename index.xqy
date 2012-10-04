xquery version "1.0-ml";

import module namespace xray="http://github.com/robwhitby/xray" at "src/xray.xqy";

(: where to look for tests :)
declare variable $dir as xs:string := xdmp:get-request-field("dir", "test");

(: module name matcher regex :)
declare variable $modules as xs:string? := xdmp:get-request-field("modules");

(: test name matcher regex :)
declare variable $tests as xs:string? := xdmp:get-request-field("tests");

(: output format html|text|xml|xunit :)
declare variable $format as xs:string := xdmp:get-request-field("format", "html");

(: library module paths for code coverage :)
declare variable $coverage-modules as xs:string* := distinct-values(
  if ($format = 'xunit') then ()
  else xdmp:get-request-field("coverage-module"));

xray:run-tests($dir, $modules, $tests, $format, $coverage-modules)

(: index.xqy :)
