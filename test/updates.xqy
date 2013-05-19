xquery version "1.0-ml";

module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";


declare %test:case function assert-timestamp()
{
  if (xdmp:request-timestamp()) then ()
  else fn:error((), "UPDATE", "Query must be read-only but contains updates!")
  ,
  assert:true(fn:true())
};


declare %test:case function updates-work()
{
  (: This will take an update lock, which will fail in timestamped mode. :)
  xdmp:lock-for-update(xdmp:integer-to-hex(xdmp:random())),
  (: Make sure we really are in update mode :)
  if (fn:not(xdmp:request-timestamp())) then ()
  else fn:error((), "UPDATE", "Query must be read-only but contains updates!"),
  assert:true(fn:true())
};


