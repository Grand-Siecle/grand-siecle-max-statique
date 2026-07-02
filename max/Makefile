TOOLS_DIR=tools/
HTTP_PORT=1234
install-basex: # BaseX: Téléchargement, installation et définition du mot de passe admin
	@if [ -d 'basex' ]; then\
		echo 'BaseX install OK.';\
	else\
		curl https://files.basex.org/releases/10.7/BaseX107.zip --output BaseX107.zip;\
		unzip BaseX107.zip;\
		curl https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/10.8/Saxon-HE-10.8.jar --output Saxon-HE-10.8.jar ;\
		curl https://files.basex.org/modules/org/basex/modules/fop/FOP.jar --output FOP.jar ;\
		mv Saxon-HE-10.8.jar basex/lib/custom/;\
		mv FOP.jar basex/lib/custom/;\
		rm BaseX107.zip;\
		./$(TOOLS_DIR)max.sh;\
    fi
.PHONY: install-basex

install: install-basex ##  installation de MaX
	./$(TOOLS_DIR)max-dev.sh
	mkdir basex/webapp/MaX
	ln -s ../../../configuration basex/webapp/MaX/
	ln -s ../../../editions basex/webapp/MaX/
	ln -s ../../../ui basex/webapp/MaX/
	ln -s ../../../plugins basex/webapp/MaX/
	ln -s ../../../max.xq basex/webapp/MaX/
	ln -s ../../../rxq basex/webapp/MaX/
	ln -s ../../../package.json basex/webapp/MaX/
	@echo "Install done !"
.PHONY: install

package:  ## packaging de la version à distribuer
	cd $(TOOLS_DIR) && ./build.sh
	@echo "Package ok"
.PHONY: package

#### end of dev targets
run:  stop ## lancement du serveur basex
	$(TOOLS_DIR)max.sh
	@if [ ! $(HTTP_PORT)  ]; then\
		./basex/bin/basexhttp -S;\
	else\
		./basex/bin/basexhttp -h$(HTTP_PORT) &\
	fi
.PHONY: run

stop:  ## arrêt du serveur basex
	./basex/bin/basexhttpstop > /dev/null 2>&1 || true
.PHONY: stop

install-tei-demo: run ## installation de l'édition de démo TEI
	sleep 2
	$(TOOLS_DIR)max.sh --d-tei
	@echo "done"
.PHONY: install-tei-demo

install-ead-demo: run ## installation de l'édition de démo EAD
	sleep 2
	$(TOOLS_DIR)max.sh --d-ead
	@echo "done"
.PHONY: install-ead-demo

enable-plugin: ## activation d'un plugin : make enable-plugin [plugin-name] [edition-name]
	cd $(TOOLS_DIR) && ./max.sh --$(MAKECMDGOALS)
.PHONY: enable-plugin

disable-plugin: ## désactivation d'un plugin : make disable-plugin [plugin-name] [edition-name]
	cd $(TOOLS_DIR) && ./max.sh --$(MAKECMDGOALS)
.PHONY: disable-plugin

list-plugins: ## affichage de la liste des plugins
	cd $(TOOLS_DIR) && ./max.sh --$(MAKECMDGOALS)
.PHONY: list-plugins

help: ## afficher l'aide
	@echo "\nChoisissez une commande. Les choix sont:\n"
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[0;36m%-12s\033[m %s\n", $$1, $$2}'
	@echo ""
.PHONY: help