<!-- For conditions of distribution and use, see the accompanying legal.txt file. -->

<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ead="urn:isbn:1-931666-22-9"
                exclude-result-prefixes="ead xsl">
    <xsl:output method="xml" encoding="utf-8"/>
    <xsl:param name="baseuri"/>
    <xsl:param name="project"/>
    <xsl:param name="docName"/>
    <xsl:param name="nodeId"/>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="//ead:c">
        <li>
            <xsl:attribute name="data-node_id">
                <xsl:value-of select="concat($docName,'|',$nodeId)"/>
            </xsl:attribute>
            <button class="btnRemoveBasketItem">Retirer</button>
            <a>
                <xsl:attribute name="href">
                    <xsl:value-of
                            select="concat($baseuri, '/', $project, '/', $docName, '/', $nodeId, '.html')"/>
                </xsl:attribute>
                <xsl:value-of select="//ead:c/ead:did/ead:unitid"/> 
                <xsl:text> – </xsl:text>
                <xsl:value-of select="//ead:c/ead:did/ead:unittitle"/>
            </a>
        </li>
    </xsl:template>
</xsl:stylesheet>
