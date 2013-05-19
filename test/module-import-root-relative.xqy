xquery version "1.0-ml";

module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace utils = "utils" at "/xray/test/utils.xqy";


declare %test:case function should-be-able-to-import-module-using-root-relative-path()
{
  let $foo := utils:upper("foo")
  return assert:equal($foo, "FOO")
};

