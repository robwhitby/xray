# xray

Heads up: This project is very much a work in progress.


## Introduction
**xray** is a framework for testing XQuery on MarkLogic Server. It differs from other XQuery test frameworks in that tests are written as standard XQuery functions.

```xquery
declare function test:string-equality-example()
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
Tests are written as library modules in the xray test namespace, importing the xray assertions module:

```xquery
xquery version '1.0-ml';
module namespace test = 'http://github.com/robwhitby/xray/test';
import module namespace assert = 'http://github.com/robwhitby/xray/assertions' at '/xray/src/assertions.xqy';

declare function test:string-equality-example()
{
  let $foo := "foo"
  return assert:equal($foo, "foo")
};

(: more tests :)
```

## Invoking Tests
* browser
* test-runner.sh
* invoking from xquery 


## Parameters
* `dir` - test directory path relative from the app server modules root. Defauts to 'test'.
* `modules` - regex match on module name. Optional.
* `tests` - regex match on test name. Optional.


## Assertions
See `src/assertions.xqy` for the current assertions.


## Ignoring Tests 
Not implemented yet. Workaround - add `private` modifier to function.


## Setup and teardown functions
`test:setup()` and `test:teardown()` are reserved function signatures. If defined, `test:setup()` is invoked before any tests in an isolated transaction, so any database updates are visible to the tests. `test:teardown()` is executed after all tests in that module have finished.

See `test/tests.xqy` for an example.


## Acknowledgements
Thanks to [Jon Snelson](http://github.com/jpcs) for the XQuery parser (part of https://github.com/xquery/xquerydoc). Without it I would still be hacking around with regexes.



