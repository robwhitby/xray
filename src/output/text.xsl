<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		            xmlns:x="http://github.com/robwhitby/xray"
                version="2.0">

  <xsl:output method="xml" omit-xml-declaration="yes"/>

  <xsl:template match="x:tests">
    <xsl:apply-templates/>
    <xsl:value-of select="'Finished: Total', count(x:module/x:test)" />
    <xsl:value-of select="', Failed', count(x:module/x:test[@result='Failed'])" />
    <xsl:value-of select="', Passed', count(x:module/x:test[@result='Passed'])" />
  </xsl:template>

  <xsl:template match="x:module[x:test]">
    <xsl:text>Module </xsl:text><xsl:value-of select="@path, '&#10;'"/>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="x:test">
    <xsl:value-of select="'--', @name, '--', upper-case(@result), '&#10;'"/>
    <xsl:apply-templates select="x:failed"/>
  </xsl:template>

  <xsl:template match="x:failed">
    <xsl:copy-of select="."/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
