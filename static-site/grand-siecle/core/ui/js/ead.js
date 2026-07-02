class EADDocumentsBasket {
    constructor(project_id) {
        this.storage = localStorage;
        this.project_id = project_id;
    }

    _fetch_basket_data() {
        let basket_data = this.storage.getItem("ead_basket-" + this.project_id);
        if (basket_data === null) {
            basket_data = [];
        } else {
            basket_data = JSON.parse(basket_data);
        }
        return basket_data;
    }

    _store_basket_data(basket_data) {
        try {
            this.storage.setItem("ead_basket-" + this.project_id, JSON.stringify(basket_data));
        } catch (e) {
            alert("Vous avez dépassé le nombre de documents autorisés dans le porte-documents.");
        }
    }

    add(document_id) {
        let basket_data = this._fetch_basket_data();
        basket_data.push(document_id);
        basket_data = [...new Set(basket_data)]; // deduplicate
        this._store_basket_data(basket_data);
    }

    remove(document_id) {
        let basket_data = this._fetch_basket_data();
        for (let i = basket_data.length - 1; i >= 0; i--) {
            if (basket_data[i] === document_id) {
                basket_data.splice(i, 1);
            }
        }
        this._store_basket_data(basket_data);
    }

    has(document_id) {
        let basket_data = this._fetch_basket_data();
        for (let i = basket_data.length - 1; i >= 0; i--) {
            if (basket_data[i] === document_id) {
                return true;
            }
        }
        return false;
    }

    toggle(document_id) {
        if (this.has(document_id)) {
            this.remove(document_id);
        } else {
            this.add(document_id);
        }
    }

    items() {
        return this._fetch_basket_data();
    }

    count() {
        return this._fetch_basket_data().length;
    }

    clear() {
        this._store_basket_data([]);
    }

    async hydrateItems() {
        let response = await fetch(baseURI  + "/ead/fetch_basket_data.html?itemsList=" + btoa(JSON.stringify(this.items())), {
            method: "GET",
        });
        return await response.text()
    }
}



function initBasketCheckbox(project_id, doc_name, cid) {
    let node_cid = doc_name + "|" + cid;
    let basket = new EADDocumentsBasket(project_id);
    let basket_toggle = document.getElementById("basket_toggle");
    if (basket_toggle) {
        basket_toggle.checked = basket.has(node_cid);
        basket_toggle.addEventListener("change", function () {
            basket.toggle(node_cid);
        });
    }
}

async function initEADPage() {
    let textElement = document.getElementById('text')
    if(textElement){
        initBasketCheckbox(projectId, route, fragmentId);
    }
    if(projectId) {  // should be declared globally in page
        initPorteDocumentsPage(projectId);
    }
}

async function initPorteDocumentsPage(project_id) {
    let basket_dom = document.getElementById('porte-document-contenu');
    if(basket_dom) {
        let basket = new EADDocumentsBasket(project_id);
        document.getElementById("porte-document-contenu").innerHTML = await basket.hydrateItems();

        let sortable = Sortable.create(basket_dom, {
            "animation": 100,
            "onEnd": function (evt) {
                basket.clear();
                let li_elems = basket_dom.getElementsByTagName("li");
                for (var i = 0, len = li_elems.length; i < len; i++) {
                    basket.add(li_elems[i].dataset.node_id);
                }
            }
        });

        let remove_buttons = document.getElementsByClassName("btnRemoveBasketItem");
        for (var i = 0, len = remove_buttons.length; i < len; i++) {
            remove_buttons[i].addEventListener("click", function () {
                basket.remove(this.parentNode.dataset.node_id);
                this.parentNode.remove();
            });
        }

        let clear_buttons = document.getElementsByClassName("btnClearBasket");
        for (var i = 0, len = clear_buttons.length; i < len; i++) {
            clear_buttons[i].addEventListener("click", function () {
                if (confirm("Sûr ?")) {
                    basket.clear();
                    while (basket_dom.lastChild) {
                        basket_dom.removeChild(basket_dom.lastChild);
                    }
                }
            });
        }

        let pdf_buttons = document.getElementsByClassName("btnMakePDF");
        for (var i = 0, len = pdf_buttons.length; i < len; i++) {
            pdf_buttons[i].addEventListener("click", function () {
                console.log(basket.items().concat(","));
                let docItems = []
                this.parentNode.parentNode.querySelectorAll("li").forEach(notice => {
                	let noticeId = notice.dataset.node_id
                	docItems.push(noticeId)
                });
                window.open(baseURI + "/ead/basket.pdf?items=" + (docItems.join()), '_blank');
            });
        }
        
        // OVP: à terminer
        let dlAllButton = document.getElementById("btnDlAllPDF")
        dlAllButton.addEventListener("click", function () {
        	let PDFList = []
        	document.querySelectorAll(".porte-document-doc-group").forEach(PDFGroup => {
        		let PDF = {}
        		let docItems = []
        		let docId = PDFGroup.querySelector("li").dataset.node_id.split('|')[0]
        		
        		PDFGroup.querySelectorAll("li").forEach(notice => {
                	let noticeId = notice.dataset.node_id.split('|')[1]
                	docItems.push(noticeId)        		
        		})
        		
        		Object.defineProperty(PDF, 'doc', {
        			value: docId,
        			enumerable: true
        		});
        		Object.defineProperty(PDF, 'itemList', {
        			value: docItems,
        			enumerable: true
        		});
        		
        		let result = JSON.stringify(PDF)
        		console.log(result)
        	})
        });
        
    }
}

// afficher/masquer la div
var coll = document.getElementsByClassName("collapsible");
var i;
for (i = 0; i < coll.length; i++) {
    coll[i].addEventListener("click", function() {
        this.classList.toggle("active");
        var content = this.nextElementSibling;
        if (content.style.display === "block") {
            content.style.display = "none";
        } else {
            content.style.display = "block";
        }
    });
}
