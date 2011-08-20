xquery version '1.0-ml';

module namespace utils = 'http://xqueryhacker.com/xqtest/utils';
declare namespace test = 'http://xqueryhacker.com/xqtest/test';
declare namespace s = 'http://www.w3.org/2009/xpath-functions/analyze-string';
declare default element namespace 'http://xqueryhacker.com/xqtest';


declare function utils:get-filelist($dir as xs:string) as xs:string*
{
    for $entry in xdmp:filesystem-directory($dir)/dir:entry
    order by $entry/dir:pathname
    return
        if ($entry/dir:type = 'file') then $entry/dir:pathname/fn:string()
        else utils:get-filelist($entry/dir:pathname/fn:string())
};


(: pretty naive but does the job for now :)
declare function utils:get-functions($module-path as xs:string, $ns-prefix as xs:string?) as xdmp:function*
{
    let $regex := fn:concat('declare\s+function\s+(', $ns-prefix, '[^\(]+)\(')
    let $module := try { fn:string(xdmp:filesystem-file($module-path)) } catch($e){}
    where $module
    return
        let $without-comments := fn:string-join(fn:analyze-string($module, '\(:.*:\)', 's')/s:non-match, ' ')
        return
            for $f in fn:analyze-string($without-comments, $regex)/s:match/s:group/fn:string()
            return xdmp:function(xs:QName($f), fn:replace($module-path, xdmp:modules-root(), '/'))
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
    element { if ($status) then 'passed' else 'failed' } {
        attribute assertion { $assertion },
        element actual { ($actual, '()')[1] },
        element expected { $expected }
    }
};


declare function utils:transform($el as element(), $format as xs:string) as item()
{
    if ($format eq 'text') then xdmp:set-response-content-type(fn:concat('text/plain')) else (),
    xdmp:xslt-invoke(fn:concat('xsl/', $format, '.xsl'), $el)
};