import { Plugin } from '../../core/ui/js/Plugin.js';

const ADD_CLASS = "add";
const DEL_CLASS = "del";

const corrI18n = {
  'fr': {
    'display': 'Afficher les interventions'
  },
  'en': {
    'display': 'Display interventions'
  }
}

class AjoutPlugin extends Plugin {
  constructor(name) {
    super(name);
  }

  run() {
    console.log("Plugin ajout running")
    var checkAttr = "";
    if (localStorage.
      getItem(MAX_LOCAL_STORAGE_PREFIX + ADD_CLASS) === MAX_VISIBLE_PROPERTY_STRING) {
      checkAttr = "checked='checked' ";
      //updates visibility
      this.on();
    }
    else {
      //updates visibility
      this.off();
    }

    const parser = new DOMParser();
    let node =
      parser.parseFromString(
        "<li><a><input id='toggle_ajout' type='checkbox' "
        + checkAttr
        + " name='toggle_ajout'>" + corrI18n[lang]['display'] + "</a></li>",
        "text/html")
        .documentElement.querySelector('li');
    document.getElementById('options-list').append(
      document.importNode(node, true)
    );
    document.getElementById('toggle_ajout').addEventListener('change', () => {
      this.setAjoutVisible()
    })
  }

  setAjoutVisible() {
    if (document.getElementById('toggle_ajout').checked) {
      this.on();
      localStorage.setItem(MAX_LOCAL_STORAGE_PREFIX + ADD_CLASS, MAX_VISIBLE_PROPERTY_STRING);
    }
    else {
      this.off();
      localStorage.removeItem(MAX_LOCAL_STORAGE_PREFIX + ADD_CLASS);
    }
  }

  /*la balise add est mise en vert et la balise del est affichée*/
  on() {
    document.querySelectorAll("." + ADD_CLASS).forEach((e) => {
      e.style.color = '#1b9044';
    });
    document.querySelectorAll("." + DEL_CLASS).forEach((e) => {
      e.style.display = 'inline';
    });

  }
  /* la balise add est affichée avec sa couleur initiale mais la balise del est masquée */
  off() {
    document.querySelectorAll("." + ADD_CLASS).forEach((e) => {
      e.style.color = 'initial';
    });
    document.querySelectorAll("." + DEL_CLASS).forEach((e) => {
      e.style.display = 'none';
    });
  }
}

MAX.addPlugin(new AjoutPlugin('Ajout'));