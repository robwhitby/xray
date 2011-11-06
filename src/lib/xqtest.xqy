xquery version '1.0-ml';

module namespace t = 'http://xqueryhacker.com/xqtest';
declare namespace test = 'http://xqueryhacker.com/xqtest/test';
import module namespace utils = 'http://xqueryhacker.com/xqtest/utils' at 'utils.xqy';
declare default element namespace 'http://xqueryhacker.com/xqtest';


declare function t:run-test($fn as xdmp:function) as element(test) {
  let $test :=
    try { xdmp:apply($fn) }
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
      return
        element module {
          attribute path { utils:relative-path($module) },
          for $fn in utils:get-functions($module, 'test')
          where fn:matches(utils:get-local-name($fn), fn:string($test-pattern))
          return t:run-test($fn)
        }
    }
  return
    if ($format = ('text', 'html')) then utils:transform($tests, $format)
    else $tests
};


declare function t:run-tests($test-dir as xs:string) as element(tests)
{
  t:run-tests($test-dir, (), (), ())
};


declare function t:run-tests() as element(tests)
{
  t:run-tests('tests')
};


declare function t:error($ex as element(error:error)) as element(error:error)
{
  $ex
};
