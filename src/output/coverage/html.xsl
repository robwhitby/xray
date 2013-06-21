<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xray="http://github.com/robwhitby/xray"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:error="http://marklogic.com/xdmp/error"
                xmlns:prof="http://marklogic.com/xdmp/profile"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                version="2.0"
                exclude-result-prefixes="xray xdmp prof error xs">

  <xsl:output method="html" omit-xml-declaration="no" indent="yes"/>

  <xsl:param name="coverage-modules"/>
  <xsl:param name="module-pattern"/>
  <xsl:param name="test-dir"/>
  <xsl:param name="test-pattern"/>

  <xsl:include href="../common.xsl"/>

  <xsl:template match="xray:module">
    <xsl:text>&lt;!DOCTYPE html&gt;</xsl:text>
    <html>
      <xsl:call-template name="html-head"/>
      <body>
        <xsl:call-template name="header"/>

        <section>
          <details open="true">
            <summary>
              Code Coverage: <xsl:value-of select="@uri"/>
            </summary>
            <ol class="coverage-source">
              <xsl:apply-templates/>
            </ol>
          </details>
        </section>

      </body>
    </html>
  </xsl:template>

  <xsl:template match="xray:line">
   <li class="{@state}">
     <pre><xsl:value-of select="."/></pre>
   </li>
  </xsl:template>



</xsl:stylesheet>
