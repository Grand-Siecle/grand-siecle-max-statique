//load thumbnails from IIIF server
// document.addEventListener("DOMContentLoaded", function () {
//     let imgsIIIF = document.querySelectorAll('img.mirador-link'); //img with class mirador-link
//
//     for (let e = 0, len = imgsIIIF.length; e < len; ++e) {
//         let currentId = imgsIIIF[e].id
//         getThumbnail(imgsIIIF[e].src).then((thumbnail) => {
//             let currentImg = document.getElementById(currentId)
//             currentImg.setAttribute("src", thumbnail)
//         })
//     }
// })
//
// async function getThumbnail(url) {
//     const response = await fetch(url);
//     let manifest = await response.json();
//     let thumbnail = manifest.thumbnail["@id"]
//     return thumbnail
// }

//import './max-mirador/MaxMirador2';
import {Plugin} from '../../core/ui/js/Plugin.js';

class MiradorViewer extends Plugin {
    constructor(name) {
        super(name);

    }

    showMirador(domElt) {
        MaxMirador.open({})
    }
}

MAX.addPlugin(new MiradorViewer('mirador_viewer'));
