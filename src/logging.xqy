xquery version "1.0-ml";

module namespace m="http://github.com/robwhitby/xray/logging" ;

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $DEBUG := true() ;

declare function m:debug-set($debug as xs:boolean)
as empty-sequence() {
  xdmp:set($DEBUG, $debug)
};

declare function m:log(
  $label as xs:string,
  $list as xs:anyAtomicType*,
  $level as xs:string)
as empty-sequence()
{
  xdmp:log(text { '[xray/'||$label||']', $list }, $level)
};

declare function m:fine(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  if ($DEBUG) then m:log($label, $list, 'fine')
  else m:error('BADDEBUG', 'Modify the caller to check $m:DEBUG')
};

declare function m:debug(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  if ($DEBUG) then m:log($label, $list, 'debug')
  else m:error('BADDEBUG', 'Modify the caller to check $m:DEBUG')
};

declare function m:info(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  m:log($label, $list, 'info')
};

declare function m:warning(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  m:log($label, $list, 'warning')
};

declare function m:error(
  $code as xs:string,
  $items as item()*)
as empty-sequence()
{
  error((), 'APIDOC-'||$code, $items)
};

(: logging.xqy :)