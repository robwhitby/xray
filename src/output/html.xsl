<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xray="http://github.com/robwhitby/xray"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:error="http://marklogic.com/xdmp/error"
                xmlns:prof="http://marklogic.com/xdmp/profile"
                version="2.0"
                exclude-result-prefixes="xray xdmp">

  <xsl:output method="html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="module-pattern"/>
  <xsl:param name="profile"/>
  <xsl:param name="test-dir"/>
  <xsl:param name="test-pattern"/>

  <xsl:template match="xray:tests">
    <xsl:text>&lt;!DOCTYPE html&gt;</xsl:text>
    <html>
      <head>
        <title>xray</title>
        <link rel="icon" type="image/png" href="favicon.ico" />
        <link rel="stylesheet" type="text/css" href="xray.css" />
        <script language="JavaScript" type="text/javascript"
                src="jquery-1.8.2.min.js">
        </script>
        <script language="JavaScript" type="text/javascript"
                src="xray.js">
        </script>
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
    <div class="xray-test">
      <h4 class="{@result}">
        <xsl:value-of select="@name, '--', upper-case(@result)"/>
      </h4>
      <xsl:choose>
        <xsl:when test="@result = 'failed'">
          <xsl:variable name="result">
            <xsl:element name="{node-name(.)}">
              <xsl:copy-of select="@*"/>
              <xsl:copy-of select="node() except prof:report"/>
            </xsl:element>
          </xsl:variable>
          <pre><xsl:value-of select="xdmp:quote($result)"/></pre>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="prof:report"/>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

  <xsl:template match="prof:report">
    <!-- TODO show or hide table on click -->
    <div class="profile-report">
      <xsl:variable
          name="count"
          select="count(prof:histogram/prof:expression/prof:count)"/>
      <xsl:variable
          name="elapsed"
          select="data(prof:metadata/prof:overall-elapsed)"/>
      <div class="profile-control">
        <span class="profile-show">&#9660;</span>
        <span class="profile-hide">&#9650;</span>
        Profiled <xsl:value-of select="$count"/> expressions
        in <xsl:value-of select="$elapsed"/>
        (<xsl:value-of select="position()"/>).
      </div>
      <table class="profile-report">
        <tr>
          <th>location</th>
          <th>expression</th>
          <th>count</th>
          <th title="Time for this expression">shallow %</th>
          <th title="Time for this expression">shallow</th>
          <th title="Time for this expression and sub-expressions">deep %</th>
          <th title="Time for this expression and sub-expressions">deep</th>
        </tr>
        <xsl:for-each select="prof:histogram/prof:expression">
          <xsl:sort select="prof:shallow-time" order="descending"/>
          <tr>
            <td class="source-location">
              <xsl:value-of select="concat(prof:uri, ':', prof:line)"/>
            </td>
            <td class="source-expression">
              <xsl:value-of select="prof:expr-source"/>
            </td>
            <td class="prof-count">
              <xsl:value-of select="prof:count"/>
            </td>
            <td class="prof-shallow-percent">
              <xsl:value-of
                  select="round(100 * prof:shallow-time div $elapsed)"/>
            </td>
            <td class="prof-shallow-time">
              <xsl:value-of select="prof:shallow-time"/>
            </td>
            <td class="prof-deep-percent">
              <xsl:value-of
                  select="round(100 * prof:deep-time div $elapsed)"/>
            </td>
            <td class="prof-deep-time">
              <xsl:value-of select="prof:deep-time"/>
            </td>
          </tr>
        </xsl:for-each>
      </table>
    </div>
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
        <input type="hidden" name="profile" value="{$profile}"/>
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
      <xsl:variable name="qs"
                    select="concat('?dir=', $test-dir,
                            '&amp;modules=', encode-for-uri($module-pattern),
                            '&amp;profile=', $profile,
                            '&amp;tests=', encode-for-uri($test-pattern),
                            '&amp;format=')"/>
      View results as
      <a href="{$qs}xml">xml</a>&#160;|&#160;<a href="{$qs}xunit">xUnit</a>&#160;|&#160;<a href="{$qs}text">text</a>
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

</xsl:stylesheet>
