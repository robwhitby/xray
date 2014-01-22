<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		            xmlns:xray="http://github.com/robwhitby/xray"
                xmlns:error="http://marklogic.com/xdmp/error"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:xray-json="http://github.com/robwhitby/xray/json"
                xmlns:json="http://json.org/"
                exclude-result-prefixes="xdmp"
                extension-element-prefixes="xdmp"
                version="2.0">

  <xdmp:import-module href="json.xqy" namespace="http://github.com/robwhitby/xray/json"/>

  <xsl:template match="xray:tests">
    <xsl:value-of select="xray-json:to-json(.)"/>
  </xsl:template>

</xsl:stylesheet>
