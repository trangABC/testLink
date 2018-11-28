#!/bin/bash
#===============================================================================
#
#          FILE: setup.sh
# 
#         USAGE: ./setup.sh 
# 
#   DESCRIPTION: File to setup ShareLedger Masternode
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: ShareRing,
#  ORGANIZATION: 
#       CREATED: 11/27/2018 10:56
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
set -e


platform=""
arch=""
SHARELEDGER="./shareledger"

getOs() {
    case "$OSTYPE" in
        "linux-gnu")
            platform="linux"
            ;;
        "darwin"* )
            platform="darwin"
            ;;
        *)
            echo "Unknown operating system"
            exit 1
            ;;
    esac

    arch=$(uname -m)
    case "$(uname -m)" in
        "x86_64")
            arch="amd64"
            ;;
        *)
            echo -e "Unknown architecture. Please contact develop team."
            exit 1
            ;;
    esac
}

getOs

# MasterNode ports
P2P_PORT=46656
RPC_PORT=46657
CONFIGDIR=${HOME}/.shareledger
TOKENS=0

# Validator Data
MONIKER=""
WEBSITE="sharering.network"
DETAILS="ShareLedger's Masternode"



# URLS
EXECUTABLE_URL="https://github.com/trangABC/testLink/raw/master/shareledger_${platform}_${arch}"
GENESIS_URL="https://github.com/trangABC/testLink/raw/master/genesis.json"
PEERS_URL="https://github.com/trangABC/testLink/raw/master/peers.txt"
PEERS_FILE="peers.txt"
DOWNLOAD_TOOL=""


SCRIPT_NAME="$0"

usage="USAGE: ${SCRIPT_NAME} [-h]
    
    Script to set up and run ShareLedger Masternode

1. To setup Masternode, run the following command:
        ${SCRIPT_NAME} -m moniker -t tokens [-c dir] [-p p2p_port] [-r rpc_port] [-w website] [-d details]

    where:
        -h  show this help text
        -m  Moniker name. Your Masternode unique name.
        -t  number of SHR tokens to be staked.
        -c  Configuration directory. (Optional. Default: ${CONFIGDIR})
        -p  P2P port. Port to open for other Masternode to listen to. (Optional. Default: 46656)
        -r  RPC port. Port for clients to connect to. ( Optional. Default: 46657 )
        -w  Masternode website. (Optional. Default: \"sharering.network\")
        -d  Maternode details. (Optional. Default: \"ShareLedger Masternode\")

    Example:
            ${SCRIPT_NAME} -m sharering -t 100

2. To run Masternode, execute:
        ${SCRIPT_NAME} run [-c dir]

    where:
        -h  show this help text
        -c  Configuration directory. (Optional. Default: ${CONFIGDIR})

    Please use the same configuration dir (-c) with the one in the setup phase if you specified different one.
"


########### UTILITIES #################


init_args () {
    local OPTIND OPTARG

    while getopts 'hm:t:c:p:r:w:d:' option; do
      case "$option" in
        h) echo "$usage"
           exit
           ;;
        m) MONIKER=$OPTARG
           #echo "MONIKER: ${MONIKER}"
           ;;
        t) TOKENS=$OPTARG
           #echo "TOKEN: ${TOKENS}"
           ;;
        c) CONFIGDIR=$OPTARG
            #echo "CONFIGDIR: ${CONFIGDIR}"
            ;;
        p) P2P_PORT=$OPTARG
            #echo "P2P_PORT: ${P2P_PORT}"
            ;;
        r) RPC_PORT=$OPTARG
            #echo "RPC_PORT: ${RPC_PORT}"
            ;;
        w) WEBSITE=$OPTARG
            #echo "WEBSITE: ${WEBSITE}"
            ;;
        d) DETAILS=$OPTARG
            #echo "DETAILS: ${DETAILS}"
            ;;
        :) printf "missing argument for -%s\n\n" "$OPTARG" >&2
           echo "$usage" >&2
           exit 1
           ;;
       \?) printf "illegal option: -%s\n\n" "$OPTARG" >&2
           echo "$usage" >&2
           exit 1
           ;;
      esac
    done
    shift $((OPTIND - 1))


    if [[ -z ${MONIKER} || ${TOKENS} == 0 ]]; then
        echo -e "-m (Moniker) and -t (tokens) are required"
        echo
        echo "$usage" >&2
        exit 1
    fi
}


run_args () {
    local OPTIND OPTARGS
    while getopts 'hc:' option; do
        case "$option" in
            h) echo "$usage"
               exit
               ;;
            c) CONFIGDIR=$OPTARG
                ;;
            :) printf "missing argument for -%s\n\n" "$OPTARG" >&2
               echo "$usage" >&2
               exit 1
               ;;
           \?) printf "illegal option: -%s\n\n" "$OPTARG" >&2
               echo "$usage" >&2
               exit 1
               ;;
        esac
    done
    shift $((OPTIND - 1))

}

prepare () {
    # Check wget/curl
    printf "Checking downloading tool (wget, curl)...."
    command -v wget >/dev/null 2>&1 && DOWNLOAD_TOOL="wget"
    if [[ -z ${DOWNLOAD_TOOL} ]]; then
        command -v curl >/dev/null 2>&1 && DOWNLOAD_TOOL="curl"
    fi

    if [[ -z {DOWNLOAD_TOOL} ]]; then
        printf "F\n"
        return 1
    else
        printf "OK\n"
        return 0
    fi

}

install () {
    if [[ $platform == "darwin" ]]; then
        printf "Install $1 using *brew*"
        if brew -q install "$1"; then
            return
        else
            if command -v brew >/dev/null 2>&1 ; then
                printf "*$1* installation using *brew* has failed. Please check"
            else
                printf "*brew* does not exist. Please install *brew*"
            fi
        fi
    else
        printf "Install $1 using *apt*"
        if sudo apt-get install -y "$1"; then
            return
        else
            return
        fi
    fi
}

download () {
    if [[ -z "${DOWNLOAD_TOOL}" ]]; then
        echo -e "wget or curl is needed"
        exit 1
    fi
    
    if [[ ${DOWNLOAD_TOOL} == "wget" ]]; then
        params="-q -O" # wget -q quiet
    else
        params="-fsSL -o" # curl -fsSL fail, silent, location
    fi
    
    printf "Download $1 to $2..."
    if ${DOWNLOAD_TOOL} "$1" ${params} "$2" >/dev/null ; then
        printf "OK\n"
        return 0
    else
        printf "F\n"
        return 1
    fi
}

init () {
    # Read command line arguments
    init_args "$@"
    
    echo "Initialize Masternode with:"
    printf "\tMasternode's moniker: ${MONIKER}\n"
    printf "\tTokens to be staked : ${TOKENS}\n"
    printf "\tConfiguration dir   : ${CONFIGDIR}\n"
    printf "\tRPC port            : ${RPC_PORT}\n"
    printf "\tP2P port            : ${P2P_PORT}\n"
    printf "\tWebsite             : ${WEBSITE}\n"
    printf "\tDetails             : ${DETAILS}\n"
    printf "\n\n"


    # Preare neccessary tools
    prepare || exit 1

    # download shareledger depending on OS
    # NOTE: depending on OS
    # cleanup 
    rm -f "${SHARELEDGER}"
    download "${EXECUTABLE_URL}"  "${SHARELEDGER}" || exit 1
    chmod +x "${SHARELEDGER}"
    
    # download persistentpeers
    download "${PEERS_URL}" "${PEERS_FILE}" || exit 1

    # init file
    printf "Initialize MasterNode:\n"
    
    peers=$(cat "${PEERS_FILE}")

    result=$("${SHARELEDGER}" init --home ${CONFIGDIR} --rpc-port ${RPC_PORT} --p2p-port ${P2P_PORT} --moniker "${MONIKER}" --persistent-peers "${peers}")

    if ! grep "PrivateValidator" <<< "${result}" >/dev/null; then
        exit 1
    fi
    
    # download genesis
    download "${GENESIS_URL}" "${CONFIGDIR}/config/genesis.json" || exit 1

    # register Masternode
    "${SHARELEDGER}" register_masternode --home "${CONFIGDIR}" --moniker "${MONIKER}" --tokens "${TOKENS}" --website "${WEBSITE}" --details "${DETAILS}"
   
}

run () {
    run_args "$@"
    "${SHARELEDGER}" node
}

main () {
    if [[ "$#" < 1  ]]; then
        echo -e "Invalid number of arguments"
        echo
        echo "$usage"
        exit 1
    fi

    case "$1" in
        init)
            shift
            init "$@"
            ;;
        run)
            shift
            run "$@"
            ;;
        address)
            shift
            if [[ ! -f ${SHARELEDGER} ]]; then
                echo -e "Executable *shareledger* not found."
                echo -e "Please init first."
                echo "$usage"
            else 
                "${SHARELEDGER}" show_priv_key
            fi
            ;;
        *)
            echo -e "Unknown command $1"
            help
            ;;
    esac
}

main "$@"
