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
declare -a surrounding_indexes
declare -i living_neighbours_count=0
declare next_cell_state

# The index of the cell in current_state that we're processing
declare -a current_index
declare -a current_state
declare -a next_state

function log() {
    printf "%s: %s\n" "$(perl -e 'use Time::HiRes qw(time); print time')" "$1" >> bash-life.log
}

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

function print_cell() {
    # Bump cells down a line to avoid header
    print_at_pos $(($1 + 1)) $2 "$3"
}

function get_term_lines() {
    printf $(tput lines)
}

function get_term_cols() {
    printf $(tput cols)
}

function update_term_size() {
    # Pretend we have one less line so we can print header
    current_lines=$(get_term_lines - 1)
    current_cols=$(get_term_cols)
}

function get_array_index() {
#    declare -i line=$1
#    declare -i col=$2
#    let array_index="(line-1) * (current_cols) + col - 1"
    let array_index="($1-1) * (current_cols) + $2 - 1"
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
    declare -i line=1
    while ((line < current_lines)); do
	declare -i col=1
	while ((col < current_cols)); do
	    get_array_index $line $col
	    current_state[$array_index]=$DEAD_CELL_VALUE
	    ((++col))
	done
	((++line))
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
#    init_next_state
}

# Returns, by setting a variable, an array of indexes for cells that surround the given cell.
# $1 => Line number
# $2 => Column number
#function get_surrounding_indexes() {
function get_living_neighbours_count() {
    declare -i line=$1
    declare -i col=$2
    declare -i index=0
    living_neighbours_count=0
    #surrounding_indexes=()
    # Yeah we could $(seq), but this should be faster
    for l in $((line-1)) $line $((line+1)); do
	(( l > 0 && l <= current_lines )) || continue
	for c in $((col-1)) $col $((col+1)); do
	    (( c > 0 && c <= current_cols )) || continue
	    if (( !(l == line && c == col) )); then
		get_array_index $l $c
		[[ ${current_state[$array_index]} == $LIVE_CELL_VALUE ]] && ((++living_neighbours_count))
		#if (( array_index < ${#current_state[*]} && array_index >= 0 )); then
		#surrounding_indexes[$index]=$array_index
		#let index=index+1
		#fi
	    fi
	done
    done
}

# function get_living_neighbours_count() {
#     declare -i line=$1
#     declare -i col=$2
#     living_neighbours_count=0
#     #log "getting surrounding indexes for $line $col"
#     get_surrounding_indexes $line $col
#     for i in ${surrounding_indexes[@]}; do
# 	if [[ ${current_state[i]} == $LIVE_CELL_VALUE ]]; then
# 	    let living_neighbours_count=living_neighbours_count+1
# 	fi
#     done
# }

# Given a cell's current state and its number of living neighbours, determines its next state by applying the
# following rules (taken from Conway's Game of Life wiki page)
# 1. Any living cell with fewer than 2 neighbours dies
# 2. Any live cell with 2 or 3 live neighbours survives
# 3. Any live cell with more than 3 neighbours dies
# 4. Any dead cell with exactly 3 neighbours comes to life
function get_next_cell_state() {
    declare -i line=$1
    declare -i col=$2
    #log "getting living neighbours count for $line $col"
    get_living_neighbours_count $line $col
    #log "have living neighbours count for $line $col"
    
    if (( living_neighbours_count < 2 || living_neighbours_count > 3 )); then
	# No cell is alive if it has fewer than 2, or greater than 3 living neighbours
	next_cell_state=$DEAD_CELL_VALUE
    elif [[ ${current_state[$current_cell_index]} == $LIVE_CELL_VALUE ]]; then
	# We know the cell has 2 or 3 live neighbours from the last condition, so if it's alive it survives
	next_cell_state=$LIVE_CELL_VALUE
    elif (( living_neighbours_count == 3 )); then
	# We know the cell is dead from the last condition, so if it has 3 living neighbours it comes to life
	next_cell_state=$LIVE_CELL_VALUE
    else
	# The cell must be dead and have only 2 live neigbours, so it stays dead.
	next_cell_state=$DEAD_CELL_VALUE
    fi
}

function update() {
    next_state=()
    for line in $(seq 1 $current_lines); do
	for col in $(seq 1 $current_cols); do
	    get_next_cell_state $line $col
	    get_array_index $line $col
	    next_state[$array_index]=$next_cell_state
	done
    done
    #log "copying next state to current"
    current_state=()
    current_state=("${next_state[@]}")
}

function draw_header() {
    print_at_pos 1 1 "Current tick: $current_tick"
}

function draw() {
    clear
    draw_header
    #log "drawing state of size ${#current_state[*]}"
    for index in $(seq 1 ${#current_state[*]}); do
	if [[ ${current_state[$index - 1]} == $LIVE_CELL_VALUE ]]; then
	    get_line_from_index $((index-1))
	    get_col_from_index $((index-1))
	    print_cell $line_from_index $col_from_index $LIVE_CELL_VALUE
	fi
    done
}

function set_test_game_state() {
    get_array_index 11 5
    current_state[$array_index]=$LIVE_CELL_VALUE
    get_array_index 11 6
    current_state[$array_index]=$LIVE_CELL_VALUE
    get_array_index 12 5
    current_state[$array_index]=$LIVE_CELL_VALUE
    get_array_index 12 6
    current_state[$array_index]=$LIVE_CELL_VALUE
    get_array_index 13 5
    current_state[$array_index]=$LIVE_CELL_VALUE
    get_array_index 13 6
    current_state[$array_index]=$LIVE_CELL_VALUE
}

> bash-life.log
init_game_state
set_test_game_state
draw
while ((1 == 1)); do
    let current_tick=current_tick+1
    update
    draw
    sleep $TICK_RATE_S
done
