<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xray="http://github.com/robwhitby/xray"
                xmlns:error="http://marklogic.com/xdmp/error"
                xmlns:prof="http://marklogic.com/xdmp/profile"
                version="2.0">

  <xsl:output method="xml" omit-xml-declaration="yes"/>

  <xsl:template match="prof:report"/>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>