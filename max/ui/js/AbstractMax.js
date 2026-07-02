export default class AbstractMax {
    constructor(pid,baseURL, fid) {
        this.projectID = pid;
        this.plugins = [];
        this.baseURL = baseURL;
        this.fragmentID = fid;

    }

    run() {
        if (this.isInFragmentContext()) {
            this.runPlugins();
        }
    }


    addPlugin(p) {
        this.plugins[p.getName()] = p;
    }

//    getPluginsBaseURL() {
//        return this.pluginsBaseURL;
//    }

    runPlugins() {
        Object.keys(this.plugins).forEach((k) =>{
            this.plugins[k].run();
        })
    }

    /*
     Vérifie si le contexte courant (page) est une consultation
     d'un fragment (présence d'un élement identifié 'text')
   */
    isInFragmentContext() {
        return document.getElementById("text");
    }


    toString() {
        return this.projectID + "s MaX";
    }

    setLanguage(l){
        fetch(this.baseURL +'setlang/' + l).then(function(){
            window.location.reload(true);
            }
        )

    }
}


