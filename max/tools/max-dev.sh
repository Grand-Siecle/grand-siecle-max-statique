#!/bin/bash
DIRECTORY=$(cd "$(dirname "$0")" && pwd)
MAX_PLUGINS_DIR=${DIRECTORY}/../plugins
dependency_test(){
  result=$(command -v "$1")
  if [[ -z $result ]]
  then
      echo "Dependency $1 is not satisfied - please install it first"
      exit 1
  else
      echo "Dependency $1 is satisfied"
  fi
}

if [[ -f ${DIRECTORY}'/../package.json' ]]
then
  dependency_test npm
  cd "${DIRECTORY}/.." || return
  npm install
  echo " -> Adds nodes_modules/.ignore file"
  touch "${DIRECTORY}/../node_modules/.ignore"
  echo -e "\n -> disabling all plugins (.ignore file)"
  for i in "${MAX_PLUGINS_DIR}"/*
  do
    if [[ -d "$i" ]]; then
      touch "${i}/.ignore" || abort
    fi
  done

  echo  -e "\n${GREEN} *** MaX initialization is finished :) *** ${NC}\n"
fi