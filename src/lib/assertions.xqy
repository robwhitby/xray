xquery version '1.0-ml';

module namespace assert='http://xqueryhacker.com/xqtest/assertions';
import module namespace utils = 'http://xqueryhacker.com/xqtest/utils' at 'utils.xqy';
declare default element namespace 'http://xqueryhacker.com/xqtest';


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

