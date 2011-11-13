xquery version '1.0-ml';

module namespace t = 'http://github.com/robwhitby/xqtest';
declare namespace test = 'http://github.com/robwhitby/xqtest/test';
import module namespace utils = 'http://github.com/robwhitby/xqtest/utils' at 'utils.xqy';
declare default element namespace 'http://github.com/robwhitby/xqtest';
declare option xdmp:update 'true';

declare function t:run-test($fn as xdmp:function) as element(test) 
{
  let $test :=
    try { t:apply($fn) }
    catch($ex) { element failed {t:error($ex)} }
  return element test {
    attribute name { utils:get-local-name($fn) },
    attribute result { if ($test//descendant-or-self::failed) then 'Failed' else 'Passed' },
    $test
  }
};


declare function t:run-tests($test-dir as xs:string, $module-pattern as xs:string?, $test-pattern as xs:string?, $format as xs:string?)
as item()
{
  let $tests := 
    element tests {
      for $module in utils:get-modules($test-dir, fn:string($module-pattern))
      let $fns := utils:get-functions($module, 'test')
      return
        element module {
          attribute path { utils:relative-path($module) },
          t:apply($fns[utils:get-local-name(.) = 'setup']),
          for $fn in $fns[fn:not(utils:get-local-name(.) = ('setup', 'teardown'))]
          where fn:matches(utils:get-local-name($fn), fn:string($test-pattern))
          return t:run-test($fn),
          t:apply($fns[utils:get-local-name(.) = 'teardown'])  
        }
    }
  return
    utils:transform($tests, $format)
};


declare function t:apply($function as xdmp:function)
{
  xdmp:eval("
    declare variable $fn as xdmp:function external; 
    declare option xdmp:update 'true';
    xdmp:apply($fn)",
    (fn:QName("","fn"), $function),
    <options xmlns="xdmp:eval"><isolation>different-transaction</isolation></options>
  )
};


declare function t:error($ex as element(error:error)) as element(error:error)
{
  $ex
};
