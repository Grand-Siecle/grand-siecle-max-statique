<!-- For conditions of distribution and use, see the accompanying legal.txt file. -->

<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" exclude-result-prefixes="ead xsl xhtml">
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

    <xsl:template match="ead:c">
        <xhtml:div>
            <xsl:attribute name="style">font-size:10px; font-family:serif;</xsl:attribute>
            <xsl:apply-templates/>
        </xhtml:div>
    </xsl:template>

    <xsl:template match="ead:c/ead:c">
        <xhtml:div>
            <xsl:attribute name="style">page-break-before:always;</xsl:attribute>
            <xsl:apply-templates/>
        </xhtml:div>

    </xsl:template>

    <!-- Typographie -->
    <xsl:template match="//ead:*[@render='super']">
        <xhtml:sup>
            <xsl:attribute name="style">font-size:80%;</xsl:attribute>
            <xsl:apply-templates/>
        </xhtml:sup>
    </xsl:template>
    <xsl:template match="//ead:*[@render='italic']">
        <xhtml:em>
            <xsl:apply-templates/>
        </xhtml:em>
    </xsl:template>
    <xsl:template match="//ead:*[@render='bold']">
        <xhtml:strong>
            <xsl:apply-templates/>
        </xhtml:strong>
    </xsl:template>
    <xsl:template match="//ead:*[@render='smcaps']">
        <xhtml:span class="small-caps">
            <xsl:attribute name="style">font-variant:small-caps;</xsl:attribute>
            <xsl:apply-templates/>
        </xhtml:span>
    </xsl:template>




    <!-- Zone de l’identification et de la description -->
    <xsl:template match="ead:did">
        <xhtml:table>
            <xsl:attribute name="style">border:1px solid #FFFFFF; background-color:#EEEEEE; font-size:9px; margin-bottom:20px;</xsl:attribute>
            <xhtml:tbody>
                <xsl:apply-templates/>
            </xhtml:tbody>
        </xhtml:table>
    </xsl:template>

    <xsl:template match="ead:unitid">
        <xhtml:tr class="unitid">
            <xsl:attribute name="style">border:1px solid #FFFFFF;</xsl:attribute>
            <xsl:choose>
                <xsl:when test="@label">
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:value-of select="@label"/>
                    </xhtml:th>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:text>Cote(s)</xsl:text>
                    </xhtml:th>
                </xsl:otherwise>
            </xsl:choose>
            <xhtml:td>
                <xsl:attribute name="style">padding:3px; border:1px solid #FFFFFF; </xsl:attribute>
                <xsl:apply-templates select="node()"/>
            </xhtml:td>
        </xhtml:tr>
    </xsl:template>

    <xsl:template match="ead:unittitle">
        <xhtml:tr class="unittitle">
            <xsl:attribute name="style">border:1px solid #FFFFFF;</xsl:attribute>
            <xsl:choose>
                <xsl:when test="@label">
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:value-of select="@label"/>
                    </xhtml:th>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:text>Intitulé</xsl:text>
                    </xhtml:th>
                </xsl:otherwise>
            </xsl:choose>
            <xhtml:td>
                <xsl:attribute name="style">padding:3px; border:1px solid #FFFFFF;</xsl:attribute>
                <xsl:apply-templates select="node()"/>
            </xhtml:td>
        </xhtml:tr>
    </xsl:template>

    <xsl:template match="ead:unittitle/ead:persname">
        <xhtml:span class="author">
            <xsl:apply-templates/>
        </xhtml:span>
        <xsl:text> – </xsl:text>
    </xsl:template>
    <xsl:template match="ead:unittitle/ead:imprint">
        <xhtml:br/>
        <xsl:text>Adresse bibliographique : </xsl:text>
        <xhtml:span>
            <xsl:apply-templates/>
        </xhtml:span>
        <xsl:text>. </xsl:text>
    </xsl:template>
    <xsl:template match="ead:unittitle/ead:imprint/ead:geogname">
        <xhtml:span class="pubplace">
            <xsl:apply-templates/>
        </xhtml:span>
        <xsl:text> : </xsl:text>
    </xsl:template>
    <xsl:template match="ead:unittitle/ead:imprint/ead:publisher">
        <xhtml:span class="pubplace">
            <xsl:apply-templates/>
        </xhtml:span>
        <xsl:text>, </xsl:text>
    </xsl:template>
    <xsl:template match="ead:physdesc">
        <xhtml:tr class="physdesc">
            <xsl:attribute name="style">padding:3px; border:1px solid #FFFFFF;</xsl:attribute>
            <xsl:choose>
                <xsl:when test="@label">
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:value-of select="@label"/>
                    </xhtml:th>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:text>Description matérielle</xsl:text>
                    </xhtml:th>
                </xsl:otherwise>
            </xsl:choose>
            <xhtml:td>
                <xsl:choose>
                    <xsl:when test="text()">
                        <xsl:apply-templates select="node()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xhtml:table class="desc">
                            <xsl:attribute name="style">border:none; background-color:#EEEEEE; font-size:8px;</xsl:attribute>
                            <xhtml:tbody>
                                <xsl:apply-templates/>
                            </xhtml:tbody>
                        </xhtml:table>
                    </xsl:otherwise>
                </xsl:choose>
            </xhtml:td>
        </xhtml:tr>
    </xsl:template>

    <xsl:template match="ead:dimensions">
        <xhtml:tr class="dimensions">
            <xsl:choose>
                <xsl:when test="@label">
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:1px; border:none; width:90px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:value-of select="@label"/>
                        <xsl:text> : </xsl:text>
                    </xhtml:th>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:1px; border:none; width:90px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:text>Dimensions :</xsl:text>
                    </xhtml:th>
                </xsl:otherwise>
            </xsl:choose>
            <xhtml:td>
                <xsl:attribute name="style">border:none;</xsl:attribute>
                <xsl:apply-templates select="node()"/>
            </xhtml:td>
        </xhtml:tr>
    </xsl:template>

    <xsl:template match="ead:physfacet">
        <xhtml:tr class="physfacet">
            <xsl:choose>
                <xsl:when test="@label">
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:1px; border:none; width:90px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:value-of select="@label"/>
                        <xsl:text> : </xsl:text>
                    </xhtml:th>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="@type">
                            <xhtml:th class="label">
                                <xsl:attribute name="style">text-align: left; padding:1px; border:none; width:90px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                                <xsl:value-of select="@type"/>
 :
                            </xhtml:th>
                        </xsl:when>
                        <xsl:otherwise>
                            <xhtml:th class="label">
                                <xsl:attribute name="style">text-align: left; padding:3px; border:none; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                                <xsl:text>Particularités physiques :</xsl:text>
                            </xhtml:th>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
            <xhtml:td>
                <xsl:attribute name="style">border:none;</xsl:attribute>
                <xsl:apply-templates select="node()"/>
            </xhtml:td>
        </xhtml:tr>
    </xsl:template>

    <xsl:template match="ead:extent">
        <xhtml:tr class="extent">
            <xsl:choose>
                <xsl:when test="@label">
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:1px; border:none; width:90px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:value-of select="@label"/>
                        <xsl:text> : </xsl:text>
                    </xhtml:th>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:1px; border:none; width:90px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:text>Importance matérielle :</xsl:text>
                    </xhtml:th>
                </xsl:otherwise>
            </xsl:choose>
            <xhtml:td>
                <xsl:attribute name="style">border:none;</xsl:attribute>
                <xsl:apply-templates select="node()"/>
            </xhtml:td>
        </xhtml:tr>
    </xsl:template>

    <xsl:template match="ead:langmaterial">
        <xhtml:tr class="langmaterial">
            <xsl:attribute name="style">border:1px solid #FFFFFF;</xsl:attribute>
            <xsl:choose>
                <xsl:when test="@label">
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:value-of select="@label"/>
                    </xhtml:th>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:text>Langue(s)</xsl:text>
                    </xhtml:th>
                </xsl:otherwise>
            </xsl:choose>
            <xhtml:td>
                <xsl:attribute name="style">padding:3px; border:1px solid #FFFFFF;</xsl:attribute>
                <xsl:apply-templates select="node()"/>
            </xhtml:td>
        </xhtml:tr>
    </xsl:template>

    <xsl:template match="ead:language">
        <xhtml:span class="lang">
            <xsl:apply-templates/>
        </xhtml:span>
        <xsl:text></xsl:text>
    </xsl:template>

    <xsl:template match="ead:origination">
        <xhtml:tr class="origination">
            <xsl:attribute name="style">border:1px solid #FFFFFF;</xsl:attribute>
            <xsl:choose>
                <xsl:when test="@label">
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:value-of select="@label"/>
                    </xhtml:th>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:text>Origine</xsl:text>
                    </xhtml:th>
                </xsl:otherwise>
            </xsl:choose>
            <xhtml:td>
                <xsl:attribute name="style">padding:3px; border:1px solid #FFFFFF;</xsl:attribute>
                <xsl:apply-templates select="node()"/>
            </xhtml:td>
        </xhtml:tr>
    </xsl:template>

    <xsl:template match="ead:repository">
        <xhtml:tr class="repository">
            <xsl:attribute name="style">border:1px solid #FFFFFF;</xsl:attribute>
            <xsl:choose>
                <xsl:when test="@label">
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:value-of select="@label"/>
                    </xhtml:th>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:text>Organisme responsable de l’accès intellectuel</xsl:text>
                    </xhtml:th>
                </xsl:otherwise>
            </xsl:choose>
            <xhtml:td>
                <xsl:attribute name="style">padding:3px; border:1px solid #FFFFFF;</xsl:attribute>
                <xsl:apply-templates select="node()"/>
            </xhtml:td>
        </xhtml:tr>
    </xsl:template>

    <xsl:template match="ead:physloc">
        <xhtml:tr class="physloc">
            <xsl:attribute name="style">border:1px solid #FFFFFF;</xsl:attribute>
            <xsl:choose>
                <xsl:when test="@label">
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:value-of select="@label"/>
                    </xhtml:th>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:text>Localisation physique</xsl:text>
                    </xhtml:th>
                </xsl:otherwise>
            </xsl:choose>
            <xhtml:td>
                <xsl:attribute name="style">padding:3px; border:1px solid #FFFFFF;</xsl:attribute>
                <xsl:apply-templates select="node()"/>
            </xhtml:td>
        </xhtml:tr>
    </xsl:template>

    <xsl:template match="ead:unitdate">
        <xhtml:tr class="unitdate">
            <xsl:attribute name="style">border:1px solid #FFFFFF;</xsl:attribute>
            <xsl:choose>
                <xsl:when test="@label">
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:value-of select="@label"/>
                    </xhtml:th>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:th class="label">
                        <xsl:attribute name="style">text-align: left; padding:3px; border:1px solid #FFFFFF; width:120px; font-weight:normal; font-family: sans-serif;</xsl:attribute>
                        <xsl:text>Datation</xsl:text>
                    </xhtml:th>
                </xsl:otherwise>
            </xsl:choose>
            <xhtml:td>
                <xsl:attribute name="style">padding:3px; border:1px solid #FFFFFF;</xsl:attribute>
                <xsl:apply-templates select="node()"/>
            </xhtml:td>
        </xhtml:tr>
    </xsl:template>

    <!-- FIN Description et identification [did]-->
    <!-- Zone du contenu -->
    <xsl:template match="ead:scopecontent">
        <xhtml:div class="scopecontent">
            <xsl:attribute name="style">font-size:9px; background-color:none; </xsl:attribute>
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:h2>
                        <xsl:attribute name="style">margin-top:5px; margin-bottom:3px; margin-left:15px; font-size:10px; font-family:sans-serif; font-weight:300;</xsl:attribute>
                        <xsl:text>Présentation du contenu</xsl:text>
                    </xhtml:h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xhtml:div>
    </xsl:template>

    <!-- FIN Zone du contenu -->

    <!-- Zone des notes -->
    <xsl:template match="ead:odd">
        <xhtml:div class="ODD">
            <xsl:attribute name="style">font-size:9px; background-color:none; margin-left:-5px;</xsl:attribute>
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="@type">
                            <xhtml:h2>
                                <xsl:attribute name="style">margin-top:5px; margin-bottom:3px; margin-left:15px; font-size:10px; font-family:sans-serif; font-weight:300;</xsl:attribute>
                                <xsl:value-of select="@type"/>
                            </xhtml:h2>
                        </xsl:when>
                        <xsl:otherwise>
                            <xhtml:h2>
                                <xsl:attribute name="style">margin-top:5px; margin-bottom:3px; margin-left:15px; font-size:10px; font-family:sans-serif; font-weight:300;</xsl:attribute>
                                <xsl:text>Zones des notes</xsl:text>
                            </xhtml:h2>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xhtml:div>
    </xsl:template>

    <!-- FIN Zone des notes -->
    <!-- Zone de l'Historique de la conservation -->
    <xsl:template match="ead:custodhist">
        <xhtml:div class="custodhist">
            <xsl:attribute name="style">font-size:9px; background-color:none; </xsl:attribute>
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:h2>
                        <xsl:attribute name="style">margin-top:5px; margin-bottom:3px; margin-left:15px; font-size:10px; font-family:sans-serif; font-weight:300;</xsl:attribute>
                        <xsl:text>Historique de la conservation</xsl:text>
                    </xhtml:h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xhtml:div>
    </xsl:template>
    <!-- Zone de la bibliographie -->
    <xsl:template match="ead:bibliography">
        <xhtml:div class="bibliography">
            <xsl:attribute name="style">font-size:9px; background-color:none; </xsl:attribute>
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:h2>
                        <xsl:attribute name="style">margin-top:5px; margin-bottom:3px; margin-left:15px; font-size:10px; font-family:sans-serif; font-weight:300;</xsl:attribute>
                        <xsl:text>Bibliographie</xsl:text>
                    </xhtml:h2>

                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>

        </xhtml:div>
    </xsl:template>

    <xsl:template match="ead:bibliography/ead:bibref">
        <xhtml:p class="bibref">
            <xsl:attribute name="style">text-indent:-15px; margin-top:2px; margin-bottom:2px;</xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xhtml:p>
    </xsl:template>

    <xsl:template match="ead:p/ead:bibref">
        <xhtml:span class="bibref">
            <xsl:apply-templates select="node()"/>
        </xhtml:span>
    </xsl:template>

    <!-- FIN Bibliographie -->
    <xsl:template match="ead:altformavail">
        <xhtml:div class="altformavail">
            <xsl:attribute name="style">font-size:9px; background-color:none; </xsl:attribute>
            <xhtml:h2>
                <xsl:attribute name="style">margin-top:5px; margin-bottom:3px; margin-left:15px; font-size:10px; font-family:sans-serif; font-weight:300;</xsl:attribute>
                <xsl:text>Autres formes disponibles</xsl:text>
            </xhtml:h2>
            <xsl:apply-templates/>
        </xhtml:div>
    </xsl:template>
    <!-- Accès controlés -->
    <xsl:template match="ead:controlaccess">
        <xhtml:div class="controlaccess">
            <xsl:attribute name="style">font-size:9px; background-color:none; </xsl:attribute>
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xhtml:h2>
                        <xsl:attribute name="style">margin-top:5px; margin-bottom:3px; margin-left:15px; font-size:10px; font-family:sans-serif; font-weight:300;</xsl:attribute>
                        <xsl:text>Accès controlés</xsl:text>
                    </xhtml:h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xhtml:div>
    </xsl:template>
    <xsl:template match="ead:controlaccess/ead:genreform">
        <xhtml:p>
            <xsl:attribute name="style">margin-top:2px; margin-bottom:2px;</xsl:attribute>
            <xsl:apply-templates/>
        </xhtml:p>
    </xsl:template>
    <xsl:template match="ead:title">
        <xhtml:span class="title">
            <!-- <xsl:attribute name="style">font-style:italic; </xsl:attribute> -->
            <xsl:apply-templates/>
        </xhtml:span>
    </xsl:template>
    <!-- Mise en page -->
    <xsl:template match="ead:p">
        <xhtml:p>
            <xsl:attribute name="style">margin-top:2px; margin-bottom:2px;</xsl:attribute>
            <xsl:apply-templates/>
        </xhtml:p>
    </xsl:template>

    <xsl:template match="ead:head">
        <xhtml:h2>
            <xsl:attribute name="style">margin-top:5px; margin-bottom:3px; margin-left:15px; font-size:10px; font-family:sans-serif; font-weight:300;</xsl:attribute>
            <xsl:apply-templates/>
        </xhtml:h2>
    </xsl:template>
    <xsl:template match="ead:blockquote">
        <xhtml:blockquote>
            <xsl:apply-templates/>
        </xhtml:blockquote>
    </xsl:template>
    <xsl:template match="ead:list">
        <xsl:if test="ead:head">
            <xhtml:p>
                <xsl:attribute name="style">margin-top:2px; margin-bottom:2px;</xsl:attribute>
                <xsl:apply-templates select="ead:head" mode="list"/>
            </xhtml:p>
        </xsl:if>
        <xhtml:ul>
            <xsl:attribute name="style">margin-top:2px; margin-bottom:2px;</xsl:attribute>
            <xsl:apply-templates/>
        </xhtml:ul>
    </xsl:template>
    <xsl:template match="ead:item">
        <xhtml:li>
            <xsl:apply-templates/>
        </xhtml:li>
    </xsl:template>
    <xsl:template match="ead:list/ead:head"/>
    <xsl:template match="ead:dao"></xsl:template>
    <xsl:template match="ead:daogrp"></xsl:template>
    <xsl:template match="ead:lb">
        <xhtml:br/>
    </xsl:template>
    <!-- Les liens  -->
    <xsl:template match="ead:extref">
        <xhtml:a>
            <xsl:attribute name="href">
                <xsl:value-of select="@xlink:href"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xhtml:a>
    </xsl:template>

    <!-- FIN LEs liens -->
</xsl:stylesheet>
