xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";
declare namespace xray = "http://github.com/robwhitby/xray";


declare function simple-mapping-operator()
{
  let $x := (1,2,3) ! . * 2
  return assert:equal(fn:sum($x), 12)
};


declare function string-concat()
{
  assert:equal("foo" || "bar", "foobar")
};

