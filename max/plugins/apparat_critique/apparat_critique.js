import {Plugin} from '../../core/ui/js/Plugin.js';

const PLUGIN_NAME='apparat';

class ApparatPlugin extends Plugin{
    constructor(name) {
        super(name);
    }

    run() {
        //si le fragment courant ne contient pas d'apparat
        if (!this.docWithApparat()) {
            document.querySelectorAll(".apparat-witnesses").forEach((e) => e.style.display = 'none');
            return;
        }
        this.wrapLacunas();
        this.showWitness("lem");
        this.witnessTooltiping();
    }

    showWitness(witnessClass) {
        document.querySelectorAll(".apparat").forEach((e) => e.style.display = 'none');
        document.querySelectorAll(".lacuna, ." +  witnessClass).forEach((e) => e.style.display = 'inline');
        document.querySelectorAll(".lacuna" + "."+witnessClass).forEach((e) => e.style.display = 'none');
    }

    witnessTooltiping() {
        document.querySelectorAll('[data-witness]').forEach((e) => {
            let wlist = e.getAttribute("data-witnesses").replace(" ", ", ");
            e.setAttribute("title", wlist);
        })
    }

    wrapLacunas() {
        document.querySelectorAll('.lacunaStart').forEach((lstart) => {
                const wit = lstart.getAttribute('data-lacuna-wit').replace('#','');
                let searchedId = lstart.getAttribute('data-lacuna-synch');
                let endElement = document.getElementById(searchedId);
                endElement = endElement.length === 0 ? document.getElementById('bas_de_page') : endElement
                let eltsBetween = this.getElementsBetweenTree(lstart, endElement);//$(self.getElementsBetweenTree(($(this))[0], endElement[0]))
                eltsBetween.forEach((elt) => {
                    let span = document.createElement("span");
                    span.classList.add('generated_lacuna');
                    span.classList.add('lacuna');
                    span.classList.add(wit);
                    span.append(elt.cloneNode(true));
                    elt.replaceWith(span);
                })
        })

    }

    getElementsBetweenTree(start, end) {
        let ancestor = this.commonAncestor(start, end);

        let before = [];
        while (start.parentNode !== ancestor) {
            var el = start;
            while (el.nextSibling)
                before.push(el = el.nextSibling);
            start = start.parentNode;
        }

        var after = [];
        while (end.parentNode !== ancestor) {
            var el = end;
            while (el.previousSibling)
                after.push(el = el.previousSibling);
            end = end.parentNode;
        }
        after.reverse();

        while ((start = start.nextSibling) !== end)
            before.push(start);
        return before.concat(after);
    }


    ancestors(node) {
        let nodes = []
        for (; node; node = node.parentNode) {
            nodes.unshift(node)
        }
        return nodes
    }

    commonAncestor(node1, node2) {
        let parents1 = this.ancestors(node1)
        let parents2 = this.ancestors(node2)

        if (parents1[0] !== parents2[0]) throw "No common ancestor!"

        for (var i = 0; i < parents1.length; i++) {
            if (parents1[i] !== parents2[i]) return parents1[i - 1]
        }
    }


    docWithApparat() {
        return document.querySelectorAll("#text .apparat, #text .lacunaStart, #text .lacunaEnd").length > 0
    }

}

let apparat = new ApparatPlugin('Apparat')
window.apparat = apparat;
MAX.addPlugin(apparat);
