class Plugin {
  constructor(name) {
    this.name = name;
    window.console.log('Plugin '+ name + ' built !')
  }

  getName(){
    return this.name;
  }

  run(){}
}
 export { Plugin }