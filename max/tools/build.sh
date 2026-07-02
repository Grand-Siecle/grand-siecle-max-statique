#!/bin/bash
#build max release ' zip

BASEX_URL=https://files.basex.org/releases/10.7/BaseX107.zip
SAXON_HE_URL="https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/10.8/Saxon-HE-10.8.jar"
FOP_URL="https://files.basex.org/modules/org/basex/modules/fop/FOP.jar"

DIRECTORY=$(cd `dirname $0` && pwd)
echo "Working directory = "$DIRECTORY

if [ -d dist ]
then
  rm -rf dist
fi

#extracts max version from package.json
MAX_VERSION=$(node -p -e "require('../package.json').version")

RELEASE_DIR=max-v$MAX_VERSION
MAX_WEBAPP_DIR=$RELEASE_DIR/max
echo "Building release "$RELEASE_DIR

#creates dest dist folder & sub folders
mkdir -p $MAX_WEBAPP_DIR
mkdir $MAX_WEBAPP_DIR/configuration
mkdir $MAX_WEBAPP_DIR/editions
mkdir $MAX_WEBAPP_DIR/plugins
mkdir $MAX_WEBAPP_DIR/tools

#copies files & folders
cp -r $DIRECTORY/../configuration/configuration.dist.xml $MAX_WEBAPP_DIR/configuration
cp -Lr $DIRECTORY/../ui $MAX_WEBAPP_DIR
cp -r $DIRECTORY/../rxq $MAX_WEBAPP_DIR
cp $DIRECTORY/../max.xq $MAX_WEBAPP_DIR
cp $DIRECTORY/../legal.txt $MAX_WEBAPP_DIR
cp $DIRECTORY/../README.md $MAX_WEBAPP_DIR
cp -Lr $DIRECTORY/../plugins $MAX_WEBAPP_DIR
MAX_PLUGINS_DIR=$MAX_WEBAPP_DIR/plugins
echo 'Target plugin dir = '$MAX_PLUGINS_DIR
for i in `ls $MAX_PLUGINS_DIR`
do
  touch $MAX_PLUGINS_DIR/$i/.ignore
done
cp $DIRECTORY/../tools/max.sh $MAX_WEBAPP_DIR/tools
cp -r $DIRECTORY/../tools/xq $MAX_WEBAPP_DIR/tools
cp $DIRECTORY/../tools/*.xml $MAX_WEBAPP_DIR/tools
cp $DIRECTORY/../CHANGELOG $MAX_WEBAPP_DIR/

#removes equations & pager plugins
rm -rf MAX_PLUGINS_DIR/equations
rm -rf MAX_PLUGINS_DIR/pager

##injects MAX VERSION in max.sh cli tool
#sed -i "2s/.*/MAX_VERSION=$MAX_VERSION/g" $MAX_WEBAPP_DIR/tools/max.sh

#creates VERSION file
echo "MaX "$MAX_VERSION >  $MAX_WEBAPP_DIR/VERSION

#gets and builds documentation
if [ -z $MAX_DOC_TOKEN ]
then
  echo 'Warning : environment variable MAX_DOC_TOKEN is not defined.'
  git clone git@git.unicaen.fr:pdn-certic/max-documentation.git
else
  echo 'Environment variable $MAX_DOC_TOKEN is correctly defined !'
  git clone https://gitlab-ci-token:$MAX_DOC_TOKEN@git.unicaen.fr/pdn-certic/max-documentation.git
fi

cd max-documentation

#override default documentation compil option for local use
cp ../mkdocs_local_config.yml mkdocs.yml
mkdocs build
mv site ../$RELEASE_DIR/documentation
cd ..
rm -rf max-documentation

#fetch basex zip release
basex_zip=`basename $BASEX_URL`
curl --silent -k -O $BASEX_URL
unzip $basex_zip
rm -rf $basex_zip
mv basex $RELEASE_DIR

#dl and copy saxon & fop jars in basex lib dir
echo 'dl and copy saxon & fop jars in basex lib dir'
cd $DIRECTORY
curl --silent -k -O $SAXON_HE_URL
curl --silent -k -O $FOP_URL
mv Saxon-HE-10.8.jar $RELEASE_DIR/basex/lib/custom/
mv FOP.jar $RELEASE_DIR/basex/lib/custom/


#create symlink to max web app in basex webapp
echo 'create symlink to max web app in basex webapp'
cd $RELEASE_DIR/basex/webapp
ln -s ../../max max



# generate Makefile from dev one
echo 'TOOLS_DIR=max/tools/' > Makefile
cat>> Makefile<< EOF

install:  ## installation, définition du mot de passe admin de BaseX
	\$(TOOLS_DIR)max.sh
	@echo "Installation ok !"
.PHONY: install

dist: ## création d'une archive prête à deployer : MaX + BaseX + Sources XML
	@if [ ! -d 'max' ]; then\
		echo 'Opération impossible';\
		exit 1;\
	fi
	@if [ -d 'build' ]; then\
		rm -rf build;\
	fi
	mkdir build
	cp -r max basex Makefile build/
	rm build/basex/.basexhome
	rm build/basex/.basex
	touch build/basex/.basexhome
	cd build && tar -czvf build.tar.gz *
	mv build/build.tar.gz .
	rm -rf build
	@echo 'Build ok'
.PHONY: dist

EOF

awk 'f;/#### end of dev targets/{f=1}' $DIRECTORY/../Makefile >> Makefile
mv Makefile $RELEASE_DIR

#create zip release
cd $DIRECTORY
zip -r --symlinks $RELEASE_DIR.zip $RELEASE_DIR

mkdir dist
mv $RELEASE_DIR.zip $RELEASE_DIR dist

echo "RELEASE BUILD SUCCESSFULLY  in dist/"$RELEASE_DIR.zip