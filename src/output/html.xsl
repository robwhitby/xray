<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xray="http://github.com/robwhitby/xray"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:error="http://marklogic.com/xdmp/error"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
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
            <footer>
              <xsl:call-template name="summary"/>
              <xsl:call-template name="format-links"/>
            </footer>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="no-tests"/>
          </xsl:otherwise>
        </xsl:choose>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="xray:module">
    <section>
      <details open="true">
        <summary>
          <xsl:attribute name="class">
            <xsl:choose>
              <xsl:when test="@failed ne '0' or @error ne '0'">failed</xsl:when>
              <xsl:when test="@ignored ne '0'">ignored</xsl:when>
              <xsl:otherwise>passed</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <a href="{xray:url(@path, (), 'html')}" title="run this module only"><xsl:value-of select="@path"/></a>
        </summary>
        <xsl:apply-templates/>
      </details>
    </section>
  </xsl:template>

  <xsl:template match="xray:test">
    <h4 class="{@result}">
      <a href="{xray:url(../@path, @name, 'html')}" title="run this test only">
        <xsl:value-of select="@name, '--', upper-case(@result), ' ', xray:format-time(.)"/>
      </a>
    </h4>
    <xsl:if test="@result = 'failed'">
      <pre><xsl:value-of select="xdmp:quote(xray:assert[@result='failed'])"/></pre>
    </xsl:if>
    <xsl:if test="@result = 'error'">
      <xsl:apply-templates/>
    </xsl:if>
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
        <button>run</button>
      </form>
    </header>
  </xsl:template>

  <xsl:template match="error:error">
    <xsl:if test="error:message/text()">
      <pre><xsl:value-of select="error:message"/></pre>
    </xsl:if>
    <xsl:if test="error:format-string/text()">
      <pre><xsl:value-of select="error:format-string"/></pre>
    </xsl:if>
    <pre class="error"><xsl:value-of select="xdmp:quote(.)"/></pre>
  </xsl:template>

  <xsl:template name="summary">
    <p>
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="xray:module[xray:test/@result = ('failed','error')]">failed</xsl:when>
          <xsl:when test="xray:module[xray:test/@result = 'ignored']">ignored</xsl:when>
          <xsl:otherwise>passed</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:value-of select="'Summary: Total', count(xray:module/xray:test)" />
      <xsl:value-of select="', Failed', count(xray:module/xray:test[@result='failed'])" />
      <xsl:value-of select="', Ignored', count(xray:module/xray:test[@result='ignored'])" />
      <xsl:value-of select="', Errors', count(xray:module/xray:test[@result='error'])" />
      <xsl:value-of select="', Passed', count(xray:module/xray:test[@result='passed'])" />
    </p>
  </xsl:template>

  <xsl:template name="format-links">
    <p>
      View results as
      <a href="{xray:url($module-pattern, $test-pattern, 'xml')}">xml</a>
      <xsl:text>&#160;|&#160;</xsl:text>
      <a href="{xray:url($module-pattern, $test-pattern, 'xunit')}">xUnit</a>
      <xsl:text>&#160;|&#160;</xsl:text>
      <a href="{xray:url($module-pattern, $test-pattern, 'text')}">text</a>
      <xsl:text>&#160;|&#160;</xsl:text>
      <a href="{xray:url($module-pattern, $test-pattern, 'json')}">json</a>
      <br/>
      <a href="http://github.com/robwhitby/xray">xray</a> version <xsl:value-of select="/@xray-version"/>
    </p>
  </xsl:template>


  <xsl:template name="no-tests">
    <section>
      <details open="true">
        <summary>No matching tests found at <xsl:value-of select="xdmp:modules-root()"/><xsl:value-of select="$test-dir"/></summary>
        <pre class="code">
<span class="c">(: sample test module :)</span>

xquery version <span class="s">"1.0-ml"</span>;
module namespace test = <span class="s">"http://github.com/robwhitby/xray/test"</span>;
import module namespace assert = <span class="s">"http://github.com/robwhitby/xray/assertions"</span> at <span class="s">"/xray/src/assertions.xqy"</span>;

declare %test:case function <span class="f">node-should-equal-foo</span> ()
{
    let <span class="v">$node</span> := <span class="x">&lt;foo/&gt;</span>
    return <span class="f">assert:equal</span>(<span class="v">$node</span>, <span class="x">&lt;foo/&gt;</span>)
};
        </pre>
      </details>
    </section>
  </xsl:template>


  <xsl:function name="xray:url" as="xs:string">
    <xsl:param name="module" as="xs:string"/>
    <xsl:param name="test" as="xs:string?"/>
    <xsl:param name="format" as="xs:string?"/>
    <xsl:value-of select="concat('?dir=', $test-dir, 
                                '&amp;modules=', encode-for-uri($module), 
                                '&amp;tests=', encode-for-uri($test), 
                                '&amp;format=', $format)"/>
  </xsl:function>

  <xsl:function name="xray:format-time" as="xs:string?">
    <xsl:param name="test" as="element(xray:test)"/>
    <xsl:if test="$test/@result != 'ignored'">
        <xsl:value-of select="' -- ', substring($test/@time, 3)"/>
    </xsl:if>
  </xsl:function>

  <xsl:template name="css">
    <link href='http://fonts.googleapis.com/css?family=Cousine:400,700' rel='stylesheet' type='text/css'/>
    <style type="text/css">
      body { margin: 0 10px; }
      body, input, button { font-family: Cousine, "Courier New", Sans-serif; }

      h1 { margin: 0 0 30px 0; }
      h1 a:link, h1 a:visited, h1 a:hover, h1 a:active {
        font-family: "Courier New", Sans-serif;
        padding: 10px 10px;
        text-decoration:none;
        color: #fff;
        background-color: #000;
        border: 1px solid #000;
        text-shadow: #fff 1px 1px 15px;
        -webkit-font-smoothing: antialiased;
      }
      h1 a:hover { color: #000; background-color: #fff; }

      summary, h4, pre { margin: 0; padding: 5px 10px; font-weight: normal; }
      summary { background-color: #eee; }
      summary.passed { background-color: #393; }
      summary.failed, h3.error { background-color: #c33; }
      summary.ignored { background-color: #f80; }
      summary a { color: white; text-decoration: none; }
      summary a:hover { text-decoration: underline; }
      h4 a { text-decoration: none; }
      h4 a:hover { text-decoration: underline; }

      p.failed, h4.failed a, p.error, h4.error a { color: #c33; }
      p.ignored, h4.ignored a { color: #f80; }
      p.passed, h4.passed a { color: #393; }

      label { padding-left: 10px; }
      abbr, .abbr { border-bottom: 1px dotted #ccc; }
      form { position: absolute; top: 10px; right: 10px; }
      section { border: 1px solid #ccc; margin: 10px 0; }

      .code .c { color: #999; }
      .code .s { color: #d00; }
      .code .v { color: purple; }
      .code .f { color: blue; }
      .code .x { color: #090; }

      summary::-webkit-details-marker {
        color: #fff;
        margin-right: 2px;
      }
      summary:focus { outline-style: none; }
    </style>
  </xsl:template>

</xsl:stylesheet>
