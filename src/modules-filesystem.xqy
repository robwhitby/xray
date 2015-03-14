xquery version "1.0-ml";

module namespace modules-fs = "http://github.com/robwhitby/xray/modules-fs";


declare function get-modules(
  $test-dir as xs:string,
  $pattern as xs:string?
) as xs:string*
{
  let $test-dir := fn:translate($test-dir, '\', '/')
  let $fs-dir := fn:translate(fn:concat(xdmp:modules-root(), fn:replace($test-dir, "^[/\\]+", "")), '\', '/')
  where filesystem-directory-exists($fs-dir)
  return
    module-filenames($fs-dir)[fn:ends-with(., $pattern) or fn:matches(fn:substring-after(., $fs-dir), fn:string($pattern))]
};


declare private function module-filenames(
  $dir as xs:string
) as xs:string*
{
  for $entry in xdmp:filesystem-directory($dir)/dir:entry
  order by $entry/dir:type descending, $entry/dir:filename ascending
  return
    if ($entry/dir:type = "file")
    then
      if (fn:matches($entry/dir:pathname, "\.xq[my]?$"))
      then fn:translate($entry/dir:pathname, '\', '/')
      else ()
    else module-filenames($entry/dir:pathname/fn:string())
};


declare private function filesystem-directory-exists(
  $dir as xs:string
) as xs:boolean
{
  try  { fn:exists(xdmp:filesystem-directory($dir)) }
  catch($e)
  {
    if ($e/error:code = "SVC-DIROPEN")
    then fn:false()
    else xdmp:rethrow()
  }
};
