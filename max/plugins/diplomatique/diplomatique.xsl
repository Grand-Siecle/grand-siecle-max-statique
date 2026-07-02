<?xml version="1.0" encoding="UTF-8"?>
<!--
 For conditions of distribution and use, see the accompanying legal.txt file.
-->

<xsl:stylesheet	version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="tei xsl">


  <xsl:template match="tei:choice"><xsl:apply-templates/></xsl:template> 
   
  <xsl:template match="tei:sic | tei:corr">
    <span>
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)"/>
      </xsl:attribute><xsl:apply-templates/>
    </span>
  </xsl:template>

   <xsl:template match="tei:orig | tei:reg">
    <span>
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)"/>
      </xsl:attribute><xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="tei:am | tei:ex">
    <span>
      <xsl:attribute name="class">
        <xsl:value-of select="local-name(.)"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  
  
  <xsl:template match="tei:abbr">
    <span class="am">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="tei:expan">
    <span class="ex">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
    
</xsl:stylesheet>