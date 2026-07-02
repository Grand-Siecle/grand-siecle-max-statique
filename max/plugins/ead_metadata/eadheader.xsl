<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:max="https://max.unicaen.fr" 
    exclude-result-prefixes="ead xsl max">

    <xsl:import href="../../ui/xsl/core/i18n.xsl"/>
    <xsl:param name="project"/>
    <xsl:param name="locale"/>

    <xsl:template match="ead:eadheader">
        <div>
            <xsl:apply-templates />
        </div>
    </xsl:template>

    <!-- 
        Si les balises sont présentes dans le fichier xml, 
        4 tableaux sont créés pour les éléments eadid, filedesc, 
        profiledesc et revisiondesc
        Un template spécifique est fait pour eadid 
        qui n'a pas tout à fait la même construction
     -->
    <xsl:template match="ead:eadheader/ead:*">
        <table class="ead_details {local-name(.)}">
            <tr>
                <th class="titreTabHeader">
                <!-- 
                pour l'affichage des révisions : 
                on compte le nombre de balises pour ajouter un rowspan
                -->
                    <xsl:if test="local-name(.)='revisiondesc'">
                        <xsl:attribute name="rowspan">
                            <xsl:value-of select="count(//ead:date) + count(//ead:item) + count(//ead:change) + 1" />
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:variable name="i18nKey">
                        <xsl:value-of select="local-name(.)" />
                    </xsl:variable>
                    <xsl:value-of select="max:i18n($project,$i18nKey,$locale)"/>
                </th>
                <xsl:apply-templates />
            </tr>
        </table>
    </xsl:template>
    <!--
        Template spécifique pour le tableau du eadid 
        qui n'a pas tout à fait la même construction
     -->
    <xsl:template match="ead:eadheader/ead:eadid">
        <table class="ead_details {local-name(.)}">
            <tr>
                <th class="titreTabHeader">
                    <xsl:variable name="i18nKey">
                        <xsl:value-of select="local-name(.)" />
                    </xsl:variable>
                    <xsl:value-of select="max:i18n($project,$i18nKey,$locale)"/>
                </th>
                <td>
                    <xsl:apply-templates />
                </td>
            </tr>
        </table>
    </xsl:template>

    <xsl:template match="ead:eadheader/ead:*//ead:*">
        <xsl:choose>
            <!-- on masque par défaut les titres, comme titleStmt et publicationStmt-->
            <xsl:when test="(local-name(.)='titlestmt') or (local-name(.)='publicationstmt')">
                <xsl:apply-templates />
            </xsl:when>
            <xsl:otherwise>
                <tr>
                    <th>
                        <xsl:variable name="i18nKey">
                            <xsl:value-of select="local-name(.)" />
                        </xsl:variable>
                        <xsl:value-of select="max:i18n($project,$i18nKey,$locale)"/>
                    </th>
                    <td>
                        <xsl:apply-templates />
                    </td>
                </tr>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

   <!-- pour les révisions on masque les balises change, item et date -->
    <xsl:template match="ead:eadheader/ead:revisiondesc//ead:*">
        <tr>
            <td>
                <xsl:apply-templates />
            </td>
        </tr>
    </xsl:template>


    <!-- on gère les éléments inline, comme emph, extref, et les lb -->
    <xsl:template match="//ead:emph">
        <xsl:choose>
            <xsl:when test="./@render='bold'">
                <span class="bold">
                    <xsl:apply-templates />
                </span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="//ead:extref">
        <a href="{href}">
            <xsl:apply-templates />
        </a>
    </xsl:template>

    <xsl:template match="//ead:lb">
        <br/>
    </xsl:template>

    <!-- certains éléments sont à conserver dans le fil du texte 
        comme les éléments date, addressline, language (peut dépendre du contexte) -->

    <xsl:template match="//ead:language">
        <span class="language">
            <xsl:apply-templates />
        </span>
    </xsl:template>

    <xsl:template match="//ead:creation/ead:date">
              <span class="date"><xsl:apply-templates /></span>
    </xsl:template>

    <xsl:template match="//ead:address/ead:addressline">
              <span class="addressline"><xsl:apply-templates /></span>
    </xsl:template>

    <xsl:template match="//ead:editionstmt/ead:edition">
              <span class="edition"><xsl:apply-templates /></span>
    </xsl:template>






</xsl:stylesheet>