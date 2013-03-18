#!/bin/bash

declare -r DEAD_CELL_VALUE=""
declare -r LIVE_CELL_VALUE="@"
declare -i TICK_RATE_S=1
# Current number of lines/columns - keep track of this in case term resized between ticks
declare -i current_lines
declare -i current_cols
declare -i current_tick=0

# The following group of variables are actually return values for their corresponding functions. For example
# get_array_index will set array_index - this is an optimization to save on subshelling
declare -i array_index
declare -i line_from_index
declare -i col_from_index

declare -a current_state
declare -a next_state

function set_cursor_pos() {
    typeset line=$1
    typeset col=$2
    printf "\033[${line};${col}H"
}

function print_at_pos() {
    typeset line=$1
    typeset col=$2
    typeset to_print=$3
    set_cursor_pos $line $col
    printf "$to_print"
}

function get_term_lines() {
    printf $(tput lines)
}

function get_term_cols() {
    printf $(tput cols)
}

function update_term_size() {
    current_lines=$(get_term_lines)
    current_cols=$(get_term_cols)
}

function get_array_index() {
    declare -i line=$1
    declare -i col=$2
    let array_index="(line-1) * (current_cols) + col - 1"
}

# Returns the line number from an array index in current_state.
function get_line_from_index() {
    let line_from_index="$1/current_cols + 1"
}

# Returns the column number from an array index
function get_col_from_index() {
    let col_from_index="$1 % current_cols + 1"
}

function init_current_state() {
    for line in $(seq 1 $current_lines); do
	for col in $(seq 1 $current_cols); do
	    get_array_index $line $col
	    current_state[$array_index]=$DEAD_CELL_VALUE
	done
    done
}

function init_next_state() {
    for line in $(seq 1 $current_lines); do
	for col in $(seq 1 $current_cols); do
	    get_array_index $line $col
	    next_state[$array_index]=$DEAD_CELL_VALUE
	done
    done
}

function init_game_state() {
    current_tick=0
    update_term_size
    init_current_state
    init_next_state
}

function update() {
    update_term_size
    init_next_state
    if (( current_tick % 2 == 0 )); then
	for line in $(seq 1 $current_lines); do
	    get_array_index $line 2
	    next_state[$array_index]=$LIVE_CELL_VALUE
	done
    fi
    current_state=("${next_state[@]}")
}

function draw() {
    clear
    for index in $(seq 1 ${#current_state[*]}); do
	if [[ ${current_state[$index - 1]} == $LIVE_CELL_VALUE ]]; then
	    get_line_from_index $((index-1))
	    get_col_from_index $((index-1))
	    print_at_pos $line_from_index $col_from_index $LIVE_CELL_VALUE
	fi
    done
}

init_game_state
while ((1 == 1)); do
    let current_tick=current_tick+1
    update
    draw
    sleep $TICK_RATE_S
done
