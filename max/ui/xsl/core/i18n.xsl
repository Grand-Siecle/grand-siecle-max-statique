<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:max="https://max.unicaen.fr"
>



    <xsl:function name="max:i18n">
        <xsl:param name="project"/>
        <xsl:param name="key"/>
        <xsl:param name="locale"/>

<!--        <xsl:variable name="localPrefix">-->
<!--            <xsl:choose>-->
<!--                <xsl:when test="$locale">-->
<!--                    <xsl:value-of select="$locale"/>-->
<!--                </xsl:when>-->
<!--                <xsl:otherwise>fr</xsl:otherwise>-->
<!--            </xsl:choose>-->
<!--        </xsl:variable>-->

        <xsl:variable name="defaultEntry">
            <xsl:value-of select="document(concat('../../i18n/i18n-',$locale,'.xml'))//entry[@key=$key]"/>
        </xsl:variable>

        <xsl:variable name="projectEntry">
            <xsl:choose>
                <xsl:when test="doc-available(concat('../../../editions/',$project,'/ui/i18n/i18n-',$locale,'.xml'))">
                    <xsl:value-of select="document(concat('../../../editions/',$project,'/ui/i18n/i18n-',$locale,'.xml'))//entry[@key=$key]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text></xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="string-length($projectEntry)>0">
                <xsl:value-of select="$projectEntry"/>
            </xsl:when>
            <xsl:when test="string-length($defaultEntry)>0">
                <xsl:value-of select="$defaultEntry"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$key"/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

</xsl:stylesheet>