<!-- For conditions of distribution and use, see the accompanying legal.txt file. -->

<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="max"
                xmlns:max="https://max.unicaen.fr"
>

    <xsl:import href="i18n.xsl"/>

    <xsl:param name="project"/>
    <xsl:param name="locale"/>



    <xsl:template match="/">
        <div id="toc">
            <h1>
                <xsl:value-of select="max:i18n($project,'menu.sommaire',$locale)"/>
            </h1>
            <xsl:apply-templates/>
        </div>

    </xsl:template>

    <xsl:template match="li">
        <li>
            <xsl:choose>
                <xsl:when test="@data-dir='true'">
                    <xsl:value-of select="./text()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="href">
                        <xsl:value-of select="replace(@data-href, 'xml', 'html')"/>
                    </xsl:variable>
                    <a href="{$href}">
                        <xsl:apply-templates/>
                    </a>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="./ul"/>
        </li>
    </xsl:template>

    <xsl:template match="ul">
        <ul>
            <xsl:apply-templates/>
        </ul>
    </xsl:template>

</xsl:stylesheet>