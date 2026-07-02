<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:max="https://max.unicaen.fr" exclude-result-prefixes="ead xsl max">

   <!-- Pour une xsl dans le dossier édition, modifier le chemin
    <xsl:import href="../../../../../ui/xsl/core/i18n.xsl"/>-->
    <xsl:import href="../../ui/xsl/core/i18n.xsl"/>
    <xsl:param name="project"/>
    <xsl:param name="locale"/>

    <xsl:template match="/">
        <div>
            <xsl:apply-templates />
        </div>
    </xsl:template>

    <xsl:template match="div/ead:*">
        <table class="ead_details {local-name(.)}">
             <tr>
                     <th class="titreTabHeader">
                        <xsl:variable name="i18nKey">
                            <xsl:value-of select="local-name(.)" />
                            <xsl:if test="@role">
                                <xsl:text>@</xsl:text>
                                <xsl:value-of select="@role" />
                            </xsl:if>
                        </xsl:variable>
                        <xsl:value-of select="max:i18n($project,$i18nKey,$locale)"/>
                    </th>
                    <td>
                        <xsl:apply-templates />
                    </td>
                </tr>
        </table>
    </xsl:template>

     <xsl:template match="div/ead:bibliography">
        <xsl:apply-templates />
     </xsl:template>

    
       <xsl:template match="div/ead:*//ead:*">
           <xsl:choose>
            <!-- on masque par défaut certaines balises, comme p-->
            <xsl:when test="(local-name(.)='p')">
                <xsl:apply-templates />
            </xsl:when>
            <xsl:otherwise>
                <tr>
                    <th>
                        <xsl:variable name="i18nKey">
                            <xsl:value-of select="local-name(.)" />
                            <xsl:if test="@role">
                                <xsl:text>@</xsl:text>
                                <xsl:value-of select="@role" />
                            </xsl:if>
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

     <xsl:template match="//ead:bibref">
        <xsl:apply-templates />
     </xsl:template>


     <xsl:template match="div/ead:controlaccess/ead:subject | div/ead:controlaccess/ead:geogname">
        <li class="{local-name(.)}">
            <xsl:apply-templates />
        </li>
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

    <xsl:template match="//ead:extref | //ead:archref">
        <a href="{@href}" target="_blank">
            <xsl:apply-templates />
        </a>
    </xsl:template>

    <xsl:template match="//ead:lb">
        <br/>
    </xsl:template>

     <!-- certains éléments sont à conserver dans le fil du texte 
        comme les éléments date, addressline, language (peut dépendre du contexte) -->

    <xsl:template match="//ead:language | //ead:corpname">
        <span class="{local-name(.)}">
            <xsl:apply-templates />
        </span>
    </xsl:template>

        <xsl:template match="//ead:address/ead:addressline">
              <span class="addressline"><xsl:apply-templates /><br/></span>
    </xsl:template>

    <xsl:template match="//ead:head">
        <h2>
            <xsl:apply-templates />
        </h2>
    </xsl:template>

    <xsl:template match="//ead:list">
        <ul>
            <xsl:apply-templates />
        </ul>
    </xsl:template>

    <xsl:template match="//ead:item">
        <li>
            <xsl:apply-templates />
        </li>
    </xsl:template>

    

   

 


</xsl:stylesheet>