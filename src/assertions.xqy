xquery version '1.0-ml';

module namespace assert='http://github.com/robwhitby/xqtest/assertions';
import module namespace utils = 'http://github.com/robwhitby/xqtest/utils' at 'utils.xqy';
declare default element namespace 'http://github.com/robwhitby/xqtest';


declare function assert:equal($actual as item()*, $expected as item()*) as element()
{
  let $status := fn:deep-equal($actual, $expected)
  return utils:test-response('equal', $status, $actual, $expected)
};


declare function assert:not-equal($actual as item()*, $expected as item()*) as element()
{
  let $status := fn:not(fn:deep-equal($actual, $expected))
  return utils:test-response('not-equal', $status, $actual, $expected)
};


declare function assert:empty($actual as item()*)
{
  let $status := fn:empty($actual)
  return utils:test-response('empty', $status, $actual, '()')
};


declare function assert:exists($actual as item()*)
{
  let $status := fn:not(fn:empty($actual))
  return utils:test-response('not-empty', $status, $actual, 'item()+')
};


declare function assert:error($actual as item()*, $expected-error-name as xs:string)
{
  let $actual-error-name := 
    if ($actual instance of element(error:error)) then $actual/error:name/fn:string()
    else ()
  let $status := $actual-error-name = $expected-error-name
  return utils:test-response('error', $status, ($actual-error-name, $actual)[1], $expected-error-name)
};
