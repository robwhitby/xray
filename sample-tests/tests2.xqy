xquery version '1.0-ml';
module namespace test = 'http://github.com/robwhitby/xqtest/test';
import module namespace assert = 'http://github.com/robwhitby/xqtest/assertions' at '/src/assertions.xqy';

declare function test:check-doc1-not-loaded() 
{
  assert:equal(fn:doc-available('doc1.xml'), fn:false())
};
