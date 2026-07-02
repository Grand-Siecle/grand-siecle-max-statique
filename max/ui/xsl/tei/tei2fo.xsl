<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" exclude-result-prefixes="xs tei xsi">

    <!-- Chargement des styles -->
    <xsl:import href="styles/styles-fo.xsl"/>

    <!-- Le pied de page est dans un fichier à part -->
    <xsl:import href="footerfo.xsl"/>

    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:param name="prettyName"/>
    <xsl:param name="idProject"/>
    <xsl:param name="directory"/>

    <xsl:variable name="langue">
        <xsl:value-of select="//tei:language"/>
    </xsl:variable>



    <!--<xsl:include href="diagramme.xsl"/>-->
    <xsl:template match="tei:TEI">
        <fo:root>
            <!-- équivalent du head html -->
            <fo:layout-master-set>
                <!-- Les gabarits de page. Au moins 1 simple-page-master obligatoire-->
                <fo:simple-page-master master-name="couverture" margin-top="10mm" margin-bottom="5mm" margin-left="20mm" margin-right="25mm">
                    <fo:region-body margin-bottom="20mm" margin-top="10mm"/>
                    <!-- <fo:region-before extent="10mm" region-name="entete-couverture"/> -->
                    <fo:region-after extent="10mm" region-name="pied-couverture"/>
                </fo:simple-page-master>

                <fo:simple-page-master master-name="premiere" margin-top="10mm" margin-bottom="10mm" margin-left="25mm" margin-right="25mm">
                    <fo:region-body margin-bottom="50mm" margin-top="50mm"/>
                    <fo:region-after extent="1cm" region-name="pied-premiere"/>
                </fo:simple-page-master>

                <fo:simple-page-master master-name="impaire" margin-top="10mm" margin-bottom="5mm" margin-left="25mm" margin-right="25mm">
                    <fo:region-body margin-bottom="20mm" margin-top="20mm"/>
                    <fo:region-before extent="10mm" region-name="entete-impaire"/>
                    <fo:region-after extent="10mm" region-name="pied-impaire"/>
                </fo:simple-page-master>

                <fo:simple-page-master master-name="paire" margin-top="10mm" margin-bottom="5mm" margin-left="25mm" margin-right="25mm">
                    <fo:region-body margin-bottom="20mm" margin-top="20mm"/>
                    <fo:region-before extent="10mm" region-name="entete-paire"/>
                    <fo:region-after extent="10mm" region-name="pied-paire"/>
                </fo:simple-page-master>

                <!-- Le modèle de séquence de pages avec enchaînement impaire/paire -->
                <fo:page-sequence-master master-name="corps">
                    <fo:repeatable-page-master-alternatives>
                        <!-- <fo:conditional-page-master-reference master-reference="couverture" page-position="first" odd-or-even="odd"/> -->
                        <fo:conditional-page-master-reference master-reference="impaire" odd-or-even="odd"/>
                        <fo:conditional-page-master-reference master-reference="paire" odd-or-even="even"/>
                    </fo:repeatable-page-master-alternatives>
                </fo:page-sequence-master>
            </fo:layout-master-set>
            <!-- La première page contenant les métadonnées du eadheader, la séquence de page utilise le modèle "couverture" décrit plus haut -->
            <fo:page-sequence master-reference="couverture">
                <fo:static-content flow-name="pied-couverture">
                <xsl:call-template name="pied-couverture">
                    </xsl:call-template>
                    <!-- <fo:block text-align="left" font-size="7pt" space-after="6pt">
                    Pôle Document numérique – MRSH – université de Caen Normandie
                        <xsl:text> – </xsl:text>
                        <xsl:value-of select="format-dateTime(current-dateTime(),'[D,2]/[M,2]/[Y]')" />
                        <xsl:text> – </xsl:text>
                        <fo:page-number/>
                    </fo:block> -->
                </fo:static-content>
                <fo:flow flow-name="xsl-region-body">
                    <fo:block text-align="center" font-size="14pt" font-style="italic" space-after="16pt">
                        <xsl:value-of select="$prettyName"/>
                    </fo:block>
                    <fo:block text-align="left" font-size="12pt" space-after="10pt">
                        <xsl:apply-templates select="tei:teiHeader" />
                    </fo:block>
                </fo:flow>
            </fo:page-sequence>

            <!-- Début du document, la séquence de page utilise le modèle "corps" décrit plus haut -->
            <fo:page-sequence master-reference="corps">
                <!-- Description des en-têtes et pieds de pages, séparateur de bloc de notes de bas de page, etc. -->
                <fo:static-content flow-name="pied-premiere">
                    <fo:block text-align="center" font-family="Times" font-size="8pt">
                        <fo:page-number/>
                    </fo:block>
                </fo:static-content>
                <fo:static-content flow-name="entete-impaire">
                    <fo:block text-align="center" font-family="serif" font-size="8pt">
                        <xsl:apply-templates select="//tei:author[@role='aut']"/>
                    </fo:block>
                </fo:static-content>
                <fo:static-content flow-name="pied-impaire">
                    <xsl:call-template name="pied-impaire">
                    </xsl:call-template>
                </fo:static-content>
                <fo:static-content flow-name="entete-paire">
                    <fo:block text-align="center" font-family="serif" font-size="8pt">
                        <xsl:apply-templates select="//tei:title[@type='main']"/>
                    </fo:block>
                </fo:static-content>
                <fo:static-content flow-name="pied-paire">
                    <xsl:call-template name="pied-paire">
                    </xsl:call-template>
                </fo:static-content>
                <fo:static-content flow-name="xsl-footnote-separator">
                    <fo:block>
                        <fo:leader leader-pattern="rule" leader-length="15%" rule-style="solid" rule-thickness="0.5pt" color="grey"/>
                    </fo:block>
                </fo:static-content>

                <!-- Le flux de texte dans la zone principale -->
                <fo:flow flow-name="xsl-region-body" xsl:use-attribute-sets="general">
                    <fo:block>
                        <xsl:apply-templates select="node() except tei:teiHeader"/>
                    </fo:block>
                    <!-- On insère ici un marqueur afin de connaître le nombre total de pages -->
                    <fo:block id="last-page"/>
                </fo:flow>
            </fo:page-sequence>
        </fo:root>
    </xsl:template>

    <!-- début du teiHeader-->
    <xsl:template match="tei:teiHeader" mode="header">
        <fo:block>
            <xsl:apply-templates select="./node()"/>
        </fo:block>
    </xsl:template>

    <xsl:template match="tei:fileDesc">
        <fo:block xsl:use-attribute-sets="sous_titreCouv">Description bibliographique du fichier [fileDesc]</fo:block>
        <fo:block xsl:use-attribute-sets="texte_cover">
            <xsl:for-each select="//tei:titleStmt/tei:title">
                <fo:block xsl:use-attribute-sets="texte_cover">
                    <fo:inline>Titre</fo:inline>
                    <xsl:text></xsl:text>
                    <xsl:if test="@type">
                        <xsl:text> (</xsl:text>
                        <xsl:value-of select="@type" />
                        <xsl:text>)</xsl:text>
                    </xsl:if>
                    <xsl:text> : </xsl:text>
                    <xsl:if test="text()">
                        <fo:inline>
                            <xsl:apply-templates />
                        </fo:inline>
                    </xsl:if>
                    <xsl:if test="not(text())">
                        <xsl:for-each select="node()">
                            <fo:block>
                                <xsl:apply-templates />
                            </fo:block>
                        </xsl:for-each>
                    </xsl:if>
                </fo:block>
            </xsl:for-each>
            <xsl:for-each select="//tei:editionStmt | //tei:publicationStmt | //tei:sourceDesc">
                <fo:block xsl:use-attribute-sets="texte_cover">
                    <fo:inline font-style="italic">
                        <xsl:value-of select="local-name(.)" />
                    </fo:inline>
                    <xsl:for-each select="node()">
                        <fo:block>
                            <xsl:if test="text()">
                                <fo:inline>
                                    <xsl:apply-templates />
                                </fo:inline>
                            </xsl:if>
                            <xsl:if test="not(text())">
                                <xsl:for-each select="node()">
                                    <fo:block>
                                        <xsl:apply-templates />
                                    </fo:block>
                                </xsl:for-each>
                            </xsl:if>
                        </fo:block>
                    </xsl:for-each>
                </fo:block>
            </xsl:for-each>
            <xsl:for-each select="//tei:seriesStmt">
                <fo:inline font-style="italic">
                    <xsl:value-of select="local-name(.)" />
                </fo:inline>
                <fo:block xsl:use-attribute-sets="texte_cover">
                    <xsl:apply-templates />
                </fo:block>
            </xsl:for-each>
        </fo:block>
    </xsl:template>

    <xsl:template match="tei:encodingDesc">
        <fo:block xsl:use-attribute-sets="sous_titreCouv">Description de l'encodage  [encodingDesc]</fo:block>
        <xsl:for-each select="tei:tagsDecl | tei:appInfo">
            <fo:block xsl:use-attribute-sets="texte_cover">
                <xsl:for-each select="node()">
                    <xsl:if test="text()">
                        <fo:block>
                            <xsl:apply-templates />
                        </fo:block>
                    </xsl:if>
                    <xsl:if test="not(text())">
                        <xsl:for-each select="node()">
                            <fo:block>
                                <xsl:apply-templates />
                            </fo:block>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:for-each>
            </fo:block>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="tei:profileDesc">
        <fo:block xsl:use-attribute-sets="sous_titreCouv">Description du profil  [profileDesc]</fo:block>
        <fo:block xsl:use-attribute-sets="texte_cover">
            <xsl:for-each select="tei:abstract">
                <xsl:for-each select="node()">
                    <xsl:if test="text()">
                        <fo:block>
                            <xsl:apply-templates />
                        </fo:block>
                    </xsl:if>
                    <xsl:if test="not(text())">
                        <xsl:for-each select="node()">
                            <fo:block>
                                <xsl:apply-templates />
                            </fo:block>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:for-each>
            </xsl:for-each>
            <xsl:for-each select="//tei:creation/tei:date">
                <fo:block>
                    <xsl:apply-templates />
                </fo:block>
            </xsl:for-each>
            <xsl:for-each select="//tei:langUsage/tei:language">
                <fo:block>
                    <xsl:value-of select="@ident" />
                </fo:block>
            </xsl:for-each>
            <fo:inline font-style="italic">
                <xsl:value-of select="//tei:textClass/tei:keywords/local-name(.)" />
            </fo:inline>
            <xsl:for-each select="//tei:textClass//tei:item">
                <fo:block>
                    <xsl:apply-templates />
                </fo:block>
            </xsl:for-each>
        </fo:block>
    </xsl:template>

    <xsl:template match="tei:revisionDesc">
        <fo:block xsl:use-attribute-sets="sous_titreCouv">Descriptif des révision  [revisionDesc]</fo:block>
        <fo:block xsl:use-attribute-sets="texte_cover">
            <xsl:for-each select="//tei:change">
                <fo:block>
                    <xsl:value-of select="@when" />
                    <xsl:text> : </xsl:text>
                    <xsl:value-of select="@who" />
                </fo:block>
            </xsl:for-each>
        </fo:block>
    </xsl:template>

    <!-- fin du teiHeader-->
    <xsl:template match="tei:index">
    </xsl:template>


    <xsl:template match="tei:note">
        <xsl:variable name="number" select="count(./preceding::tei:note) + 1"/>
        <fo:footnote xsl:use-attribute-sets="notes">
            <fo:inline baseline-shift="5pt" font-size="7pt">
                <!-- appel de notes en exposant-->
                <xsl:value-of select="$number"/>
            </fo:inline>
            <fo:footnote-body>
                <!-- tableau en bas de page pour l'affichage des notes -->
                <fo:table xsl:use-attribute-sets="table">
                    <fo:table-column column-width="8mm"/>
                    <fo:table-column column-width="95%"/>
                    <fo:table-body>
                        <fo:table-row>
                            <fo:table-cell xsl:use-attribute-sets="cell" text-align="left">
                                <fo:block>
                                    <fo:inline font-size="7pt">
                                        <xsl:value-of select="$number"/>
                                        <xsl:text>.</xsl:text>
                                    </fo:inline>
                                </fo:block>
                            </fo:table-cell>
                            <fo:table-cell xsl:use-attribute-sets="cell">
                                <fo:block>
                                    <fo:inline font-size="9pt">
                                        <xsl:apply-templates/>
                                    </fo:inline>
                                </fo:block>
                            </fo:table-cell>
                        </fo:table-row>
                    </fo:table-body>
                </fo:table>
            </fo:footnote-body>
        </fo:footnote>
    </xsl:template>

    <xsl:template match="tei:div">
        <fo:block>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="tei:titlePart[@type='main']">
        <fo:block xsl:use-attribute-sets="head">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="tei:titlePart[@xml:lang='en']">
    </xsl:template>

    <xsl:template match="tei:head">
        <fo:block>
            <xsl:apply-templates select="./@style"/>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="tei:p">
        <xsl:choose>
            <xsl:when test="local-name(parent::node()) != 'note'">
                <fo:block>
                    <xsl:apply-templates select="./@style"/>
                    <xsl:apply-templates/>
                </fo:block>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:bibl[not(@type='citation')]">
        <fo:block xsl:use-attribute-sets="ref_bibliographique">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="tei:quote">
        <fo:block xsl:use-attribute-sets="citation">
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="tei:persName/tei:surname">
        <fo:inline>
            <xsl:text></xsl:text>
            <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>

    <!-- Un peu de typo -->
    <!-- <xsl:template match="tei:hi">
        <fo:inline>
            <xsl:apply-templates select="./@style"/>
            <xsl:apply-templates/>
        </fo:inline>
    </xsl:template> -->


</xsl:stylesheet>