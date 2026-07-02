import { Plugin } from '../../core/ui/js/Plugin.js';

const CORR_CLASS = "corr";
const SIC_CLASS = "sic";
const ORIG_CLASS = "orig";
const REG_CLASS = "reg";
const EX_CLASS = "ex";
const AM_CLASS = "am";

const corrI18n = {
  'fr': {
    'display': 'Affichage régularisé'
  },
  'en': {
    'display': 'Regularized display'
  }
}

class DiplomatiquePlugin extends Plugin {
  constructor(name) {
    super(name);
  }

  run() {
    console.log("plugin diplomatique running")
    var checkAttr = "";
    if (localStorage.
      getItem(MAX_LOCAL_STORAGE_PREFIX + CORR_CLASS) === MAX_VISIBLE_PROPERTY_STRING && localStorage.
        getItem(MAX_LOCAL_STORAGE_PREFIX + REG_CLASS) === MAX_VISIBLE_PROPERTY_STRING && localStorage.
          getItem(MAX_LOCAL_STORAGE_PREFIX + EX_CLASS) === MAX_VISIBLE_PROPERTY_STRING) {
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
        "<li><a><input id='toggle_diplo' type='checkbox' "
        + checkAttr
        + " name='toggle_diplo'>" + corrI18n[lang]['display'] + "</a></li>",
        "text/html")
        .documentElement.querySelector('li');
    document.getElementById('options-list').append(
      document.importNode(node, true)
    );

    document.getElementById('toggle_diplo').addEventListener('change', () => {
      this.setCorrVisible()
    })
  }

  setCorrVisible() {
    if (document.getElementById('toggle_diplo').checked) {
      this.on();
      localStorage.setItem(MAX_LOCAL_STORAGE_PREFIX + CORR_CLASS, MAX_VISIBLE_PROPERTY_STRING);
      localStorage.setItem(MAX_LOCAL_STORAGE_PREFIX + REG_CLASS, MAX_VISIBLE_PROPERTY_STRING);
      localStorage.setItem(MAX_LOCAL_STORAGE_PREFIX + EX_CLASS, MAX_VISIBLE_PROPERTY_STRING);
    }

    else {
      this.off();
      localStorage.removeItem(MAX_LOCAL_STORAGE_PREFIX + CORR_CLASS);
      localStorage.removeItem(MAX_LOCAL_STORAGE_PREFIX + REG_CLASS);
      localStorage.removeItem(MAX_LOCAL_STORAGE_PREFIX + EX_CLASS);
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
    document.querySelectorAll("." + ORIG_CLASS).forEach((e) => {
      e.style.display = 'none';
    });
    document.querySelectorAll("." + REG_CLASS).forEach((e) => {
      e.style.display = 'inline';
    });
    document.querySelectorAll("." + AM_CLASS).forEach((e) => {
      e.style.display = 'none';
    });
    document.querySelectorAll("." + EX_CLASS).forEach((e) => {
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
    document.querySelectorAll("." + ORIG_CLASS).forEach((e) => {
      e.style.display = 'inline';
    });
    document.querySelectorAll("." + REG_CLASS).forEach((e) => {
      e.style.display = 'none';
    });
    document.querySelectorAll("." + AM_CLASS).forEach((e) => {
      e.style.display = 'inline';
    });
    document.querySelectorAll("." + EX_CLASS).forEach((e) => {
      e.style.display = 'none';
    });
  }
}

MAX.addPlugin(new DiplomatiquePlugin('Diplomatique'));
