xquery version "1.0-ml";

module namespace test = "http://github.com/robwhitby/xray/test";

import module namespace assert="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy" ;

import module namespace cover="http://github.com/robwhitby/xray/coverage"
  at "/xray/src/coverage.xqy";
import module namespace log="http://github.com/robwhitby/xray/logging"
  at "/xray/src/logging.xqy";
import module namespace xray="http://github.com/robwhitby/xray"
  at "/xray/src/xray.xqy";

declare %test:case function an-error-with-coverage-enabled()
{
  let $res := xray:run-tests(
    'test', 'tests.xqy',
    'should-detect-runtime-error', 'xml',
    '/xray/src/assertions.xqy')
  let $_ := xdmp:log(xdmp:quote($res))
  let $mod as element(xray:module) := $res/xray:tests/xray:module
  return assert:true($mod/@error eq 1)
};

declare %test:case function cover-lib-assertions()
 as element(xray:assert)
{
  let $res as element(xray:tests) := xray:run-tests(
    'test', 'default-fn-namespace.xqy',
    'should-allow-setting-default-function-namespace', 'xml',
    '/xray/src/assertions.xqy')/*
  let $summary as element() := $res/xray:coverage-summary
  let $cover as element() := $res/xray:module/xray:test/xray:coverage
  return assert:true(
    $cover/xray:covered/@count gt 0
    and $cover/xray:covered/@count eq $summary/@covered-count)
};

declare %test:case function can-format-html()
 as element(xray:assert)
{
  let $res as element(html) := xray:run-tests(
    'test', 'default-fn-namespace.xqy',
    'should-allow-setting-default-function-namespace', 'html',
    '/xray/src/assertions.xqy')/*
  return assert:not-empty($res)
};

declare %test:case function can-format-text()
 as element(xray:assert)
{
  let $res as text() := xray:run-tests(
    'test', 'default-fn-namespace.xqy',
    'should-allow-setting-default-function-namespace', 'text',
    '/xray/src/assertions.xqy')/node()
  return assert:not-empty($res)
};

declare %test:case function can-format-xml()
 as element(xray:assert)
{
  let $res as element(xray:tests) := xray:run-tests(
    'test', 'default-fn-namespace.xqy',
    'should-allow-setting-default-function-namespace', 'xml',
    '/xray/src/assertions.xqy')/*
  return assert:not-empty($res)
};

declare %test:case function can-format-xunit()
 as element(xray:assert)
{
  let $res as element(testsuites) := xray:run-tests(
    'test', 'default-fn-namespace.xqy',
    'should-allow-setting-default-function-namespace', 'xunit',
    '/xray/src/assertions.xqy')/*
  return assert:not-empty($res)
};

declare %test:case function error-on-MODULEDNE()
 as element(xray:assert)
{
  let $res as element(xray:tests) := xray:run-tests(
    'test', 'default-fn-namespace.xqy',
    'should-allow-setting-default-function-namespace', 'xml',
    'DNE')/*
  let $ex as element(error:error) := $res/xray:module/*
  return assert:error(
    $ex,
    'DBG-MODULEDNE')
};

declare %test:case function module-view-DNE()
 as element(xray:assert)
{
  let $res as element(xray:module) := cover:module-view(
    'DNE', 'xml',
    (11 to 20), (17 to 23))
  (: NB - different error code when using database modules! :)
  return assert:true(contains($res, 'SVC-FILOPN'))
};

declare %test:case function module-view-html()
 as element(xray:assert)
{
  let $res as element(html) := cover:module-view(
    '/xray/src/assertions.xqy', 'html',
    (11 to 20), (17 to 23))/*
  return assert:not-empty($res)
};

declare %test:case function module-view-text()
 as element(xray:assert)
{
  let $res as text()+ := cover:module-view(
    '/xray/src/assertions.xqy', 'text',
    (11 to 20), (17 to 23))
  return assert:not-empty($res)
};

declare %test:case function module-view-xml()
 as element(xray:assert)
{
  let $res as element(xray:module) := cover:module-view(
    '/xray/src/assertions.xqy', 'xml',
    (11 to 20), (17 to 23))
  return assert:not-empty($res)
};

declare %test:case function module-view-xunit-error()
 as element(xray:assert)
{
  assert:error(
    try {
      cover:module-view(
        '/xray/src/assertions.xqy', 'xunit',
        (11 to 20), (17 to 23)) }
    catch ($ex) { $ex },
    'XRAY-BADFORMAT')
};

declare %test:case function prepare-1mod-1fn()
 as element(xray:assert)
{
  let $res as map:map := cover:prepare(
    '/xray/src/assertions.xqy',
    xdmp:function(xs:QName('test:module-view-xunit-error')),
    '/xray/test/coverage.xqy')
  return assert:equal(map:keys($res), '/xray/src/assertions.xqy')
};

declare %test:case function prepare-1mod-4fn()
 as element(xray:assert)
{
  let $res as map:map := cover:prepare(
    '/xray/src/assertions.xqy',
    (xdmp:function(xs:QName('test:module-view-html')),
      xdmp:function(xs:QName('test:module-view-text')),
      xdmp:function(xs:QName('test:module-view-xml')),
      xdmp:function(xs:QName('test:module-view-xunit-error'))),
    '/xray/test/coverage.xqy')
  return assert:equal(map:keys($res), '/xray/src/assertions.xqy')
};

declare %test:case function prepare-2mod-4fn()
 as element(xray:assert)
{
  let $res as map:map := cover:prepare(
    ('/xray/src/assertions.xqy',
      '/xray/src/logging.xqy'),
    (xdmp:function(xs:QName('test:module-view-html')),
      xdmp:function(xs:QName('test:module-view-text')),
      xdmp:function(xs:QName('test:module-view-xml')),
      xdmp:function(xs:QName('test:module-view-xunit-error'))),
    '/xray/test/coverage.xqy')
  return assert:equal(
    for $k in map:keys($res) order by $k return $k,
    ('/xray/src/assertions.xqy',
      '/xray/src/logging.xqy'))
};

declare %test:case function prepare-3mod-1fn()
 as element(xray:assert)
{
  let $res as map:map := cover:prepare(
    ('/xray/src/assertions.xqy',
      '/xray/src/logging.xqy',
      '/xray/src/modules-database.xqy'),
    (xdmp:function(xs:QName('test:error-on-MODULEDNE'))),
    '/xray/test/coverage.xqy')
  return assert:equal(
    for $k in map:keys($res) order by $k return $k,
    ('/xray/src/assertions.xqy',
      '/xray/src/logging.xqy',
      '/xray/src/modules-database.xqy'))
};

declare %test:case function prepare-toobig()
 as element(xray:assert)
{
  xdmp:set($cover:LIMIT, 9),
  let $res as element() := try {
    cover:prepare(
      '/xray/src/assertions.xqy',
      xdmp:function(xs:QName('test:module-view-xunit-error')),
      '/xray/test/coverage.xqy') } catch ($ex) { $ex }
  return assert:error($res, 'XRAY-TOOBIG')
};

(: xray/test/coverage.xqy :)