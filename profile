export PROFILE=$PROFILE:$BASH_SOURCE

# Environment and Profile
alias path='echo $PATH | tr : "\n"'
alias ..='. ~/.bash_profile'

function exportf {
	export $(xargs <$1)
}

function maybe {
	if [ -f $1 ]
	then . $1
	fi
}

# Generic bash sugar
alias please='yes |'

# Filesystem
alias l='ls -lah'
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

# Productivity
alias today='vim $HOME/today'

# vim
alias vim='nvim'

# Network
alias flushdns='sudo killall -HUP mDNSResponder'
alias watch='watch -n1 '

alias status='curl -sw "%{http_code}\n" -o /dev/null'

function xon {
	curl -v --resolve "$1:443:$2" https://$1
}

function xoni {
	curl -v --resolve "$1:80:$2" http://$1
}

function ip {
	curl https://ipinfo.io/$1 2>/dev/null | jq
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

# Kubernetes

alias kubectx='kubectl config current-context'

alias kubedns='kubectl get pods --namespace=kube-system -l k8s-app=kube-dns'

alias kubevm='vboxmanage list vms --long | grep -e "Name:" -e "State:"'

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

alias kubesh='kubectl run busybox --image=busybox --restart=Never --tty -i --generator=run-pod/v1'

alias kubereset='minikube delete && minikube start --kubernetes-version v1.7.0'

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

alias goescape='go build -gcflags "-m"'

# Certs
function newcert {
	go run /usr/local/go/src/crypto/tls/generate_cert.go --host $1
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
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

# Google Cloud: run setup for Google Cloud
# The next line updates PATH for the Google Cloud SDK.
maybe '/usr/local/bin/google-cloud-sdk/path.bash.inc'

# The next line enables shell command completion for gcloud.
maybe '/usr/local/bin/google-cloud-sdk/completion.bash.inc'

alias gprojects='gcloud projects list'
alias gcontext='gcloud config get-value project'

# Azure
maybe $HOME/lib/azure-cli/az.completion

# Fun
alias shrug='echo "¯\_(ツ)_/¯"'

alias missionfire='curl isthemissiononfire.com 2>/dev/null | grep h1 | sed "s/<h1>//" | sed "s?</h1>??"'

alias improv101='yes &' # prints y forever and backgrounds the job to make it more annoying to stop
