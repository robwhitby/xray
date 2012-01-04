xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

declare function check-doc1-not-loaded() 
{
  assert:empty(fn:doc("doc1.xml"))
};
