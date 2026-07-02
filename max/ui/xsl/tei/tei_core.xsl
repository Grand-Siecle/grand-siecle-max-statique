<?xml version="1.0" encoding="UTF-8"?>
<!--
 For conditions of distribution and use, see the accompanying legal.txt file.
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="tei xsl">

    <xsl:import href="document_title.xsl"/>

    <xsl:output method="xml" encoding="utf-8"/>

    <xsl:param name="baseuri"/>
    <xsl:param name="project"/>
    <xsl:param name="route"/>
    <xsl:param name="id"/>

    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>


    <xsl:template match="/tei:div | /tei:body | /div | /tei:list">

           <div id='text' class="col-sm-8">
                <xsl:apply-templates />
            <div id='bas_de_page'>
                <xsl:call-template name="bas_de_page"/>
            </div>
           </div>
    </xsl:template>

    <xsl:template match="//tei:text | //tei:body">
      <div>
        <xsl:apply-templates />
      </div>
    </xsl:template>

     <!-- toutes les divs sauf si racine-->
    <xsl:template match="//tei:div[parent::*]">
      <div>
            <xsl:if test="@xml:id">
              <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
            </xsl:if>
            <xsl:apply-templates />
      </div>
    </xsl:template>

    <!-- transformation des <head> en <h2>-->
    <xsl:template match="//tei:head" >
        <h2>
            <xsl:attribute name="class">subpart</xsl:attribute>
            <xsl:apply-templates />
        </h2>
    </xsl:template>

    <!-- les paragraphes -->
    <xsl:template match="//tei:p" >
            <p>
                <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
                <xsl:apply-templates />
            </p>

    </xsl:template>
    <!-- fin paragraphes-->

    <!--Notes de bas de page: dans le flux de texte, on place les appels de note-->
    <xsl:template match="//tei:note[@place='footer']" >
        <xsl:variable name='numeroNote'>
            <xsl:value-of select="count(preceding::tei:note[@place='footer'])+1"/>
        </xsl:variable>

        <a>
            <xsl:attribute name="class">note</xsl:attribute>
            <xsl:attribute name="id">appel<xsl:value-of select="$numeroNote"/></xsl:attribute>
            <xsl:attribute name="href">#bdp<xsl:value-of select="$numeroNote"/></xsl:attribute>
            <!-- tooltiping -->
            <xsl:attribute name="data-bs-toggle">tooltip</xsl:attribute>
            <xsl:attribute name="title">
                <xsl:apply-templates></xsl:apply-templates>
            </xsl:attribute>
            <!-- Contenu: numéro de la note -->
            <xsl:value-of select="$numeroNote"/>
        </a>
    </xsl:template>


    <!--template bas de page-->
    <xsl:template name="bas_de_page">
        <xsl:for-each select="//tei:note[@place='footer']">
            <xsl:variable name="numeroNote">
                <xsl:value-of select="count(preceding::tei:note[@place='footer'])+1"/>
            </xsl:variable>
            <div id="wrap_bdp_{$numeroNote}" class="footnote">
                <a>
                    <xsl:attribute name="class">note_to_text</xsl:attribute>
                    <xsl:attribute name="name">bdp<xsl:value-of select="$numeroNote"/></xsl:attribute>
                    <xsl:attribute name="href"><xsl:value-of select="concat('#appel', $numeroNote)"/></xsl:attribute>
                    <xsl:value-of select="$numeroNote"/>
                </a>
                <xsl:apply-templates />
            </div>
        </xsl:for-each>
    </xsl:template>

    <!-- Notes de type manchette-->
    <xsl:template match='//tei:note[@type="marginalia"]' >
        <xsl:variable name='numeroNote'>
            <xsl:value-of select='count(.|preceding::tei:note[@type="marginalia"])'/>
        </xsl:variable>
        <sup>
            <xsl:attribute name="class">appel_note_marge</xsl:attribute>
            <xsl:attribute name="id">appel_marge<xsl:value-of select="$numeroNote"/></xsl:attribute>
            <xsl:text>(</xsl:text><xsl:number value="$numeroNote" format="a"/><xsl:text>)</xsl:text>
        </sup>
        <span>
            <xsl:choose>
                <xsl:when test="@place='margin_left'">
                    <xsl:attribute name="class">manchette_gauche</xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="class">manchette_droite</xsl:attribute>
                </xsl:otherwise>
            </xsl:choose>
            <sup>
                <xsl:text>(</xsl:text><xsl:number value="$numeroNote" format="a"/><xsl:text>) </xsl:text>
            </sup>
            <xsl:apply-templates />
        </span>
    </xsl:template>


    <!--figures -->
    <xsl:template match="tei:figure" >
        <div class="figure">
            <xsl:apply-templates select="tei:graphic"/>
            <xsl:apply-templates select="tei:head"/>
            <p class="figure_legend">
               <xsl:apply-templates select="tei:figDesc"/>
            </p>
        </div>
    </xsl:template>

    <xsl:template match="tei:graphic" >
      <img>
         <xsl:attribute name="src">
         <xsl:value-of select="concat($baseuri, '/ui/images/',@url)"/>
         </xsl:attribute>
     </img>
    </xsl:template>
    <!-- Fin figures -->

    <!-- Limite de pages -->
    <xsl:template match="//tei:pb">
        <a>
            <xsl:attribute name="class">pb</xsl:attribute>
            <xsl:attribute name="name">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>

            <xsl:attribute name="href">#</xsl:attribute>

            <xsl:value-of select="@n"/>
        </a>

    </xsl:template>
    <!-- FIN Limite de pages -->

    <xsl:template match="//tei:lb">
      <br/>
    </xsl:template>

    <!-- les enrichissements typographiques-->
    <xsl:template match="tei:hi" >
        <span>
            <xsl:attribute name="class">
                <xsl:value-of select="@rend"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="@rend">
        <xsl:attribute name="class">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>


   <!-- Tables-->
    <xsl:template match="tei:table">
        <table>
        <div class="table_title"><xsl:value-of select="child::tei:head"/></div>
        <xsl:for-each select="child::tei:row">
            <tr>
                <xsl:apply-templates select="child::tei:cell"/>
            </tr>
        </xsl:for-each>
        </table>
    </xsl:template>

    <xsl:template match="tei:cell">
        <td>
            <xsl:apply-templates/>
        </td>
    </xsl:template>

    <!--citations-->
    <xsl:template match="tei:quote">
        <blockquote>
            <xsl:apply-templates/>
        </blockquote>
    </xsl:template>

    <!--references bibliographiques-->
      <xsl:template match="tei:bibl">
        <span>
            <xsl:attribute name="class">bibl</xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="tei:author">
        <span>
            <xsl:attribute name="class">author</xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="tei:title">
        <span>
            <xsl:attribute name="class">title</xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="tei:date">
        <span>
            <xsl:attribute name="class">date</xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="tei:publisher">
        <span>
            <xsl:attribute name="class">publisher</xsl:attribute>
            <xsl:apply-templates/>
        </span>
    </xsl:template>


    <xsl:template match="tei:teiHeader | tei:fileDesc">
            <xsl:apply-templates></xsl:apply-templates>
    </xsl:template>

    <xsl:template match="tei:titleStmt">
        <h1>
            <xsl:apply-templates></xsl:apply-templates>
        </h1>
    </xsl:template>


    <xsl:template match="//tei:back | //tei:front | //tei:sourceDesc"></xsl:template>

    <xsl:template match="//tei:TEI">
        <div>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

</xsl:stylesheet>
