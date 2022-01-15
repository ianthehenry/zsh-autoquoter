declare -a ZAQ_PREFIXES=()

_zaq_check_prefix() {
  local prefix input stripped leading_quote expected_ending_quote
  prefix=$1
  input=$2
  stripped=${input#"$prefix "}
  if [[ "$input" = "$stripped" ]]; then
    return 1
  fi

  # if it's already quoted, don't re-quote it.
  # this is a separate assignment to take advantage
  # of the fact that assignments to expansions like this
  # do not glob words. i cannot wrap this pattern in double
  # quotes without being unable to enter double-quotes in
  # the alternative. seems like a zsh bug to me.
  leading_quote=${(M)stripped#(\'|\"|$\')}
  if [[ "$leading_quote" ]]; then
    expected_ending_quote="${leading_quote#$}"
    if [[ "${(M)stripped%$expected_ending_quote}" ]]; then
      return 1
    fi
  fi

  return 0
}

_zaq_prefix_length() {
  local prefix
  for prefix in $ZAQ_PREFIXES; do
    if _zaq_check_prefix "$prefix" "$1"; then
      # add one for the space after it
      echo $(( $#prefix + 1 ))
      return 0
    fi
  done

  return 1
}

autoquote() {
  local prefix_length command args smart_single_quoted double_quoted

  if prefix_length=$(_zaq_prefix_length "$BUFFER"); then
    command=${BUFFER:0:$prefix_length}
    args=${BUFFER:$prefix_length}

    # we use (q+) instead of (q-) because (q-) will sometimes escape with
    # backslashes instead of quotes, and (q+) doesn't seem to do that:
    #
    #   $ x="it's"
    #   $ echo ${(q-)x}
    #   it\'s
    #   $ echo ${(q+)x}
    #   'it'\''s'
    #
    # (we always want to escape with quotes so that our "don't double-escape"
    # logic works correctly)
    smart_single_quoted=${(q+)args}
    double_quoted=${(qqq)args}

    if [[ ${#smart_single_quoted} -lt ${#double_quoted} ]]; then
      BUFFER="$command$smart_single_quoted"
    else
      BUFFER="$command$double_quoted"
    fi
    zle -R
  fi

  zle .accept-line
}

zle -N accept-line autoquote

_zsh_highlight_highlighter_zaq_predicate() {
  _zsh_highlight_buffer_modified
}

: ${ZSH_HIGHLIGHT_STYLES[zaq:string]:=fg=yellow,underline}

_zsh_highlight_highlighter_zaq_paint() {
  local prefix_length
  if prefix_length=$(_zaq_prefix_length "$BUFFER"); then
    _zsh_highlight_add_highlight "$prefix_length" $#BUFFER zaq:string
  fi
}
