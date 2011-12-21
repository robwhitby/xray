# xray

Heads up: This project is very much a work in progress.


## Introduction
**xray** is a framework for testing XQuery on MarkLogic Server. Test cases are written as standard XQuery functions like this:  

```xquery
declare function string-equality-example()
{
  let $foo := "foo"
  return assert:equal($foo, "foo")
};
```

## Getting Started
* Copy xray into the root directory of your project 
* Create an HTTP app server pointing to the root directory of your project.
* Check all is well at `http://server:port/xray/`
* Write some tests..


## Writing Tests
Tests are grouped into library modules in the xray test namespace, importing the xray assertions module:

```xquery
xquery version '1.0-ml';
module namespace test = 'http://github.com/robwhitby/xray/test';
import module namespace assert = 'http://github.com/robwhitby/xray/assertions' at '/xray/src/assertions.xqy';

declare function string-equality-example()
{
  let $foo := "foo"
  return assert:equal($foo, "foo")
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

(: more tests :)
```

## Invoking Tests
**xray** will find and execute all the test cases defined in a directory (and sub-directories), and can be told to execute a subset by specifying regex patterns to match tests by module name or test name.

* in browser - `http://server:port/xray/`
* command line - test-runner.sh is a sample shell script, edit default vars (tested on OSX only).
* invoke from xquery - import `src/xray.xqy` and call `xray:run-tests()`


## Parameters
`dir` - test directory path relative from the app server modules root. Optional, defaults to 'test'.

`modules` - regex match on module name. Optional, default to match all.

`tests` - regex match on test name. Optional, defaults to match all.

`format` - set output format to html, xml or text. Optional, defaults to html.

## Assertions
See `src/assertions.xqy` for the current assertions.


## Ignoring Tests 
Not implemented yet. 
Workaround - add `private` modifier to function.


## Setup and teardown functions
`setup()` and `teardown()` are special function signatures. If defined, `setup()` is invoked before any tests in a seperate transaction, so any database updates are visible to the tests. `teardown()` is executed after all tests in that module have finished.

See `test/tests.xqy` for an example.


## Acknowledgements
Thanks to [John Snelson](http://github.com/jpcs) for the XQuery parser (part of https://github.com/xquery/xquerydoc). Without it I would still be hacking around with regexes.



