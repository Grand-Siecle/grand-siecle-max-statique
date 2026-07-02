document.addEventListener("DOMContentLoaded", async function() {

	let currentPage = window.location.href;
	if(currentPage.includes("/index/") && currentPage.includes("#")) {
		if(document.querySelector(".subindex") !== null) {
			cleanIndexSubindex(currentPage) ;
		} else {
			cleanIndex(currentPage) ;
		}
	}
});

async function cleanIndexSubindex(currentPage) {		
	let searchedEntry = decodeURIComponent(currentPage.split("#")[1].replaceAll("+"," "));
	const foundEntry = (key) => key.textContent === searchedEntry ;
	document.querySelectorAll(".subindex").forEach(subindex => {
		let subindexContent = Array.from(subindex.querySelectorAll("span"));
		if(subindexContent.some(foundEntry)) {
			getEntry(subindex, searchedEntry).then(entry => {
				subindex.removeChild(subindex.querySelector("div"));
				entry.forEach(para => {
					subindex.appendChild(para)
				})
			})
		} else {
			subindex.style.display = "none";
		}
	});
};

async function cleanIndex(currentPage) {
	let searchedEntry = decodeURIComponent(currentPage.split("#")[1].replaceAll("+"," "));
	const foundEntry = (key) => key.textContent === searchedEntry ;
	let index = document.querySelector(".index");
	
	getEntry(index, searchedEntry).then(entry => {
		index.querySelectorAll("fieldset").forEach(field => {
			index.removeChild(field)
		})		
		entry.forEach(para => {
			index.appendChild(para)
		})
	})	
};

async function getEntry(index, searchedEntry) {
	let result = []
	index.querySelectorAll("p").forEach(entry => {
		let keyValue = entry.querySelector("span").textContent;
		if(keyValue === searchedEntry) {
			result.push(entry);
		}
	});
	return result
};