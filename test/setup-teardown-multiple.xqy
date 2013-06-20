xquery version "1.0-ml";

module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";


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

declare %test:setup function setup1()
{
  for $doc in $test-docs/doc
  return xdmp:document-insert($doc/@uri, $doc/node(), (), "xray-test")
};

(: optional teardown function evaluated after all tests :)
declare %test:teardown function teardown()
{
  xdmp:collection-delete("xray-test")
};

declare %test:teardown function teardown2()
{
  xdmp:collection-delete("xray-test2")
};


(: can have multiple setup or teardown functions, not sure why you'd want to though :)
declare %test:setup function setup2()
{
  for $doc in $test-docs/doc
  return xdmp:document-insert("setup2/" || $doc/@uri , $doc/node(), (), "xray-test2")
};


declare %test:case function check-both-setups-ran() {
  assert:equal(fn:count(fn:collection("xray-test")/root/test), 2),
  assert:equal(fn:count(fn:collection("xray-test2")/root/test), 2)
};

