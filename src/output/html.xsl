<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xray="http://github.com/robwhitby/xray"
                xmlns:xdmp="http://marklogic.com/xdmp"
                version="2.0"
                exclude-result-prefixes="xray xdmp">

  <xsl:output method="html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="test-dir"/>
  <xsl:param name="module-pattern"/>
  <xsl:param name="test-pattern"/>

  <xsl:template match="xray:tests">
    <xsl:text>&lt;!DOCTYPE html&gt;</xsl:text>
    <html>
      <head>
        <title>xray</title>
        <link rel="icon" type="image/png" href="favicon.png" />
        <xsl:call-template name="css"/>
      </head>
      <body>
        <xsl:call-template name="header"/>
        <xsl:apply-templates/>
        <xsl:call-template name="summary"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="xray:module[xray:test]">
    <div class="module">
      <h3><xsl:value-of select="@path"/></h3>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="xray:test">
    <h4 class="{@result}"><xsl:value-of select="@name, '--', upper-case(@result)"/></h4>
    <xsl:call-template name="result"/>
  </xsl:template>

  <xsl:template name="result">
    <xsl:if test="@result = 'failed'">
      <pre><xsl:value-of select="xdmp:quote(.)"/></pre>
    </xsl:if>
  </xsl:template>

  <xsl:template name="header">
      <h1><a href="http://github.com/robwhitby/xray">xray</a></h1>
      <form>
        <label for="test-dir"><abbr title="test directory path relative from app server root">directory</abbr></label>
        <input type="text" name="dir" id="test-dir" value="{$test-dir}"/>
        <label for="module-pattern"><abbr title="regex match on module name">modules</abbr></label>
        <input type="text" name="modules" id="module-pattern" value="{$module-pattern}"/>
        <label for="test-pattern"><abbr title="regex match on test name">tests</abbr></label>
        <input type="text" name="tests" id="test-pattern" value="{$test-pattern}"/> 
        <input type="hidden" name="format" value="html"/>
        <button>run</button>
      </form>
  </xsl:template>

  <xsl:template name="summary">
    <p id="summary">
      <xsl:choose>
        <xsl:when test="xray:module/xray:test">
          <xsl:attribute name="class">
            <xsl:choose>
                <xsl:when test="xray:module/xray:test[@result='failed']">failed</xsl:when>
                <xsl:otherwise>passed</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:value-of select="'Finished: Total', count(xray:module/xray:test)" />
          <xsl:value-of select="', Failed', count(xray:module/xray:test[@result='failed'])" />
          <xsl:value-of select="', Ignored', count(xray:module/xray:test[@result='ignored'])" />
          <xsl:value-of select="', Passed', count(xray:module/xray:test[@result='passed'])" />
        </xsl:when>
        <xsl:otherwise>
          No matching tests found
        </xsl:otherwise>
      </xsl:choose>
    </p>
    <p>
      <xsl:variable name="qs" select="concat('?dir=', $test-dir, 
                                            '&amp;modules=', encode-for-uri($module-pattern), 
                                            '&amp;tests=', encode-for-uri($test-pattern), 
                                            '&amp;format=')"/>
      View as <a href="{$qs}xml">xml</a>&#160;<a href="{$qs}text">text</a>
    </p>
  </xsl:template>

  <xsl:template name="css">
    <style type="text/css">
      body { margin: 0 10px; }
      body, input, button { font-family: "Courier New",Sans-serif; }
      h1 { margin: 0 0 30px 0; }
      h1 a:link, h1 a:visited, h1 a:hover, h1 a:active { padding: 10px 10px; text-decoration:none; color: #fff; background-color: #000; border: 1px solid #000; }
      h1 a:hover { color: #000; background-color: #fff; }
      h3, h4, pre { margin: 0; padding: 5px 10px; font-weight: normal; }
      h3 { background-color: #eee; }
      label { padding-left: 10px; }
      abbr, .abbr { border-bottom: 1px dotted #ccc; }
      form { position: absolute; top: 10px; right: 10px; }
      #summary { font-weight: bold; }
      .module { border: 1px solid #ccc; margin: 10px 0; }
      .failed { color: red; }
      .passed { color: green; }
    </style>
  </xsl:template>

</xsl:stylesheet>
