xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace utils = "utils" at "/xray/test/utils.xqy";

declare function check-doc1-not-loaded() 
{
  assert:empty(fn:doc("doc1.xml"))
};

declare function should-be-able-to-import-module-using-root-relative-path() 
{
  let $foo := utils:upper("foo")
  return assert:equal($foo, "FOO")
};