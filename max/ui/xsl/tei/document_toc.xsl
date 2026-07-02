<!-- For conditions of distribution and use, see the accompanying legal.txt file. -->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:max="https://max.unicaen.fr"
                exclude-result-prefixes="tei max">

    <xsl:import href="../core/i18n.xsl"/>

    <xsl:param name="project"/>
    <xsl:param name="locale"/>
    <xsl:param name="docTitle"/>

    <xsl:template match="/">
        <div id="document-toc">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="tei:ul">
        <ul>
            <xsl:apply-templates/>
        </ul>
    </xsl:template>

    <xsl:template match="tei:li">
        <li>
            <xsl:attribute name="data-target">
                <xsl:value-of select="@id"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </li>
    </xsl:template>

    <xsl:template match="tei:head">
        <a>
            <xsl:attribute name="href">
                <xsl:value-of select="concat(../@data-href,'.html')"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </a>
    </xsl:template>

    <xsl:template match="tei:hi">
        <span>
            <xsl:attribute name="class">
                <xsl:value-of select="@rend"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="tei:author">
    </xsl:template>

    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>


</xsl:stylesheet>