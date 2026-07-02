Plugin mirador pour affiche IIIF
=======================
* Intègre le visualiseur IIIF mirador à l'aide de la librairie [max-mirador](https://git.unicaen.fr/pdn-certic/max-mirador)

Le déclenchement du visualiseur se fait sur les séquences XML suivantes :

En EAD :

````
	<extref entity='iiif_manifest' xlink:href='linkToIIIFManifest'>
		[...]
	</extref>

````

et


````
	<dao entity='iiif_manifest' xlink:href='linkToIIIFManifest'>
		[...]
	</dao>

````

Par défaut, dans le cas de l'utilisation d'un `ead:dao` une vignette est affichée en plus du lien vers le visualiseur.

Pour pointer vers une vue précise dans un manifest il est possible d'ajouter soit l'index du canvas soit son identifiant comme une ancre dans le lien :

````
	<extref entity='iiif_manifest' xlink:href='linkToIIIFManifest#15'>
		[...]
	</extref>
````

pour ouvrir le visualiseur mirador à la 15e image.

Et 

````
	<extref entity='iiif_manifest' xlink:href='linkToIIIFManifest#identifiantDuCanvasSouhaite'>
		[...]
	</extref>
````

pour ouvrir le visualiseur mirador à l'image identifiée par "identifiantDuCanvasSouhaite".

En TEI :

````
	<pb rend='iiif_manifest' n='linkToIIIFManifest'/>
````

