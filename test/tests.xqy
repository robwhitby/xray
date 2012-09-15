xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace utils = "utils" at "utils.xqy";

declare namespace xray = "http://github.com/robwhitby/xray";



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


(: all public functions are evaluated by the test-runner :)
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

declare function should-be-able-to-test-number-equality()
{
  assert:equal(1, 1)
};

declare function should-be-able-to-test-string-equality()
{
  assert:equal("foo", "bar", "not foo so should fail")
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
  fn:error((), 'XRAY-PRIVATE', "this test is private!")
};

declare function IGNORE-should-skip-this-test()
{
  fn:error((), 'XRAY-PRIVATE', "this test should be ignored!")
};

(:
declare function test:should-not-attempt-to-run-commented-out-function()
{
  fn:error((), 'XRAY-PRIVATE', "this test is commented out!")
};
:)

declare function should-handle-sequences()
{
  assert:equal((1,2,3), (1,2,3)),
  assert:not-equal((1,2,3), (1,2)),
  assert:not-equal(1, (1,2)),
  assert:not-equal((), 1),
  assert:equal((1, "two", <three/>), (1, "two", <three/>))
};

declare function should-be-able-to-assert-true-and-false()
{
  assert:true(fn:true()),
  assert:false(fn:false())
};

declare function should-be-able-to-test-simple-cts-query-equality()
{
  let $query := <cts:and-query/>
  return (
    assert:equal(cts:and-query(()), cts:and-query(())),
    assert:equal($query, $query),
    assert:equal(cts:and-query(()), $query),
    assert:equal($query, <cts:and-query/>)
  )
};

declare function should-be-able-to-test-complex-cts-query-equality()
{
  let $query :=
    cts:or-query((
      cts:element-value-query(xs:QName("foo"), ("bar", "baz"), ("unstemmed", "case-insensitive"), 5),
      cts:word-query("foo", "stemmed", 10)
    ))
  return assert:equal($query, $query)
};

declare function should-include-optional-assert-message-on-failure()
{
  let $msg := "$a equals $b"
  let $assert-no-msg := assert:equal(1, 2)
  let $assert-with-msg := assert:equal(1, 2, $msg)
  return (
    assert:equal($assert-no-msg/xray:message/fn:string(), ""),
    assert:equal($assert-with-msg/xray:message/fn:string(), $msg)
  )
};

declare function IGNORE-should-also-skip-this-test()
{
  fn:error((), 'XRAY-IGNORE', "this test should be ignored!")
};

declare function should-be-able-to-import-module-using-relative-path()
{
  let $foo := utils:upper("foo")
  return assert:equal($foo, "FOO")
};
