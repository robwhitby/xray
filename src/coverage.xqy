xquery version "1.0-ml";

(: coverage.xqy
 :
 : Library functions for code coverage.
 :
 : @author Michael Blakeley
 :
 : Modified by Rob Whitby
 :)

module namespace cover = "http://github.com/robwhitby/xray/coverage";

import module namespace modules = "http://github.com/robwhitby/xray/modules" at "modules.xqy";

declare default element namespace "http://github.com/robwhitby/xray";

declare private variable $NBSP := fn:codepoints-to-string(160);
declare private variable $DEBUG := fn:false();

declare private function cover:_sequence-from-map(
  $map as map:map)
{
  for $k in map:keys($map)
  order by $k
  return xs:integer($k)
};

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

(:
 : This function stops on breakpoints, updating the results map.
 : This is dead code, but might come in handy some time.
 :)
declare private function cover:actual-via-debug(
  $request as xs:unsignedLong,
  $modules as xs:string+,
  $results-map as map:map)
{
  (: Advance to the first breakpoint. :)
  dbg:finish($request),
  (: Conserve stack space by using a loop instead of recursion. :)
  try {
    let $timeout := 125
    for $i in 1 to 7654321
    let $status := dbg:status($request)
    let $expr-id := $status/dbg:request/dbg:expr-id/fn:data(.)
    (: If there is no expression and the request is not running, we are done. :)
    let $is-running := ($status/dbg:request/dbg:request-status = 'running')
    let $should-wait := fn:not($expr-id) and $is-running
    let $is-break := fn:not($expr-id) and fn:not($is-running)
    let $maybe-detach :=
      if (fn:not($is-break) or fn:empty($status/dbg:request)) then ()
      else
        try { dbg:detach($request) }
        catch ($ex) {
          if (fn:not($ex/error:code = 'DBG-REQUESTRECORD')) then xdmp:rethrow()
          else () }
    return
      if ($is-break) then fn:error((), 'XRAY-BREAKLOOP')
      else if ($should-wait) then dbg:wait($request, $timeout)
      else
        let $expr as element() := dbg:expr($request, $expr-id)
        let $uri := ($expr/dbg:uri/fn:string(), '')[1]
        let $map := map:get($results-map, $uri)[1]
        let $key := $expr/dbg:line/fn:string()
        (: In theory we should never put the same key twice. :)
        let $put := cover:_put($map, $key)
        let $clear := dbg:clear($request, $expr-id)
        let $continue := dbg:continue($request)
        return dbg:wait($request, $timeout) }
  catch ($ex) {
    if (fn:not($ex/error:code = 'XRAY-BREAKLOOP')) then xdmp:rethrow()
    else () }
};

declare function cover:cover(
  $request as xs:unsignedLong,
  $modules as xs:string+,
  $results-map as map:map)
{
  cover:actual-via-debug($request, $modules, $results-map)
  ,
  if ($DEBUG) then
    for $uri in $modules
    let $map := map:get($results-map, $uri)[1]
    return xdmp:log(text { 'DEBUG', $uri, 'actual', map:count($map), 'lines' })
  else ()
  ,
  (: reprocess :)
  for $key in map:keys($results-map)
  let $seq := map:get($results-map, $key)
  let $actual := $seq[1]
  let $wanted := $seq[2]
  let $assert :=
    if (map:count($actual - $wanted) eq 0) then ()
    else fn:error((), 'BAD', map:keys($actual - $wanted))
  order by $key
  return element coverage {
    attribute uri { $key },
    element wanted {
      for $line in xs:integer(map:keys($wanted))
      order by $line
      return $line },
    element actual {
      for $line in xs:integer(map:keys($actual))
      order by $line
      return $line },
    element missing {
      for $line in xs:integer(map:keys($wanted - $actual))
      order by $line
      return $line } }
};

declare private function cover:_prepare-from-request(
  $request as xs:unsignedLong,
  $uri as xs:string,
  $results-map as map:map)
{
  if ($DEBUG) then xdmp:log(text { 'DEBUG request', $request, 'module', $uri }) else (),
  try {
    let $lines-map := map:get($results-map, $uri)[2]
    (: Semi-infinite loop, to be broken using DBG-LINE.
     : This avoids stack overflow errors.
     : Half a million lines of XQuery ought to be enough for any module.
     :)
    for $line in 1 to 654321
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
    return cover:_put($lines-map, $key) }
  catch ($ex) {
    if (fn:not($ex/error:code = ("DBG-LINE", "DBG-MODULEDNE"))) then xdmp:rethrow()
    else ()
  }
};

declare private function cover:_prepare-R(
  $fn as xdmp:function,
  $rest as xdmp:function*,
  $results-map as map:map*,
  $path as xs:string)
{
  (: TODO implement caching :)
  if ($DEBUG) then xdmp:log(text { 'DEBUG function', fn:string(xdmp:function-name($fn)), fn:count($rest) }) else (),
  let $modules := map:keys($results-map)
  let $request := dbg:eval(cover:query($fn, $path))
  let $do := (
    _prepare-from-request($request, $modules, $results-map),
    xdmp:request-cancel(xdmp:host(), xdmp:server("TaskServer"), $request))
  let $modules-remaining :=
    for $uri in $modules
    where map:count(map:get($results-map, $uri)[2]) eq 0
    return $uri
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
  cover:_prepare-R($functions[1], fn:subsequence($functions, 2), $results-map, $path)
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
  $results as item()*,
  $did-succeed as xs:boolean)
{
  (: TODO if we bring in cprof this will need to change. :)
  $results[fn:not(. instance of element(prof:report))]
  ,
  if (fn:not($did-succeed)) then () else
  (: report test-level coverage data :)
  let $modules := map:keys($results-map)
  let $do := (
    (: Populate the coverage maps from the profiler output. :)
    for $expr in $results[
      . instance of element(prof:report)]/prof:histogram/prof:expression[
      prof:uri = $modules ]
    let $m := map:get($results-map, $expr/prof:uri)[1]
    let $key := $expr/prof:line/fn:string()
    where fn:not(map:get($m, $key))
    return cover:_put($m, $key))
  for $uri in $modules
  let $seq := map:get($results-map, $uri)
  let $covered := $seq[1]
  let $wanted := $seq[2]
  let $assert :=
    if (map:count($covered - $wanted) eq 0) then ()
    else fn:error((), 'BAD', map:keys($covered - $wanted))
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
  xdmp:set-response-content-type('text/plain'),
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
  cover:module-view($module, $format, $lines, $wanted, $covered, $wanted - $covered)
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
  $path as xs:string
) as xs:string
{
  'xquery version "1.0-ml";
  import module namespace t="' || fn:namespace-uri-from-QName(xdmp:function-name($fn)) || '" at "' || $path || '";
  t:' || fn:local-name-from-QName(xdmp:function-name($fn)) || '()'
};
