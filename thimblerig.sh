export NONTHIMBLEPATH="$PATH"
export PREV_WD=`pwd`

function augment_path {
    if [ "$PWD" = "$PREV_WD" ]; then return 0; fi;

    THIMBLEPATH="$HOME/.thimblerig`pwd`"
    mkdir -p $THIMBLEPATH
#	>&2 echo "thimblerig: adding to PATH $THIMBLEPATH"
    export PATH="$THIMBLEPATH:$NONTHIMBLEPATH"
    export PREV_WD=`pwd`
}

# TODO: allow prompt command chaining
PROMPT_COMMAND=augment_path # for bash
precmd() { eval "$PROMPT_COMMAND" } # for zsh

# TODO: system for CRUD executables / links into the THIMBLEPATH
