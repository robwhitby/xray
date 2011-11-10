<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		            xmlns:t="http://xqueryhacker.com/xqtest"
                version="2.0">

  <xsl:output method="xml" omit-xml-declaration="yes"/>

  <xsl:template match="t:tests">
    <xsl:apply-templates/>
    <xsl:value-of select="'Finished: Total', count(t:module/t:test)" />
    <xsl:value-of select="', Failed', count(t:module/t:test[@result='Failed'])" />
    <xsl:value-of select="', Passed', count(t:module/t:test[@result='Passed'])" />
  </xsl:template>

  <xsl:template match="t:module[t:test]">
    <xsl:text>Module </xsl:text><xsl:value-of select="@path, '&#10;'"/>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="t:test">
    <xsl:value-of select="'--', @name, '--', upper-case(@result), '&#10;'"/>
    <xsl:apply-templates select="t:failed"/>
  </xsl:template>

  <xsl:template match="t:failed">
    <xsl:copy-of select="."/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
