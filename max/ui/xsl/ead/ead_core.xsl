<?xml version="1.0" encoding="UTF-8"?>
<!--For conditions of distribution and use, see the accompanying legal.txt file.-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:ead="urn:isbn:1-931666-22-9" 
                xmlns:max="https://max.unicaen.fr"
                version="2.0" 
                exclude-result-prefixes="ead xsl xlink">
    <xsl:import href="../core/i18n.xsl"/>
    <xsl:output method="xhtml" encoding="utf-8"/>



    <xsl:param name="baseuri"/>
    <xsl:param name="project"/>
    <xsl:param name="locale"/>
    <xsl:param name="docName"/>

    <xsl:template match="ead:runner"></xsl:template>
    <xsl:template match="ead:*[@audience='internal']"/>
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="ead:c">
        <div class="ead_style" id="text">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- Description et identification [did]-->

    <xsl:template match="ead:dsc">
        <xsl:apply-templates/>
    </xsl:template>


    <xsl:template match="ead:did">
        <table class="ead_details {local-name(.)}">
            <tbody>
                <xsl:apply-templates/>
            </tbody>
        </table>
    </xsl:template>

    <xsl:template match="ead:unitid">
        <tr class="unitid">
            <xsl:choose>
                <xsl:when test="@label">
                    <th>
                        <xsl:value-of select="@label"/>
                    </th>
                </xsl:when>
                <xsl:otherwise>
                    <th>Cote</th>
                </xsl:otherwise>
            </xsl:choose>
            <td>
                <xsl:apply-templates select="node()"/>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="ead:unittitle">
        <tr class="unittitle">
            <xsl:choose>
                <xsl:when test="@label">
                    <th>
                        <xsl:value-of select="@label"/>
                    </th>
                </xsl:when>
                <xsl:otherwise>
                    <th>Intitulé</th>
                </xsl:otherwise>
            </xsl:choose>
            <td>
                <xsl:apply-templates select="node()"/>
            </td>
        </tr>
    </xsl:template>
    

    <xsl:template match="ead:physdesc">
        <tr class="physdesc">
            <xsl:choose>
                <xsl:when test="@label">
                    <th>
                        <xsl:value-of select="@label"/>
                    </th>
                </xsl:when>
                <xsl:otherwise>
                    <th>Description matérielle</th>
                </xsl:otherwise>
            </xsl:choose>
            <td>
                <xsl:choose>
                    <xsl:when test="text()">
                        <xsl:apply-templates select="node()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <table class="desc">
                            <tbody>
                                <xsl:apply-templates/>
                            </tbody>
                        </table>
                    </xsl:otherwise>
                </xsl:choose>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="ead:extent">
        <tr class="extent">
            <xsl:choose>
                <xsl:when test="@label">
                    <th>
                        <xsl:value-of select="@label"/><xsl:text> : </xsl:text>
                    </th>
                </xsl:when>
                <xsl:otherwise>
                    <th>Importance matérielle :</th>
                </xsl:otherwise>
            </xsl:choose>
            <td>
                <xsl:apply-templates select="node()"/>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="ead:dimensions">
        <tr class="dimensions">
            <xsl:choose>
                <xsl:when test="@label">
                    <th>
                        <xsl:value-of select="@label"/><xsl:text> : </xsl:text>
                    </th>
                </xsl:when>
                <xsl:otherwise>
                    <th>Dimensions :</th>
                </xsl:otherwise>
            </xsl:choose>
            <td>
                <xsl:apply-templates select="node()"/>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="ead:physfacet">
        <tr class="physfacet">
            <xsl:choose>
                <xsl:when test="@label">
                    <th>
                        <xsl:value-of select="@label"/><xsl:text> : </xsl:text>
                    </th>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="@type">
                            <th>
                                <xsl:value-of select="@type"/> :
                            </th>
                        </xsl:when>
                        <xsl:otherwise>
                            <th>Particularités physiques :</th>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>
            <td>
                <xsl:apply-templates select="node()"/>
            </td>
        </tr>
    </xsl:template>


    <xsl:template match="ead:langmaterial">
        <tr class="langmaterial">
            <xsl:choose>
                <xsl:when test="@label">
                    <th>
                        <xsl:value-of select="@label"/>
                    </th>
                </xsl:when>
                <xsl:otherwise>
                    <th>Langue(s)</th>
                </xsl:otherwise>
            </xsl:choose>
            <td>
                <xsl:apply-templates select="node()"/>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="ead:origination">
        <tr class="origination">
            <xsl:choose>
                <xsl:when test="@label">
                    <th>
                        <xsl:value-of select="@label"/>
                    </th>
                </xsl:when>
                <xsl:otherwise>
                    <th>Origine</th>
                </xsl:otherwise>
            </xsl:choose>
            <td>
                <xsl:apply-templates select="node()"/>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="ead:repository">
        <tr class="repository">
            <xsl:choose>
                <xsl:when test="@label">
                    <th>
                        <xsl:value-of select="@label"/>
                    </th>
                </xsl:when>
                <xsl:otherwise>
                    <th>Organisme responsable de l’accès intellectuel</th>
                </xsl:otherwise>
            </xsl:choose>
            <td>
                <xsl:apply-templates select="node()"/>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="ead:physloc">
        <tr class="physloc">
            <xsl:choose>
                <xsl:when test="@label">
                    <th>
                        <xsl:value-of select="@label"/>
                    </th>
                </xsl:when>
                <xsl:otherwise>
                    <th>Localisation physique</th>
                </xsl:otherwise>
            </xsl:choose>
            <td>
                <xsl:apply-templates select="node()"/>
            </td>
        </tr>
    </xsl:template>

    <xsl:template match="ead:unitdate">
        <tr class="unitdate">
            <xsl:choose>
                <xsl:when test="@label">
                    <th>
                        <xsl:value-of select="@label"/>
                    </th>
                </xsl:when>
                <xsl:otherwise>
                    <th>Datation</th>
                </xsl:otherwise>
            </xsl:choose>
            <td>
                <xsl:apply-templates select="node()"/>
            </td>
        </tr>
    </xsl:template>

    <!-- FIN Description et identification [did]-->
    <!-- Zone du contenu -->
    <xsl:template match="ead:scopecontent">
        <div class="scopecontent">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Présentation du contenu</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- FIN Zone du contenu -->
    <!-- Note sur le plan de classement -->
    <xsl:template match="ead:arrangement">
        <div class="arrangement">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Organisation du plan de classement</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    <!-- plan de classement -->

    <!-- Note sur le plan de classement -->
    <xsl:template match="ead:processinfo">
        <div class="processinfo">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Informations sur le traitement</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    <!-- plan de classement -->

    <xsl:template match="ead:note">
        <xsl:apply-templates/>
    </xsl:template>


    <!-- Zone des notes -->
    <xsl:template match="ead:odd">
        <div class="odd">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="@type">
                            <h2>
                                <xsl:value-of select="@type"/>
                            </h2>
                        </xsl:when>
                        <xsl:otherwise>
                            <h2>Zones des notes</h2>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- FIN Zone des notes -->


    <!-- Zone de l'Historique de la conservation -->
    <xsl:template match="ead:custodhist">
        <div class="custodhist">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Historique de la conservation</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- FIN Historique de la conservation -->

    <!-- Modalités d’acquisition -->
    <xsl:template match="ead:acqinfo">
        <div class="acqinfo">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Modalités d’entrée</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- FIN Modalités d’acquisition -->
    <!-- Documents en relation  -->
    <xsl:template match="ead:relatedmaterial">
        <div class="relatedmaterial">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Documents en relation</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- FIN Documents en relation -->

    <!-- Biographie ou histoire  -->
    <xsl:template match="ead:bioghist">
        <div class="bioghist">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Biographie</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- FIN Biographie ou histoire -->

    <!-- Conditions d'utilisation  -->
    <xsl:template match="ead:userestrict">
        <div class="userestrict">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Conditions d'utilisation</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- FIN Conditions d'utilisation -->

    <!--  Conditions d'accès -->
    <xsl:template match="ead:accessrestrict">
        <div class="accessrestrict">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Conditions d’accès</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- FIN Conditions d’accès -->

    <!--  Autres instruments de recherche -->
    <xsl:template match="ead:otherfindaid">
        <div class="otherfindaid">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Autres instruments de recherche</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- FIN Autres instruments de recherche -->

    <xsl:template match="ead:altformavail">
        <div class="altformavail">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <!-- Zone de la bibliographie -->
    <xsl:template match="ead:bibliography">
        <div class="bibliography">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Bibliographie</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>

        </div>
    </xsl:template>

    <xsl:template match="ead:bibliography/ead:bibref">
        <p class="bibref">
            <xsl:apply-templates select="node()"/>
        </p>
    </xsl:template>

    <xsl:template match="ead:p/ead:bibref">
        <span class="bibref">
            <xsl:apply-templates select="node()"/>
        </span>
    </xsl:template>

    <!-- FIN Bibliographie -->
    <!-- Zone de la bibliographie -->
    <xsl:template match="ead:controlaccess">
        <div class="controlaccess">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Accès controlés</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>

        </div>
    </xsl:template>
    <!-- FIN Controlaccess -->
    <xsl:template match="ead:descgroup">
        <div class="descgroup">
            <xsl:choose>
                <xsl:when test="ead:head">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <h2>Mémento</h2>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>

        </div>
    </xsl:template>

       <xsl:template match="ead:archdesc/ead:dsc/ead:c | ead:c/ead:c">
        <div class="composant">
            <h2 class="collapsible composants">
                <xsl:value-of select="ead:did/ead:unitid[1]"/>
            </h2>
            <div class="developper">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>


    <!-- index -->
    <xsl:template match="ead:title">
        <span>
            <xsl:attribute name="class">index title
                <xsl:value-of select="@type"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="ead:persname">
        <span class="index persname">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="ead:name">
        <span class="index name">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="ead:genreform">
        <span class="index genreform">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

<xsl:template match="ead:corpname">
        <span class="index corpname">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="ead:geogname">
        <span class="index geogname">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="ead:date">
        <span class="index date">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="ead:subject">
        <span class="index subject">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <!-- fin index -->


    <xsl:template match="ead:imprint">
        <p class="imprint">
            <span class="intitule">Adresse bibliographique :</span>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="ead:address">
        <p class="address">
            <span class="intitule">Géolocalisation :</span>
            <xsl:apply-templates/>
        </p>
    </xsl:template>

    <xsl:template match="ead:addressline">
        <span class="addressline">
            <xsl:apply-templates/>
        </span>
    </xsl:template>


    <!-- Mise en page -->
    <xsl:template match="ead:p">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="ead:head">
        <h2>
            <xsl:apply-templates/>
        </h2>
    </xsl:template>
    <xsl:template match="ead:blockquote">
        <blockquote>
            <xsl:apply-templates/>
        </blockquote>
    </xsl:template>
    <xsl:template match="ead:list">
        <ul>
            <xsl:apply-templates/>
        </ul>
    </xsl:template>
    <xsl:template match="ead:item">
        <li>
            <xsl:apply-templates/>
        </li>
    </xsl:template>


    <xsl:template match="ead:lb">
        <br/>
    </xsl:template>

    <!-- FIN Mise en page -->
    <!-- Typographie -->
    <xsl:template match="ead:emph">
        <span class="{@render}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="ead:*[@render]">
        <span class="{@render}">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <!-- FIN Typographie -->
    <!-- Les liens  -->
    <xsl:template match="ead:extref">
        <a target="_blank">
            <xsl:attribute name="href">
                <xsl:value-of select="@xlink:href"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </a>
    </xsl:template>
    <xsl:template match="ead:ref">
    <a>
        <xsl:attribute name="href">
            <xsl:value-of select="@target"/>
            <xsl:text>.html</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates/>
    </a>
    </xsl:template>
    <!-- FIN LEs liens -->

    <!-- Les images -->
    <xsl:template match="ead:did/ead:daogrp">
        <tr>
            <th>Numérisations</th>
            <td>
                <xsl:apply-templates/>
            </td>
        </tr>
    </xsl:template>


    <xsl:template match="ead:daoloc">
        <figure>
            <img src="{@xlink:href}" alt="IMAGE">
            <xsl:attribute name="src">
         <xsl:value-of select="concat($baseuri, $project, '/ui/images/',@xlink:href)"/>
         </xsl:attribute>
            
            </img>
        </figure>
    </xsl:template>

    <xsl:template match="ead:dao">
    <table class="ead_details {local-name(.)}">
    <tr>
            <th>Numérisations</th>
     <td>

        <img>
            <xsl:attribute name="src">
            <xsl:value-of select="concat($baseuri, $project, '/ui/images/',@xlink:href)"/>
            </xsl:attribute>
        </img>
        <!-- <desc><xsl:apply-templates select="ead:daodesc/ead:p/node()"/></desc>-->
    </td>
    </tr>
    </table>
    </xsl:template>


    <!-- FIN Les images FIN -->
</xsl:stylesheet>
