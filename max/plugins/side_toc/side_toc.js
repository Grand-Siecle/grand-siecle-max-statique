import {Plugin} from '../../core/ui/js/Plugin.js';




class SideTocPlugin extends Plugin{
  constructor(name) {
    super(name);
  }

  run(){
    console.log("plugin side toc running");
    // if(document.getElementById('text') && document.getElementById(fragmentId)){
    if(document.getElementById('text') && fragmentId){
        this.highlightTreeNode('details_'+fragmentId)
    }
   }

   highlightTreeNode(id) {
       let selected_details = document.getElementById(id);
       if (selected_details) {
           selected_details.setAttribute("open", "open");
           selected_details.classList.add("selected_details");
           let current_element = selected_details;
           while (current_element.tagName.toUpperCase() !== "NAV") {
               let parent = current_element.parentElement;
               if (parent.tagName.toUpperCase() === "DETAILS") {
                   parent.setAttribute("open", "open");
               }
               current_element = parent;
           }
           let scrollPoint = selected_details.previousSibling;
           if (scrollPoint == null) {
               scrollPoint = selected_details;
           }
           selected_details.scrollIntoView({block: "center"});
       }
   }
}

MAX.addPlugin(new SideTocPlugin('SideToc'));

