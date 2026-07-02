import {Plugin} from '../../core/ui/js/Plugin.js';

class ImageViewer extends Plugin {
    constructor(name) {
        super(name);
        const parser = new DOMParser();
        let viewables = document.querySelectorAll('#text .img_viewer_link'); //img + pb
        let images = document.querySelectorAll('#text img');//img only
        if (viewables.length > 0) {
            let scriptNode = document.createElement('script');
            scriptNode.setAttribute('type', 'text/javascript');
            scriptNode.setAttribute('src',baseURI + 'plugins/img_viewer/openseadragon.min.js');
            document.getElementsByTagName('head')[0].appendChild(scriptNode);

            let node =
                parser.parseFromString(
                '<div id="img_dialog_wrap" class="modal" tabindex="-1" role="dialog">' +
                '<div>' +
                '<div class="modal-content">' +
                '<div class="modal-header">' +
                '<h5 class="modal-title" id="img-title"></h5>' +
                '<button type="button" onclick="document.getElementById(\'img_dialog_wrap\').style.display=\'none\'" class="close" aria-label="Close">' +
                '<span aria-hidden="true">&times;</span>' +
                '</button>' +
                '</div>' +
                '<div class="modal-body">' +
                '<p>Modal body text goes here.</p>' +
                '</div>' +
                '</div>' +
                '</div>' +
                '</div>',
                "text/html")
                .documentElement.querySelector('#img_dialog_wrap');

            document.body.append(document.importNode(node, true));
            document.getElementById('img_dialog_wrap').style.display = 'none';


            if (images.length > 1) {
                let gnode =
                    parser.parseFromString('<div id="gallery-wrap">'
                        + '<button id="all-images-btn" class="btn btn-secondary" onclick="MAX.plugins[\'img_viewer\'].openImagesInDialog()">'
                        + '<img alt="voir la galerie d\'images de la page" title="voir la galerie d\'images de la page" src="' + baseURI + 'plugins/img_viewer/images/gallery.png"/>'
                        + '</button></div>', "text/html").documentElement.querySelector('#gallery-wrap');
                document.getElementById('text').parentElement.append(document.importNode(gnode, true))

            }
        }
    }

    openImageInDialog(href) {
        let tiled = href.endsWith('dzi') || href.endsWith('json');
        this.showImages(tiled ? href : {type: 'image', url: href})
    }

    async getData(file) {
        const response = await fetch(file);
        let tiles = await response.json();
        return tiles
    }

    openCollectionInDialog(resource) {
        console.log(resource);

        let tabImages = []

        this.getData(resource).then((tiles) => {
            tabImages = tiles['images'];
            document.querySelector('#img_dialog_wrap .modal-body').innerHTML = '<div id="osd-viewer" style="display: flex;"></div>'
            OpenSeadragon({
                id: "osd-viewer",
                prefixUrl: baseURI + "plugins/img_viewer/images/osd/",
                tileSources: tabImages,
                sequenceMode: true
            });
            document.getElementById('img_dialog_wrap').style.display = 'block';
        });
    }

    showImages(tileSources) {
        //document.querySelector('#img_dialog_wrap .modal-body')innerHTML = '';
        document.querySelector('#img_dialog_wrap .modal-body').innerHTML = '<div id="osd-viewer" style="display: flex;"></div>'
        OpenSeadragon({
            id: "osd-viewer",
            prefixUrl: baseURI + "plugins/img_viewer/images/osd/",
            tileSources: tileSources,
            sequenceMode: tileSources.length > 1
        });
        document.getElementById('img_dialog_wrap').style.display = 'flex';
    }

    openImagesInDialog() {
        var tileSources = [];
        var images = document.querySelectorAll('#text img');
        for (var i = 0; i < images.length; i++) {
            tileSources.push({'type': 'image', 'url': images[i].src})
        }
        this.showImages(tileSources)
    }

}


MAX.addPlugin(new ImageViewer('img_viewer'));