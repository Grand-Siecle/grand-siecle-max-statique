<?xml version="1.0" encoding="UTF-8"?>
<!-- 
For conditions of distribution and use, see the accompanying legal.txt file.
 -->

<xsl:stylesheet	version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="tei xsl">



    <xsl:template match="//tei:app">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="//tei:lem">
        <span>
            <xsl:attribute name="class">
                <xsl:if test="count(.//tei:lem)=0">
                    <xsl:text>lem apparat </xsl:text>
                </xsl:if>
                <xsl:value-of select="translate(@wit,'#','')"/>
            </xsl:attribute>
            <xsl:attribute name="data-witnesses">
              <xsl:value-of select="translate(@wit,'#','')"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="//tei:rdg">
        <span>
            <xsl:attribute name="class">
                <xsl:value-of select="concat(translate(@wit,'#',''),' apparat')"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>

    </xsl:template>

    <xsl:template match="//tei:witDetail">
      <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="//tei:lacunaStart | //tei:lacunaEnd">    
      <span>
        <xsl:attribute name='class'>
          <xsl:value-of select='name(.)'/>
        </xsl:attribute>
        <xsl:attribute name='data-lacuna-synch'>
          <xsl:value-of select='@synch'/>
        </xsl:attribute>
        <xsl:attribute name='data-lacuna-wit'>
          <xsl:value-of select='@wit'/>
        </xsl:attribute>
        <xsl:attribute name='id'>
          <xsl:value-of select='@xml:id'/>
        </xsl:attribute>
      </span>
    </xsl:template>
    
    <xsl:template match="//tei:span[contains(@class,'varLong')]">
        <span>
            <xsl:attribute name="class"><xsl:value-of select="@class"/></xsl:attribute><xsl:apply-templates/>
        </span>
    </xsl:template>
    


</xsl:stylesheet>