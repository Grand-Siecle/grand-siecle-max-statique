import AbstractMax from './AbstractMax.js'

export default class Max extends AbstractMax{
    constructor(pid,baseURL, pluginsURL, fid) {
        super(pid, baseURL, pluginsURL, fid)

    }
}

window.MAX = new Max(projectId, baseURI, fragmentId);

document.addEventListener('DOMContentLoaded', () => {
   MAX.run();
})


