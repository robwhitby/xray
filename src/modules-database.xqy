xquery version "1.0-ml";

module namespace modules-db = "http://github.com/robwhitby/xray/modules-db";

declare variable $ROOT := xdmp:modules-root();

declare private variable $eval-options :=
  <options xmlns="xdmp:eval">
    <database>{xdmp:modules-database()}</database>
  </options>;


declare private function append-path(
  $path as xs:string,
  $step as xs:string
) as xs:string
{
  fn:concat(
    $path, if (fn:ends-with($path, '/')) then '' else '/',
    if (fn:starts-with($step, '/')) then fn:substring-after($step, '/')
    else $step)
};


declare function resolve-path(
  $path as xs:string
) as xs:string
{
  append-path($ROOT, $path)
};


declare function get-modules(
  $test-dir as xs:string,
  $pattern as xs:string?
) as xs:string*
{
  xdmp:eval('
    xquery version "1.0-ml";
    declare variable $test-dir as xs:string external;
    declare variable $pattern as xs:string external;
    declare variable $modules-root as xs:string external;

    let $uri-prefix := fn:concat($modules-root, fn:replace($test-dir, "^[/\\]+", ""))
    for $doc in fn:collection()
    let $uri := xdmp:node-uri($doc)
    where
      fn:starts-with($uri, $uri-prefix)
      and fn:matches($uri, "\.xqy?$")
      and fn:matches(fn:substring-after($uri, $modules-root), fn:string($pattern))
    return $uri
  ',
  (
    xs:QName("test-dir"), $test-dir,
    xs:QName("pattern"), $pattern,
    xs:QName("modules-root"), $ROOT
  ),
  $eval-options)
};


declare function get-module(
  $module-path as xs:string
) as xs:string
{
  xdmp:eval('
    xquery version "1.0-ml";
    declare variable $uri as xs:string external;
    fn:doc($uri)
  ',
  (xs:QName("uri"), $module-path),
  $eval-options)
};
