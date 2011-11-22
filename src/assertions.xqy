xquery version '1.0-ml';

module namespace assert='http://github.com/robwhitby/xray/assertions';
import module namespace xray = 'http://github.com/robwhitby/xray' at 'xray.xqy';


declare function assert:equal($actual as item()*, $expected as item()*) as element()
{
  let $status := fn:deep-equal($actual, $expected)
  return xray:test-response('equal', $status, $actual, $expected)
};


declare function assert:not-equal($actual as item()*, $expected as item()*) as element()
{
  let $status := fn:not(fn:deep-equal($actual, $expected))
  return xray:test-response('not-equal', $status, $actual, $expected)
};


declare function assert:empty($actual as item()*)
{
  let $status := fn:empty($actual)
  return xray:test-response('empty', $status, $actual, 'empty-sequence()')
};


declare function assert:not-empty($actual as item()*)
{
  let $status := fn:not(fn:empty($actual))
  return xray:test-response('not-empty', $status, $actual, 'item()+')
};


declare function assert:error($actual as item()*, $expected-error-name as xs:string)
{
  let $actual-error-name := 
    if ($actual instance of element(error:error)) then $actual/error:name/fn:string()
    else ()
  let $status := $actual-error-name = $expected-error-name
  return xray:test-response('error', $status, ($actual-error-name, $actual)[1], $expected-error-name)
};
