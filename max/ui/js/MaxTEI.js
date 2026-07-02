import AbstractMax from './AbstractMax.js'

window.MAX_LOCAL_STORAGE_PREFIX = "MaXLS.";
window.MAX_VISIBLE_PROPERTY_STRING = "visible";
window.NOTE_TO_TXT_CLASS = ".note_to_text";

class MaxTEI extends AbstractMax {
    constructor(pid, baseURL, fid) {
        super(pid, baseURL, fid)
    }

    run() {
        if (this.isInFragmentContext()) {
            if (this.isWithNotes()) {
                //ajout d'une colonne de notes + placement
                this.manageMarginNotes();
            }

            this.bindNavigationTool();
            this.runPlugins();
            this.textOptions();

            let targets = document.getElementsByClassName('target')
            if(targets.length > 0){
                this.scrollToID((targets[0]).getAttribute('id'),0)
            }
            //affiche le bas de page si non vide
            let footnotes = document.querySelectorAll('#bas_de_page .footnote');
            if(footnotes.length > 0){
                document.getElementById("bas_de_page").style.display = 'block';
            }
        }
    }

    getProjectID() {
        return this.projectID;
    }

    getFragmentID() {
        return this.fragmentID;
    }

    getBaseURL() {
        return this.baseURL;
    }

    scrollToID(id) {
        document.getElementById(id).scrollIntoView({block: "center"});
    }

    textOptions() {
        //shows option's button if needed
        if (document.querySelectorAll("#options-list li").length > 0) {
            document.getElementById("txt_options").style.display = 'block';
        }

        //checkbox options (load from localstorage)
        document.querySelectorAll(".visibility_toggle").forEach(function (e) {
            let optionName = e.dataset.option;//$(this).data('option');
            if (localStorage.getItem(window.MAX_LOCAL_STORAGE_PREFIX + optionName) === window.MAX_VISIBLE_PROPERTY_STRING) {
                e.setAttribute("checked", "checked");
                //updates visibility
                document.querySelectorAll("." + optionName).forEach((e) => {
                    e.style.display = 'inline';
                })
            } else {
                e.removeAttribute('checked');
                //updates visibility
                document.querySelectorAll("." + optionName).forEach((e) => {
                    e.style.display = 'none';
                })
            }

        });
    }

    manageMarginNotes() {
        let mainContainer = document.getElementById("main-max-container");
        let leftBloc = mainContainer.childNodes[0];
        leftBloc.classList.add("row");
        document.getElementById("text").classList.add("col-sm-8");
        let marginNode = document.createElement('div');
        marginNode.setAttribute('id', 'margin_notes');
        marginNode.classList.add('col-sm-2')
        leftBloc.append(marginNode);

        let previousNote = null;
        document.querySelectorAll(".manchette_droite").forEach((manchette) =>{
            //stocke le top original avant de déplacer la note
            let originalTop = manchette.offsetTop//$(this).position().top;
            //déplacement de la note dans la colonne prévue
            marginNode.append(manchette);
            //mise à jour top (+anti-chevauchement)
            let newTop = originalTop;
            if (previousNote != null && previousNote.offsetTop) {
                let bottomPrevious = previousNote.offsetTop + previousNote.offsetHeight;
                if (bottomPrevious + 5 > newTop) {
                    newTop = bottomPrevious + 5;
                }
            }
            manchette.style.top = newTop + "px";
            previousNote = manchette;//$(this);
        });

    }

    /*Branchements 'onClick' sur les flèches de la barre de navigation*/
    bindNavigationTool() {
        //local function : find next or previous nav link
        let nextOrPrevious = function (step) {
            let current = document.getElementById("navigation-tool").querySelector('button').getAttribute("data-target").replace("selected-", "");//remove 'selected' prefix
            let links = document.getElementById('dropdown-navigation').querySelectorAll('li');
            let position = -1;
            console.log(links);
            links.forEach((link, index) => {
                if(link.dataset.target === current){
                    position = index;
                }
            })
            let nextOrPrevious = links[position + step];
            window.location.href = nextOrPrevious.querySelector('a').getAttribute("href");
        };

        let navPrev = document.getElementById('nav_previous');
        let navNext = document.getElementById('nav_next');
        if(navPrev){
            navPrev.addEventListener('click', () => {
                nextOrPrevious(-1);
            })
        }
        if(navNext){
            navNext.addEventListener('click', () => {
                nextOrPrevious(1);
            })
        }
    }


    isWithNotes() {
        return document.querySelectorAll('.appel_note_marge').length > 0
    }

    /*Affichage / masquage des éléments d'une classe CSS depuis un checkBox
    des options d'affichage
    */
    setClassVisibility(className) {

        if (document.getElementById('toggle_' + className).checked) {
            document.querySelectorAll('.'+className).forEach((e) => {
                e.style.display='';
            })
            localStorage.setItem(window.MAX_LOCAL_STORAGE_PREFIX + className, window.MAX_VISIBLE_PROPERTY_STRING);
        } else {
            document.querySelectorAll('.'+className).forEach((e) => {
                e.style.display='none'
            })
            localStorage.removeItem(window.MAX_LOCAL_STORAGE_PREFIX + className);
        }
    }

    toString() {
        return this.projectID + "s MaX";
    }
}

window.MAX = new MaxTEI(projectId, baseURI, fragmentId);

window.addEventListener('DOMContentLoaded', (event) => {
    MAX.run();
});


