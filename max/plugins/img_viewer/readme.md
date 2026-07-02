Plugin d'affichage des images
=======================
* Fonctionne avec la librairie Openseadragon

Ce plugin requiert le chemin de stockage des images relatif à l'édition (`imagesRepository`) comme paramètre de configuration :

```
     <plugin name="img_viewer">
       <parameters>
         <parameter key="imagesRepository" value="ui/images/" xsl="true"/>
       </parameters>
     </plugin>
```
Le chemin (ici <span class="dossier">ui/images</span>) est indiqué dans l'attribut `@value` de la balise `<parameter>`.

