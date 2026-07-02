<!-- For conditions of distribution and use, see the accompanying legal.txt file. -->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="tei"
                xmlns:tei="http://www.tei-c.org/ns/1.0">

    <xsl:template match="tei:titleStmt">
        <span class="max-doc-title"><xsl:apply-templates/></span>
    </xsl:template>

    <xsl:template match="tei:title">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="tei:author">
    </xsl:template>

    <xsl:template match="tei:editor">
    </xsl:template>

    <xsl:template match="tei:lb"><xsl:text> </xsl:text></xsl:template>

    <xsl:template match="tei:note" />

    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tei:hi">
        <span>
            <xsl:attribute name="class">
                <xsl:value-of select="@rend"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

</xsl:stylesheet>
