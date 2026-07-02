<!-- For conditions of distribution and use, see the accompanying legal.txt file. -->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="#all">

    <xsl:param name="baseURI"/>
    <xsl:param name="selectedTarget"/>
    <xsl:param name="projectId"/>

    <xsl:template match="/">
        <xsl:variable name="topEntry"
                      select="/menu//entry[target/text()=$selectedTarget]/ancestor-or-self::entry[@type='main']"/>
        <nav class="navbar navbar-expand-lg navbar-light">
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarSupportedContent">
                <ul class="navbar-nav">
                    <xsl:for-each select="/menu/entry[@type='main']">
                        <xsl:choose>
                            <xsl:when test="count(./entry) > 0">
                                <li class="nav-item dropdown">
                                    <xsl:if test="./id/text()=$topEntry/id/text()">
                                        <xsl:attribute name="class">nav-item active</xsl:attribute>
                                    </xsl:if>
                                    <div class="dropdown">
                                        <a
                                                role="button"
                                                class="nav-link dropdown-toggle"
                                                id="dropdownMenuButton1"
                                                data-bs-toggle="dropdown" aria-expanded="false">
                                            <xsl:choose>
                                                <xsl:when test="./label/child::*">
                                                    <xsl:copy-of select="./label/child::*"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="./label/text()"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </a>
                                        <ul class="dropdown-menu" aria-labelledby="dropdownMenuButton1">

                                            <xsl:for-each select="./entry">
                                                <li>
                                                    <a class="dropdown-item" href="{$baseURI}{$projectId}/{./target/text()}">
                                                        <xsl:choose>
                                                            <xsl:when test="./label/child::*">
                                                                <xsl:copy-of select="./label/child::*"/>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:value-of select="./label/text()"/>
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </a>
                                                </li>
                                            </xsl:for-each>
                                        </ul>
                                    </div>
                                </li>
                            </xsl:when>
                            <xsl:otherwise>
                                <li class='nav-item'>
                                    <xsl:if test="./id/text()=$topEntry/id/text()">
                                        <xsl:attribute name="class">nav-item active</xsl:attribute>
                                    </xsl:if>
                                    <a class="nav-link" href="{$baseURI}{$projectId}/{./target/text()}">
                                        <xsl:choose>
                                            <xsl:when test="./label/child::*">
                                                <xsl:copy-of select="./label/child::*"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="./label/text()"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </a>
                                </li>
                            </xsl:otherwise>
                        </xsl:choose>

                    </xsl:for-each>
                </ul>
            </div>
        </nav>

    </xsl:template>


</xsl:stylesheet>
