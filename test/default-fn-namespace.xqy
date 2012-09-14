xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";


declare function test:should-allow-setting-default-function-namespace()
{
  assert:true(true())
};
