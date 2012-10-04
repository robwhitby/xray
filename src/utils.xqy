xquery version "1.0-ml";

module namespace utils = "http://github.com/robwhitby/xray/utils";

declare namespace xray = "http://github.com/robwhitby/xray";
declare namespace test = "http://github.com/robwhitby/xray/test";
import module namespace cover = "http://github.com/robwhitby/xray/coverage"
  at "coverage.xqy";
import module namespace xqp = "http://github.com/jpcs/xqueryparser.xq" at "parsers/xqueryparser.xq";
import module namespace modules-fs = "http://github.com/robwhitby/xray/modules-fs" at "modules-filesystem.xqy";
import module namespace modules-db = "http://github.com/robwhitby/xray/modules-db" at "modules-database.xqy";

declare private variable $TEST-NS-URI := fn:namespace-uri-for-prefix("test", <test:x/>);
declare private variable $USE-MODULES-DB := (xdmp:modules-database() ne 0);


declare function get-modules(
  $test-dir as xs:string,
  $pattern as xs:string?
) as xs:string*
{
  if ($USE-MODULES-DB)
  then modules-db:get-modules($test-dir, $pattern)
  else modules-fs:get-modules($test-dir, $pattern)
};


declare function get-functions(
  $module-path as xs:string
) as xdmp:function*
{
  for $fn in parse-xquery($module-path)//FunctionDecl
  let $qname := fn:QName($fn/QName/@uri, $fn/QName/@localname)
  where $fn[fn:not(preceding-sibling::Annotation/TOKEN = "private")]
  return xdmp:function($qname, relative-path($module-path))
};


declare function relative-path(
  $path as xs:string
) as xs:string
{
  fn:substring($path, fn:string-length(xdmp:modules-root()))
};


declare function get-local-name(
  $fn as xdmp:function
) as xs:string
{
  fn:string(fn:local-name-from-QName(xdmp:function-name($fn)))
};


declare function transform(
  $el as element(),
  $test-dir as xs:string,
  $module-pattern as xs:string?,
  $test-pattern as xs:string?,
  $format as xs:string,
  $coverage-modules as xs:string*
) as document-node()
{
  if ($format eq "text") then xdmp:set-response-content-type("text/plain")
  else ()
  ,
  if ($format ne "xml")
  then
    let $params := map:map()
    let $_ := map:put($params, "coverage-modules", $coverage-modules)
    let $_ := map:put($params, "module-pattern", $module-pattern)
    let $_ := map:put($params, "test-dir", $test-dir)
    let $_ := map:put($params, "test-pattern", $test-pattern)
    return xdmp:xslt-invoke(
      fn:concat("output/", $format, ".xsl"),
      if (fn:empty($coverage-modules) or $format eq 'xunit') then $el
      else cover:transform($el),
      $params)
  else document {
    if (fn:empty($coverage-modules)) then $el
    else cover:transform($el) }
};


declare function query($fn as xdmp:function)
as xs:string
{
  text {
    'xquery version "1.0-ml";',
    'import module namespace t=',
    fn:concat('"', fn:namespace-uri-from-QName(xdmp:function-name($fn)), '"'),
    'at', fn:concat('"', xdmp:function-module($fn), '";'),
    fn:concat('t:', xdmp:function-name($fn), '()')
  }
};


declare private function parse-xquery(
  $module-path as xs:string
) as element(XQuery)?
{
  let $source as xs:string := get-module($module-path)
  where fn:contains($source, $TEST-NS-URI) (: preliminary check to speed things up a bit :)
  return
    let $parsed := xqp:parse($source)
    return
      if ($parsed/self::ERROR) then fn:error((), "XRAY-PARSE", ("Error parsing module", $parsed))
      else if ($TEST-NS-URI eq $parsed/Module/LibraryModule/ModuleDecl/URILiteral/@value)
      then $parsed
      else ()
};


declare function get-module(
  $module-path as xs:string,
  $is-absolute as xs:boolean
) as xs:string
{
  if ($USE-MODULES-DB) then modules-db:get-module(
    if ($is-absolute) then $module-path
    else modules-db:resolve-path($module-path))
  else modules-fs:get-module(
    if ($is-absolute) then $module-path
    else modules-fs:resolve-path($module-path))
};

declare function get-module(
  $module-path as xs:string
) as xs:string
{
  get-module($module-path, fn:true())
};

(: utils.xqy :)
