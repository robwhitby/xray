xquery version "1.0-ml";

module namespace assert="http://github.com/robwhitby/xray/assertions";
import module namespace xray = "http://github.com/robwhitby/xray" at "xray.xqy";


declare function assert:equal(
  $actual as item()*,
  $expected as item()*
) as element(xray:assert)
{
  assert:equal($actual, $expected, ())
};

declare function assert:equal(
  $actual as item()*,
  $expected as item()*,
  $message as xs:string?
) as element(xray:assert)
{
  let $status := deep-equal($actual, $expected)
  return xray:assert-response("equal", $status, $actual, $expected, $message)
};


declare function assert:not-equal(
  $actual as item()*,
  $expected as item()*
) as element(xray:assert)
{
  assert:not-equal($actual, $expected, ())
};

declare function assert:not-equal(
  $actual as item()*,
  $expected as item()*,
  $message as xs:string?
) as element(xray:assert)
{
  let $status := fn:not(deep-equal($actual, $expected))
  return xray:assert-response("not-equal", $status, $actual, $expected, $message)
};


declare function assert:empty(
  $actual as item()*
) as element(xray:assert)
{
  assert:empty($actual, ())
};

declare function assert:empty(
  $actual as item()*,
  $message as xs:string?
) as element(xray:assert)
{
  let $status := fn:empty($actual)
  return xray:assert-response("empty", $status, $actual, "empty-sequence()", $message)
};


declare function assert:not-empty(
  $actual as item()*
) as element(xray:assert)
{
  assert:not-empty($actual, ())
};

declare function assert:not-empty(
  $actual as item()*,
  $message as xs:string?
) as element(xray:assert)
{
  let $status := fn:not(fn:empty($actual))
  return xray:assert-response("not-empty", $status, $actual, "item()+", $message)
};


declare function assert:error(
  $actual as item()*,
  $expected-error-code as xs:string
) as element(xray:assert)
{
  assert:error($actual, $expected-error-code, ())
};

declare function assert:error(
  $actual as item()*,
  $expected-error-code as xs:string,
  $message as xs:string?
) as element(xray:assert)
{
  let $actual-error-code :=
    if ($actual instance of element(error:error)) then $actual/error:code/fn:string()
    else ()
  let $status := $actual-error-code = $expected-error-code
  return xray:assert-response("error", $status, ($actual-error-code, $actual)[1], $expected-error-code, $message)
};


declare function assert:true(
  $actual as item()*
) as element(xray:assert)
{
  assert:true($actual, ())
};

declare function assert:true(
  $actual as item()*,
  $message as xs:string?
) as element(xray:assert)
{
  let $status := $actual instance of xs:boolean and $actual
  return xray:assert-response("true", $status, $actual, "true", $message)
};


declare function assert:false(
  $actual as item()*
) as element(xray:assert)
{
  assert:false($actual, ())
};

declare function assert:false(
  $actual as item()*,
  $message as xs:string?
) as element(xray:assert)
{
  let $status := $actual instance of xs:boolean and fn:not($actual)
  return xray:assert-response("false", $status, $actual, "false", $message)
};


declare private function deep-equal(
  $a as item()*,
  $b as item()*
) as xs:boolean
{
  if ($a instance of cts:query)
  then fn:deep-equal(<q>{$a}</q>, <q>{$b}</q>)
  else fn:deep-equal($a, $b)
};
