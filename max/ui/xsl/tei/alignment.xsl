<?xml version="1.0" encoding="UTF-8"?>
<!--For conditions of distribution and use, see the accompanying legal.txt file.-->

<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="tei xsl">


    <xsl:param name="first-prefix"/>
    <xsl:param name="second-prefix"/>


    <xsl:template match="align">
        <div id="text">
            <xsl:apply-templates select="descendant::tei:div[starts-with(@xml:id, $first-prefix)]"/>
            <div id='bas_de_page'>
                <xsl:call-template name="align_bas_de_page"/>
            </div>
        </div>
    </xsl:template>


    <xsl:template match="align//tei:div[@type] | align//div[@type]">
        <xsl:choose>
            <xsl:when test="starts-with(@xml:id,$first-prefix)">
                <div class="{@type}">
                    <xsl:apply-templates/>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="align//tei:p | align//tei:head | align//tei:opener">
        <div>
            <xsl:attribute name="class">
                <xsl:value-of select="local-name(.)"/>
            </xsl:attribute>
            <xsl:if test="starts-with(../@xml:id, $first-prefix)">
                <xsl:choose>
                    <xsl:when test="local-name(.)='head'">
                        <h2 class="align-left subpart">
                            <xsl:attribute name="id">
                                <xsl:value-of select="@xml:id"/>
                            </xsl:attribute>
                            <xsl:apply-templates/>
                        </h2>
                    </xsl:when>
                    <xsl:otherwise>
                        <p class="align-left">
                            <xsl:attribute name="id">
                                <xsl:value-of select="@xml:id"/>
                            </xsl:attribute>
                            <xsl:apply-templates/>
                        </p>
                    </xsl:otherwise>
                </xsl:choose>

                <xsl:variable name="alignedID">
                    <xsl:value-of select="concat($second-prefix,substring-after(@xml:id,$first-prefix))"/>
                </xsl:variable>

                <xsl:choose>
                    <xsl:when test="local-name(.)='head'">
                        <h2 class="align-right subpart">
                            <xsl:call-template name="aligner">
                                <xsl:with-param name="alignedID" select="$alignedID"/>
                            </xsl:call-template>
                        </h2>
                    </xsl:when>
                    <xsl:otherwise>
                        <p class="align-right">
                            <xsl:call-template name="aligner">
                                <xsl:with-param name="alignedID" select="$alignedID"/>
                            </xsl:call-template>
                        </p>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <div class='clearer'/>
        </div>
    </xsl:template>


    <!--Surcharge des notes-->
    <xsl:template match="//tei:note">
        <xsl:variable name="currentPrefix">
            <xsl:choose>
                <xsl:when test="starts-with(@xml:id, $first-prefix)">
                    <xsl:value-of select="$first-prefix"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$second-prefix"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name='numeroNote'>
            <xsl:value-of select="count(preceding::tei:note[starts-with(@xml:id, $currentPrefix)])+1"/>
        </xsl:variable>

        <a>
            <xsl:attribute name="class">note</xsl:attribute>
            <xsl:attribute name="id">appel<xsl:value-of select="$currentPrefix"/><xsl:value-of select="$numeroNote"/>
            </xsl:attribute>
            <xsl:attribute name="href">#bdp<xsl:value-of select="$currentPrefix"/><xsl:value-of select="$numeroNote"/>
            </xsl:attribute>
            <xsl:value-of select="$numeroNote"/>
        </a>
    </xsl:template>


    <xsl:template name="aligner">
        <xsl:param name="alignedID"/>
        <xsl:for-each select="//*[@xml:id=$alignedID]">
            <xsl:apply-templates/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="align_bas_de_page">
        <div class="align-left">
            <xsl:call-template name="notes_by_prefix">
                <xsl:with-param name="prefix" select="$first-prefix"/>
            </xsl:call-template>
        </div>

        <div class="align-right">
            <xsl:call-template name="notes_by_prefix">
                <xsl:with-param name="prefix" select="$second-prefix"/>
            </xsl:call-template>
        </div>

    </xsl:template>

    <xsl:template name="notes_by_prefix">
        <xsl:param name="prefix"/>

        <xsl:for-each select="//tei:note[starts-with(@xml:id, $prefix)]">
            <xsl:variable name="numeroNote">
                <xsl:value-of select="count(preceding::tei:note[starts-with(@xml:id, $prefix)])+1"/>
            </xsl:variable>
            <p>
                <a>
                    <xsl:attribute name="class">note_to_text footnote</xsl:attribute>
                    <xsl:attribute name="name">bdp<xsl:value-of select="$prefix"/><xsl:value-of select="$numeroNote"/>
                    </xsl:attribute>
                    <xsl:attribute name="href">
                        <xsl:value-of select="concat('#appel', $prefix, $numeroNote)"/>
                    </xsl:attribute>
                    <xsl:value-of select="$numeroNote"/>
                </a>
                <xsl:apply-templates/>
            </p>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>