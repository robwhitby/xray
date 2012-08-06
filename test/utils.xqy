xquery version "1.0-ml";

module namespace utils = "utils";

 
declare function upper($s as xs:string) as xs:string
{
  fn:upper-case($s)
};
