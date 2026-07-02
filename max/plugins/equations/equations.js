import {Plugin} from '../../core/ui/js/Plugin.js';
// const MathJax = require('mathjax');

//TODO : terminer la dé-jquerylisation !

class EquationPlugin extends Plugin{
  constructor(name) {
    super(name);
  }

  run(){
    if(!this.docWithEquation())
        return;
    //appends lib + conf into head element
    //let mathjax = "<script type='text/x-mathjax-config'>";
    let mathjax = "MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}";
    mathjax+=",TeX: {Macros: {textnormal: '{}',ad: '{=}'}}});</script>";
    let script = document.createElement('script');
    script.setAttribute('type', 'text/x-mathjax-config');
    script.append(mathjax);

    document.querySelector("head").appendChild(script);
    let scriptImport = document.createElement('script');
    scriptImport.setAttribute('type', 'text/javascript');
    scriptImport.setAttribute('src',MAX.getBaseURL() + 'plugins/equations/mathjax/MathJax.js?config=TeX-AMS-MML_HTMLorMML');
    document.querySelector("head").appendChild(scriptImport);
    //document.querySelector("head").append('<script type="text/javascript" src="'+MAX.getBaseURL() + 'plugins/equations/mathjax/MathJax.js?config=TeX-AMS-MML_HTMLorMML"></script>');

    //appends text options components
    $("#options-list").append("<li role='separator' class='divider'></li><li><a href='#'>"
      +"<input id='toggle_equations_on' type='radio' name='equations' checked>Afficher les images de l\'édition originale</a></li>");
    $("#options-list").append("<li><a href='#'><input id='toggle_equations_off' type='radio' name='equations'>"+
    "Afficher les équations modernisées en mode texte</a></li><li role='separator' class='divider'></li>");
    this.setEquationsVisible();
    let self = this;
    $('#toggle_equations_on').change(function(e){
        self.toggleModernEquations(true);
    });
    $('#toggle_equations_off').change(function(e){
            self.toggleModernEquations(false);
        });
  }


  setEquationsVisible(){
        $(".tex").show();
        $(".formula").hide();
  }

  toggleModernEquations(on){
    //console.log("Set modern equations visible =" + on)
    if(on){
      $(".tex").show();
      $(".formula").hide();
    }
    else{
      $(".formula").show();
      $(".tex").hide();
    }

  }

  docWithEquation(){
   return document.querySelectorAll(".formula").length > 0;
  }
}


MAX.addPlugin(new EquationPlugin('Equation'));
