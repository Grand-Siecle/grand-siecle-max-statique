# Plugin metadata

Revoir les routes, pour que les urls soient de type : `projet/archdesc/mon_fichier_xml.html` et `projet/eadheader/mon_fichier_xml.html`

Route permettant d'afficher les métadonnées des fichiers xml, comme eadheader et archdesc.

La route associée est de type `projet/info/tag.html`où `tag` est l'élément que l'on veut afficher.

Pour l'instant, cette route a été testée avec `eadheader` et `archdesc`. 

La balise `archdesc` est gérée de façon particulière pour que la xquery ne récupère pas l'ensemble des balises `c` qu'elle contient. Car trop compliqué à gérer en xsl.

Les `xsl` utilisées, nommées `[tag].xsl`, sont celles trouvées dans le dossier du projet s'il y en a, sinon on applique celles qui se trouvent dans le dossier du plugin.
