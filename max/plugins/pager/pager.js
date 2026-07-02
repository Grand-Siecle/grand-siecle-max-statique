import {Plugin} from '../../core/ui/js/Plugin.js';

class PagerPlugin extends Plugin{
  constructor(name) {
    super(name);
  }

  run(){}

}

MAX.addPlugin(new PagerPlugin('Pager'));