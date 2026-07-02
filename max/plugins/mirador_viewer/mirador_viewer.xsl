<?xml version="1.0" encoding="UTF-8" ?>
<!--
 For conditions of distribution and use, see the accompanying legal.txt file.
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:ead="urn:isbn:1-931666-22-9" 
  exclude-result-prefixes="tei xsl ead xlink">



  <!-- ead -->
  <!-- lien (sans imagette) -->
  <!-- Ugly template for alpha tests-->
  <xsl:template match="ead:extref[contains(@xlink:href,'/manifest')]">
   <xsl:variable name="iiifLink">
      <xsl:value-of select="$baseuri"/>
      <xsl:value-of select="$project"/>
      <xsl:text>/mirador/?link=</xsl:text>
      <xsl:choose>
        <xsl:when test="contains(@xlink:href,'#')">
          <xsl:value-of select="substring-before(@xlink:href,'#')"/>
          <xsl:choose>
            <xsl:when test="contains(@xlink:href,'#http')">
              <xsl:text>&amp;canvasId=</xsl:text>
              <xsl:value-of select="substring-after(@xlink:href,'#')"/>
              <xsl:text>&amp;canvasIndex=</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>&amp;canvasId=&amp;canvasIndex=</xsl:text>
              <xsl:value-of select="substring-after(@xlink:href,'#')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@xlink:href"/>
          <xsl:text>&amp;canvasId=&amp;canvasIndex=</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <span onclick="window.open('{$iiifLink}','Mirador Viewer','width=800,height=600,location=no')" class="mirador-link"><xsl:value-of select="."/></span>
  </xsl:template>

  <!-- dao avec imagette -->
    <!-- dao avec imagette -->
  <xsl:template match="ead:dao[@entityref='iiif_manifest']">
    <xsl:variable name="iiifLink">
      <xsl:value-of select="$baseuri"/>
      <xsl:value-of select="$project"/>
      <xsl:text>/mirador/?link=</xsl:text>
      <xsl:choose>
        <xsl:when test="contains(@xlink:href,'#')">
          <xsl:value-of select="substring-before(@xlink:href,'#')"/>
          <xsl:choose>
            <xsl:when test="contains(@xlink:href,'#http')">
              <xsl:text>&amp;canvasId=</xsl:text>
              <xsl:value-of select="substring-after(@xlink:href,'#')"/>
              <xsl:text>&amp;canvasIndex=</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>&amp;canvasId=&amp;canvasIndex=</xsl:text>
              <xsl:value-of select="substring-after(@xlink:href,'#')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@xlink:href"/>
          <xsl:text>&amp;canvasId=&amp;canvasIndex=</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="imgId">
      <xsl:text>thumbnail</xsl:text>
      <xsl:value-of select="count(preceding::*:dao[@entityref='iiif_manifest'])+1"/>
    </xsl:variable>
    <span onclick="window.open('{$iiifLink}','Mirador Viewer','width=800,height=600,location=no')" class="mirador-link">
      <xsl:value-of select="."/>
    </span>
    <figure>
      <img id="{$imgId}" src="{@xpointer}" onclick="window.open('{$iiifLink}','Mirador Viewer','width=800,height=600,location=no')" class="mirador-link">
      </img>
    </figure>
  </xsl:template>
  
  <!-- tei -->
  <xsl:template match="tei:pb[@tei:rend='iiif_manifest']">
    <xsl:variable name="iiifLink">
      <xsl:value-of select="$baseuri"/>
      <xsl:value-of select="$project"/>
      <xsl:text>/mirador/?link=</xsl:text>
      <xsl:value-of select="@tei:n"/>
    </xsl:variable>

    <span onclick="window.open('{$iiifLink}','Mirador Viewer','width=800,height=600,location=no')">
      <xsl:attribute name="class">pb mirador-link</xsl:attribute>
      <xsl:attribute name="name">
        <xsl:value-of select="@xml:id"/>
      </xsl:attribute>
      <xsl:value-of select="@tei:n"/>
    </span>
  </xsl:template>


</xsl:stylesheet>                
