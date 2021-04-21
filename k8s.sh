# use the cluster that kubectl is currently pointed at as the command prompt
# usage:
# $ kprompt
# working.dk1.kiva.org$
function kprompter {
  export PS1="$(kubectl config current-context)""$ "
}
alias kprompt='PROMPT_COMMAND=kprompter'

# print current context or switch contexts
function kubectx {
    local context="$1"
    if [[ "$context" == "" ]]
    then
        kubectl config current-context
    else
        kubectl config use-context $1
    fi
}

alias kubectxs='yq r ~/.kube/config "contexts.*.name"'

# Launch a shell in k8s
# usage:
# $ kubesh
# [root@session-username /]# ls
# anaconda-post.log  bin  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
function kubesh {
    kubectl get pod session-$USER &> /dev/null;
    if [ $? != 0 ]; then
        kubectl run session-$USER --restart=Never --image=voutasaurus/kubesh:latest -- sh -c 'tail -f /dev/null';
        sleep 5;
    fi
    kubectl exec -it session-$USER bash;
}

# chartout will output kubernetes config yaml files based on helm templates and
# the values yaml files.
# usage:
# $ cd service-name
# $ chartout
# wrote output/service-name/templates/service.yaml
# wrote output/service-name/templates/deployment.yaml
function chartout {
    stat helm-config >/dev/null && \
    mkdir -p output && \
    helm template --values helm-config/values.yaml --output-dir output helm-config
}

# list all secrets in plaintext for a secrets object
# usage:
# $ secrets secretname
function secrets {
    kubectl get secrets $1 -o go-template='{{ range $k, $v := .data }}{{ printf "%s %s\n" $k $v }}{{ end }}' | while read key value; do
        echo -n "$key="
        echo -n "$value" | base64 --decode
        echo ""
    done
}

# list all the keys for a secret object
# usage:
# $ sekkeys secretname
# LOGGING_LEVEL
# ...
# OTHER_SERVICE_URL
function sekkeys {
    kubectl get secrets $1 -o go-template='{{ range $k, $v := .data }}{{ printf "%s\n" $k }}{{ end }}'
}

# retrieve a specific key from a secrets object
# usage:
# $ sekret secretname LOGGING_LEVEL
# INFO
function sekret {
    local out=$(kubectl get secrets $1 -o go-template="{{.data.$2}}")
    if [[ "$out" == "<no value>" ]]; then
       >&2 echo "$2 not set in $1";
       return 1;
    fi
    echo -n $out | base64 --decode
    >&2 echo ""
}

# set a value of a specific key in a secrets object
# usage:
# $ sekretset secretname LOGGING_LEVEL DEBUG
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
# kubernetes secret object. It will fail if the secret object doesn't exist.
# usage:
#   $ envtosecret secretname < .env
function envtosecret {
    export -f sekretset
    sed 's/#.*$//' | grep -v -e '^$' | sed 's/=/ /' | xargs -n 2 -I{} bash -c "sekretset $1 {}"
}

# scan each secret object to see what an environment variable is set to
# usage:
# $ sekretscan LOGGING_LEVEL
# secret-1: DEBUG
# ...
# secret-n: INFO
function sekretscan {
    kubectl get secrets -o go-template='{{ range $v := .items }}{{ printf "%s\n" $v.metadata.name }}{{ end }}' \
    | grep -v default | grep -v regcred | grep -v helm | \
    while read x; do
        echo -n $x": ";
        sekret $x $1;
    done
}

# allsecrets returns all the secrets for all services
# usage:
# $ allsecrets > secret-backup.txt
function allsecrets {
    export -f decodex
    export -f secrets
    kubectl get secrets -o go-template='{{range $x := .items}}{{printf "%s\n" $x.metadata.name}}{{end}}' | xargs -I OBJECT bash -c 'echo OBJECT; secrets OBJECT'
}

# scan each pod in the namespace to see what an environment variable is set to
# NOTE: pods need to be restarted to pick up changes in a secret object
# usage:
# $ envcheck LOGGING_LEVEL
# pod-1-6d5ccc688b-dpwgc: INFO
# ...
# pod-n-b746476d6-skl24: INFO
function envcheck {
    kubectl get pods -o go-template='{{ range $v := .items }}{{ printf "%s\n" $v.metadata.name }}{{ end }}' | grep -v session | while read x; do echo -n $x": "; kubectl exec $x -- sh -c "echo \$$1"; done
}

# kenv prints the current env value for a particular pod and key
# usage:
# $ kenv pod-name ENV_VAR
# this-is-the-value-of-an-environment-variable
function kenv {
    kubectl exec $1 -- sh -c "echo \$$2"
}

# kat prints the current file contents for a particular pod and filepath
# usage:
# $ kat pod-name /file/path
# These are the contents of a file
function kat {
    kubectl exec $1 -- sh -c "cat $2"
}

# allpods prints the names of all the pods in the current namespace
# usage: see filescan
function allpods {
    kubectl get pods -o go-template='{{ range $v := .items }}{{ printf "%s\n" $v.metadata.name }}{{ end }}'
}

# filescan reads filepaths from a specific environment key in each pod matching
# a substring and prints the file contents.
# usage: 
# $ filescan service-name ENV_VAR_CONTAINING_PATH_TO_FILE
function filescan {
    allpods | grep $1 | while read x; do echo $x": "; kat $x $(kenv $x $2); done
}

# restartpods will delete all the pods matching the argument
# usage:
# $ restartpods service-name
function restartpods {
    if [ $# -eq 0 ]
    then
        >&2 echo "please provide a pod type to restart"
        return 1
    fi

    allpods | grep $1 | xargs kubectl delete pod
}

function kimages {
    if [ -z "$1" ]
    then
        kubectl get pod -o go-template='{{ range $v := .items }}{{ range $u := .spec.containers }}{{ printf "%s\n" $u.image }}{{ end }}{{ end }}' | sort -u
    else
        kubectl get pod -o go-template='{{ range $v := .items }}{{ range $u := .spec.containers }}{{ printf "%s\n" $u.image }}{{ end }}{{ end }}' | sort -u | grep $1
    fi
}

# usage:
# $ pilotsql $pghost -U $pguser -d $pgdbname
# Password for user $pguser: <paste password here>
#
# prereq:
# - kubectl set up locally
# - psql installed: brew (re)install postgresql
function pilotsql {
    pghost=$1
    shift

    # launch proxy
    kubectl run pg-tunnel-$USER --image=alpine/socat --expose=true --port=5432 tcp-listen:5432,fork,reuseaddr "tcp-connect:$pghost:5432"
    sleep 5 # wait for pod to be ready
    kubectl port-forward pod/pg-tunnel-$USER 5432:5432 &
    echo "waiting for port forwarding to connect..."
    sleep 10

    # connect to database via localhost
    psql -h localhost $@

    # cleanup local and remote resources
    lsof -ti tcp:5432 | xargs kill -9
    kubectl delete pod/pg-tunnel-$USER
    kubectl delete svc/pg-tunnel-$USER
}

# patch a deployment to use a different image:tag
# usage:
# $ deployup deploymentname voutasaurus/kubesh:latest
function deployup {
    kubectl patch deployment $1 -p '{"spec":{"template":{"spec":{"containers":[{"name":"'"$1"'","image":"'"$2"'"}]}}}}'
}

# Get service ports
# usage:
# $ kubeaddrs
function kubeaddrs {
    kubectl get services -o go-template='{{ range $x, $v := .items }}{{range $j, $port := $v.spec.ports}}{{printf "%s:%v\n" $v.metadata.name $port.port}}{{end}}{{ end }}'
}
