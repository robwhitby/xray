xquery version "1.0-ml";

module namespace test = "some other namespace";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";


declare %test:case function should-not-include-modules-not-in-xray-test-namespace()
{
  fn:error((), 'XRAY-IGNORE', "this test should not be invoked")
};
