xquery version "1.0-ml";

(: coverage.xqy
 :
 : Library functions for code coverage.
 :
 : @author Michael Blakeley
 :
 : Modified by Rob Whitby
 :)

module namespace cover="http://github.com/robwhitby/xray/coverage";

import module namespace log="http://github.com/robwhitby/xray/logging"
  at "logging.xqy";
import module namespace modules="http://github.com/robwhitby/xray/modules"
  at "modules.xqy";

declare default element namespace "http://github.com/robwhitby/xray";

(: Half a million lines of XQuery ought to be enough for any module. :)
declare variable $LIMIT as xs:integer := 654321 ;

declare private function cover:_put(
  $map as map:map,
  $key as xs:string)
{
  map:put($map, $key, $key)
};

declare private function cover:_put-new(
  $map as map:map,
  $key as xs:string)
{
  if (fn:exists(map:get($map, $key))) then ()
  else cover:_put($map, $key)
};

declare private function cover:_map-from-sequence(
  $map as map:map,
  $seq as xs:integer*)
{
  cover:_put($map, xs:string($seq)),
  $map
};

declare private function cover:_map-from-sequence(
  $seq as xs:integer*)
{
  cover:_map-from-sequence(map:map(), $seq)
};

declare private function cover:_task-cancel-safe(
  $id as xs:unsignedLong)
{
  try {
    xdmp:request-cancel(
      xdmp:host(), xdmp:server("TaskServer"), $id) }
  catch ($ex) {
    if ($ex/error:code eq 'XDMP-NOREQUEST') then ()
    else xdmp:rethrow() }
};

declare private function cover:_prepare-from-request(
  $request as xs:unsignedLong,
  $uri as xs:string,
  $limit as xs:integer,
  $results-map as map:map)
{
  if (not($log:DEBUG)) then () else log:debug(
    'cover:_prepare-from-request',
    ('request', $request, 'module', $uri)),

  try {
    let $lines-map := map:get($results-map, $uri)[2]
    (: Semi-infinite loop, to be broken using DBG-LINE.
     : This avoids stack overflow errors.
     :)
    for $line in 1 to $limit
    (: We only need to break once per line, but we set a breakpoint
     : on every expression to maximize the odds of seeing that line.
     : But dbg:line will return the same expression more than once,
     : at the start of a module or when it sees an expression
     : that covers multiple lines. So we call dbg:expr for the right info.
     : Faster to loop once and call dbg:expr many extra times,
     : or gather all unique expr-ids and then loop again?
     : Because of the loop-break technique, one loop is easier.
     :)
    for $expr-id in dbg:line($request, $uri, $line)
    let $set := dbg:break($request, $expr-id)
    let $expr := dbg:expr($request, $expr-id)
    let $key := $expr/dbg:line/fn:string()
    where fn:not(map:get($lines-map, $key))
    return cover:_put($lines-map, $key),
    (: We should always hit EOF and DBG-LINE before this.
     : Tell the caller that we could not do it.
     :)
    cover:_task-cancel-safe($request),
    fn:error(
      (), 'XRAY-TOOBIG',
      ('Module is too large for code coverage limit:', $limit)) }
  catch ($ex) {
    if ($ex/error:code = ("DBG-LINE")) then ()
    else (
      (: Avoid leaving tasks in error state on the task server. :)
      cover:_task-cancel-safe($request),
      xdmp:rethrow()) }
};

declare private function cover:_prepare-R(
  $fn as xdmp:function,
  $rest as xdmp:function*,
  $results-map as map:map*,
  $path as xs:string)
{
  (: TODO implement caching :)
  if (not($log:DEBUG)) then () else log:debug(
    'cover:_prepare-R',
    ('function', fn:string(xdmp:function-name($fn)), fn:count($rest))),

  let $modules := map:keys($results-map)
  let $request := dbg:eval(cover:query($fn, $path))
  let $_ := _prepare-from-request($request, $modules, $LIMIT, $results-map)
  let $_ := _task-cancel-safe($request)
  let $modules-remaining := (
    for $uri in $modules
    let $_ := if (not($log:DEBUG)) then () else log:debug(
      'cover:_prepare-R', ('module', $uri))
    where map:count(map:get($results-map, $uri)[2]) eq 0
    return $uri)
  (: Continue recursion until we run out of modules or functions.
   : If we run out of functions, the results will show 0 lines to be covered.
   :)
  return
    if (fn:empty($modules-remaining)) then ()
    else if (fn:empty($rest)) then ()
    else cover:_prepare-R($rest[1], fn:subsequence($rest, 2), $results-map, $path)
};

(:~
 : This function prepares code coverage information for the specified modules.
 :)
declare private function cover:_prepare(
  $modules as xs:string+,
  $functions as xdmp:function*,
  $results-map as map:map,
  $path as xs:string)
as map:map
{
  (: When this comes back, each map key will have two entries:
   : covered-lines-map, wanted-lines-map.
   : The wanted-lines-map will be an identity map.
   :)
  for $m in $modules
  return map:put($results-map, $m, (map:map(), map:map()))
  ,
  cover:_prepare-R(
    $functions[1], fn:subsequence($functions, 2), $results-map, $path)
  ,
  $results-map
};

(:~
 : This function prepares code coverage information for the specified modules.
 :)
declare function cover:prepare(
  $modules as xs:string*,
  $functions as xdmp:function*,
  $path as xs:string)
as map:map?
{
  if (fn:not($modules)) then ()
  else cover:_prepare($modules, $functions, map:map(), $path)
};

declare private function cover:_result(
  $name as xs:string,
  $map as map:map)
{
  element { $name } {
    attribute count { map:count($map) },
    for $line in xs:integer(map:keys($map))
    order by $line
    return $line
  }
};

declare function cover:results(
  $results-map as map:map,
  $results as item()*)
{
  (: TODO if we bring in cprof this will need to change. :)
  $results[fn:not(. instance of element(prof:report))]
  ,
  (: report test-level coverage data :)
  let $modules := map:keys($results-map)
  let $do := (
    (: Populate the coverage maps from the profiler output. :)
    for $expr in $results[
      . instance of element(prof:report)]/prof:histogram/prof:expression[
      prof:uri = $modules]
    let $m := map:get($results-map, $expr/prof:uri)[1]
    let $key := $expr/prof:line/fn:string()
    where fn:not(map:get($m, $key))
    return cover:_put($m, $key))
  for $uri in $modules
  let $seq := map:get($results-map, $uri)
  let $covered := $seq[1]
  let $wanted := $seq[2]
  let $assert := (
    if (not($log:DEBUG and map:count($covered - $wanted) gt 0)) then ()
    else log:warning(
      'cover:results',
      ($uri, "more coverage than expected: lines = ",
        map:keys($covered - $wanted))))
  order by $uri
  return element coverage {
    attribute uri { $uri },
    cover:_result('wanted', $wanted),
    cover:_result('covered', $covered),
    cover:_result('missing', $wanted - $covered)
  }
};

declare function cover:transform(
  $tests as element()
)
{
  element { fn:node-name($tests) } {
    $tests/(@*|node()),
    let $map := map:map()
    let $do := (
      for $c in $tests/module/test/coverage
      let $uri := $c/@uri/fn:string()
      let $old := map:get($map, $uri)
      let $old := (
        (: Do we already have a 'wanted' list for this uri? :)
        if (fn:exists($old)) then $old else (
          let $new := (map:map(), map:map())
          let $put := map:put($map, $uri, $new)
          return $new))
      let $covered := $old[1]
      let $wanted := $old[2]
      let $do := (
        cover:_put-new($covered, xs:NMTOKENS($c/covered)),
        if (map:count($wanted) or 0 eq $c/wanted/@count) then ()
        else cover:_put-new($wanted, xs:NMTOKENS($c/wanted)))
      return ())
    let $seq := map:get($map, '*')
    let $covered-count := fn:sum(
      for $uri in map:keys($map)
      return map:count(map:get($map, $uri)[1]))
    let $wanted-count := fn:sum(
      for $uri in map:keys($map)
      return map:count(map:get($map, $uri)[2]))
    return element coverage-summary {
      attribute wanted-count { $wanted-count },
      attribute covered-count { $covered-count },
      attribute missing-count { $wanted-count - $covered-count },
      (: by module :)
      for $uri in map:keys($map)
      let $seq := map:get($map, $uri)
      let $covered := $seq[1]
      let $wanted := $seq[2]
      order by $uri
      return element module-coverage {
        attribute uri { $uri },
        cover:_result('wanted', $wanted),
        cover:_result('covered', $covered),
        cover:_result('missing', $wanted - $covered)
      }
    }
  }
};

declare function cover:module-view-text(
  $module as xs:string,
  $lines as xs:string*,
  $wanted as map:map,
  $covered as map:map,
  $missing as map:map)
{
  text { 'Module', $module },
  for $i at $x in $lines
  let $key := fn:string($x)
  return text {
    if (map:get($covered, $key)) then '+'
    else if (map:get($wanted, $key)) then '!'
    else ' ',
    $x, $i }
};

declare function cover:module-view-xml(
  $module as xs:string,
  $lines as xs:string*,
  $wanted as map:map,
  $covered as map:map,
  $missing as map:map)
{
  <module xmlns="http://github.com/robwhitby/xray">
  {
    attribute uri { $module },
    attribute covered { map:count($covered) },
    attribute wanted { map:count($wanted) },
    for $i at $x in $lines
    let $key := fn:string($x)
    return element line {
      attribute number { $x },
      attribute state {
        if (map:get($covered, $key)) then 'covered'
        else if (map:get($wanted, $key)) then 'wanted'
        else 'none'},
      $i }
  }
  </module>
};

declare function cover:module-view(
  $module as xs:string,
  $format as xs:string,
  $lines as xs:string*,
  $wanted as map:map,
  $covered as map:map,
  $missing as map:map)
{
  if ($format eq "html") then
    xdmp:xslt-invoke(
      fn:concat("output/coverage/", $format, ".xsl"),
      cover:module-view-xml($module, $lines, $wanted, $covered, $missing)
    )
  else if ($format eq "text") then cover:module-view-text($module, $lines, $wanted, $covered, $missing)
  else if ($format eq "xml") then cover:module-view-xml($module, $lines, $wanted, $covered, $missing)
  else fn:error((), "XRAY-BADFORMAT", ("Format invalid for code coverage view: ", $format))
};


declare function cover:module-view(
  $module as xs:string,
  $format as xs:string,
  $lines as xs:string*,
  $wanted as map:map,
  $covered as map:map
)
{
  cover:module-view(
    $module, $format, $lines, $wanted, $covered, $wanted - $covered)
};


declare function cover:module-view(
  $module as xs:string,
  $format as xs:string,
  $wanted as xs:integer*,
  $covered as xs:integer*
)
{
  let $source :=
    try {
      fn:tokenize(modules:get-module($module, fn:false()), '\n')
    } catch ($ex) {
      $ex/error:format-string
    }

  return cover:module-view(
    $module,
    $format,
    $source,
    cover:_map-from-sequence($wanted),
    cover:_map-from-sequence($covered)
  )
};


declare private function cover:query(
  $fn as xdmp:function,
  $path as xs:string,
  $qn as xs:QName
) as xs:string
{
  concat(
    'xquery version "1.0-ml"; ',
    'import module namespace t="',
    fn:namespace-uri-from-QName($qn),
    '" at "', $path, '"; ',
    't:', fn:local-name-from-QName($qn), '()')
};

declare private function cover:query(
  $fn as xdmp:function,
  $path as xs:string
) as xs:string
{
  cover:query($fn, $path, xdmp:function-name($fn))
};

(: src/coverage.xqy :)