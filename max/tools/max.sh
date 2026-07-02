#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

abort(){
  echo -e "\n ${RED}Abort${NC} \n"
  exit 1
}

#get the last gitlab project release number
last_gitlab_project_release(){
  basename "$(curl -fs -o/dev/null -w %{redirect_url} "$1")"
}

display_usage(){
    echo
    echo -e "\t-h: Display help."
    echo -e "\t-v: Display MaX version."
    echo -e "\t-p: Specify BaseX port to use for db feed. Default one is $PORT."
    echo -e "\t-b: Specify custom BaseX home. Common BaseX will be used by default if presents."
    echo -e "\t-n: Deploy new edition with its XML sources."
    echo -e "\t--d-tei: Deploy the TEI demo edition project."
    echo -e "\t--d-ead: Deploy the EAD demo edition project."
    echo -e "\t--list-plugins: Show plugins and status."
    echo -e "\t--enable-plugin [plugin_name] [edition_name]: Enable [plugin_name] plugin in [edition_name] edition."
    echo -e "\t--disable-plugin [plugin_name] [edition_name]: Disable [plugin_name] plugin in [edition_name] edition."
    echo
}

PORT=1984
DIRECTORY=$(cd "$(dirname "$0")" && pwd)

#read max version in package.json(dev mode) file or VERSION file (prod mode)
if [[ ! -f ${DIRECTORY}/../VERSION ]]
then
  MAX_VERSION=$(node -p -e "require('${DIRECTORY}/../package.json').version")'-dev'
else
  MAX_VERSION=$(cat "${DIRECTORY}/../VERSION")
fi

# save args for end of script routines
args=( "$@" )
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h) display_usage
            exit 0;;
        -v) echo $MAX_VERSION
            exit 0;;
        -p) PORT="$2"; shift ;;
        -b) BASEX_PATH="$2"; shift ;;
    esac
    shift
done


MAX_PLUGINS_DIR=${DIRECTORY}/../plugins
BASEX_CLIENT_BIN="basexclient"
BASEX_BIN="basex"
TEI_DEMO_URL="https://git.unicaen.fr/pdn-certic/max-tei-demo"
EAD_DEMO_URL="https://git.unicaen.fr/pdn-certic/max-ead-demo"
MAX_TEI_DEMO_VERSION_NUMBER=$(last_gitlab_project_release $TEI_DEMO_URL'/-/releases/permalink/latest')
check=$?
if [[ $check -gt 0 ]]
  then
    display_usage
    echo
    echo -e "${RED}MaX : Cannot access to remote url - please check your network configuration.${NC}"
    abort
fi
MAX_EAD_DEMO_VERSION_NUMBER=$(last_gitlab_project_release $EAD_DEMO_URL'/-/releases/permalink/latest')
MAX_TEI_DEMO_VERSION="max-tei-demo-$MAX_TEI_DEMO_VERSION_NUMBER"
MAX_EAD_DEMO_VERSION="max-ead-demo-$MAX_EAD_DEMO_VERSION_NUMBER"
TEI_DEMO_RELEASE_URL="$TEI_DEMO_URL/-/archive/$MAX_TEI_DEMO_VERSION_NUMBER/$MAX_TEI_DEMO_VERSION.zip"
EAD_DEMO_RELEASE_URL="$EAD_DEMO_URL/-/archive/$MAX_EAD_DEMO_VERSION_NUMBER/$MAX_EAD_DEMO_VERSION.zip"
#SAXON_HE_URL="https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/10.8/Saxon-HE-10.8.jar"
#FOP_URL="https://files.basex.org/modules/org/basex/modules/fop/FOP.jar"
DEFAULT_EAD_PLUGINS=(side_toc ead_basket)

echo "---------------------------"
echo "  MaX - Utilities - $MAX_VERSION"
echo "---------------------------"

# creates config file if not exists (.dist copy)
if [[ ! -f ${DIRECTORY}/../configuration/configuration.xml ]]
then
    echo "Configuration file does not exist: copying the .dist one"
    cp  "${DIRECTORY}/../configuration/configuration.dist.xml" "${DIRECTORY}/../configuration/configuration.xml"
fi

echo
echo -e "Let's check and set BaseX binaries..."
echo

if [[ -d ${DIRECTORY}/../basex ]]
then
  BASEX_CLIENT_BIN="${DIRECTORY}/../basex/bin/basexclient"
  BASEX_BIN="${DIRECTORY}/../basex/bin/basex"
  BASEX_HTTP="${DIRECTORY}/../basex/bin/basexhttp"
  BASEX_HTTPSTOP="${DIRECTORY}/../basex/bin/basexhttpstop"
  echo "BaseX OK"
elif [[ -d ${DIRECTORY}/../../basex ]]
then
  BASEX_CLIENT_BIN="${DIRECTORY}/../../basex/bin/basexclient"
  BASEX_BIN="${DIRECTORY}/../../basex/bin/basex"
  BASEX_HTTP="${DIRECTORY}/../../basex/bin/basexhttp"
  BASEX_HTTPSTOP="${DIRECTORY}/../../basex/bin/basexhttpstop"
  echo "BaseX OK"
else
  echo 'BaseX is missing'
  abort
fi

echo
echo "Your config : "
echo -e "\tBASEX_CLIENT_BIN = $BASEX_CLIENT_BIN"
echo -e "\tBASEX_BIN = $BASEX_BIN"
echo

#set password admin password if not already defined
if [[ ! -f ${DIRECTORY}/../basex/data/users.xml ]] && [[ ! -f ${DIRECTORY}/../../basex/data/users.xml ]]
then
  $BASEX_HTTPSTOP || true
  $BASEX_HTTP -S
  echo 'Please define a BaseX admin password'
  $BASEX_BIN -c'PASSWORD'
  $BASEX_HTTPSTOP
fi


list_plugins(){
  echo
  echo -e ' --- MaX plugins --- '
#  list_plugins_dir $MAX_PLUGINS_DIR
  for i in "${MAX_PLUGINS_DIR}"/*
  do
    plug=$(basename "${i}")
    COUNT_PLUGIN_USAGE=$($BASEX_BIN "count(doc('../configuration/configuration.xml')//plugin[@name='$plug'])")
    echo -ne "- ${plug} :"
    if [[ $COUNT_PLUGIN_USAGE -eq 0 ]]
    then
      echo -e " ${RED}not used${NC}"
    else
      echo -e " ${GREEN}enabled${NC} in $COUNT_PLUGIN_USAGE edition(s)"
    fi
  done
  echo
}


enable_plugin(){
  if [[ ! $2 ]]
  then
    echo -e "Usage : max.sh --enable-plugin [plugin_name] [edition_name]: Enable [plugin_name] plugin for edition [edition_name]\n"
    return
  fi
  echo -en "Enabling plugin $1"
  if [[ ! -d $MAX_PLUGINS_DIR/$1 ]]
    then
      echo -e " ${RED}Oups ! $MAX_PLUGINS_DIR/$1 does not exist.${NC}\n"
      return
  fi

  if [[ -f $MAX_PLUGINS_DIR/$1/.ignore ]]
  then
      rm "$MAX_PLUGINS_DIR/$1/.ignore"
  fi
  echo -ne " ... "
  $BASEX_BIN -u -b pluginId="$1" -b projectId="$2" "${DIRECTORY}/xq/insert_plugin_config.xq" # -u => save modified file on disk
  ret=$?
  if [[ $ret -eq 0 ]]
  then
    echo -ne "${GREEN}OK"
  else
    echo -ne "${RED}ERROR"
  fi
  echo -e "${NC}"
}

disable_plugin(){
  echo
  if [[ ! $2 ]]
  then
    echo "Usage : max.sh --disable-plugin [plugin_name] [edition_name]: disable [plugin_name] plugin for edition [edition_name]"
    echo
    return
  fi

  $BASEX_BIN -u -b pluginId="$1" -b projectId="$2" "$DIRECTORY/xq/remove_plugin_config.xq" # -u => save modified file on disk

  NB_USAGE=$($BASEX_BIN "count(doc('${DIRECTORY}/../configuration/configuration.xml')//plugin[@name='$1'])")

  if [[ $NB_USAGE -eq 0 ]]
  then
    touch "$MAX_PLUGINS_DIR/$1/.ignore"
  fi
  echo -e "Plugin $1 successfully disabled."
  echo
}


#adds xml datas to a new db
db_project_feed(){
   # basex must be running
   $BASEX_HTTPSTOP || true
   $BASEX_HTTP -S
   echo "CREATE DATABASE $1" > feed.txt
   echo "ADD $2" >> feed.txt
   echo "Please type your BaseX login/password :"

   $BASEX_CLIENT_BIN -p "${PORT}" -c feed.txt
   ret=$?
   if [[ $ret -gt 0 ]]
    then echo "Cannot insert data in DB. Is your BaseX running on port $PORT ?"
    rm feed.txt
    $BASEX_HTTPSTOP
    return 1
   else
    echo "INFO: The $1 DB was successfully created."
    rm feed.txt
    $BASEX_HTTPSTOP
    return 0
   fi
}

#is project already declared in main config file ?
check_project_xinclude(){
  echo -e "Check project config..."
  cmd="$BASEX_BIN -b projectId=$1 -b maxPath=${DIRECTORY}/.. ${DIRECTORY}/xq/check_config_exists.xq"
  a=$(eval "${cmd}")
  if [[ $a == 0 ]]
  then
    echo "Edition $1 is already declared in configuration file. Remove it before installing your edition."
    abort
  fi
  return 0
}

# demo edition deployment
install_demo(){
  echo -e "Install demo..."
  url=$1
  echo -e "\tURL: ${1}"
  zip_name=$2
  echo -e "\tZip:${2}"
  edition_name=$3
  echo -e "\tEdition:${3}"
  check_project_xinclude "$edition_name"

  if [[ ! -d ${DIRECTORY}/../editions ]]
  then
    echo 'Creates "editions" directory.'
    mkdir "${DIRECTORY}/../editions"
  fi

  if [[ -d ${DIRECTORY}/../editions/$edition_name ]]
  then
    echo "Removes existing demo edition."
    rm -rf "${DIRECTORY}/../editions/$edition_name"
  fi

  cd "${DIRECTORY}/../editions" || abort
  echo "Downloading Max Demo resources at $url"
  curl --silent -O "$url"
  unzip "$zip_name.zip"
  getResult=$?
  if [[ $getResult -ne 0 ]]
  then
   echo "MaX demo install error : Cannot fetch $url"
   abort
  fi
  mv "$zip_name" "$edition_name"
  rm "$zip_name.zip"
  cd "${DIRECTORY}" || abort

  # db_demo_feed
  db_project_feed "$edition_name" "${DIRECTORY}/../editions/$edition_name/dataset/"
  ret_code=$?
  if [[ $ret_code -gt 0 ]]
  then
    echo "$edition_name: installation failed"
    rm -rf "${DIRECTORY}/../editions/$edition_name"
    abort
  else
    echo -e "$edition_name: db fed successfully"
  fi

  #include edition conf file in main max config one
  include_project_config "$edition_name"

  # get plugins list from config file
  echo -e "\nInstall plugins"
  plugin_list=$($BASEX_BIN -q'for $p in doc("../configuration/configuration.xml")//edition[@xml:id="'$edition_name'"]//plugin return string($p/@name)')
  for plugin in ${plugin_list[@]}
  do
    enable_plugin "$plugin" "$edition_name"
  done

  echo -e "\n${GREEN}INFO: The edition $edition_name was successfully deployed.${NC}\n"
  return 0
}


deploy_new_edition(){
  read -r -e -p "Project ID ? " project_id
  read -r -e -p "XML Project type (tei, ead, ...) ? " xmlns
  read -r -e -p "Database path ? " db_path

  check_project_xinclude "$project_id"
  ret=$?
  if [[ $ret -gt 0 ]]
  then
    exit 1
  fi

  new_edition_build "$project_id" "$db_path" "$xmlns"
  read -r -e -p "XML sources path ? " data_path
  db_project_feed "$db_path" "$data_path"
  ret_code=$?
  if [[ $ret_code -gt 0 ]]
  then
    echo 'Process failed'
    return 1
  fi

  mkdir -p "${DIRECTORY}/../editions/$project_id/fragments/fr"
  mkdir "${DIRECTORY}/../editions/$project_id/xq"
  mkdir "${DIRECTORY}/../editions/$project_id/ui"
  mkdir "${DIRECTORY}/../editions/$project_id/ui/css"
  mkdir "${DIRECTORY}/../editions/$project_id/ui/fonts"
  mkdir "${DIRECTORY}/../editions/$project_id/ui/i18n"
  mkdir "${DIRECTORY}/../editions/$project_id/ui/images"
  mkdir "${DIRECTORY}/../editions/$project_id/ui/js"
  mkdir "${DIRECTORY}/../editions/$project_id/ui/templates"
  mkdir "${DIRECTORY}/../editions/$project_id/ui/xsl"

  touch "${DIRECTORY}/../editions/$project_id/ui/css/$project_id.css"

  # creates about frag page
  sed "s/\$project_id/$project_id/g;" "${DIRECTORY}/about.frag_tmpl.html" | tee "${DIRECTORY}/../editions/$project_id/fragments/fr/about.frag.html"
  cp "${DIRECTORY}/menu_default.xml" "${DIRECTORY}/../editions/$project_id/menu.xml"
  if [[ $xmlns = 'ead' ]]
  then
      for plugin in "${DEFAULT_EAD_PLUGINS[@]}"
      do
        enable_plugin "$plugin" "$project_id"
      done
  fi
  echo
  echo "Project $project_id is ready !"
  exit 0
}


include_project_config(){
    $BASEX_BIN -u -b projectId="$1" "${DIRECTORY}/xq/include_project_config.xq" # -u => save modified file on disk
}

new_edition_build(){
  if [[ ! -d ${DIRECTORY}/../editions ]]
  then
    echo 'Creates "editions" directory.'
    mkdir "${DIRECTORY}/../editions"
  fi
  mkdir "${DIRECTORY}/../editions/$1"
  $BASEX_BIN -b projectId="$1" -b dbPath="$2" -b envType="$3" -b maxPath="${DIRECTORY}/.." ${DIRECTORY}/xq/create_project_config.xq
  include_project_config "$1"
}

set -- "${args[@]}"
while [[  "$#" -gt 0 ]]; do
    case $1 in
        -p) shift ;; # already done
        -b) shift ;; # already done
        -n) deploy_new_edition;exit 0;;
        --d-tei) install_demo "$TEI_DEMO_RELEASE_URL" "$MAX_TEI_DEMO_VERSION" max_tei_demo;exit 0;;
        --d-ead) install_demo "$EAD_DEMO_RELEASE_URL" "$MAX_EAD_DEMO_VERSION" max_ead_demo;exit 0;;
        --list-plugins) list_plugins;exit 0;;
        --enable-plugin) enable_plugin "$2" "$3";exit 0;;
        --disable-plugin) disable_plugin "$2" "$3";exit 0;;
         *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done
