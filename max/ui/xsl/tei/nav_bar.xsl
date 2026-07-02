<!-- For conditions of distribution and use, see the accompanying legal.txt file. -->

<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:max="https://max.unicaen.fr"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="tei max"

>

    <xsl:import href="document_title.xsl"/>


    <xsl:output
            method="xhtml"/>

    <xsl:param name="baseuri"/>
    <xsl:param name="project"/>
    <xsl:param name="selectedId"/>
    <xsl:param name="nextArrow"/>
    <xsl:param name="prevArrow"/>



    <xsl:template match="/div">
        <div id="navigation-tool" class="dropdown">
            <xsl:if test="$prevArrow='true'">
                <span id="nav_previous">
                    <img>
                        <xsl:attribute name="src">
                            <xsl:value-of select="concat($baseuri,'core/ui/images/previous.png')"/>
                        </xsl:attribute>
                    </img>
                </span>
            </xsl:if>

            <button
                    class="btn btn-default dropdown-toggle"
                    type="button"
                    data-target="selected-{$selectedId}"
                    id="selected-{$selectedId}"
                    data-bs-toggle="dropdown"
                    aria-haspopup="true"
                    aria-expanded="true">
                <xsl:apply-templates exclude-result-prefixes="max" select=".//li[@data-target = $selectedId]/a"/>
            </button>

            <ul id="dropdown-navigation" class="dropdown-menu" aria-labelledby="selected-{$selectedId}">
                <xsl:apply-templates select="./div/ul"/>
            </ul>

            <xsl:if test="$nextArrow='true'">
                <span id="nav_next">
                    <img>
                        <xsl:attribute name="src">
                            <xsl:value-of select="concat($baseuri,'core/ui/images/next.png')"/>
                        </xsl:attribute>
                    </img>
                </span>
            </xsl:if>
        </div>
    </xsl:template>


</xsl:stylesheet>
