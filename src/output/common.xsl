<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xray="http://github.com/robwhitby/xray"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:error="http://marklogic.com/xdmp/error"
                xmlns:prof="http://marklogic.com/xdmp/profile"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                version="2.0"
                exclude-result-prefixes="xray xdmp prof error xs">

  <xsl:template name="html-head">
    <head>
      <title>xray</title>
      <link rel="icon" type="image/png" href="favicon.ico" />
      <link href='http://fonts.googleapis.com/css?family=Cousine:400,700' rel='stylesheet' type='text/css'/>
      <link rel="stylesheet" type="text/css" href="src/output/xray.css" />
    </head>
  </xsl:template>

  <xsl:template name="header">
    <header>
      <h1><a href="http://robwhitby.github.com/xray">xray</a></h1>
      <form>
        <label for="test-dir"><abbr title="test directory path relative from app server root">directory</abbr></label>
        <input type="text" name="dir" id="test-dir" value="{$test-dir}"/>
        <label for="module-pattern"><abbr title="regex match on module name">modules</abbr></label>
        <input type="text" name="modules" id="module-pattern" value="{$module-pattern}"/>
        <label for="test-pattern"><abbr title="regex match on test name">tests</abbr></label>
        <input type="text" name="tests" id="test-pattern" value="{$test-pattern}"/>
        <input type="hidden" name="format" value="html"/>
        <xsl:for-each select="$coverage-modules">
          <input type="hidden" name="coverage-module" value="{.}"/>
        </xsl:for-each>
        <button>run</button>
      </form>
    </header>
  </xsl:template>

  <xsl:function name="xray:coverage-percent" as="xs:int">
    <xsl:param name="covered" as="xs:int"/>
    <xsl:param name="wanted" as="xs:int"/>
    <xsl:value-of select="if ($wanted ne 0) then min((100, round(100 * $covered div $wanted))) else 0"/>
  </xsl:function>


</xsl:stylesheet>