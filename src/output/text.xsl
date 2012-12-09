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
    <xsl:value-of select="', Errors', count(xray:module/xray:test[@result='error'])" />
    <xsl:value-of select="', Passed', count(xray:module/xray:test[@result='passed'])" /> 
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
