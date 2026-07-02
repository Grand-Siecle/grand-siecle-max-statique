<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ead="urn:isbn:1-931666-22-9" exclude-result-prefixes="xsl ead">

  <xsl:variable name="langue">
    <xsl:value-of select="//ead:language"/>
  </xsl:variable>

  <xsl:template match="@render">
    <xsl:choose>
      <xsl:when test=".='italic'">
        <xsl:attribute name="font-style">italic</xsl:attribute>
      </xsl:when>
      <xsl:when test=".='smcaps'">
        <!-- <xsl:attribute name="font-variant">small-caps</xsl:attribute> -->
        <xsl:attribute name="text-transform">uppercase</xsl:attribute>
        <!-- <xsl:attribute name="color">red</xsl:attribute> -->
        <xsl:attribute name="font-size">85%</xsl:attribute>
      </xsl:when>
      <xsl:when test=".='super'">
        <xsl:attribute name="font-size">7pt</xsl:attribute>
        <xsl:attribute name="baseline-shift">3pt</xsl:attribute>
      </xsl:when>
      <xsl:when test=".='bold'">
        <xsl:attribute name="font-weight">bold</xsl:attribute>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  <!-- Les liens -->
  <xsl:attribute-set name="liens">
    <xsl:attribute name="color">grey</xsl:attribute>
    <xsl:attribute name="text-decoration">underline</xsl:attribute>
  </xsl:attribute-set>

  <!-- styles des composants -->
  <xsl:attribute-set name="composants">
    <xsl:attribute name="font-size">10pt</xsl:attribute>
    <xsl:attribute name="font-family">serif</xsl:attribute>
    <xsl:attribute name="page-break-after">always</xsl:attribute>
  </xsl:attribute-set>

 <xsl:attribute-set name="infoParent">
    <!-- <xsl:attribute name="border">1px solid red</xsl:attribute> -->
    <!-- <xsl:attribute name="margin-bottom">10pt</xsl:attribute> -->
    <xsl:attribute name="background-color">#EEEEEE</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="infoEnfants">
    <!-- <xsl:attribute name="border">1px solid black</xsl:attribute> -->
     <xsl:attribute name="background-color">#EEEEEE</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="table">
    <xsl:attribute name="background-color">#EEEEEE</xsl:attribute>
  </xsl:attribute-set>
  <xsl:attribute-set name="cell">
    <xsl:attribute name="font-size">9pt</xsl:attribute>
    <xsl:attribute name="text-align">left</xsl:attribute>
    <xsl:attribute name="padding">10pt</xsl:attribute>
    <xsl:attribute name="border">1pt solid green</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="label">
  <xsl:attribute name="padding-left">10pt</xsl:attribute>
    <xsl:attribute name="margin-top">3pt</xsl:attribute>
    <xsl:attribute name="font-size">9pt</xsl:attribute>
    <xsl:attribute name="font-family">serif</xsl:attribute>
    <xsl:attribute name="line-height">1.3</xsl:attribute>
    <!-- <xsl:attribute name="color">pink</xsl:attribute> -->
  </xsl:attribute-set>

  <xsl:attribute-set name="content">
    <xsl:attribute name="margin-top">3pt</xsl:attribute>
    <xsl:attribute name="font-size">9pt</xsl:attribute>
    <xsl:attribute name="font-family">serif</xsl:attribute>
    <xsl:attribute name="line-height">1.3</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="tableBorder">
    <xsl:attribute name="border">solid 0.1mm black</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="div">
    <xsl:attribute name="font-size">10pt</xsl:attribute>
    <xsl:attribute name="text-align">justify</xsl:attribute>
    <xsl:attribute name="margin-top">5pt</xsl:attribute>
    <xsl:attribute name="margin-bottom">5pt</xsl:attribute>
    <xsl:attribute name="padding">5pt</xsl:attribute>
    <xsl:attribute name="padding-bottom">5pt</xsl:attribute>
    <!-- <xsl:attribute name="border">solid 1pt red</xsl:attribute> -->
  </xsl:attribute-set>

   <xsl:attribute-set name="divDid">
    <xsl:attribute name="font-size">10pt</xsl:attribute>
    <xsl:attribute name="text-align">justify</xsl:attribute>
    <xsl:attribute name="padding">5pt</xsl:attribute>
    <xsl:attribute name="padding-bottom">5pt</xsl:attribute>
   
  </xsl:attribute-set>

  <xsl:attribute-set name="para">
    <xsl:attribute name="font-size">9pt</xsl:attribute>
    <xsl:attribute name="font-family">serif</xsl:attribute>
    <xsl:attribute name="line-height">14pt</xsl:attribute>
    <xsl:attribute name="line-height-shift-adjustment">disregard-shifts</xsl:attribute>
    <xsl:attribute name="hyphenate">true</xsl:attribute>
    <xsl:attribute name="hyphenation-character">-</xsl:attribute>
    <xsl:attribute name="hyphenation-remain-character-count">2</xsl:attribute>
    <xsl:attribute name="hyphenation-push-character-count">3</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="containerPrettyName">
    <xsl:attribute name="position">relative</xsl:attribute>
    <xsl:attribute name="top">0cm</xsl:attribute>
    <xsl:attribute name="left">0cm</xsl:attribute>
    <xsl:attribute name="width">100%</xsl:attribute>
    <xsl:attribute name="height">1cm</xsl:attribute>
    <xsl:attribute name="background-color">#93A9BE</xsl:attribute>
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
    <xsl:attribute name="color">#fff</xsl:attribute>
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

  <xsl:attribute-set name="head1">
    <xsl:attribute name="font-family">serif</xsl:attribute>
    <xsl:attribute name="padding-top">10pt</xsl:attribute>
    <xsl:attribute name="padding-bottom">5pt</xsl:attribute>
    <xsl:attribute name="font-size">12pt</xsl:attribute>
    <xsl:attribute name="text-align">left</xsl:attribute>
    <xsl:attribute name="color">#0056b3</xsl:attribute>
  </xsl:attribute-set>
  <xsl:attribute-set name="head2">
    <xsl:attribute name="font-family">serif</xsl:attribute>
    <xsl:attribute name="padding-top">4pt</xsl:attribute>
    <xsl:attribute name="padding-bottom">3pt</xsl:attribute>
    <xsl:attribute name="font-size">10pt</xsl:attribute>
    <xsl:attribute name="text-align">left</xsl:attribute>
    <xsl:attribute name="color">#0056b3</xsl:attribute>
  </xsl:attribute-set>
  <xsl:attribute-set name="head-list">
    <xsl:attribute name="font-family">serif</xsl:attribute>
    <xsl:attribute name="margin-top">5pt</xsl:attribute>
    <xsl:attribute name="margin-left">10pt</xsl:attribute>
    <xsl:attribute name="font-size">10pt</xsl:attribute>
    <xsl:attribute name="text-align">left</xsl:attribute>
    <xsl:attribute name="font-size">9pt</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="item">
    <xsl:attribute name="space-before.optimum">5pt</xsl:attribute>
    <xsl:attribute name="margin-left">10pt</xsl:attribute>
    <!-- <xsl:attribute name="border">1pt solid black</xsl:attribute> -->
  </xsl:attribute-set>

  <xsl:attribute-set name="item-puce">
    <xsl:attribute name="end-indent">label-end()</xsl:attribute>
    <xsl:attribute name="margin-left">15pt</xsl:attribute>
    <!-- <xsl:attribute name="border">1pt solid blue</xsl:attribute> -->
  </xsl:attribute-set>
  <xsl:attribute-set name="item-corps">
    <xsl:attribute name="start-indent">body-start()</xsl:attribute>
    <xsl:attribute name="font-size">9pt</xsl:attribute>
    <!-- <xsl:attribute name="border">1pt solid red</xsl:attribute> -->

  </xsl:attribute-set>
  <xsl:attribute-set name="item-texte">
    <xsl:attribute name="text-align">justify</xsl:attribute>
    <xsl:attribute name="font-family">serif</xsl:attribute>
    <xsl:attribute name="font-size">9pt</xsl:attribute>
    <!-- <xsl:attribute name="border">1pt solid green</xsl:attribute> -->
  </xsl:attribute-set>

  <xsl:attribute-set name="bibref">
    <xsl:attribute name="font-family">serif</xsl:attribute>
    <xsl:attribute name="font-size">9pt</xsl:attribute>
    <xsl:attribute name="line-height-shift-adjustment">disregard-shifts</xsl:attribute>
    <xsl:attribute name="text-indent">-6mm</xsl:attribute>
    <xsl:attribute name="margin-left">6mm</xsl:attribute>
    <xsl:attribute name="space-after">5pt</xsl:attribute>
  </xsl:attribute-set>
  <!-- Héritage Pierre-Yves -->

  <xsl:attribute-set name="general">
    <xsl:attribute name="font-size">10pt</xsl:attribute>
    <xsl:attribute name="text-align">justify</xsl:attribute>
    <xsl:attribute name="font-family">serif</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="citation">
    <xsl:attribute name="font-size">10pt</xsl:attribute>
    <xsl:attribute name="line-height">12pt</xsl:attribute>
    <xsl:attribute name="line-height-shift-adjustment">disregard-shifts</xsl:attribute>
    <xsl:attribute name="margin-left">10mm</xsl:attribute>
    <xsl:attribute name="space-before">10pt</xsl:attribute>
    <xsl:attribute name="space-after">10pt</xsl:attribute>
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
    <xsl:attribute name="text-align">justify</xsl:attribute>
  </xsl:attribute-set>

  <xsl:attribute-set name="p_notes">
    <xsl:attribute name="text-indent">-10mm</xsl:attribute>
    <xsl:attribute name="margin-left">10mm</xsl:attribute>
    <xsl:attribute name="font-size">9pt</xsl:attribute>
    <xsl:attribute name="font-weight">normal</xsl:attribute>
    <xsl:attribute name="line-height">11pt</xsl:attribute>
    <xsl:attribute name="line-height-shift-adjustment">disregard-shifts</xsl:attribute>
  </xsl:attribute-set>
</xsl:stylesheet>