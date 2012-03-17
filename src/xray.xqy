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
  let $ignore := fn:starts-with(utils:get-local-name($fn), "IGNORE")
  let $test := if ($ignore) then () else xray:apply($fn)
  return element test {
    attribute name { utils:get-local-name($fn) },
    attribute result { 
      if ($ignore) then "ignored"
      else if ($test/error:error or $test//descendant-or-self::assert[@result="failed"]) then "failed" 
      else "passed"
    },
    $test
  }
};


declare function xray:test-response(
  $assertion as xs:string, 
  $passed as xs:boolean, 
  $actual as item()*, 
  $expected as item()*
) as element(assert)
{
  element assert {
    attribute test { $assertion },
    attribute result { if ($passed) then "passed" else "failed" },
    element actual { $actual },
    element expected { $expected }
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
  try {
    xdmp:eval("
      declare variable $fn as xdmp:function external;
      declare option xdmp:update 'true';
      xdmp:apply($fn)",
      (fn:QName("","fn"), $function),
      <options xmlns="xdmp:eval"><isolation>different-transaction</isolation></options>
    )
  }
  catch($ex) { element exception { xray:error($ex)} }
};


declare private function xray:error(
  $ex as element(error:error)
) as element(error:error)
{
  $ex
};
