<?xml version="1.0" encoding="UTF-8"?>
<!--
 For conditions of distribution and use, see the accompanying legal.txt file.
-->

<xsl:stylesheet	version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="tei xsl">
     
           
  <xsl:template match="tei:formula[@notation='TeX']">
          <span class='tex'><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="tei:formula[not(@notation='TeX')]">
          <span class='formula'><xsl:apply-templates/></span>
  </xsl:template>
  
  <!-- Attention ! balises utilisées pour le plugin normalisation
  
  <xsl:template match="tei:orig">
          <xsl:apply-templates/>
  </xsl:template>
  
    <xsl:template match="tei:reg">
          <xsl:apply-templates/>
  </xsl:template> -->
  
</xsl:stylesheet>