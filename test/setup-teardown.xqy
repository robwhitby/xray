xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";
declare namespace xray = "http://github.com/robwhitby/xray";


(:
  optional setup function evaluated first
  add any test docs used by the tests in this module
:)

declare private variable $test-docs :=
  <docs>
    <doc uri="one.xml">
      <root><test>one</test></root>
    </doc>
    <doc uri="two.xml">
      <root><test>two</test></root>
    </doc>
  </docs>;

declare function setup()
{
  for $doc in $test-docs/doc
  return xdmp:document-insert($doc/@uri, $doc/node(), (), "xray-test")
};

(: optional teardown function evaluated after all tests :)
declare function teardown()
{
  xdmp:collection-delete("xray-test")
};


declare function check-docs-loaded() {
  for $uri in $test-docs/doc/@uri/fn:string()
  return assert:not-empty(fn:doc($uri))
};

declare function check-xpath-doc() {
  assert:equal(fn:count(fn:collection("xray-test")/root/test), 2)
};

