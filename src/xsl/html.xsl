<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		            xmlns:t="http://github.com/robwhitby/xqtest"
                xmlns:xdmp="http://marklogic.com/xdmp"
                version="2.0"
                exclude-result-prefixes="t xdmp">

  <xsl:output method="html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="t:tests">
    <xsl:text>&lt;!DOCTYPE html&gt;</xsl:text>
    <html>
      <head>
        <title>XQTest Results</title>
        <xsl:call-template name="css"/>
      </head>
      <body>
        <xsl:apply-templates/>
        <xsl:call-template name="finished"/>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="t:module[t:test]">
    <div class="module">
      <h3>Module <xsl:value-of select="@path"/></h3>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="t:test">
    <h4 class="{@result}"><xsl:value-of select="@name, '--', upper-case(@result)"/></h4>
    <xsl:apply-templates select="t:failed"/>
  </xsl:template>

  <xsl:template match="t:failed">
    <pre><xsl:value-of select="xdmp:quote(.)"/></pre>
  </xsl:template>
    
  <xsl:template name="finished">
    <p>
      <xsl:value-of select="'Finished: Total', count(t:module/t:test)" />
      <xsl:value-of select="', Failed', count(t:module/t:test[@result='Failed'])" />
      <xsl:value-of select="', Passed', count(t:module/t:test[@result='Passed'])" />
    </p>
  </xsl:template>

  <xsl:template name="css">
    <style type="text/css">
      body { margin: 10px; font-family: "Gill Sans MT","Gill Sans",Arial,Sans-serif; }
      h3, h4, pre { margin: 0; padding: 5px 10px; font-weight: normal; }
      h3 { background-color: #eee; }
      .module { border: 1px solid #ccc; margin: 10px 0; }
      .Failed { color: red; }
      .Passed { color: green; }
    </style>
  </xsl:template>

</xsl:stylesheet>
