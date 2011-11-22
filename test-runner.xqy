xquery version '1.0-ml';

import module namespace xray='http://github.com/robwhitby/xray' at 'src/xray.xqy';
declare variable $dir as xs:string := xdmp:get-request-field('dir', '');
declare variable $modules as xs:string? := xdmp:get-request-field('modules');
declare variable $tests as xs:string? := xdmp:get-request-field('tests');
declare variable $format as xs:string := xdmp:get-request-field('format', 'xml');

let $dir := if (fn:string-length($dir) eq 0) then 'test' else $dir
return xray:run-tests($dir, $modules, $tests, $format)
