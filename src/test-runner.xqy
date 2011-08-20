xquery version '1.0-ml';

import module namespace xqtest='http://xqueryhacker.com/xqtest' at 'lib/xqtest.xqy';
declare variable $test-dir as xs:string := xdmp:get-request-field('testdir', fn:substring(fn:replace(xdmp:get-request-path(), 'test-runner.xqy', 'tests'), 2));
declare variable $modules as xs:string? := xdmp:get-request-field('modules');
declare variable $tests as xs:string? := xdmp:get-request-field('tests');
declare variable $format as xs:string := xdmp:get-request-field('format', 'xml');

declare option xdmp:update 'false';

xqtest:run-tests($test-dir, $modules, $tests, $format)
