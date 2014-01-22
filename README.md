# xray

**xray** is a framework for writing XQuery unit tests on MarkLogic Server. Version 2.0 uses function annotations to define tests, and requires MarkLogic 6 or above. For MarkLogic 5 support use the v1.1 branch.

Test cases are written as standard XQuery functions like this:  

```xquery
declare %test:case function string-equality-example ()
{
  let $foo := "foo"
  return assert:equal($foo, "foo")
};
```

**xray** can output test results as HTML, XML, xUnit compatible XML, JSON, and plain text, so it should be simple to integrate with your favourite build/ci server.

## Getting Started
* Clone/copy/symlink xray into the root directory of your project e.g.<br/>
`git clone git://github.com/robwhitby/xray.git`  
or  
`git submodule add git://github.com/robwhitby/xray.git` 
* Create an HTTP app server pointing to the root directory of your project.
* Check all is well at `http://server:port/xray/`
* Write some tests..


## Writing Tests
Tests are grouped into library modules in the xray test namespace. Import the xray assertions module along with the modules to be tested.

```xquery
xquery version "1.0-ml";
module namespace test = "http://github.com/robwhitby/xray/test";
import module namespace assert = "http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace some-module = "http://some-module-to-test" at "/some-module-to-test.xqy";

declare %test:case function string-equality-example ()
{
  let $foo := some-module:foo()
  return assert:equal($foo, "foo")
};

declare %test:case function multiple-assert-example ()
{
  let $foo := some-module:foo()
  let $bar := "bar"
  return (
    assert:not-empty($foo, "an optional failure help message"),
    assert:equal($foo, "foo"),
    assert:not-equal($foo, $bar),
    assert:true(return-true())
  )
};

declare %test:ignore function ignored-test-example ()
{
  let $foo := some-module:not-implemented-yet()
  return assert:equal($foo, <foo/>)
}
```


## Invoking Tests
**xray** will find all functions with the `%test:case` annotation defined in library modules within a specific directory (including sub-directories), and can be told to execute a subset by specifying regex patterns to match tests by module name or test name.

* browser - `http://server:port/xray/`
* command line - call `test-runner.sh` with your project parameters (see below, tested on OSX only).
* invoke from xquery - import `src/xray.xqy` and call `xray:run-tests()`. See `index.xqy` for example.

By default, xray looks for a directory called `test` at the same level as the `xray` directory:
<pre>
project-root/
├── src
├── test
│   └── tests.xqy
└── xray
</pre>

To invoke tests stored elsewhere, set the directory parameter.


## Test Runner Command Line Parameters
```shell
usage: test-runner.sh [options...]
Options:
      -c <user:password>    Credential for HTTP authentication.
      -d <path>             Look for tests in this directory.
      -h                    This message.
      -m <regex>            Test modules that match this pattern.
      -t <regex>            Test functions that match this pattern.
      -u <URL>              HTTP server location where index.xqy can be found.
```

## Test Runner Shortcut
Rather than modify test-runner.sh or always pass in custom parameters, it's handy to create a small wrapper script in the project root, something like this:

```shell
./xray/test-runner.sh -u http://localhost:8765/xray/ -c user:pass -d testdir $*
```

This still allows using `-t` and `-m` to select which tests to run but removes the need to constantly set the url and test directory.

See `run-xray-tests.sh` for an example.


## Assertions
```xquery
assert:equal ($actual as item()*, $expected as item()*, [$message as xs:string?])

assert:not-equal ($actual as item()*, $expected as item()*, [$message as xs:string?])

assert:empty ($actual as item()*, [$message as xs:string?])

assert:not-empty ($actual as item()*, [$message as xs:string?])

assert:error ($actual as item()*, $expected-error-name as xs:string, [$message as xs:string?])

assert:true ($actual as item()*, [$message as xs:string?])

assert:false ($actual as item()*, [$message as xs:string?])
```
See `src/assertions.xqy` for the assertion definitions. All assertions are overloaded to accept an optional message parameter to provide more information of failures.

## Setup and teardown functions
Use the annotations `%test:setup` and `%test:teardown`. If defined, the setup function is invoked before any tests, and in a different transaction so any database updates are visible to the tests. The teardown function is executed after all tests in that module have finished.

See `test/setup-teardown.xqy` for an example.

## Ignoring Tests 
Tests can be ignored by adding the `%test:ignore` annotation

```xquery
declare %test:ignore function this-test-will-be-ignored()
```

## MarkLogic Configuration
The app server user must belong to a role with the following execute privileges:
`xdmp:eval`, `xdmp:filesystem-directory`, `xdmp:filesystem-file`, `xdmp:invoke`, `xdmp:xslt-invoke`

To work with modules stored in a modules database, the additional privileges are required:
`xdmp:eval-in`
And the user must have read rights to files in the modules db.

&nbsp;
## Screenshots
![screenshot of html output](https://github.com/robwhitby/xray/raw/master/screenshot-html.png)
![screenshot of terminal output](https://github.com/robwhitby/xray/raw/master/screenshot-terminal.png)
