<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/XSL/Format"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:i18n="http://apache.org/cocoon/i18n/2.1" exclude-result-prefixes="xsl xhtml">



    <!-- Le template de l'en-tête -->
    <xsl:template name="pied-impaire">
        <block>
            <table>
                <table-body>
                    <table-row>
                        <table-cell>
                            <block text-align="left" font-family="Times" font-size="7pt">
                                <xsl:value-of select="$idProject" />
                                <xsl:text> – </xsl:text>
                                <xsl:value-of select="format-dateTime(current-dateTime(),'[D,2]/[M,2]/[Y]')" />
                            </block>
                        </table-cell>
                        <table-cell>
                            <block text-align="right" font-family="Times" font-size="8pt">
                                <xsl:text>Page </xsl:text>
                                <page-number/>
                            </block>
                        </table-cell>
                    </table-row>
                </table-body>
            </table>
        </block>
    </xsl:template>

    <xsl:template name="pied-paire">
        <table>
            <table-body>
                <table-row>
                    <table-cell>
                        <block text-align="left" font-family="Times" font-size="8pt">
                            <!-- <page-number/> -->
                            <xsl:text>Page </xsl:text>
                            <page-number/>
                            <!-- <page-number-citation ref-id="last-page"/>  -->
                        </block>
                    </table-cell>
                    <table-cell>
                        <block text-align="right" font-family="Times" font-size="7pt">
                            <xsl:value-of select="$idProject" />
                            <xsl:text> – </xsl:text>
                            <xsl:value-of select="format-dateTime(current-dateTime(),'[D,2]/[M,2]/[Y]')" />
                        </block>
                    </table-cell>
                </table-row>
            </table-body>
        </table>
    </xsl:template>

</xsl:stylesheet>