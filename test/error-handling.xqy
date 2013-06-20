xquery version "1.0-ml";

module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";


declare private function something-that-errors() {
  fn:error((), "MY-ERROR", "something went wrong")
};

declare %test:case function should-be-able-to-assert-error-code()
{
  let $actual := try { something-that-errors() } catch ($ex) { $ex }
  return (
    assert:error($actual, "MY-ERROR"),
    assert:equal($actual/error:data/fn:string(), "something went wrong")
  )
};



