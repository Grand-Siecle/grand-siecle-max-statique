import { Plugin } from '../../core/ui/js/Plugin.js';

const CORR_CLASS = "corr";
const SIC_CLASS = "sic";

const corrI18n = {
  'fr': {
    'display': 'Afficher les corrections'
  },
  'en': {
    'display': 'Display corrections'
  }
}

class CorrectionPlugin extends Plugin {
  constructor(name) {
    super(name);
  }

  run() {
    console.log("plugin correction running")
    var checkAttr = "";
    if (localStorage.
      getItem(MAX_LOCAL_STORAGE_PREFIX + CORR_CLASS) === MAX_VISIBLE_PROPERTY_STRING) {
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
        "<li><a><input id='toggle_corr' type='checkbox' "
        + checkAttr
        + " name='toggle_corr'>" + corrI18n[lang]['display'] + "</a></li>",
        "text/html")
        .documentElement.querySelector('li');
    document.getElementById('options-list').append(
      document.importNode(node, true)
    );
    document.getElementById('toggle_corr').addEventListener('change', () => {
      this.setCorrVisible()
    })
  }

  setCorrVisible() {
    if (document.getElementById('toggle_corr').checked) {
      this.on();
      localStorage.setItem(MAX_LOCAL_STORAGE_PREFIX + CORR_CLASS, MAX_VISIBLE_PROPERTY_STRING);
    }
    else {
      this.off();
      localStorage.removeItem(MAX_LOCAL_STORAGE_PREFIX + CORR_CLASS);
    }
  }

  /*corr visibles*/
  on() {
    document.querySelectorAll("." + SIC_CLASS).forEach((e) => {
      e.style.display = 'none';
    });
    document.querySelectorAll("." + CORR_CLASS).forEach((e) => {
      e.style.display = 'inline';
    });

  }
  /*corr hidden (sic visibles)*/
  off() {
    document.querySelectorAll("." + SIC_CLASS).forEach((e) => {
      e.style.display = 'inline';
    });
    document.querySelectorAll("." + CORR_CLASS).forEach((e) => {
      e.style.display = 'none';
    });
  }
}

MAX.addPlugin(new CorrectionPlugin('Correction'));
