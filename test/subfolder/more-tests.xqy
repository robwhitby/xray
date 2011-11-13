xquery version '1.0-ml';
module namespace test = 'http://github.com/robwhitby/xqtest/test';
import module namespace assert = 'http://github.com/robwhitby/xqtest/assertions' at '/XQTest/src/assertions.xqy';

declare function test:xml-nodes-equal() {
    assert:equal(<test foo="bar"/>, <test foo="bar"/>)
};

declare function test:different-text-content() {
    assert:not-equal(<p>test</p>, <p>test1</p>)
};

declare function test:check-doc1-not-loaded() 
{
  assert:empty(fn:doc('doc1.xml'))
};


