xquery version "1.0-ml";

module namespace xray = "http://github.com/robwhitby/xray";
declare namespace test = "http://github.com/robwhitby/xray/test";
import module namespace cover = "http://github.com/robwhitby/xray/coverage"
  at "coverage.xqy";
import module namespace utils = "http://github.com/robwhitby/xray/utils" at "utils.xqy";
declare default element namespace "http://github.com/robwhitby/xray";

declare function xray:run-tests(
  $test-dir as xs:string,
  $module-pattern as xs:string?,
  $test-pattern as xs:string?,
  $format as xs:string?,
  $coverage-modules as xs:string*
) as item()*
{
  utils:transform(
    element tests {
      attribute dir { $test-dir },
      attribute module-pattern { $module-pattern },
      attribute test-pattern { $test-pattern },
      for $module in utils:get-modules($test-dir, fn:string($module-pattern))
      let $all-fns :=
        try { utils:get-functions($module) }
        catch ($ex) { xray:error($ex) }
      let $error := if ($all-fns instance of element(error:error)) then $all-fns else ()
      let $test-fns := if ($error) then () else xray:test-functions($all-fns, $test-pattern)
      let $coverage := cover:prepare($coverage-modules, $test-fns)
      where fn:exists(($test-fns, $error))
      return
        element module {
          attribute path { utils:relative-path($module) },
          if (fn:exists($error)) then $error
          else (
            xray:apply($all-fns[utils:get-local-name(.) = "setup"]),
            for $fn in $test-fns return xray:run-test($fn, $coverage),
            xray:apply($all-fns[utils:get-local-name(.) = "teardown"])
          )
        }
    },
    $test-dir, $module-pattern, $test-pattern, $format,
    $coverage-modules)
};


declare function xray:run-tests(
  $test-dir as xs:string,
  $module-pattern as xs:string?,
  $test-pattern as xs:string?,
  $format as xs:string?
) as item()*
{
  xray:run-tests($test-dir, $module-pattern, $test-pattern, $format, ())
};


declare function xray:run-test(
  $fn as xdmp:function,
  $coverage as map:map?
) as element(test)
{
  let $start as xs:dayTimeDuration := xdmp:elapsed-time()
  let $ignore := fn:starts-with(utils:get-local-name($fn), "IGNORE")
  let $test := if ($ignore) then () else xray:apply($fn, $coverage)
  let $status :=
    if ($ignore) then "ignored"
    else if ($test instance of element(exception)
      or $test instance of element(error:error)
      or $test//descendant-or-self::assert[@result="failed"]) then "failed"
    else "passed"
  return element test {
    attribute name { utils:get-local-name($fn) },
    attribute result { $status },
    attribute time { xdmp:elapsed-time() - $start },
    if (fn:empty($coverage)) then $test
    else cover:results($coverage, $test, $status eq 'passed')
  }
};


declare function xray:test-response(
  $assertion as xs:string,
  $passed as xs:boolean,
  $actual as item()*,
  $expected as item()*,
  $message as xs:string?
) as element(xray:assert)
{
  element assert {
    attribute test { $assertion },
    attribute result { if ($passed) then "passed" else "failed" },
    element actual { $actual },
    element expected { $expected },
    element message { $message }
  }
};


declare private function xray:test-functions(
  $functions as xdmp:function*,
  $pattern as xs:string?
) as xdmp:function*
{
  for $fn in $functions
  let $name := utils:get-local-name($fn)
  where
    fn:matches($name, fn:string($pattern))
    and fn:not($name = ("setup", "teardown"))
  return $fn
};


declare private function xray:apply(
  $fn as xdmp:function,
  $coverage as map:map?
) as item()*
{
  (: The test tool itself should always run in timestamped mode. :)
  if (xdmp:request-timestamp()) then ()
  else fn:error((), 'UPDATE', 'Query must be read-only but contains updates!'),
  (: Since we already have xdmp:function items we could use xdmp:apply here.
   : But there is an inherent problem with xdmp:apply
   : https://github.com/robwhitby/xray/issues/9
   : It does not know if the function to be applied is an update or not.
   : We do not want all tests to run as updates,
   : because some queries check to see if they are run in timestamped mode.
   : So we build a query string from the function data, and eval it.
   :)
  try {
    if (fn:empty($coverage)) then xdmp:eval(utils:query($fn))
    else prof:eval(utils:query($fn))
  }
  catch ($ex) { element exception { xray:error($ex)} }
};

declare private function xray:apply(
  $fn as xdmp:function
) as item()*
{
  xray:apply($fn, ())
};

declare private function xray:error(
  $ex as element(error:error)
) as element(error:error)
{
  $ex
};
