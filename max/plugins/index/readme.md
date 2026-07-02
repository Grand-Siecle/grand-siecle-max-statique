# Plugin d'indexation #

Ce plugin propose une route unique pour tous les index.

Les index sont trop spécifiques pour permettre la mise en place d'un traitement par défaut satisfaisant.

Ce plugin propose donc une solution pour systématiser la production des index ainsi que les routes correspondantes.
Il permet de limiter les temps de calcul en stockant les fragments html de chaque page d'index.

La route associée à un index est `projet/index/typeindex.html` où `typeindex` est une valeur choisie par l'utilisateur. 

Ce plugin propose une route de base pour les types de documents en EAD (voir `index.xqm` et `indexing.xsl`).

Ne pas oublier de créer un dossier index, dans le dossier fragments, xq et ui/xsl du PROJET.

Un fichier html est généré lors du premier accès à cette page, la requête XQUERY et le traitement XSL associé sont exécutés lors de ce premier appel. Pour générer à nouveau la page d'index il suffit de supprimer le fichier `PROJET/fragments/LOCALE/index/index_typeindex.frag.html` souhaité.

Exemple de configuration du fichier xquery pour la génération d'un index des personnes (fichier à placer dans `PROJET/xq/index/index_personnes.xq`) :

```
<index type="personnes">
	{for $idx in collection("bvmsm")//*:persname
  	let $cId := $idx/ancestor::*:c[1]/@id
		let $baseuri := base-uri($idx)
    let $cOtherlevel := $idx/ancestor::*:c[1]/@otherlevel
    let $role := $idx/@role
		let $initiale := substring($idx/@normal,1,1) 
    let $cUnitid := $idx/ancestor::*:c[1]/descendant::*:unitid[1]/text()
    let $result := 
			<marker id="{$cId}" otherlevel="{$cOtherlevel}" role="{$role}">
   			<entry>{$cUnitid}</entry>
				<value>{data($idx/@normal)}</value>
				<baseuri>{$baseuri}</baseuri>
				<initiale>{$initiale}</initiale>
			</marker>
		return $result
	}
</index>

```

Exemple de traitement XSL associé (fichier à placer dans `PROJET/ui/xsl/index/index_personnes.xsl`) :

```
<xsl:stylesheet version="2.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xinclude="http://www.w3.org/2001/XInclude"
  xmlns:xhtml="http://www.w3.org/TR/xhtml/strict"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:ead="urn:isbn:1-931666-22-9"
  xmlns:hfp="http://www.w3.org/2001/XMLSchema-hasFacetAndProperty"
  xmlns:max="https://max.unicaen.fr"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="max ead tei xsl xsi xs xlink xinclude xhtml tei hfp">
  <!--pour importer le i18n-->
  <xsl:import href="../../../../ui/xsl/i18n.xsl"/>
  <xsl:output method="xhtml" encoding="utf-8" indent="no"/>
  
  <xsl:preserve-space elements="*:*"/>
  
<!--variables pour le i18n-->
  <xsl:param name="project"/>
  <xsl:param name="locale"/>
  <xsl:param name="key"/>
  <xsl:template match="*:index[@type='personnes']">

    <div class="{./@type}">
      <h1>Index des personnes</h1>
      <xsl:for-each-group select="./descendant::*:marker" group-by="@role">
        <xsl:sort select="@role" order="ascending"/>
        <div class="subindex" id="{current-grouping-key()}">
          <h2 class="collapsible">
            <xsl:choose>
              <xsl:when test="@role='auteur'">
                <!-- pour avoir une variante de titre selon la langue -->
                  <xsl:value-of select="max:i18n($project,'label.index_auteur',$locale)"/>
                
              </xsl:when>
              <xsl:when test="@role='annotateur'">
                <xsl:text>Annotateurs</xsl:text>
              </xsl:when>
              <xsl:when test="@role='commanditaire'">
                <xsl:text>Commanditaires</xsl:text>
              </xsl:when>
              <xsl:when test="@role='commentateur'">
                <xsl:text>Commentateurs</xsl:text>
              </xsl:when>
              <xsl:when test="@role='conservateur'">
                <xsl:text>Conservateurs</xsl:text>
              </xsl:when>
              <xsl:when test="@role='dedicataire'">
                <xsl:text>Dédicataires</xsl:text>
              </xsl:when>
              <xsl:when test="@role='donateur'">
                <xsl:text>Donateurs</xsl:text>
              </xsl:when>
              <xsl:when test="@role='editeur_sci'">
                <xsl:text>Éditeurs scientifiques</xsl:text>
              </xsl:when>
              <xsl:when test="@role='graveur'">
                <xsl:text>Graveurs</xsl:text>
              </xsl:when>
              <xsl:when test="@role='illustrateur'">
                <xsl:text>Illustrateurs</xsl:text>
              </xsl:when>
              <xsl:when test="@role='imprimeur-libraire'">
                <xsl:text>Imprimeurs-libraires</xsl:text>
              </xsl:when>
              <xsl:when test="@role='possesseur'">
                <xsl:text>Possesseurs</xsl:text>
              </xsl:when>
              <xsl:when test="@role='scribe'">
                <xsl:text>Scribes</xsl:text>
              </xsl:when>
              <xsl:when test="@role='traducteur'">
                <xsl:text>Traducteurs</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="current-grouping-key()"/>
              </xsl:otherwise>
            </xsl:choose>

          </h2>
          <div class="developper">

            <xsl:for-each-group select="current-group()" group-by="./*:initiale">
              <xsl:sort select="./*:initiale" order="ascending"/>
              <fieldset id="{@role}{./*:initiale}">
                <legend class="collapsible">
                  <xsl:value-of select="./*:initiale"/>
                </legend>
                <div class="developper">
                  <xsl:for-each-group select="current-group()" group-by="./*:value">
                    <xsl:sort select="./*:value" order="ascending"/>
                    <p class="entries">
                      <xsl:text>–&#160;</xsl:text>
                      <span class="persname">
                        <xsl:value-of select="*:value"/>
                      </span>
                      <xsl:text>&#160;:&#160;</xsl:text>
                      <xsl:for-each select="current-group()">
                        <a target="_blank">
                          <xsl:attribute name="href">
                            <xsl:value-of select="./*:baseuri[1]"/>
                            <xsl:text>/</xsl:text>
                            <xsl:value-of select="./@id"/>
                            <xsl:text>.html</xsl:text>
                          </xsl:attribute>
                          <xsl:value-of select="./*:entry"/>
                        </a>
                        <xsl:if test="not(position()=last())">
                          <xsl:text>&#160;; </xsl:text>
                        </xsl:if>
                      </xsl:for-each>
                    </p>
                  </xsl:for-each-group>
                </div>
              </fieldset>
            </xsl:for-each-group>
          </div>
        </div>
      </xsl:for-each-group>
    </div>
  </xsl:template>

</xsl:stylesheet>
```  


