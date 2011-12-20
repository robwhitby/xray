<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		            xmlns:xray="http://github.com/robwhitby/xray"
                xmlns:xdmp="http://marklogic.com/xdmp"
                version="2.0"
                exclude-result-prefixes="xray xdmp">

  <xsl:output method="html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="xray:tests">
    <xsl:text>&lt;!DOCTYPE html&gt;</xsl:text>
    <html>
      <head>
        <title>XQTest Results</title>
        <xsl:call-template name="css"/>
      </head>
      <body>
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
    <xsl:apply-templates select="xray:assert"/>
  </xsl:template>

  <xsl:template match="xray:assert">
    <xsl:if test="@result = 'failed'">
      <pre><xsl:value-of select="xdmp:quote(.)"/></pre>
    </xsl:if>
  </xsl:template>
    
  <xsl:template name="summary">
    <p id="summary">
      <xsl:attribute name="class">
        <xsl:choose>
            <xsl:when test="xray:module/xray:test[@result='failed']">failed</xsl:when>
            <xsl:otherwise>passed</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:value-of select="'Finished: Total', count(xray:module/xray:test)" />
      <xsl:value-of select="', Failed', count(xray:module/xray:test[@result='failed'])" />
      <xsl:value-of select="', Passed', count(xray:module/xray:test[@result='passed'])" />
    </p>
  </xsl:template>

  <xsl:template name="css">
    <style type="text/css">
      body { margin: 10px; font-family: "Courier New",Sans-serif; }
      h3, h4, pre { margin: 0; padding: 5px 10px; font-weight: normal; }
      h3 { background-color: #eee; }
      #summary { font-weight: bold; }
      .module { border: 1px solid #ccc; margin: 10px 0; }
      .failed { color: red; }
      .passed { color: green; }
    </style>
  </xsl:template>

</xsl:stylesheet>
