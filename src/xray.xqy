xquery version "1.0-ml";

module namespace xray = "http://github.com/robwhitby/xray";
declare namespace test = "http://github.com/robwhitby/xray/test";
import module namespace utils = "http://github.com/robwhitby/xray/utils" at "utils.xqy";
declare default element namespace "http://github.com/robwhitby/xray";


declare function xray:run-tests(
  $test-dir as xs:string,
  $module-pattern as xs:string?,
  $test-pattern as xs:string?,
  $format as xs:string?
) as item()*
{
  let $modules as xs:string* := utils:get-modules($test-dir, fn:string($module-pattern))
  let $tests :=
    element tests {
      attribute dir { $test-dir },
      attribute module-pattern { $module-pattern },
      attribute test-pattern { $test-pattern },
      for $module in $modules
      let $all-fns :=
        try { utils:get-functions($module) }
        catch ($ex) { xray:error($ex) }
      let $error := if ($all-fns instance of element(error:error)) then $all-fns else ()
      let $test-fns := if (fn:exists($error)) then () else xray:test-functions($all-fns, $test-pattern)
      where fn:exists(($test-fns, $error))
      return
        element module {
          attribute path { utils:relative-path($module) },
          if (fn:exists($error)) then $error
          else (
            xray:apply($all-fns[utils:get-local-name(.) = "setup"]),
            for $fn in $test-fns
            return xray:run-test($fn),
            xray:apply($all-fns[utils:get-local-name(.) = "teardown"])
          )
        }
    }
  return
    utils:transform($tests, $test-dir, $module-pattern, $test-pattern, $format)
};


declare function xray:run-test(
  $fn as xdmp:function
) as element(test)
{
  let $start as xs:dayTimeDuration := xdmp:elapsed-time()
  let $ignore := fn:starts-with(utils:get-local-name($fn), "IGNORE")
  let $test := if ($ignore) then () else xray:apply($fn)
  return element test {
    attribute name { utils:get-local-name($fn) },
    attribute result {
      if ($ignore) then "ignored"
      else if ($test instance of element(exception)
        or $test instance of element(error:error)
        or $test//descendant-or-self::assert[@result="failed"]) then "failed"
      else "passed"
    },
    attribute time { xdmp:elapsed-time() - $start },
    $test
  }
};


declare function xray:test-response(
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
  $function as xdmp:function
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
  try { xdmp:eval(utils:query($function)) }
  catch ($ex) { element exception { xray:error($ex)} }
};


declare private function xray:error(
  $ex as element(error:error)
) as element(error:error)
{
  $ex
};
