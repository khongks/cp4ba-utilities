#!/bin/bash

_CLR_OFF="\033[0m"     # Color off
_CLR_BLNK="\033[5m"    # Blink
_CLR_BLU="\033[0;34m"  # Blue
_CLR_CYN="\033[0;36m"  # Cyan
_CLR_GRN="\033[0;32m"  # Green
_CLR_PPL="\033[0;35m"  # Purple
_CLR_RED="\033[0;31m"  # Red
_CLR_WHT="\033[0;37m"  # White
_CLR_YLW="\033[0;33m"  # Yellow
_CLR_BBLU="\033[1;34m" # Bold Blue
_CLR_BCYN="\033[1;36m" # Bold Cyan
_CLR_BGRN="\033[1;32m" # Bold Green
_CLR_BPPL="\033[1;35m" # Bold Purple
_CLR_BRED="\033[1;31m" # Bold Red
_CLR_BWHT="\033[1;37m" # Bold White
_CLR_BYLW="\033[1;33m" # Bold Yellow

#rif https://github.ibm.com/MSCH/footprint-tool/blob/main/footprint.sh


_BAW_DEPL_NAMESPACE=""
_BAW_DEPL_NAME=""
_CR_NAME=""
_BAW_ADMINUSER=""
_BAW_ADMINPASSWORD=""
_BAW_BAW_APP_FILE=""
_BAW_BAW_APP_CASE_FORCE=false

installApplication () {

  _BAW_EXTERNAL_BASE_URL=$(oc get ICP4ACluster -n ${_BAW_DEPL_NAMESPACE} ${_CR_NAME} -o jsonpath='{.status.endpoints}' | jq '.[] | select(.scope == "External") | select(.name | contains("base URL for '${_BAW_DEPL_NAME}'"))' | jq .uri | sed 's/"//g')

  LOGIN_URI="${_BAW_EXTERNAL_BASE_URL}ops/system/login"

  until _CSRF_TOKEN=$(curl -ks -u ${_BAW_ADMINUSER}:${_BAW_ADMINPASSWORD} -X POST -H 'accept: application/json' -H 'Content-Type: application/json' ${LOGIN_URI} -d '{"refresh_groups": true, "requested_lifetime": 7200}' | jq .csrf_token | sed 's/"//g') && [[ -n "$_CSRF_TOKEN" ]]
  do
    sleep 1
  done

  _INSTALL_CMD="ops/std/bpm/containers/install?inactive=false%26caseOverwrite=${_BAW_BAW_APP_CASE_FORCE}"
  INST_RESPONSE=$(curl -sk -u ${_BAW_ADMINUSER}:${_BAW_ADMINPASSWORD} -H 'accept: application/json' -H 'BPMCSRFToken: '${_CSRF_TOKEN} -H 'Content-Type: multipart/form-data' -F 'install_file=@'${_BAW_BAW_APP_FILE}';type=application/x-zip-compressed' -X POST "${_BAW_EXTERNAL_BASE_URL}${_INSTALL_CMD}")
  INST_DESCR=$(echo ${INST_RESPONSE} | jq .description | sed 's/"//g')
  INST_URL=$(echo ${INST_RESPONSE} | jq .url | sed 's/"//g')

  echo "Request result: "${INST_DESCR}
  sleep 2
  echo "Get installation status at url: "${INST_URL}
  while [ true ]
  do
    INST_STATE=$(curl -sk -u ${_BAW_ADMINUSER}:${_BAW_ADMINPASSWORD} -H 'accept: application/json' -H 'BPMCSRFToken: '${_CSRF_TOKEN} -X GET ${INST_URL} | jq .state | sed 's/"//g')
    if [[ ${INST_STATE} == "running" ]]; then
      sleep 2
    else
      echo ""
      echo "Final installation state: "${INST_STATE}
      break
    fi
  done

}


# to be updated
_BAW_DEPL_NAMESPACE="cp4ba-wfps-baw-pfs-demo"
_BAW_DEPL_NAME="baw1"
_CR_NAME="wfps-demo"
_BAW_ADMINUSER=cp4admin
_BAW_ADMINPASSWORD=dem0s
_BAW_BAW_APP_FILE="/home/marco/cp4ba-projects/cp4ba-wfps/apps/SimpleDemoBawWfPS.zip"

installApplication