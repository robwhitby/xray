<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xray="http://github.com/robwhitby/xray"
                xmlns:error="http://marklogic.com/xdmp/error"
                version="2.0">

  <xsl:output method="xml" omit-xml-declaration="yes"/>

  <xsl:template match="xray:tests">
    <xsl:apply-templates/>
    <xsl:value-of select="'Finished: Total', count(xray:module/xray:test)" />
    <xsl:value-of select="', Failed', count(xray:module/xray:test[@result='failed'])" />
    <xsl:value-of select="', Ignored', count(xray:module/xray:test[@result='ignored'])" />
    <xsl:value-of select="', Errors', count(xray:module/error:error)" />
    <xsl:value-of select="', Passed', count(xray:module/xray:test[@result='passed'])" />
  </xsl:template>

  <xsl:template match="xray:coverage-summary">
    <xsl:variable name="covered" select="@covered-count"/>
    <xsl:variable name="wanted" select="@wanted-count"/>
    <xsl:text>Code Coverage: </xsl:text>
    <xsl:value-of
        select="concat(round(100 * $covered div $wanted), '%')"/>
    <xsl:text>&#10;</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="xray:module-coverage">
    <xsl:variable name="covered" select="xray:covered/@count"/>
    <xsl:variable name="wanted" select="xray:wanted/@count"/>
    <xsl:text>-- </xsl:text>
    <xsl:value-of select="@uri"/>
    <xsl:text> -- </xsl:text>
    <xsl:value-of
        select="concat(round(100 * $covered div $wanted), '%')"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xray:module">
    <xsl:text>Module </xsl:text><xsl:value-of select="@path, '&#10;'"/>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="xray:test">
    <xsl:value-of select="'--', @name, '--', upper-case(@result), '&#10;'"/>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="error:error">
    <xsl:copy-of select="."/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="xray:assert">
    <xsl:if test="@result = 'failed'">
      <xsl:copy-of select="."/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
