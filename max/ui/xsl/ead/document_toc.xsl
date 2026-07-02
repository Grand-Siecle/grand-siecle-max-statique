<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:ns="urn:isbn:1-931666-22-9"
    xmlns:ead="urn:isbn:1-931666-22-9" exclude-result-prefixes="ead ns xlink">

    <xsl:template match="/">
        <!-- <xsl:copy-of select="."/> -->
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="*:origination"/>
    <xsl:template match="*:physdesc"/>
    <xsl:template match="*:physloc"/>
    <xsl:template match="*:repository"/>
    <xsl:template match="*:langmaterial"/>
    <xsl:template match="*:unitid[@type='Cote_ancienne']"/>
    <xsl:template match="*:note"/>
    <xsl:template match="*:imprint"/>
    <xsl:template match="*:dao"/>
    <xsl:template match="nav">
        <nav>
            <xsl:apply-templates/>
        </nav>
    </xsl:template>
    <xsl:template match="details">
        <details>
        <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </details>
    </xsl:template>
    <xsl:template match="div[@class='detail']">
        <div>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="summary">
        <summary>
            <xsl:apply-templates/>
        </summary>
    </xsl:template>
    <xsl:template match="a">
        <a href="{@href}">
            <xsl:apply-templates/>
        </a>
    </xsl:template>

    <xsl:template match="*:emph">
        <span class="{@render}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="*:unittitle">
        <span class="unittitle">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="*:unitid">
        <span class="unitid">
            <xsl:apply-templates/>
            <xsl:text> – </xsl:text>
        </span>
    </xsl:template>
    <xsl:template match="*:persname">
        <span class="persname">
            <xsl:apply-templates/>
            <xsl:text>, </xsl:text>
        </span>
    </xsl:template>
    <xsl:template match="*:title">
        <span class="title">
            <xsl:apply-templates/>            
        </span>
    </xsl:template>
</xsl:stylesheet>