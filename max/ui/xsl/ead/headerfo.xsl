<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/XSL/Format"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:i18n="http://apache.org/cocoon/i18n/2.1" exclude-result-prefixes="xsl xhtml">

    <!-- Le template de l'en-tête -->
    <xsl:template name="output-header">
        <xsl:param name="prettyName"/>
        <xsl:param name="bloc-biblio"/>
        <!-- Un block-container permet de fixer une hauteur, et donc d'ajuster l'image de fond -->
        <block-container xsl:use-attribute-sets="containerPrettyName">
            <!-- Le contenu -->
            <block xsl:use-attribute-sets="prettyName">
                <xsl:value-of select="$prettyName"/>
            </block>
        </block-container>
        <block xsl:use-attribute-sets="titlePage">
            <xsl:apply-templates select="../*:frontmatter/*:titlepage"/>
        </block>
    </xsl:template>
</xsl:stylesheet>