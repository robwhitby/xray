<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xray="http://github.com/robwhitby/xray"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:error="http://marklogic.com/xdmp/error"
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
        <link rel="icon" type="image/png" href="favicon.ico" />
        <xsl:call-template name="css"/>
      </head>
      <body>
        <xsl:call-template name="header"/>
        <xsl:apply-templates/>
        <xsl:choose>
          <xsl:when test="xray:module[xray:test|error:error]">
            <xsl:call-template name="summary"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="no-tests"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:call-template name="format-links"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="xray:module">
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
      <h1><a href="http://robwhitby.github.com/xray">xray</a></h1>
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

  <xsl:template match="error:error">
    <pre><xsl:value-of select="xdmp:quote(.)"/></pre>
  </xsl:template>

  <xsl:template name="summary">
    <p id="summary">  
      <xsl:attribute name="class">
        <xsl:choose>
            <xsl:when test="xray:module[xray:test/@result='failed' or error:error]">failed</xsl:when>
            <xsl:otherwise>passed</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:value-of select="'Finished: Total', count(xray:module/xray:test)" />
      <xsl:value-of select="', Failed', count(xray:module/xray:test[@result='failed'])" />
      <xsl:value-of select="', Ignored', count(xray:module/xray:test[@result='ignored'])" />
      <xsl:value-of select="', Errors', count(xray:module/error:error)" />
      <xsl:value-of select="', Passed', count(xray:module/xray:test[@result='passed'])" />
    </p>
  </xsl:template>

  <xsl:template name="format-links">
    <p>
      <xsl:variable name="qs" select="concat('?dir=', $test-dir, 
                                            '&amp;modules=', encode-for-uri($module-pattern), 
                                            '&amp;tests=', encode-for-uri($test-pattern), 
                                            '&amp;format=')"/>
      View results as <a href="{$qs}xml">xml</a>&#160;<a href="{$qs}text">text</a>
    </p>
  </xsl:template>


  <xsl:template name="no-tests">
    <h2>No matching tests found at <xsl:value-of select="xdmp:modules-root()"/><xsl:value-of select="$test-dir"/></h2>
    <div class="module">
      <h3>Sample test module</h3>
      <pre class="code">xquery version <span class="s">"1.0-ml"</span>;
module namespace test = <span class="s">"http://github.com/robwhitby/xray/test"</span>;
import module namespace assert = <span class="s">"http://github.com/robwhitby/xray/assertions"</span> at <span class="s">"/xray/src/assertions.xqy"</span>;

declare function <span class="f">node-should-equal-foo</span> ()
{
    let <span class="v">$node</span> := <span class="x">&lt;foo/&gt;</span>
    return <span class="f">assert:equal</span>(<span class="v">$node</span>, <span class="x">&lt;foo/&gt;</span>)
};</pre>
    </div>
  </xsl:template>

  <xsl:template name="css">
    <style type="text/css">
      body { margin: 0 10px; }
      body, input, button { font-family: "Courier New",Sans-serif; }
      h1 { margin: 0 0 30px 0; }
      h1 a:link, h1 a:visited, h1 a:hover, h1 a:active { 
        padding: 10px 10px; 
        text-decoration:none; color: #fff;
        background-color: #000;
        border: 1px solid #000;
        text-shadow: #fff 1px 1px 15px;
        -webkit-font-smoothing: antialiased;
      }
      h1 a:hover { color: #000; background-color: #fff; }
      h3, h4, pre { margin: 0; padding: 5px 10px; font-weight: normal; }
      h3 { background-color: #eee; }
      label { padding-left: 10px; }
      abbr, .abbr { border-bottom: 1px dotted #ccc; }
      form { position: absolute; top: 10px; right: 10px; }
      #summary { font-weight: bold; }
      .module { border: 1px solid #ccc; margin: 10px 0; }
      .failed { color: red; }
      .ignored { color: orange; }
      .passed { color: green; }
      .code .s { color: red; }
      .code .v { color: purple; }
      .code .f { color: blue; }
      .code .x { color: green; }
    </style>
  </xsl:template>

</xsl:stylesheet>
