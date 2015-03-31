xquery version "1.0-ml";

module namespace xray = "http://github.com/robwhitby/xray";
declare namespace test = "http://github.com/robwhitby/xray/test";
import module namespace modules = "http://github.com/robwhitby/xray/modules" at "modules.xqy";
declare default element namespace "http://github.com/robwhitby/xray";

declare variable $XRAY-VERSION := "2.0";
declare variable $ROOT := fn:substring-before(xdmp:get-request-path(), "/xray/");

declare function run-tests(
  $test-dir as xs:string,
  $module-pattern as xs:string?,
  $test-pattern as xs:string?,
  $format as xs:string?
) as item()*
{
  let $modules as xs:string* := modules:get-modules($test-dir, fn:string($module-pattern))
  let $tests :=
    element tests {
      attribute dir { $test-dir },
      attribute module-pattern { $module-pattern },
      attribute test-pattern { $test-pattern },
      attribute xray-version { $XRAY-VERSION },
      for $module in $modules
      let $results := run-module($module, $test-pattern)
      where fn:exists($results)
      return
        element module {
          attribute path { $module },
          if ($results instance of element(error:error)) then (
            attribute total { 0 },
            attribute passed { 0 },
            attribute ignored { 0 },
            attribute failed { 0 },
            attribute error { 1 },
            $results
          )
          else (
            attribute total { fn:count($results) },
            attribute passed { fn:count($results[@result="passed"]) },
            attribute ignored { fn:count($results[@result="ignored"]) },
            attribute failed { fn:count($results[@result="failed"]) },
            attribute error { fn:count($results[@result="error"]) },
            $results
          )
        }
    }
  return
    xray:transform($tests, $test-dir, $module-pattern, $test-pattern, $format)
};


declare function run-test(
  $fn as function(*),
  $path as xs:string
) as element(test)
{
  let $ignore := has-test-annotation($fn, "ignore")
  let $map := if ($ignore) then () else xray:apply($fn, $path)
  let $test := map:get($map, "results")
  let $time := map:get($map, "time")
  return element test {
    attribute name { fn-local-name($fn) },
    attribute result {
      if ($ignore) then "ignored"
      else if ($test instance of element(exception) or $test instance of element(error:error)) then "error"
      else if ($test//descendant-or-self::assert[@result="failed"]) then "failed"
      else "passed"
    },
    attribute time { ($time, "PT0S")[1] },
    $test
  }
};


declare function assert-response(
  $assertion as xs:string,
  $passed as xs:boolean,
  $actual as item()*,
  $expected as item()*,
  $message as xs:string?
) as element(assert)
{
  element assert {
    attribute test { $assertion },
    attribute result { if ($passed) then "passed" else "failed" },
    element actual { $actual },
    element expected { $expected },
    element message { $message }
  }
};


declare private function apply(
  $fn as function(*),
  $path as xs:string
) as item()*
{
  (: The test tool itself should always run in timestamped mode. :)
  if (xdmp:request-timestamp()) then ()
  else fn:error((), "UPDATE", "Query must be read-only but contains updates"),
  (: Since we already have a function item we could use $fn() here.
   : But there is an inherent problem with xdmp:apply
   : https://github.com/robwhitby/xray/issues/9
   : It does not know if the function to be applied is an update or not.
   : We do not want all tests to run as updates,
   : because some queries check to see if they are run in timestamped mode.
   : So we build a query string from the function data, and eval it.
   :)
  try {
    xdmp:eval('
      xquery version "1.0-ml";
      import module namespace test = "http://github.com/robwhitby/xray/test" at "' || $path || '";

      let $start := xdmp:elapsed-time()
      let $results := try { test:' || fn-local-name($fn) || '() } catch($err) { $err }
      let $duration := xdmp:elapsed-time() - $start
      let $map := map:map()
      let $_ := (
        map:put($map, "results", $results),
        map:put($map, "time", $duration)
      )
      return $map
    ')
  }
  catch * { $err:additional }
};


declare function run-module(
  $path as xs:string,
  $test-pattern as xs:string?
) as element()*
{
  try {
    xdmp:eval('
      xquery version "1.0-ml";
      import module namespace xray = "http://github.com/robwhitby/xray" at "' || $ROOT || '/xray/src/xray.xqy";
      import module namespace test = "http://github.com/robwhitby/xray/test" at "' || $path || '";
      declare variable $xray:path as xs:string external;
      declare variable $xray:test-pattern as xs:string external;
      xray:run-module-tests($xray:path, $xray:test-pattern)
    ',
    (xs:QName("path"), $path, xs:QName("test-pattern"), fn:string($test-pattern))
    )
  }
  catch($ex) {
    (: https://github.com/spig/xray/commit/3bf0e7facaa5260f19556bf431469d967d00c3c1 :)
    switch ($ex/error:code)
      case "XDMP-IMPMODNS"
        return
          if ($ex/error:data/error:datum/fn:contains(., $path)) then
            () (: ignore - module not in test namespace :)
          else $ex (: must be an error in an import of the $path module :)
      case "XDMP-IMPORTMOD"
        return
          if ($ex/error:data/error:datum/fn:contains(., $path)) then
            () (: ignore - main module if path of current module :)
          else $ex (: must be an error in an import of the $path module :)
      default return $ex
  }
};


declare function run-module-tests(
  $path as xs:string,
  $test-pattern as xs:string
) as element()*
{
  let $fns :=
    for $f in xdmp:functions()
    let $name := fn-local-name($f)
    where
      has-test-annotation($f, ("setup", "teardown")) or
      has-test-annotation($f, ("case", "ignore")) and fn:matches($name, $test-pattern)
    order by $name
    return $f
  return (
    map:get(apply($fns[has-test-annotation(., "setup")], $path), "results"),
    run-test($fns[has-test-annotation(., "case") or has-test-annotation(., "ignore")], $path),
    map:get(apply($fns[has-test-annotation(., "teardown")], $path), "results")
  )
};

declare function has-test-annotation(
  $fn as function(*),
  $name as xs:string
) as xs:boolean
{
  fn:exists(xdmp:annotation($fn, xs:QName("test:" || $name)))
};


declare private function fn-local-name(
  $fn as function(*)
) as xs:string
{
  fn:string(fn:local-name-from-QName(xdmp:function-name($fn)))
};


declare private function transform(
  $el as element(),
  $test-dir as xs:string,
  $module-pattern as xs:string?,
  $test-pattern as xs:string?,
  $format as xs:string
) as document-node()
{
  if ($format eq "text") then xdmp:set-response-content-type("text/plain") else (),
  if ($format eq "json") then xdmp:set-response-content-type("application/json") else (),
  if ($format ne "xml")
  then
    let $params := map:map()
    let $_ := map:put($params, "test-dir", $test-dir)
    let $_ := map:put($params, "module-pattern", $module-pattern)
    let $_ := map:put($params, "test-pattern", $test-pattern)
    return xdmp:xslt-invoke(fn:concat("output/", $format, ".xsl"), $el, $params)
  else document { $el }
};
