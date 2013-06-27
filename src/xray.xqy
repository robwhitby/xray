xquery version "1.0-ml";

module namespace xray = "http://github.com/robwhitby/xray";

declare namespace test = "http://github.com/robwhitby/xray/test";
import module namespace modules = "http://github.com/robwhitby/xray/modules" at "modules.xqy";
import module namespace cover = "http://github.com/robwhitby/xray/coverage" at "coverage.xqy";

declare default element namespace "http://github.com/robwhitby/xray";

declare private variable $XRAY-VERSION := "2.1";
declare private variable $VALID-ANNOTATIONS := ("case", "ignore", "setup", "teardown");
declare private variable $PASSED := "passed";
declare private variable $IGNORED := "ignored";
declare private variable $FAILED := "failed";
declare private variable $ERROR := "error";

declare function run-tests(
  $test-dir as xs:string,
  $module-pattern as xs:string?,
  $test-pattern as xs:string?,
  $format as xs:string?,
  $coverage-modules as xs:string*
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
      let $results := run-module($module, $test-pattern, $coverage-modules)
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
            attribute passed { fn:count($results[@result = $PASSED]) },
            attribute ignored { fn:count($results[@result = $IGNORED]) },
            attribute failed { fn:count($results[@result = $FAILED]) },
            attribute error { fn:count($results[@result = $ERROR]) },
            $results
          )
        }
    }
  return
    xray:transform($tests, $test-dir, $module-pattern, $test-pattern, $format, $coverage-modules)
};


declare function run-test(
  $fn as xdmp:function,
  $path as xs:string,
  $coverage as map:map?
) as element(test)
{
  let $start-time as xs:dayTimeDuration := xdmp:elapsed-time()
  let $ignore := has-test-annotation($fn, "ignore")
  let $test := if ($ignore) then () else xray:apply($fn, $path, $coverage)
  let $status := if ($ignore) then $IGNORED else get-status($test)
  return element test {
    attribute name { fn-local-name($fn) },
    attribute result { $status },
    attribute time { xdmp:elapsed-time() - $start-time },
    if (fn:empty($coverage)) then $test
    else cover:results($coverage, $test, $status eq $PASSED)
  }
};


declare private function get-status(
  $test as element()*
) as xs:string
{
  if ($test instance of element(exception) or $test instance of element(error:error)) then $ERROR
  else if ($test//descendant-or-self::assert[@result = $FAILED]) then $FAILED
  else $PASSED
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
    attribute result { if ($passed) then $PASSED else $FAILED },
    element actual { $actual },
    element expected { $expected },
    element message { $message }
  }
};


declare private function apply(
  $fn as xdmp:function,
  $path as xs:string,
  $coverage as map:map?
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
    let $q := '
      xquery version "1.0-ml";
      import module namespace test = "http://github.com/robwhitby/xray/test" at "' || $path || '";
      test:' || fn-local-name($fn) || '()
    '
    return
      if (fn:empty($coverage)) then xdmp:eval($q)
      else prof:eval($q) 
  }
  catch * { $err:additional }
};


declare function run-module(
  $path as xs:string,
  $test-pattern as xs:string?,
  $coverage-modules as xs:string*
) as element()*
{
  try {
    xdmp:eval('
      xquery version "1.0-ml";
      import module namespace xray = "http://github.com/robwhitby/xray" at "/xray/src/xray.xqy";
      import module namespace test = "http://github.com/robwhitby/xray/test" at "' || $path || '";
      declare variable $xray:path as xs:string external;
      declare variable $xray:test-pattern as xs:string external;
      declare variable $xray:coverage-modules as element() external;

      xray:run-module-tests($xray:path, $xray:test-pattern, $xray:coverage-modules/xray:m/fn:string())
      ',
      (
        xs:QName("path"), $path,
        xs:QName("test-pattern"), fn:string($test-pattern),
        xs:QName("coverage-modules"), <c>{$coverage-modules ! <m>{.}</m>}</c>
      )
    )
  }
  catch($ex) {
    switch ($ex/error:code)
      case "XDMP-IMPMODNS" return () (: ignore - module not in test namespace :)
      case "XDMP-IMPORTMOD" return () (: ignore - main module :)
      default return $ex (: return all other errors :)
  }
};


declare function run-module-tests(
  $path as xs:string,
  $test-pattern as xs:string,
  $coverage-modules as xs:string*
) as element()*
{
  let $fns :=
    for $f in xdmp:functions()
    let $name := fn-local-name($f)
    where has-test-annotation($f) and fn:matches($name, $test-pattern)
    order by $name
    return $f
  let $coverage := cover:prepare($coverage-modules, $fns, $path)
  return (
    apply($fns[has-test-annotation(., "setup")], $path, $coverage),
    run-test($fns[has-test-annotation(., "case") or has-test-annotation(., "ignore")], $path, $coverage),
    apply($fns[has-test-annotation(., "teardown")], $path, $coverage)
  )
};

declare function has-test-annotation(
  $fn as xdmp:function,
  $name as xs:string
) as xs:boolean
{
  fn:exists(xdmp:annotation($fn, xs:QName("test:" || $name)))
};

declare function has-test-annotation(
  $fn as xdmp:function
) as xs:boolean
{
  has-test-annotation($fn, $VALID-ANNOTATIONS) = fn:true()
};


declare private function fn-local-name(
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
  if ($format eq "text") then xdmp:set-response-content-type("text/plain") else (),

  let $params := map:map()
  let $_ := map:put($params, "coverage-modules", $coverage-modules)
  let $_ := map:put($params, "module-pattern", $module-pattern)
  let $_ := map:put($params, "test-dir", $test-dir)
  let $_ := map:put($params, "test-pattern", $test-pattern)
  return
    xdmp:xslt-invoke(
      fn:concat("output/", $format, ".xsl"),
      if (fn:empty($coverage-modules) or fn:empty($el//xray:test) or $format eq "xunit") then $el else cover:transform($el),
      $params
    )
};