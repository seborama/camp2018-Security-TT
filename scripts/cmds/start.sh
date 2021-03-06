#!/usr/bin/env bash
# A desirable attribute of a sub-script is that it does not use global env variables that
# were created by its parents (bash and system env vars are ok). Use function arguments instead to
# pass such variables
# There should be scarce exceptions to this rule (such as a var that contains the script main install dir)


[ -z "${SECURITY_TT_HOME}" ] && echo "ERROR - Invalid state - Make sure you use lab.sh" && exit 1


#####################################################################
function start_Docker() {
#####################################################################
    banner "Starting Docker"

    open --background -a Docker

    while ! docker system info &>/dev/null; do
        sleep 2
    done
}


#####################################################################
function wait_for_k8s_environment() {
#####################################################################
    local -r minikubeProfile=$1 ; : ${minikubeProfile:?<- missing argument in "'${FUNCNAME[0]}()'"}

    banner "Waiting for K8s environment readiness"
    wait_until_k8s_environment_is_ready ${minikubeProfile}
}


#####################################################################
function wait_for_minikube_registry_addon() {
#####################################################################
    local -r minikubeProfile=$1 ; : ${minikubeProfile:?<- missing argument in "'${FUNCNAME[0]}()'"}
    local -r registryHost=$2 ; : ${registryHost:?<- missing argument in "'${FUNCNAME[0]}()'"}

    banner "Waiting for Minikube registry addon readiness"
    wait_minikube_registry_addon_is_ready ${minikubeProfile} ${registryHost}
}


#####################################################################
function start_minikube() {
#####################################################################
    local -r minikubeProfile=$1 ; : ${minikubeProfile:?<- missing argument in "'${FUNCNAME[0]}()'"}

    if [ -f ~/.minikube/machines/${minikubeProfile}/config.json ]; then
        minikube start || exit 1
    else
        echo "It doesn't appear that you have not initialised the environment yet (profile: ${minikubeProfile})"
        echo "Please run: lab.sh init"
        exit 1
    fi
}


#####################################################################
function start_Kali() {
#####################################################################
    pushd "${SECURITY_TT_HOME}/Kali_Linux" >/dev/null || exit 1

    vagrant up || exit 1

    popd >/dev/null || exit 1
}


#####################################################################
function start() {
#####################################################################
    local -r minikubeProfile=$1 ; : ${minikubeProfile:?<- missing argument in "'${FUNCNAME[0]}()'"}
    local -r registryHost=$2 ; : ${registryHost:?<- missing argument in "'${FUNCNAME[0]}()'"}

    start_Kali

    start_Docker

    start_minikube ${minikubeProfile}
    wait_for_k8s_environment ${minikubeProfile}
    wait_for_minikube_registry_addon ${minikubeProfile} ${registryHost}
}

start "$@"
