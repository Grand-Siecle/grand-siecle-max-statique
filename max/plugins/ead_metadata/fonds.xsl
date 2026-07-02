<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:max="https://max.unicaen.fr" 
    exclude-result-prefixes="ead xsl max">

    <xsl:import href="../../ui/xsl/core/i18n.xsl"/>
    <xsl:param name="project"/>
    <xsl:param name="locale"/>

      <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

 

</xsl:stylesheet>