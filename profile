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

function ca {
	if [ -d "$1" -o -z "$1" ]; then
		ls $1
		return
	fi
	cat $1
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
	docker run -v $HOME/go/src:/root/go/src -it golang:$1 bash
}

function lf {
	grep func $1 | sed G
}

function vendored {
	go list -f {{.Deps}} | tr ' ' "\n" | grep '^'"$1"'/vendor' | sed 's%'"$1"'/vendor/%%'
}

# Certs
function newcert {
	go run /usr/local/go/src/crypto/tls/generate_cert.go --host $1
}

# Node: run setup for Node
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

# Google Cloud: run setup for Google Cloud
# The next line updates PATH for the Google Cloud SDK.
maybe '/usr/local/bin/google-cloud-sdk/path.bash.inc'

# The next line enables shell command completion for gcloud.
maybe '/usr/local/bin/google-cloud-sdk/completion.bash.inc'

# Azure
maybe $HOME/lib/azure-cli/az.completion

# Fun
alias shrug='echo "¯\_(ツ)_/¯"'

alias missionfire='curl isthemissiononfire.com 2>/dev/null | grep h1 | sed "s/<h1>//" | sed "s?</h1>??"'

alias improv101='yes &' # prints y forever and backgrounds the job to make it more annoying to stop
