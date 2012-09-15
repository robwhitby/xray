<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:xray="http://github.com/robwhitby/xray"
				xmlns:xdmp="http://marklogic.com/xdmp"
				xmlns:error="http://marklogic.com/xdmp/error"
				version="2.0"
				exclude-result-prefixes="xray xdmp error">

	<xsl:output method="xml" omit-xml-declaration="no" indent="yes"/>

	<xsl:param name="test-dir"/>
	<xsl:param name="module-pattern"/>
	<xsl:param name="test-pattern"/>

	<xsl:template match="xray:tests">
		<testsuites
			name="{$test-dir}"
			errors="{count(//(error:error|xray:test[@result='error']))}"
			failures="{count(//xray:test[@result='failed'])}"
			skipped="{count(//xray:test[@result='ignored'])}"
			tests="{count(//xray:test)}">
			<xsl:apply-templates/>
		</testsuites>
	</xsl:template>

	<xsl:template match="xray:module">
		<testsuite
			name="{@path}"
			classname="{@path}"
			errors="{count((error:error|xray:test[@result='error']))}"
			failures="{count(xray:test[@result='failed'])}"
			skipped="{count(xray:test[@result='ignored'])}"
			tests="{count(xray:test)}">
			<xsl:apply-templates/>
		</testsuite>
	</xsl:template>

	<!-- Rh: Removed additional attributes, confuses some tools that parse JUnit format (like TeamCity) -->
	<xsl:template match="xray:test">
		<testcase
			name="{@name}"
			time="{seconds-from-duration (@time)}">
			<xsl:apply-templates/>
			<xsl:if test="@result = 'ignored'">
				<skipped/>
			</xsl:if>
		</testcase>
	</xsl:template>

	<xsl:template match="xray:assert[@result = 'failed']">
		<failure type="{@test}">expected: <xsl:value-of select="xdmp:quote(xray:expected/node())"/>, actual: <xsl:value-of select="xdmp:quote(xray:actual/node())"/>
		</failure>
	</xsl:template>

	<xsl:template match="xray:assert"/>

	<xsl:template match="error:error">
		<error message="{error:message}">
			<xsl:copy-of select="."/>
		</error>
	</xsl:template>

</xsl:stylesheet>
