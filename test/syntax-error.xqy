xquery version "1.0-ml";

module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/src/assertions.xqy";


declare %test:case function syntax-error-in-module()
{
  "no closing semi-colon"
}
