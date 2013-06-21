<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xray="http://github.com/robwhitby/xray"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:error="http://marklogic.com/xdmp/error"
                xmlns:prof="http://marklogic.com/xdmp/profile"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                version="2.0"
                exclude-result-prefixes="xray xdmp prof error xs">

  <xsl:output method="html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="coverage-modules"/>
  <xsl:param name="module-pattern"/>
  <xsl:param name="test-dir"/>
  <xsl:param name="test-pattern"/>

  <xsl:include href="common.xsl"/>

  <xsl:template match="xray:tests">
    <xsl:text>&lt;!DOCTYPE html&gt;</xsl:text>
    <html>
      <xsl:call-template name="html-head"/>
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

  <xsl:template match="xray:coverage-summary">
    <section>
      <details open="false">
        <summary>
          Code Coverage: <xsl:value-of select="xray:coverage-percent(xs:int(@covered-count), xs:int(@wanted-count))"/>%
        </summary>
        <ul>
          <xsl:apply-templates/>
        </ul>
      </details>
    </section>
  </xsl:template>

  <xsl:template match="xray:module-coverage">
    <xsl:variable name="link" select="concat('coverage.xqy?module=', encode-for-uri(@uri),
                                             '&amp;wanted=', encode-for-uri(xray:wanted/string()),
                                             '&amp;covered=', encode-for-uri(xray:covered/string()),
                                             '&amp;format=html')"/>
    <xsl:variable name="pct" select="xray:coverage-percent(xs:int(xray:covered/@count), xs:int(xray:wanted/@count))"/>
    <xsl:variable name="status">
      <xsl:choose>
        <xsl:when test="$pct eq 100">passed</xsl:when>
        <xsl:when test="$pct le 0">failed</xsl:when>
        <xsl:otherwise>ignored</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <li class="{$status}">
      <span class="pct"><xsl:value-of select="$pct"/>%</span>
      <a href="{$link}"><xsl:value-of select="@uri"/></a>
    </li>
  </xsl:template>

  <xsl:template match="prof:report"/>

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
        <ul>
          <xsl:apply-templates/>
        </ul>
      </details>
    </section>
  </xsl:template>

  <xsl:template match="xray:test">
    <li class="{@result}">
      <a href="{xray:url(../@path, @name, 'html')}" title="run this test only">
        <xsl:value-of select="@name, '--', upper-case(@result), ' ', xray:format-time(.)"/>
      </a>
      <xsl:if test="@result = 'failed'">
        <pre><xsl:value-of select="xdmp:quote(xray:assert[@result='failed'])"/></pre>
      </xsl:if>
      <xsl:if test="@result = 'error'">
        <xsl:apply-templates/>
      </xsl:if>
    </li>
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
    <p id="summary">
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
      <br/>
      <a href="http://github.com/robwhitby/xray">xray</a> version <xsl:value-of select="/@xray-version"/>
    </p>
  </xsl:template>


  <xsl:template name="no-tests">
    <section>
      <details open="true">
        <summary>
          No matching tests found at <xsl:value-of select="xdmp:modules-root()"/><xsl:value-of select="$test-dir"/>
        </summary>
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

    <xsl:variable name="qs-coverage-modules">
      <xsl:for-each select="$coverage-modules">
          <xsl:value-of select="concat('&amp;coverage-module=', encode-for-uri(.))" />
      </xsl:for-each>
    </xsl:variable>
    <xsl:value-of select="concat('?dir=', $test-dir,
                                '&amp;modules=', encode-for-uri($module), 
                                '&amp;tests=', encode-for-uri($test),
                                 $qs-coverage-modules,
                                '&amp;format=', $format)"/>
  </xsl:function>

  <xsl:function name="xray:format-time" as="xs:string?">
    <xsl:param name="test" as="element(xray:test)"/>
    <xsl:if test="$test/@result != 'ignored'">
        <xsl:value-of select="' -- ', substring($test/@time, 3)"/>
    </xsl:if>
  </xsl:function>


</xsl:stylesheet>
