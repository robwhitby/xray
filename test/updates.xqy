xquery version "1.0-ml";
(: test/updates.xqy :)
module namespace test = "http://github.com/robwhitby/xray/test";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace assert = "http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

declare function test:assert-timestamp()
{
  if (xdmp:request-timestamp()) then ()
  else error((), 'UPDATE', 'Query must be read-only but contains updates!')
  ,
  assert:true(true())
};

declare function test:updates-work()
{
  (: This will take an update lock, which will fail in timestamped mode. :)
  xdmp:lock-for-update(xdmp:integer-to-hex(xdmp:random())),
  (: Make sure we really are in update mode :)
  if (not(xdmp:request-timestamp())) then ()
  else error((), 'UPDATE', 'Query must be read-only but contains updates!'),
  assert:true(true())
};

(: test/updates.xqy :)
