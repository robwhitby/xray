xquery version "1.0-ml";
(:
 : cprof.xqy
 :
 : Copyright (c) 2011 Michael Blakeley. All Rights Reserved.
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 : http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :
 : The use of the Apache License does not indicate that this project is
 : affiliated with the Apache Software Foundation.
 :
 :)
module namespace p = "com.blakeley.cprof";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace xe = "xdmp:eval";

declare private variable $STACK as element(prof:report)* := () ;

declare private variable $IS-DISABLED as xs:boolean := true() ;

declare private function p:push(
  $list as item()+)
as item()*
{
  let $report as element(prof:report) := subsequence($list, 1, 1)
  let $push := xdmp:set($STACK, ($STACK, $report))
  return subsequence($list, 2)
};

declare private function p:reports-merge(
  $parent as element(prof:report))
as element(prof:report)
{
  element prof:report {
    $parent/@*,
    $parent/prof:metadata,
    element prof:histogram {
      (: TODO consider stripping out
       : $parent/prof:histogram/prof:expression[
       :   matches(
       :     prof:expr-source,
       :     '^prof:(eval|invoke|value|xslt-eval|xslt-invoke)\(') ]
       : Doing so would avoid showing the same elapsed time twice,
       : but might make it harder to track down which eval is which.
       : All nested expressions would tend to look like '.main:  1:  0' in cq.
       :)
      $parent/prof:histogram/node(),
      $STACK/prof:histogram/node()
    }
  }
};

declare function p:enabled()
as xs:boolean
{
  not($IS-DISABLED)
};

declare function p:enable()
as empty-sequence()
{
  xdmp:set($IS-DISABLED, false()),
  prof:enable(xdmp:request())
};

declare function p:disable()
as empty-sequence()
{
  xdmp:set($IS-DISABLED, true())
};

declare function p:eval(
  $xquery as xs:string,
  $vars as item()*,
  $options as element(xe:options)?)
as item()*
{
  if ($IS-DISABLED) then xdmp:eval($xquery, $vars, $options)
  else p:push(prof:eval($xquery, $vars, $options))
};

declare function p:eval(
  $xquery as xs:string,
  $vars as item()*)
as item()*
{
  p:eval($xquery, $vars, ())
};

declare function p:eval(
  $xquery as xs:string)
as item()*
{
  p:eval($xquery, (), ())
};

declare function p:invoke(
  $path as xs:string,
  $vars as item()*,
  $options as element(xe:options)?)
as item()*
{
  if ($IS-DISABLED) then xdmp:invoke($path, $vars, $options)
  else p:push(prof:invoke($path, $vars, $options))
};

declare function p:invoke(
  $path as xs:string,
  $vars as item()*)
as item()*
{
  p:invoke($path, $vars, ())
};

declare function p:invoke(
  $path as xs:string)
as item()*
{
  p:invoke($path, (), ())
};

declare function p:value(
  $expr as xs:string)
as item()*
{
  if ($IS-DISABLED) then xdmp:value($expr)
  else p:push(prof:value($expr))
};

declare function p:reset()
as empty-sequence()
{
  if ($IS-DISABLED) then ()
  else (
    prof:reset(xdmp:request()),
    xdmp:set($STACK, ()))
};

declare function p:report(
  $merge as xs:boolean)
as element(prof:report)*
{
  if ($IS-DISABLED) then ()
  else if (not($merge)) then (
    prof:report(xdmp:request()),
    $STACK)
  else p:reports-merge(prof:report(xdmp:request()))
};

declare function p:report()
as element(prof:report)*
{
  p:report(false())
};

declare function p:xslt-eval(
  $stylesheet as element(),
  $input as node()?,
  $params as map:map?,
  $options as element(xe:options)?)
as item()*
{
  if ($IS-DISABLED) then xdmp:xslt-eval(
    $stylesheet, $input, $params, $options)
  else p:push(
    prof:xslt-eval($stylesheet, $input, $params, $options))
};

declare function p:xslt-eval(
  $stylesheet as element(),
  $input as node()?,
  $params as map:map)
as item()*
{
  p:xslt-eval($stylesheet, $input, $params, ())
};

declare function p:xslt-eval(
  $stylesheet as element(),
  $input as node()?)
as item()*
{
  p:xslt-eval($stylesheet, $input, (), ())
};

declare function p:xslt-invoke(
  $path as xs:string,
  $input as node()?,
  $params as map:map?,
  $options as element(xe:options)?)
as item()*
{
  if ($IS-DISABLED) then xdmp:xslt-invoke(
    $path, $input, $params, $options)
  else p:push(
    prof:xslt-invoke($path, $input, $params, $options))
};

declare function p:xslt-invoke(
  $path as xs:string,
  $input as node()?,
  $params as map:map)
as item()*
{
  p:xslt-invoke($path, $input, $params, ())
};

declare function p:xslt-invoke(
  $path as xs:string,
  $input as node()?)
as item()*
{
  p:xslt-invoke($path, $input, (), ())
};

(: cprof.xqy :)
