# MaX

Le Moteur d'Affichage XML est une interface de lecture de sources XML développé par l'[Université de Caen Normandie](http://www.unicaen.fr) ([Pôle Document Numérique](http://www.unicaen.fr/recherche/mrsh/document_numerique) / [CERTIC](https://www.certic.unicaen.fr)) notamment dans le cadre de l'Equipex [Biblissima](http://www.biblissima-condorcet.fr/)

## Licence

voir [legal.txt](legal.txt)

## Participer au développement

Demander à rejoindre [MaX-Community](https://git.unicaen.fr/MaX-Community).

## Contacts

Vous pouvez nous contacter via [contact.certic@unicaen.fr](mailto:contact.certic@unicaen.fr?subject=[MaX])

---

## Prérequis

- Java 11+

- NodeJS (et npm) 10+


## Installation

MaX propose un script pour initialiser votre environnement de développement, 
télécharger et installer les dépendances requises.

### Affichage de l'aide

```bash
$ make help
```

### Installation

```bash
$ make install
```

Cette étape vous demandera de saisir le mot de passe d'administration de BaseX de votre choix.

### Lancement du serveur

```bash
$ make run
```

Vous pouvez vérifier votre installation sur http://localhost:1234/max.html

### Éditions de démonstration

Pour l'édition TEI :
```bash
$ make install-tei-demo
```

Pour la version EAD :
```bash
$ make install-ead-demo
```

Ces installations nécessite la saisie du mot de passe défini lors du `make install`, l'utilisateur étant 'admin' par défaut.

Les éditions de démonstration sont consultables sur :
- http://localhost:1234/max_tei_demo/accueil.html (TEI)
- http://localhost:1234/max_ead_demo/accueil.html (EAD)

## Paramétrage et customisation

La documentation utilisateur est disponible [ici](https://pdn-certic.pages.unicaen.fr/max-documentation/).



![UNICAEN-PDN-CERTIC](https://www.certic.unicaen.fr/ui/images/UNICAEN_PDN_CERTIC.png)

<img src="https://projet.biblissima.fr/sites/default/files/2021-11/biblissima-baseline-sombre-ia.png" alt="Biblissima" width="600px"/>
