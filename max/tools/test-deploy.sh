#!/bin/bash

TARGET=max-install-test
DIRECTORY=/tmp/$TARGET
BASEX_URL=https://files.basex.org/releases/10.4/BaseX104.zip


cd /tmp

#remove existing test dir if exists
if [ -d $TARGET ]
then
    echo 'delete existing test directory'
    rm -rf $TARGET
fi   

#create test tmp dir
mkdir $TARGET
cd $TARGET

git clone git@git.unicaen.fr:pdn-certic/MaX.git

#curl basex zip
basex_zip=`basename $BASEX_URL`
curl --silent -k -O $BASEX_URL
unzip $basex_zip
rm -rf $basex_zip

MAX_DIR=$DIRECTORY/MaX

echo 'Create symlink in basex webapp to MaX dir'
ln -s $MAX_DIR basex/webapp/

echo 'Export BASEX_PATH to '$DIRECTORY/basex
export BASEX_PATH=$DIRECTORY/basex
echo 'Initialize MaX'
./MaX/tools/max.sh -i
echo 'Run basexhttp'
./basex/bin/basexhttpstop -h4242
./basex/bin/basexhttp -h4242 &
echo 'Install Max Tei DEMO'
./MaX/tools/max.sh --d-tei
if [[ $OSTYPE == 'darwin'* ]]
then
  open -a firefox http://localhost:4242/max_tei_demo
else
  firefox http://localhost:4242/max_tei_demo
fi
