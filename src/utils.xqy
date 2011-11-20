xquery version '1.0-ml';

module namespace utils = 'http://github.com/robwhitby/xqtest/utils';
declare namespace t = 'http://github.com/robwhitby/xqtest';
declare namespace test = 'http://github.com/robwhitby/xqtest/test';
import module namespace parser = 'XQueryML10' at 'parsers/XQueryML10.xq';


declare function utils:get-filelist($dir as xs:string) as xs:string*
{
  for $entry in xdmp:filesystem-directory($dir)/dir:entry
  order by $entry/dir:type descending, $entry/dir:filename ascending
  return
    if ($entry/dir:type = 'file') then $entry/dir:pathname/fn:string()
    else utils:get-filelist($entry/dir:pathname/fn:string())
};


declare function utils:get-functions($module-path as xs:string) as xdmp:function*
{
  let $parsed := utils:parse-xquery($module-path)
  return 
    for $fn in $parsed//FunctionDecl
    where $fn[fn:not(TOKEN = 'private')]
    return xdmp:function(xs:QName($fn/FunctionName/QName), fn:replace($module-path, xdmp:modules-root(), '/'))
};


declare function utils:get-modules($test-dir as xs:string, $pattern as xs:string?) as xs:string*
{
  for $filepath in utils:get-filelist(fn:concat(xdmp:modules-root(), $test-dir))
  where fn:matches(utils:relative-path($filepath), $pattern)
  return $filepath
};


declare function utils:relative-path($path as xs:string) as xs:string
{
  fn:replace($path, xdmp:modules-root(), '/')
};


declare function utils:get-local-name($fn as xdmp:function) as xs:string
{
  fn:string(fn:local-name-from-QName(xdmp:function-name($fn)))
};


declare function utils:test-response($assertion as xs:string, $status as xs:boolean, $actual as item()?, $expected as item()?)
as element()
{
  element { if ($status) then 't:passed' else 't:failed' } {
    attribute assertion { $assertion },
    element t:actual { ($actual, '()')[1] },
    element t:expected { $expected }
  }
};


declare function utils:transform($el as element(), $format as xs:string) as item()
{
  if ($format eq 'text') then xdmp:set-response-content-type('text/plain') else ()
  ,
  if ($format = ('html', 'text'))
  then xdmp:xslt-invoke(fn:concat('xsl/', $format, '.xsl'), $el)
  else $el
};


declare function utils:parse-xquery($module-path as xs:string) as element(XQuery)
{
  let $source := fn:string(xdmp:filesystem-file($module-path))
  return parser:parse-XQuery($source)
};

