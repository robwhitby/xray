xquery version "1.0-ml";

module namespace modules-db = "http://github.com/robwhitby/xray/modules-db";

declare private variable $eval-options :=
  <options xmlns="xdmp:eval">
    <database>{xdmp:modules-database()}</database>
  </options>;


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

    try {
      let $uri-prefix := fn:concat($modules-root, fn:replace($test-dir, "^[/\\]+", ""), "*")
      for $uri in cts:uri-match($uri-prefix)
      where
        fn:matches($uri, "\.xq[my]?$")
        and (fn:ends-with($uri, $pattern) or fn:matches(fn:substring-after($uri, $modules-root), fn:string($pattern)))
      return $uri
    }
    catch($ex) {
      let $uri-prefix := fn:concat($modules-root, fn:replace($test-dir, "^[/\\]+", ""))
      for $doc in fn:collection()
      let $uri := xdmp:node-uri($doc)
      where
        fn:starts-with($uri, $uri-prefix)
        and fn:matches($uri, "\.xq[my]?$")
        and (fn:ends-with($uri, $pattern) or fn:matches(fn:substring-after($uri, $modules-root), fn:string($pattern)))
      return $uri
    }
  ',
  (
    xs:QName("test-dir"), $test-dir,
    xs:QName("pattern"), $pattern,
    xs:QName("modules-root"), xdmp:modules-root()
  ),
  $eval-options)
};
