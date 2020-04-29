export PROFILE=$PROFILE:$BASH_SOURCE

# Environment and Profile
alias path='echo $PATH | tr : "\n"'
alias ..='. ~/.zshrc'

function exportf {
	export $(xargs <$1)
}

function exporta {
	set -a
	. $1
	set +a
}

function maybe {
	if [ -f $1 ]
	then . $1
	fi
}

# Terminal magic
#
# ctrl+x+e (open an editor to write a long command)
#

# magic prompt
# To use export PROMPT_COMMAND=prompter
function prompter {
  export PS1="$(promptext)""$ "
}

function promptext {
  # edit to provide more context (see kprompter for example)
  echo -n ""
}

# open an editor to fix the previous command
alias fixcommand=fc

alias retire='disown -a && exit'

# Generic bash sugar
alias please='yes |'

# Random
alias pp='base64 < /dev/urandom | head -c'
function pp2 {
	head /dev/urandom | LC_ALL=C tr -dc A-Za-z0-9 | head -c $1 ; echo ''
}

# base64

function decodex {
    echo -n "$1 = "
    echo $2 | base64 --decode
    echo ""
}

function b64diff {
    read before
    read after
    beforedecode=$(echo ${before#"-"} | base64 --decode)
    afterdecode=$(echo ${after#"+"} | base64 --decode)
    diff <(echo "$beforedecode") <(echo "$afterdecode")
}

# Time
function epochtodate {
	date -r $1 '+%m/%d/%Y:%H:%M:%S'
}

# Filesystem
alias l='ls -halt'
alias recent='l | head'
alias pls='pwd && ls'
alias filesopen='sudo lsof | wc -l'
alias ll='wc -l * | sort -n'

alias find='find . -name'

function ca {
	if [ -d "$1" -o -z "$1" ]; then
		ls $1
		return
	fi
	cat $1
}

alias mkdate='mkdir $(date +%Y%m%d-%H%M%S)'

function cddate {
	d=$(date +%Y%m%d-%H%M%S)
	mkdir $d
	cd $d
}

function touchx {
	touch $1
	chmod +x $1
}

# usage: envset VERSION 1.0.0 env.sh
function envset {
	sed -ie s/^$1=.*$/$1=$2/ $3
}

# Clipboard
function pb {
	pbpaste | $1 | pbcopy
}

# Git
alias gitlog='git log --pretty=oneline --abbrev-commit'

function changes {
	git log --pretty=oneline --abbrev-commit $1..HEAD $2
}

alias standup='git-standup'

function repo {
	gh mk $1
	git clone https://github.com/voutasaurus/$1
	cd $1
}

# Productivity
alias today='vim $HOME/today'

function debug {
  suffix=$1
  if [ -z $suffix ]; then
    suffix=$(date '+%Y%m%d%H%M%S')
  fi
  cp $HOME/template-checklist-debug debug-checklist-$suffix && nvim debug-checklist-$suffix
}

# vim
alias vim='nvim'

# Network
alias flushdns='sudo killall -HUP mDNSResponder'
alias watch='watch -n1 '

alias dns='dig +short'

alias status='curl -sw "%{http_code}\n" -o /dev/null'

function ports {
	grep -oE ':[0-9]{1,5}' | sort | uniq
}

function xon {
	curl -v --resolve "$1:443:$2" https://$1
}

function xoni {
	curl -v --resolve "$1:80:$2" http://$1
}

function ip {
	curl https://ipinfo.io/$1 2>/dev/null
}

function statusbork {
	if [ $1 -ge 400 ]
	then
	    >&2 echo "statusbork(22): curl recieved status code $1"
	    exit 22
	fi
}

function pork {
	pid=$(lsof -ti tcp:$1)
	if [[ $pid ]]; then
		kill -9 $pid
	fi
}

function ng {
	nghttp -nv "https://$1"
}

# h2i google.com:443

function caa {
	dig @8.8.8.8 $1 type257
}

alias checktls='for domain in $(pbpaste); do curl https://$domain 2>/dev/null 1>/dev/null; echo $domain = $?; done'

function simple {
	open http://localhost:8000/
	python -m SimpleHTTPServer 8000
}

function fetchdir {
	local pempath=${1}
	local user=${2}
	local remotehost=${3}
	local dirpath=${4}
	scp -r -i $pempath $user@$remotehost:$dirpath .
}

function getgo {
	local url=$1
	d=$(mktemp -d)
	trap 'rm -rf $d' 0
	curl $url 2>/dev/null >$d/exec
	chmod +x $d/exec
	$d/exec
}

# Kubernetes
function chartout {
    stat helm-config >/dev/null && \
    mkdir -p output && \
    helm template --values helm-config/values.yaml --output-dir output helm-config
}

# To use kprompter, call kprompt to set PROMPT_COMMAND alias
function kprompter {
  export PS1="$(date -u "+%Y-%m-%dT%H:%M:%SZ") $(kubectl config current-context)""$ "
}

# kprompt
alias kprompt='PROMPT_COMMAND=kprompter'

function kubectx {
    local context="$1"
    if [[ "$context" == "dev" ]]
    then
        kubectl config use-context $KUBE_DEV
    elif [[ "$context" == "qa" ]]
    then
        kubectl config use-context $KUBE_QA
    elif [[ "$context" == "sand" ]]
    then
        kubectl config use-context $KUBE_SAND
    elif [[ "$context" == "prod" ]]
    then
        kubectl config use-context $KUBE_PROD
    elif [[ "$context" == "altdev" ]]
    then
        kubectl config use-context $KUBE_ALT_DEV
    elif [[ "$context" == "altsand" ]]
    then
        kubectl config use-context $KUBE_ALT_SAND
    elif [[ "$context" == "altprod" ]]
    then
        kubectl config use-context $KUBE_ALT_PROD
    elif [[ "$context" == "" ]]
    then
        kubectl config current-context
    else
        echo "context unknown"
    fi
}

function kubecent {
    kubectl get pod session-$USER &> /dev/null
    if [ $? != 0 ]; then
        kubectl run session-$USER --restart=Never --image=centos:7 -- sleep infinity
        sleep 5
    fi
    kubectl exec -it session-$USER bash
}

function kubebounce {
    kubectl get pods -o go-template='{{ range $v := .items }}{{ printf "%s\n" $v.metadata.name }}{{ end }}' | grep -v session | grep -v tiller | xargs kubectl delete pod
}

function secrets {
    kubectl get secrets $1 -o go-template='{{ range $k, $v := .data }}{{ printf "%s %s\n" $k $v }}{{ end }}' | while read key value; do
        echo -n "$key="
        echo -n "$value" | base64 --decode
        echo ""
    done
}

function sekret {
    local out=$(kubectl get secrets $1 -o go-template="{{.data.$2}}")
    if [[ "$out" == "<no value>" ]]; then
       >&2 echo "$2 not set in $1";
       return 1;
    fi
    echo -n $out | base64 --decode
    >&2 echo ""
}

function sekretset {
    # check $3 is set
    if [ $# -lt 3 ]
    then
        >&2 echo "please provide a secrets object, a key, and a value"
        return 1
    fi

    kubectl patch secrets $1 -p '{"data":{"'"$2"'":"'"$(echo -n $3 | base64)"'"}}'
}

# envtosecret reads an .env file and adds the key values to the named
# kubernetes secret object
# usage:
#   $ envtosecret secretname < .env
function envtosecret {
    export -f sekretset
    sed 's/#.*$//' | grep -v -e '^$' | sed 's/=/ /' | xargs -n 2 -I{} bash -c "sekretset $1 {}"
}

function sekkeys {
    kubectl get secrets $1 -o go-template='{{ range $k, $v := .data }}{{ printf "%s\n" $k }}{{ end }}'
}

# scan each secret object to see what an environment variable is set to
# usage:
# $ sekretscan ENV
function sekretscan {
    kubectl get secrets -o go-template='{{ range $v := .items }}{{ printf "%s\n" $v.metadata.name }}{{ end }}' \
    | grep -v default | grep -v regcred | grep -v helm | \
    while read x; do
        echo -n $x": "
        sekret $x $1
    done
}

# scan each pod in the namespace to see what an environment variable is set to
# NOTE: pods need to be restarted to pick up changes in a secret object
# usage:
# $ envcheck ENV
function envcheck {
    kubectl get pods -o go-template='{{ range $v := .items }}{{ printf "%s\n" $v.metadata.name }}{{ end }}' | grep -v session | grep -v tiller | while read x; do echo -n $x": "; kubectl exec $x -- sh -c "echo \$$1"; done
}

function kenv {
    kubectl exec $1 -- sh -c "echo \$$2"
}

function kat {
    kubectl exec $1 -- sh -c "cat $2"
}

function allpods {
    kubectl get pods -o go-template='{{ range $v := .items }}{{ printf "%s\n" $v.metadata.name }}{{ end }}'
}

function filescan {
    allpods | grep $1 | while read x; do echo $x": "; kat $x $(kenv $x $2); done
}

# restartpods will delete all the pods matching the argument
function restartpods {
    if [ $# -eq 0 ]
    then
        >&2 echo "please provide a pod type to restart"
        return 1
    fi

    allpods | grep $1 | xargs kubectl delete pod
}

function deployup {
    kubectl patch deployment $1 -p '{"spec":{"template":{"spec":{"containers":[{"name":"'"$1"'","image":"'"$2"'"}]}}}}'
}

function kubeaddrs {
    kubectl get services -o go-template='{{ range $x, $v := .items }}{{range $j, $port := $v.spec.ports}}{{printf "%s:%v\n" $v.metadata.name $port.port}}{{end}}{{ end }}'
}

alias kubedns='kubectl get pods --namespace=kube-system -l k8s-app=kube-dns'

alias kubevm='vboxmanage list vms --long | grep -e "Name:" -e "State:"'

function kuberestart {
	kubectl get pod $2 -n $1 -o yaml | kubectl replace --force -f -
}

function kubeip {
	kubectl get pod $1 -o go-template='{{.status.podIP}}'
}

function kubesrvip {
	kubectl get service $1 -o go-template='{{.spec.clusterIP}}'
}

function kubesrvport {
	kubectl get service $1 -o go-template='{{(index .spec.ports 0).port}}'
}

function kubesrvaddr {
	echo "$(kubesrvip $1)":"$(kubesrvport $1)"
}

alias kubereset='minikube delete && minikube start --kubernetes-version v1.8.0'

function kubepod {
	xargs -I nspace kubectl --namespace=nspace get pods -o go-template='{{range $i, $v := .items}}{{$v.metadata.name | printf "%s.nspace\n"}}{{end}}'
}

function kubepods {
	kubens | grep -v "kube-system" | grep -v "kube-public" | kubepod
}

function kuberun {
	local pod=$(echo $1 | cut -d "." -f 1)
	local ns=$(echo $1 | cut -d "." -f 2)

	GOOS=linux go build -o runner .
	kubectl cp runner $ns/$pod:/runner
	kubectl --namespace=$ns exec -it $pod -- /runner
}

# function kubeportal {
#     local domain=$(echo $1 | cut -d ":" -f 1)
#     local port=$(echo $1 | cut -d ":" -f 2)
#     local host=$(echo $domain | cut -d "." -f 1)
#     local namespace=$(echo $domain | cut -d "." -f 2)
#     kubectl --namespace=$namespace port-forward svc/$host :$port
# }

function kimages {
    if [ -z "$1" ]
    then
        kubectl get pod -o go-template='{{ range $v := .items }}{{ range $u := .spec.containers }}{{ printf "%s\n" $u.image }}{{ end }}{{ end }}' | sort -u
    else
        kubectl get pod -o go-template='{{ range $v := .items }}{{ range $u := .spec.containers }}{{ printf "%s\n" $u.image }}{{ end }}{{ end }}' | sort -u | grep $1
    fi
}

# Graph
function g {
	dot -Tsvg $1 > o.svg
	open o.svg
}

# Notifications
function notify {
	osascript -e 'on run argv
		display notification item 1 of argv with title item 2 of argv sound name item 3 of argv
	end run' "$2" "$1" "$3"
	say "$4"
}

alias success='notify "Success" "operation completed successfully" "Hero"'
alias failure='notify "Failed" "operation failed" "Basso"'

# docker
function flip {
	echo "(╯°□°）╯︵ ┻━┻"
	docker ps -aq | xargs docker rm -f
	docker network prune -f
	echo "The little boat flipped over."
}

alias sink='docker images -q | sort | uniq | xargs docker rmi -f'

# Go
function gov {
	docker run -v $HOME/go/src:/go/src -it golang:$1 bash
}

function lf {
	grep func $1 | sed G
}

function vendored {
	go list -f {{.Deps}} | tr ' ' "\n" | grep '^'"$1"'/vendor' | sed 's%'"$1"'/vendor/%%'
}

alias goget='GO111MODULE=off go get'

# Go debug type checking
alias goescape='go build -gcflags "-m"'

# Go pprof (local)
# see: https://godoc.org/github.com/rakyll/autopprof

# Certs / keys
#

function newkey {
  openssl ecparam -genkey -name prime256v1 -noout -out ec_private.pem
  openssl ec -in ec_private.pem -pubout -out ec_public.pem
}

function newcert {
	go run /usr/local/go/src/crypto/tls/generate_cert.go --host $1 --duration=$[20*365*24]h --ecdsa-curve=P256
}

function newca {
	go run /usr/local/go/src/crypto/tls/generate_cert.go --host none --ca --duration=$[20*365*24]h --ecdsa-curve=P256
}

# Package Management

# usage: installdmg https://example.com/path/to/pkg.dmg
function installdmg {
	set -x
	tempd=$(mktemp -d)
	curl $1 > $tempd/pkg.dmg
	listing=$(sudo hdiutil attach $tempd/pkg.dmg | grep Volumes)
	volume=$(echo "$listing" | cut -f 3)
	if [ -e "$volume"/*.app ]; then
	  sudo cp -rf "$volume"/*.app /Applications
	elif [ -e "$volume"/*.pkg ]; then
	  package=$(ls -1 | grep *.pkg | head -1)
	  sudo installer -pkg "$volume"/"$package".pkg -target /
	fi
	sudo hdiutil detach "$(echo "$listing" | cut -f 1)"
	rm -rf $tempd
	set +x
}

# Machine Learning

alias tenseup='source ~/tensorflow/bin/activate'

function packerup {
	set -x
	minikube start
	pachctl deploy local
	kubectl get all
	set +x
}

# Node: run setup for Node
# Defer initialization of nvm until nvm, node or a node-dependent command is
# run. Ensure this block is only run once if it gets sourced multiple times by
# checking whether __init_nvm is a function.
#
# Note: This is to be used in lieu of the nvm init commands that `brew install
# nvm` recommends (with nvm 0.34.0)
if [ -s "/usr/local/opt/nvm/nvm.sh" ] && [ ! "$(type -t __init_nvm)" = function ]; then
  export NVM_DIR="$HOME/.nvm"
  export NVM_ROOT="/usr/local/opt/nvm"
  [ -s "$NVM_ROOT/etc/bash_completion" ] && . "$NVM_ROOT/etc/bash_completion"
  declare -a __node_commands=('nvm' 'node' 'npm' 'yarn' 'gulp' 'grunt' 'webpack')
  function __init_nvm() {
    for i in "${__node_commands[@]}"; do unalias $i; done
    . "$NVM_ROOT"/nvm.sh
    unset __node_commands
    unset -f __init_nvm
  }
  for i in "${__node_commands[@]}"; do alias $i='__init_nvm && '$i; done
fi

# Google Cloud: run setup for Google Cloud
# The next line updates PATH for the Google Cloud SDK.
maybe '/usr/local/bin/google-cloud-sdk/path.bash.inc'

# The next line enables shell command completion for gcloud.
maybe '/usr/local/bin/google-cloud-sdk/completion.bash.inc'

alias gprojects='gcloud projects list'
alias gcontext='gcloud config get-value project'

# usage gcp [INSTANCE_NAME]:[REMOTE_FILE_PATH] [LOCAL_FILE_PATH]
alias gcp='gcloud compute scp'

# Azure
maybe $HOME/lib/azure-cli/az.completion

# Fun
alias shrug='echo "¯\_(ツ)_/¯"'

alias missionfire='curl isthemissiononfire.com 2>/dev/null | grep h1 | sed "s/<h1>//" | sed "s?</h1>??"'

alias improv101='yes &' # prints y forever and backgrounds the job to make it more annoying to stop
