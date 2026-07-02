<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:ead="urn:isbn:1-931666-22-9"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:fo="http://www.w3.org/1999/XSL/Format" exclude-result-prefixes="xs ead xsi">

  <!-- Chargement des styles -->
  <xsl:import href="styles/styles-fo.xsl"/>
  <!-- La sortie de l'en-tête est dans un fichier à part -->
  <xsl:import href="headerfo.xsl"/>
  <xsl:import href="footerfo.xsl"/>

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
  <xsl:param name="prettyName"/>
  <xsl:param name="idProject"/>

  <xsl:template match="ead:eadheader"/>
  <xsl:template match="ead:frontmatter"/>
  <xsl:template match="ead:*[@audience='internal']"/>

  <!-- <xsl:variable name="pretty-name">
    <xsl:value-of select="$prettyName"/>
  </xsl:variable> -->


  <xsl:template match="ead:ead">
    <fo:root>
      <!-- équivalent du head html -->
      <fo:layout-master-set>
        <!-- Les gabarits de page. Au moins 1 simple-page-master obligatoire-->
        <fo:simple-page-master master-name="couverture" margin-top="40mm" margin-bottom="20mm" margin-left="20mm" margin-right="40mm">
          <fo:region-body margin-bottom="20mm" margin-top="20mm"/>
          <fo:region-after extent="10mm" region-name="pied-couverture"/>
        </fo:simple-page-master>

        <fo:simple-page-master master-name="premiere" margin-top="10mm" margin-bottom="10mm" margin-left="25mm" margin-right="25mm">
          <fo:region-body margin-bottom="20mm" margin-top="20mm"/>
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
            <fo:conditional-page-master-reference master-reference="eadheader" page-position="first" odd-or-even="odd"/>
            <fo:conditional-page-master-reference master-reference="impaire" odd-or-even="odd"/>
            <fo:conditional-page-master-reference master-reference="paire" odd-or-even="even"/>
          </fo:repeatable-page-master-alternatives>
        </fo:page-sequence-master>
      </fo:layout-master-set>

      <!-- La première page contenant les métadonnées du eadheader, la séquence de page utilise le modèle "couverture" décrit plus haut -->
      <fo:page-sequence master-reference="couverture">
        <fo:static-content flow-name="pied-couverture">
          <fo:block text-align="left" font-size="8pt" space-after="6pt">
          <xsl:text>Pôle Document numérique – MRSH – université de Caen Normandie – </xsl:text>
            <xsl:value-of select="format-dateTime(current-dateTime(),'[D,2]/[M,2]/[Y]')" />
          </fo:block>
        </fo:static-content>
        <fo:flow flow-name="xsl-region-body">
          <fo:block text-align="center" font-size="14pt" font-style="italic" space-after="16pt">
            <xsl:value-of select="$prettyName"/>
          </fo:block>
          <fo:block text-align="center" font-size="14pt" font-weight="bold" space-after="26pt">
            <xsl:value-of select="ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper"/>
          </fo:block>
          <fo:block text-align="left" font-size="10pt" space-after="6pt">
            <xsl:text>Auteur(s) : </xsl:text>
            <xsl:value-of select="ead:eadheader/ead:filedesc/ead:titlestmt/ead:author"/>
          </fo:block>
          <fo:block text-align="left" font-size="10pt" space-after="6pt">
            <xsl:if test="ead:eadheader/ead:filedesc/ead:titlestmt/ead:sponsor">
              <xsl:text>Commanditaire : </xsl:text>
              <xsl:value-of select="ead:eadheader/ead:filedesc/ead:titlestmt/ead:sponsor"/>
            </xsl:if>
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
          <xsl:call-template name="output-header">
            <xsl:with-param name="prettyName" select="$prettyName"/>
          </xsl:call-template>
        </fo:static-content>
        <fo:static-content flow-name="pied-impaire">
          <xsl:call-template name="pied-impaire">
          </xsl:call-template>
        </fo:static-content>
        <fo:static-content flow-name="entete-paire">
          <xsl:call-template name="output-header">
            <xsl:with-param name="prettyName" select="$prettyName"/>
          </xsl:call-template>
        </fo:static-content>
        <fo:static-content flow-name="pied-paire">
          <xsl:call-template name="pied-paire">
          </xsl:call-template>
        </fo:static-content>
        <fo:static-content flow-name="xsl-footnote-separator">
          <fo:block>
            <fo:leader leader-pattern="rule" leader-length="10%" rule-style="solid" rule-thickness="0.5pt"/>
          </fo:block>
        </fo:static-content>

        <!-- Le flux de texte dans la zone principale -->
        <fo:flow flow-name="xsl-region-body" xsl:use-attribute-sets="general">
          <fo:block>
            <xsl:apply-templates />
          </fo:block>
          <!-- On insère ici un marqueur afin de connaître le nombre total de pages -->
          <fo:block id="last-page"/>
        </fo:flow>
      </fo:page-sequence>
    </fo:root>
  </xsl:template>




  <!-- Gestion de la référence bibliographique qui se trouve dans le frontmatter-->

  <xsl:template match="*:titlepage">
    <fo:block xsl:use-attribute-sets="bibref">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="*:titlepage/*:p/*:emph">
    <fo:inline>
      <xsl:apply-templates select="./@render"/>
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>

  <!-- Un peu de typo -->
  <xsl:template match="ead:emph | ead:title[@render]">
    <fo:inline>
      <xsl:apply-templates select="./@render"/>
      <xsl:apply-templates/>
    </fo:inline>
  </xsl:template>


  <!-- Les composants -->
  <xsl:template match="ead:dsc/ead:c">
    <fo:block xsl:use-attribute-sets="composants">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>
  <!-- Les sous-composants -->
  <xsl:template match="ead:c/ead:c">
    <fo:block xsl:use-attribute-sets="composants">
      <!-- <xsl:attribute name="page-break-before">always</xsl:attribute> -->
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <!-- DID -->


  <xsl:template match="ead:c/ead:did">
    <fo:block xsl:use-attribute-sets="infoParent">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead:c/ead:c/ead:did">
    <fo:block xsl:use-attribute-sets="infoEnfants">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>


  <xsl:template match="ead:unitid | ead:unittitle | ead:language | ead:unitdate | ead:origination | ead:physloc | ead:repository | ead:materialspec">
    <fo:block xsl:use-attribute-sets="divDid">
      <fo:inline xsl:use-attribute-sets="label">
        <xsl:choose>
          <xsl:when test="@label">
            <xsl:value-of select="@label"/>
            <xsl:text> : </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="self::ead:unitid">
                <xsl:text>Cote(s) : </xsl:text>
              </xsl:when>
              <xsl:when test="self::ead:unittitle">
                <xsl:text>Intitulé</xsl:text>
              </xsl:when>
              <xsl:when test="self::ead:unitdate">
                <xsl:text>Datation : </xsl:text>
              </xsl:when>
              <xsl:when test="self::ead:physdesc">
                <xsl:text>Description matérielle : </xsl:text>
              </xsl:when>
              <xsl:when test="self::ead:language">
                <xsl:text>Langue(s) : </xsl:text>
              </xsl:when>
              <xsl:when test="self::ead:origination">
                <xsl:text>Origine : </xsl:text>
              </xsl:when>
              <xsl:when test="self::ead:physloc">
                <xsl:text>Localisation physique : </xsl:text>
              </xsl:when>
              <xsl:when test="self::ead:repository">
                <xsl:text>Organisme responsable de l’accès intellectuel : </xsl:text>
              </xsl:when>
              <xsl:when test="self::ead:materialspec">
                <xsl:text>Particularités de certains types de documents : </xsl:text>
              </xsl:when>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </fo:inline>
      <fo:inline xsl:use-attribute-sets="content">
        <xsl:apply-templates/>
      </fo:inline>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead:dimensions | ead:extent | ead:physfacet | ead:address">
    <fo:block xsl:use-attribute-sets="divDid">
      <fo:inline xsl:use-attribute-sets="label">
        <xsl:choose>
          <xsl:when test="@label">
            <xsl:value-of select="@label"/>
            <xsl:text> : </xsl:text>
          </xsl:when>
          <xsl:when test="@type">
            <xsl:value-of select="@type"/>
            <xsl:text> : </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="self::ead:dimensions">
                <xsl:text>Dimensions : </xsl:text>
              </xsl:when>
              <xsl:when test="self::ead:extent">
                <xsl:text>Étendue : </xsl:text>
              </xsl:when>
              <xsl:when test="self::ead:physfacet">
                <xsl:text>Particularité(s) physique(s)</xsl:text>
              </xsl:when>
              <xsl:when test="self::ead:physdesc">
                <xsl:text>Description matérielle</xsl:text>
              </xsl:when>
              <xsl:when test="self::ead:language">
                <xsl:text>Langue(s)</xsl:text>
              </xsl:when>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </fo:inline>
      <fo:inline xsl:use-attribute-sets="content">
        <xsl:apply-templates/>
      </fo:inline>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead:physfacet/ead:genreform">
    <xsl:apply-templates/>
    <xsl:if test="position() != last()">
      <xsl:text> ; </xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="ead:address/ead:addressline">
    <xsl:apply-templates/>
    <xsl:if test="position() != last()">
      <xsl:text> ; </xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="ead:accessrestrict | ead:accruals | ead:acqinfo | ead:altformavail | ead:appraisal | ead:arrangement | ead:bibliography | ead:bioghist | ead:controlaccess | ead:custodhist | ead:odd | ead:originalsloc | ead:otherfindaid | ead:phystech | ead:prefercite | ead:processinfo | ead:relatedmaterial | ead:scopecontent | ead:separatedmaterial | ead:userestrict">
    <fo:block xsl:use-attribute-sets="div">
      <xsl:choose>
        <xsl:when test="ead:head">
          <xsl:apply-templates/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="@type">
              <xsl:choose>
                <xsl:when test="parent::ead:odd">
                  <fo:block xsl:use-attribute-sets="head2" keep-with-next="always">
                    <xsl:value-of select="@type"/>
                  </fo:block>
                </xsl:when>
                <xsl:otherwise>
                  <fo:block xsl:use-attribute-sets="head1" keep-with-next="always">
                    <xsl:value-of select="@type"/>
                  </fo:block>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <fo:block xsl:use-attribute-sets="head1">
                <xsl:choose>
                  <xsl:when test="self::ead:accessrestrict">
                    <xsl:text>Conditions d’accès</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:accruals">
                    <xsl:text>Accroissement</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:acqinfo">
                    <xsl:text>Informations sur les modalités d’entrée</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:altformavail">
                    <xsl:text>Documents de substitution</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:appraisal">
                    <xsl:text>Informations sur l’évaluation</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:arrangement">
                    <xsl:text>Classement</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:bibliography">
                    <xsl:text>Bibliographie</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:bioghist">
                    <xsl:text>Biographie ou histoire</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:controlaccess">
                    <xsl:text>Accès controlés</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:custodhist">
                    <xsl:text>Historique de la conservation</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:odd">
                    <xsl:text>Autres descriptions documentaires</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:originalsloc">
                    <xsl:text>Existence et lieu de conservation des documents originaux</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:otherfindaid">
                    <xsl:text>Autre(s) instrument(s) de recherche</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:phystech">
                    <xsl:text>Caractéristiques matérielles et contraintes techniques</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:prefercite">
                    <xsl:text>Mention conseillée</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:processinfo">
                    <xsl:text>Informations sur le traitement</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:relatedmaterial">
                    <xsl:text>Documents en relation</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:scopecontent">
                    <xsl:text>Présentation du contenu</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:separatedmaterial">
                    <xsl:text>Documents séparés</xsl:text>
                  </xsl:when>
                  <xsl:when test="self::ead:userestrict">
                    <xsl:text>Conditions d’utilisation</xsl:text>
                  </xsl:when>
                </xsl:choose>
              </fo:block>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead:odd/ead:p | ead:custodhist/ead:p | ead:scopecontent/ead:p | ead:controlaccess/ead:p">
    <fo:block xsl:use-attribute-sets="para">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead:head">
    <xsl:choose>
      <xsl:when test="parent::ead:bibliography">
        <fo:block xsl:use-attribute-sets="head2">
          <xsl:apply-templates/>
        </fo:block>
      </xsl:when>
      <xsl:otherwise>
        <fo:block xsl:use-attribute-sets="head1">
          <xsl:apply-templates/>
        </fo:block>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ead:bibliography/ead:bibref | ead:bibliography/ead:p">
    <fo:block xsl:use-attribute-sets="bibref">
      <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead:list">
    <xsl:if test="ead:head">
      <fo:block xsl:use-attribute-sets="head-list">
        <xsl:apply-templates select="ead:head" mode="titre_liste"/>
      </fo:block>
    </xsl:if>
    <fo:list-block >
      <xsl:apply-templates/>
    </fo:list-block>
  </xsl:template>

  <xsl:template match="ead:item">
    <fo:list-item xsl:use-attribute-sets="item">
      <fo:list-item-label xsl:use-attribute-sets="item-puce">
        <fo:block>–</fo:block>
      </fo:list-item-label>
      <fo:list-item-body xsl:use-attribute-sets="item-corps">
        <fo:block xsl:use-attribute-sets="item-texte">
          <xsl:apply-templates/>
        </fo:block>
      </fo:list-item-body>
    </fo:list-item>
  </xsl:template>

  <xsl:template match="ead:list/ead:head" mode="titre_liste">
    <xsl:apply-templates select="node()"/>
  </xsl:template>
  <xsl:template match="ead:list/ead:head"></xsl:template>
  <!-- <xsl:template match="ead:head" mode="sanstitre"></xsl:template> -->
  <!-- Les mots clés -->

  <xsl:template match="ead:controlaccess/ead:geogname | ead:controlaccess/ead:subject | ead:controlaccess/ead:genreform | ead:controlaccess/ead:persname">
    <fo:inline>
      <xsl:apply-templates/>
    </fo:inline>
    <xsl:if test="position() != last()">
      <xsl:text> ; </xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- Les liens -->

  <xsl:template match="ead:extref">
    <fo:basic-link xsl:use-attribute-sets="liens" external-destination="{@xlink:href}">
      <xsl:apply-templates/>
    </fo:basic-link>
  </xsl:template>

  <xsl:template match="ead:ref">
    <!-- <fo:basic-link xsl:use-attribute-sets="liens" external-destination="{@xlink:href}"> -->
    <xsl:apply-templates/>
    <!-- </fo:basic-link> -->
  </xsl:template>

  <!-- Les images -->

  <xsl:template match="ead:daogrp[1]">
      <fo:inline xsl:use-attribute-sets="label">
      Document(s) iconographique(s)
    </fo:inline>
     <fo:block>
       <xsl:apply-templates/>
    </fo:block>
  </xsl:template>

  <xsl:template match="ead:daodesc">
     <fo:inline xsl:use-attribute-sets="label">
  <xsl:apply-templates/>
  </fo:inline>
</xsl:template>

  <xsl:template match="ead:daoloc">
  <fo:inline xsl:use-attribute-sets="content">
      [Image] <external-graphic src="{@*:href}" width="50%"/>
  <xsl:apply-templates/>
  </fo:inline>
</xsl:template>

 <xsl:template match="ead:dao">
   <fo:inline xsl:use-attribute-sets="label">
      FFDocument(s) iconographique(s) : 
     </fo:inline>
    <fo:block xsl:use-attribute-sets="content">
      [Image] <external-graphic src="url('file:/Users/anne/Documents/MaXStandaloneV2/maxTemplatesPDDN/templates-editions/max_ead_demo/ui/images/nummus/medaillier/DSCN7998.jpg')" width="5%"/>
  <xsl:apply-templates/>
   </fo:block>
</xsl:template>



</xsl:stylesheet>

