xquery version "1.0-ml";

module namespace modules = "http://github.com/robwhitby/xray/modules";

declare namespace xray = "http://github.com/robwhitby/xray";
declare namespace test = "http://github.com/robwhitby/xray/test";
import module namespace modules-fs = "http://github.com/robwhitby/xray/modules-fs" at "modules-filesystem.xqy";
import module namespace modules-db = "http://github.com/robwhitby/xray/modules-db" at "modules-database.xqy";

declare private variable $TEST-NS-URI := fn:namespace-uri-for-prefix("test", <test:x/>);
declare private variable $USE-MODULES-DB := (xdmp:modules-database() ne 0);


declare function get-modules(
  $test-dir as xs:string,
  $pattern as xs:string?
) as xs:string*
{
  (
    if ($USE-MODULES-DB)
    then modules-db:get-modules($test-dir, $pattern)
    else modules-fs:get-modules($test-dir, $pattern)
  ) ! relative-path(.)
};


declare function relative-path(
  $path as xs:string
) as xs:string
{
  fn:substring($path, fn:string-length(xdmp:modules-root()))
};

