<?xml version="1.0" encoding="UTF-8" ?>
<!--
 For conditions of distribution and use, see the accompanying legal.txt file.
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:ead="urn:isbn:1-931666-22-9"
  xmlns:max="https://max.unicaen.fr"
  exclude-result-prefixes="tei xsl ead xlink max">

    <xsl:import href="../../ui/xsl/core/i18n.xsl"/>
    <xsl:param name="imagesRepository"/>
    <xsl:param name="locale"/>

    <xsl:template match="tei:pb">
        <xsl:variable name="href">
            <xsl:choose>
                <xsl:when test="starts-with(@facs,'http')">
                    <xsl:value-of select="@facs"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($baseuri,$imagesRepository,@facs)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <a>
            <xsl:attribute name="class">pb img_viewer_link</xsl:attribute>
            <xsl:attribute name="name">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
            <xsl:attribute name="href">#</xsl:attribute>
            <xsl:attribute name="onclick">MAX.plugins['img_viewer'].openImageInDialog('<xsl:value-of select="$href"/>')</xsl:attribute>
            <xsl:value-of select="@n"/>
        </a>
    </xsl:template>


    <xsl:template match="tei:figure">
        <div class="figure">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="tei:graphic|ead:dao">
      <xsl:variable name="link">
        <xsl:choose>
          <xsl:when test="@url">
            <xsl:value-of select="@url"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@*:href"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="href">
        <xsl:value-of select="concat($baseuri,$imagesRepository ,$link)"/>
      </xsl:variable>
      <xsl:variable name="id">
        <xsl:value-of select="generate-id(.) "/>
      </xsl:variable>
      <img class="viewable img_viewer_link" id="{$id}">
        <xsl:attribute name="onclick">MAX.plugins['img_viewer'].openImageInDialog('<xsl:value-of select="$href"/>')</xsl:attribute>
        <xsl:attribute name="src">
          <xsl:value-of select="concat($baseuri,$imagesRepository,$link)"/>
        </xsl:attribute>
      </img>
    </xsl:template>

    <xsl:template match="ead:daogrp">
      <div id="diaporama">
        <h2>
          <xsl:value-of select="max:i18n($project,'label.daogrp',$locale)"/>
      </h2>
        <xsl:apply-templates/>
      </div>
    </xsl:template>

    <xsl:template match="ead:daoloc">
      <img class="img_viewer_link">
        <xsl:attribute name="src">
          <xsl:value-of select="concat($baseuri,$imagesRepository)"/>
          <xsl:value-of select="@*:href"/>
        </xsl:attribute>
        <xsl:attribute name="href">#</xsl:attribute>
        <xsl:attribute name="onclick">
          <xsl:text>MAX.plugins['img_viewer'].openImagesInDialog('</xsl:text>
          <xsl:value-of select="concat($baseuri,$imagesRepository)"/>
          <xsl:value-of select="@*:href"/>
          <xsl:text>')</xsl:text>
        </xsl:attribute>
      </img>
    </xsl:template>

</xsl:stylesheet>
