<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Cette feuille n'est pas nommée breadcrumb.xsl, pour ne pas être appliquée en bout de chaîne de
    transformation du texte -->

    <xsl:template match="/">
        <span class="fragmentTitle">
            <xsl:apply-templates select="(.//*:head)[1]"/>
        </span>
    </xsl:template>

    <xsl:template match="*:head">
        <xsl:if test="preceding-sibling::*:head"><xsl:text> </xsl:text></xsl:if><xsl:apply-templates />
     </xsl:template>

    <!-- on masque les notes -->
    <xsl:template match="*:note">
      </xsl:template>

    <xsl:template match="*:fw">
    </xsl:template>

    <xsl:template match="*:rdg">
    </xsl:template>

    <xsl:template match="*:witDetail">
    </xsl:template>

    <!-- on gère les enrichissements typographiques-->
    <xsl:template match="*:hi" >
        <span>
            <xsl:attribute name="class">
                <xsl:value-of select="@rend"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="@rend">
        <xsl:attribute name="class">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>

    <xsl:template match="*:index[@indexName='Index']">
		<xsl:apply-templates select="*:term[@type='orig']/text()"/>
  </xsl:template>


</xsl:stylesheet>