import { Plugin } from '../../core/ui/js/Plugin.js';

const REG_CLASS = "reg";
const ORIG_CLASS = "orig";

const regI18n = {
  'fr': {
    'display': 'Afficher les normalisations'
  },
  'en': {
    'display': 'Display normalisations'
  }
}

class NormalisationPlugin extends Plugin {
  constructor(name) {
    super(name);
  }

  run() {
    var checkAttr = "";
    if (localStorage.
      getItem(MAX_LOCAL_STORAGE_PREFIX + REG_CLASS) === MAX_VISIBLE_PROPERTY_STRING) {
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
        "<li><a><input id='toggle_reg' type='checkbox' "
        + checkAttr
        + " name='toggle_reg'>" + regI18n[lang]['display'] + "</a></li>",
        "text/html")
        .documentElement.querySelector('li');
    document.getElementById('options-list').append(
      document.importNode(node, true)
    );

    document.getElementById('toggle_reg').addEventListener('change', () => {
      this.setRegVisible()
    })
  }

  setRegVisible() {
    if (document.getElementById('toggle_reg').checked) {
      this.on();
      localStorage.setItem(MAX_LOCAL_STORAGE_PREFIX + REG_CLASS, MAX_VISIBLE_PROPERTY_STRING);
    }
    else {
      this.off();
      localStorage.removeItem(MAX_LOCAL_STORAGE_PREFIX + REG_CLASS);
    }
  }

  /*reg visibles*/
  on() {
    document.querySelectorAll("." + ORIG_CLASS).forEach((e) => {
      e.style.display = 'none';
    });
    document.querySelectorAll("." + REG_CLASS).forEach((e) => {
      e.style.display = 'inline';
    });
  }
  /*reg hidden (orig visibles)*/
  off() {
    document.querySelectorAll("." + ORIG_CLASS).forEach((e) => {
      e.style.display = 'inline';
    });
    document.querySelectorAll("." + REG_CLASS).forEach((e) => {
      e.style.display = 'none';
    });
  }

}



MAX.addPlugin(new NormalisationPlugin('Normalisation'));