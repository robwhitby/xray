xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

(: 
  optional setup function evaluated first
  add any test docs used by the tests in this module
:)
declare function setup()
{
  xdmp:document-insert("doc1.xml", <doc1>foo bar</doc1>, (), "test")
};

(: optional teardown function evaluated after all tests :)
declare function teardown()
{
  xdmp:document-delete("doc1.xml")
};


declare function tests-can-contain-multiple-asserts()
{
  let $foo := "foo"
  let $bar := "bar"
  return (
    assert:not-empty($foo),
    assert:equal($foo, "foo"),
    assert:not-equal($foo, $bar)
  )
};


(: all public functions are evaluated by the test-runner :)
declare function should-be-able-to-test-number-equality()
{
  assert:equal(1, 1)
};

declare function should-be-able-to-test-string-equality()
{
  assert:equal("foo", "not foo so should fail")
};

declare function should-be-able-to-return-multiple-asserts()
{
  assert:equal(0.5, 0.5),
  assert:equal("bar ", "bar ")
};

declare function should-be-able-to-test-string-inequality()
{
  assert:not-equal("foo", "bar"),
  assert:not-equal("foo", "Foo")
};

declare function should-be-able-to-test-xml-equality()
{
  assert:equal(
    <test><p>para 1</p><p>para 2</p></test>,
    <test><p>para 1</p><p>para 2</p></test>
  )
};

declare function should-ignore-attribute-order-in-xml-equality()
{
  assert:equal(
    <test foo="1" bar="2"/>,
    <test bar="2" foo="1"/>
  )
};

declare function should-be-able-to-test-xml-inequality()
{
  assert:not-equal(
    <test><p>para 1</p><p>para 2</p></test>,
    <test><p>para 2</p><p>para 1</p></test>
  )
};

declare function should-be-able-to-test-xpath()
{
  let $xml := <test><p>para 1</p><p>para 2</p></test>
  return assert:equal($xml/p[2], <p>para 2</p>)
};

declare function should-be-able-to-test-empty-xpath()
{
  let $xml := <test><p>para 1</p><p>para 2</p></test>
  return assert:empty($xml/p[3])
};

declare private function get-xml()
{
  <test><p>para 1</p><p>para 2</p></test>
};

declare function should-be-able-to-call-private-functions()
{
  let $xml := test:get-xml()
  return (
    assert:empty($xml/p[3]),
    assert:equal(fn:name($xml), "test"),
    assert:equal($xml/p[2]/fn:string(), "para 2")
  )
};

declare function
  check-doc1-loaded() {
  assert:not-empty(fn:doc("doc1.xml"))
};

declare function 
test:check-doc1-is-searchable()
{
  let $results := cts:search(fn:collection("test"), "foo")
  return assert:equal($results/doc1/fn:string(), "foo bar")
};


declare private function test:should-not-run-private-function()
{
  fn:error()
};

(:
declare function test:should-not-attempt-to-run-commented-out-function() 
{
  fn:error()
};
:)
