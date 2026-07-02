<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="xsl tei">


    <xsl:template match="@style">
        <xsl:choose>
            <xsl:when test=".='txt_Normal'">
                <xsl:attribute name="font-size">10pt</xsl:attribute>
                <xsl:attribute name="line-height">14pt</xsl:attribute>
                <xsl:attribute name="line-height-shift-adjustment">disregard-shifts</xsl:attribute>
                <xsl:attribute name="font-family">serif</xsl:attribute>
                <xsl:attribute name="language"><xsl:value-of select="$langue"/></xsl:attribute>
                <xsl:attribute name="hyphenate">true</xsl:attribute>
                <xsl:attribute name="hyphenation-character">-</xsl:attribute>
                <xsl:attribute name="hyphenation-remain-character-count">2</xsl:attribute>
                <xsl:attribute name="hyphenation-push-character-count">3</xsl:attribute>
            </xsl:when>
             <xsl:when test=".='T_chapitre'">
                <xsl:attribute name="font-family">serif</xsl:attribute>
                <xsl:attribute name="font-weight">bold</xsl:attribute>
                <xsl:attribute name="font-size">15pt</xsl:attribute>
                <xsl:attribute name="space-before">15pt</xsl:attribute>
                <xsl:attribute name="space-after">10pt</xsl:attribute>
                <xsl:attribute name="keep-with-next">always</xsl:attribute>
                <xsl:attribute name="text-align">center</xsl:attribute>

            </xsl:when>
            <xsl:when test=".='T_1'">
                <xsl:attribute name="font-family">serif</xsl:attribute>
                <xsl:attribute name="font-weight">bold</xsl:attribute>
                <xsl:attribute name="font-size">14pt</xsl:attribute>
                <xsl:attribute name="space-before">15pt</xsl:attribute>
                <xsl:attribute name="space-after">10pt</xsl:attribute>
                <xsl:attribute name="keep-with-next">always</xsl:attribute>
            </xsl:when>
            <xsl:when test=".='typo_Italique'">
                <xsl:attribute name="font-style">italic</xsl:attribute>
            </xsl:when>
            <xsl:when test=".='typo_SC'">
                <xsl:attribute name="font-variant">small-caps</xsl:attribute>
            </xsl:when>
            <xsl:when test=".='typo_Exposant'">
                <xsl:attribute name="font-size">7pt</xsl:attribute>
                <xsl:attribute name="baseline-shift">5pt</xsl:attribute>
            </xsl:when>
        </xsl:choose>
    </xsl:template>


    <xsl:attribute-set name="texte_cover">
        <xsl:attribute name="font-family">serif</xsl:attribute>
        <!-- <xsl:attribute name="font-weight">bold</xsl:attribute> -->
        <xsl:attribute name="space-after">2pt</xsl:attribute>
        <xsl:attribute name="margin-top">5pt</xsl:attribute>
        <xsl:attribute name="font-size">10pt</xsl:attribute>
        <xsl:attribute name="text-align">left</xsl:attribute>
        
    </xsl:attribute-set> 

    <xsl:attribute-set name="author_cover">
        <xsl:attribute name="padding">2pt</xsl:attribute>
        <xsl:attribute name="padding-top">5pt</xsl:attribute>
        <xsl:attribute name="font-family">serif</xsl:attribute>
        <!-- <xsl:attribute name="font-weight">bold</xsl:attribute> -->
        <xsl:attribute name="space-after">2pt</xsl:attribute>
        <xsl:attribute name="margin-top">20pt</xsl:attribute>
        <xsl:attribute name="font-size">12pt</xsl:attribute>
        <xsl:attribute name="text-align">left</xsl:attribute>
    </xsl:attribute-set> 

    <xsl:attribute-set name="sous_titreCouv">
     <xsl:attribute name="margin-top">20pt</xsl:attribute>
        <xsl:attribute name="padding">2pt</xsl:attribute>
        <xsl:attribute name="font-family">serif</xsl:attribute>
        <xsl:attribute name="font-size">11pt</xsl:attribute>
        <xsl:attribute name="text-align">left</xsl:attribute>
        <xsl:attribute name="color">black</xsl:attribute>
        <xsl:attribute name="color">grey</xsl:attribute>
    </xsl:attribute-set> 

      <xsl:attribute-set name="affiliation_cover">
        <xsl:attribute name="padding">2pt</xsl:attribute>
        <xsl:attribute name="padding-top">5pt</xsl:attribute>
        <xsl:attribute name="font-family">serif</xsl:attribute>
        <!-- <xsl:attribute name="font-weight">regular</xsl:attribute> -->
        <xsl:attribute name="space-after">2pt</xsl:attribute>
        <xsl:attribute name="font-size">12pt</xsl:attribute>
        <xsl:attribute name="text-align">left</xsl:attribute>
    </xsl:attribute-set> 
    
    <xsl:attribute-set name="ref_cover">
        <xsl:attribute name="padding">2pt</xsl:attribute>
        <xsl:attribute name="padding-top">5pt</xsl:attribute>
        <xsl:attribute name="font-family">serif</xsl:attribute>
        <!-- <xsl:attribute name="font-weight">regular</xsl:attribute> -->
        <xsl:attribute name="space-after">2pt</xsl:attribute>
        <xsl:attribute name="font-size">10pt</xsl:attribute>
        <xsl:attribute name="text-align">left</xsl:attribute>
    </xsl:attribute-set> 

    <xsl:attribute-set name="citation">
    <xsl:attribute name="font-family">serif Light</xsl:attribute>
      <xsl:attribute name="font-size">10pt</xsl:attribute>
      <xsl:attribute name="line-height">14pt</xsl:attribute>
      <xsl:attribute name="line-height-shift-adjustment">disregard-shifts</xsl:attribute>
      <xsl:attribute name="margin-left">10mm</xsl:attribute>
      <xsl:attribute name="space-before">20pt</xsl:attribute>
      <xsl:attribute name="space-after">10pt</xsl:attribute>
    </xsl:attribute-set>


  <!-- Les liens -->
  <xsl:attribute-set name="liens">
    <xsl:attribute name="color">grey</xsl:attribute>
    <xsl:attribute name="text-decoration">underline</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="content">
    <xsl:attribute name="margin-top">3pt</xsl:attribute>
    <xsl:attribute name="font-family">serif</xsl:attribute>
    <xsl:attribute name="line-height">1.3</xsl:attribute>
  </xsl:attribute-set>


  <xsl:attribute-set name="div">
    <xsl:attribute name="font-size">10pt</xsl:attribute>
    <xsl:attribute name="text-align">justify</xsl:attribute>
    <xsl:attribute name="margin-top">5pt</xsl:attribute>
    <xsl:attribute name="margin-bottom">5pt</xsl:attribute>
    <!-- <xsl:attribute name="border">solid 1pt red</xsl:attribute> -->
  </xsl:attribute-set>


  <xsl:attribute-set name="prettyName">
    <xsl:attribute name="margin-right">10pt</xsl:attribute>
    <xsl:attribute name="margin-left">10pt</xsl:attribute>
    <xsl:attribute name="margin-top">1mm</xsl:attribute>
    <xsl:attribute name="padding">2pt</xsl:attribute>
    <xsl:attribute name="font-size">14pt</xsl:attribute>
    <xsl:attribute name="font-style">italic</xsl:attribute>
    <xsl:attribute name="font-family">serif</xsl:attribute>
    <xsl:attribute name="text-align">center</xsl:attribute>
    <xsl:attribute name="color">grey</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="titlePage">
    <xsl:attribute name="margin-right">0pt</xsl:attribute> 
            <xsl:attribute name="margin-left">0pt</xsl:attribute>
            <xsl:attribute name="margin-top">1mm</xsl:attribute>
            <xsl:attribute name="padding">2pt</xsl:attribute>
            <xsl:attribute name="font-size">7pt</xsl:attribute>
            <xsl:attribute name="font-family">serif</xsl:attribute>
            <xsl:attribute name="text-align">right</xsl:attribute>
  </xsl:attribute-set>

   <xsl:attribute-set name="head">
        <xsl:attribute name="padding">2pt</xsl:attribute>
        <xsl:attribute name="padding-top">5pt</xsl:attribute>
        <xsl:attribute name="font-family">serif</xsl:attribute>
        <xsl:attribute name="font-weight">bold</xsl:attribute>
        <xsl:attribute name="space-after">30pt</xsl:attribute>
        <xsl:attribute name="margin-top">10pt</xsl:attribute>
        <xsl:attribute name="font-size">15pt</xsl:attribute>
        <xsl:attribute name="text-align">center</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="head2">
        <xsl:attribute name="padding">2pt</xsl:attribute>
        <xsl:attribute name="font-family">Calibri Light</xsl:attribute>
        <xsl:attribute name="space-after">15pt</xsl:attribute>
        <xsl:attribute name="font-size">12pt</xsl:attribute>
        <xsl:attribute name="text-align">left</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="head3">
        <xsl:attribute name="padding">2pt</xsl:attribute>
        <xsl:attribute name="font-family">Junicode</xsl:attribute>
        <xsl:attribute name="space-after">15pt</xsl:attribute>
        <xsl:attribute name="font-size">12pt</xsl:attribute>
        <xsl:attribute name="text-align">left</xsl:attribute>
    </xsl:attribute-set>

  <xsl:attribute-set name="general">
    <xsl:attribute name="font-size">10pt</xsl:attribute>
    <xsl:attribute name="text-align">justify</xsl:attribute>
    <xsl:attribute name="font-family">serif</xsl:attribute>
  </xsl:attribute-set>


  <xsl:attribute-set name="ref_bibliographique">
    <xsl:attribute name="line-height">14pt</xsl:attribute>
    <xsl:attribute name="line-height-shift-adjustment">disregard-shifts</xsl:attribute>
    <xsl:attribute name="text-indent">-6mm</xsl:attribute>
    <xsl:attribute name="margin-left">6mm</xsl:attribute>
    <xsl:attribute name="space-after">10pt</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="notes">
    <xsl:attribute name="margin-top">10pt</xsl:attribute>
    <xsl:attribute name="padding-top">5pt</xsl:attribute>
    <xsl:attribute name="font-size">7pt</xsl:attribute>
    <xsl:attribute name="baseline-shift">5pt</xsl:attribute>
    <xsl:attribute name="text-align">right</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="p_notes">
    <xsl:attribute name="text-indent">-10mm</xsl:attribute>
    <xsl:attribute name="margin-left">10mm</xsl:attribute>
    <xsl:attribute name="font-size">9pt</xsl:attribute>
    <xsl:attribute name="font-weight">normal</xsl:attribute>
    <xsl:attribute name="line-height">11pt</xsl:attribute>
    <xsl:attribute name="line-height-shift-adjustment">disregard-shifts</xsl:attribute>
  </xsl:attribute-set>


    <xsl:attribute-set name="table">
    <xsl:attribute name="background-color">#ffffff</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="cell">
    <xsl:attribute name="font-size">9pt</xsl:attribute>
    <xsl:attribute name="text-align">justify</xsl:attribute>
    <xsl:attribute name="padding">3pt</xsl:attribute>
    <xsl:attribute name="font-weight">normal</xsl:attribute>
  </xsl:attribute-set>

    <xsl:attribute-set name="figures">
      <xsl:attribute name="font-size">8pt</xsl:attribute>
      <xsl:attribute name="line-height">12pt</xsl:attribute> 
      <xsl:attribute name="line-height-shift-adjustment">disregard-shifts</xsl:attribute>
      <xsl:attribute name="font-family">Calibri Light</xsl:attribute>
      <xsl:attribute name="margin-left">10mm</xsl:attribute>
      <xsl:attribute name="margin-right">10mm</xsl:attribute>
      <xsl:attribute name="text-align">center</xsl:attribute>
      <xsl:attribute name="space-before">20pt</xsl:attribute>
      <xsl:attribute name="space-after">20pt</xsl:attribute>
    </xsl:attribute-set>

</xsl:stylesheet>