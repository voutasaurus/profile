export PREV_WD=`pwd`
export THIMBLEROOT="$HOME/.thimblerig"
export THIMBLEPATH="$THIMBLEROOT`pwd`"

function augment_path {
    if [ "$PWD" = "$PREV_WD" ]; then return 0; fi;

    # Unlist previous thimblepaths
    export PATH=$(echo $PATH | tr ":" "\n" | sed "s|^$THIMBLEROOT.*$||g" | sed "/^[[:space:]]*$/d" | tr "\n" ":")

    export THIMBLEPATH="$THIMBLEROOT`pwd`"
    mkdir -p $THIMBLEPATH
#	>&2 echo "thimblerig: adding to PATH $THIMBLEPATH"
    export PATH="$THIMBLEPATH:$PATH"
    export PREV_WD=`pwd`
}

# TODO: allow prompt command chaining
PROMPT_COMMAND=augment_path # for bash
precmd() { eval "$PROMPT_COMMAND" } # for zsh

# TODO: system for CRUD executables / links into the THIMBLEPATH
