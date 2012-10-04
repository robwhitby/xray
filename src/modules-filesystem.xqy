xquery version "1.0-ml";

module namespace modules-fs = "http://github.com/robwhitby/xray/modules-fs";

declare variable $ROOT := xdmp:modules-root();

declare variable $IS-WINNT := xdmp:platform() eq "winnt";

declare variable $FSEP := if ($IS-WINNT) then '\' else '/';

declare private function clean-path(
  $path as xs:string
) as xs:string
{
  if ($IS-WINNT) then fn:translate($path, '/', $FSEP)
  else fn:translate($path, '\', $FSEP)
};


declare private function append-path(
  $path as xs:string,
  $step as xs:string
) as xs:string
{
  fn:concat(
    $path, if (fn:ends-with($path, $FSEP)) then '' else $FSEP,
    if (fn:starts-with($step, $FSEP)) then fn:substring-after($step, $FSEP)
    else $step)
};


declare function resolve-path(
  $path as xs:string
) as xs:string
{
  append-path(clean-path($ROOT), clean-path($path))
};


declare function get-modules(
  $test-dir as xs:string,
  $pattern as xs:string?
) as xs:string*
{
  let $fs-dir := append-path(clean-path($ROOT), clean-path($test-dir))
  where filesystem-directory-exists($fs-dir)
  return module-filenames($fs-dir)[
    fn:matches(fn:substring-after(., $fs-dir), $pattern)]
};


declare function get-module(
  $module-path as xs:string
) as xs:string
{
  fn:string(xdmp:filesystem-file($module-path))
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
      (: support xq, xqe, xqm, and xqy :)
      if (fn:matches($entry/dir:pathname, "\.xq[emy]?$"))
      then $entry/dir:pathname
      else ()
    else module-filenames($entry/dir:pathname)
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
