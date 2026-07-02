import { Plugin } from '../../core/ui/js/Plugin.js';

const EX_CLASS = "ex";
const AM_CLASS = "am";

const corrI18n = {
  'fr': {
    'display': 'Développer les abréviations'
  },
  'en': {
    'display': 'Expand abbreviations'
  }
}

class AbreviationPlugin extends Plugin {
  constructor(name) {
    super(name);
  }

  run() {
    console.log("Plugin abréviation running")
    var checkAttr = "";
    if (localStorage.
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
        "<li><a><input id='toggle_ex' type='checkbox' "
        + checkAttr
        + " name='toggle_ex'>" + corrI18n[lang]['display'] + "</a></li>",
        "text/html")
        .documentElement.querySelector('li');
    document.getElementById('options-list').append(
      document.importNode(node, true)
    );
    document.getElementById('toggle_ex').addEventListener('change', () => {
      this.setExVisible()
    })
  }

  setExVisible() {
    if (document.getElementById('toggle_ex').checked) {
      this.on();
      localStorage.setItem(MAX_LOCAL_STORAGE_PREFIX + EX_CLASS, MAX_VISIBLE_PROPERTY_STRING);
    }
    else {
      this.off();
      localStorage.removeItem(MAX_LOCAL_STORAGE_PREFIX + EX_CLASS);
    }
  }

  on() {
    document.querySelectorAll("." + AM_CLASS).forEach((e) => {
      e.style.display = 'none';
    });
    document.querySelectorAll("." + EX_CLASS).forEach((e) => {
      e.style.display = 'inline';
    });

  }

  off() {
    document.querySelectorAll("." + AM_CLASS).forEach((e) => {
      e.style.display = 'inline';
    });
    document.querySelectorAll("." + EX_CLASS).forEach((e) => {
      e.style.display = 'none';
    });
  }
}

MAX.addPlugin(new AbreviationPlugin('Abreviation'));
