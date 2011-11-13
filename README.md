#XQTest

###A simple XQuery test framework for MarkLogic

Write tests as xquery functions 



###Getting Started
Clone or add as a submodule into your project

```
git submodule add git@github.com:robwhitby/XQTest.git
git submodule init
```

Create a test directory (by default XQTest looks for a folder called test in the app server root) and a test module
```xquery
xquery version '1.0-ml';
module namespace test = 'http://github.com/robwhitby/xqtest/test';
import module namespace assert = 'http://github.com/robwhitby/xqtest/assertions' at '/XQTest/src/assertions.xqy';

declare function test:one-plus-one-equals-two() 
{
  assert:equal(1 + 1, 2)
};
```

Create an HTTP app server at your project's root and browse to:
http://localhost:xxxx/XQTest/test-runner.xqy

Or run the shell script with the above URL:
XQTest/test-runner.sh -u http://localhost:xxxx/XQTest/test-runner.xqy










