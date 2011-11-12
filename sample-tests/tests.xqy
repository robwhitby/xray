xquery version '1.0-ml';
module namespace test = 'http://github.com/robwhitby/xqtest/test';
import module namespace assert = 'http://github.com/robwhitby/xqtest/assertions' at '/src/assertions.xqy';

declare function test:setup()
{
  xdmp:document-insert('doc1.xml', <doc1>1</doc1>, (), 'test')
};

declare function test:teardown()
{
  xdmp:document-delete('doc1.xml')
};

declare function test:check-doc1-loaded() 
{
  assert:equal(fn:doc-available('doc1.xml'), fn:true())
};

declare function test:should-be-able-to-test-number-equality()
{
  assert:equal(1, 1)
};

declare function test:should-be-able-to-test-string-equality()
{
  assert:equal('foo', 'not foo so should fail')
};

declare function test:should-be-able-to-return-multiple-asserts()
{
  assert:equal(0.5, 0.5),
  assert:equal('bar ', 'bar ')
};

declare function test:should-be-able-to-test-string-inequality()
{
  assert:not-equal('foo', 'bar'),
  assert:not-equal('foo', 'Foo')
};

declare function test:should-be-able-to-test-xml-equality()
{
  assert:equal(
    <test><p>para 1</p><p>para 2</p></test>,
    <test><p>para 1</p><p>para 2</p></test>
  )
};

declare function test:should-ignore-attribute-order-in-xml-equality()
{
  assert:equal(
    <test foo="1" bar="2"/>,
    <test bar="2" foo="1"/>
  )
};

declare function test:should-be-able-to-test-xml-inequality()
{
  assert:not-equal(
    <test><p>para 1</p><p>para 2</p></test>,
    <test><p>para 2</p><p>para 1</p></test>
  )
};

declare function test:should-be-able-to-test-xpath()
{
  let $xml := <test><p>para 1</p><p>para 2</p></test>
  return assert:equal($xml/p[2], <p>para 2</p>)
};

declare function test:should-be-able-to-test-empty-xpath()
{
  let $xml := <test><p>para 1</p><p>para 2</p></test>
  return assert:empty($xml/p[3])
};

declare private function test:get-xml()
{
  <test><p>para 1</p><p>para 2</p></test>
};

declare function test:should-be-able-to-call-private-functions()
{
  let $xml := test:get-xml()
  return (
    assert:empty($xml/p[3]),
    assert:equal(fn:name($xml), 'test'),
    assert:equal($xml/p[2]/fn:string(), 'para 2')
  )
};

