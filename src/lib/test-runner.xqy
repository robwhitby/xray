xquery version '1.0-ml';

import module namespace xqtest='http://xqueryhacker.com/xqtest' at 'xqtest.xqy';
declare variable $dir as xs:string := xdmp:get-request-field('dir', 'test');
declare variable $modules as xs:string? := xdmp:get-request-field('modules');
declare variable $tests as xs:string? := xdmp:get-request-field('tests');
declare variable $format as xs:string := xdmp:get-request-field('format', 'xml');

declare option xdmp:update 'false';

xqtest:run-tests($dir, $modules, $tests, $format)
