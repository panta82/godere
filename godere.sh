[[ -z ${GO_TO_PROJECT_ROOT} ]] && GO_TO_PROJECT_ROOT="$HOME"
[[ -z ${GO_TO_PROJECT_DEPTH} ]] && GO_TO_PROJECT_DEPTH="4"
[[ -z ${GO_TO_PROJECT_STAT} ]] && GO_TO_PROJECT_STAT="stat"
[[ -z ${GO_TO_PROJECT_EXCLUDE_DIRS} ]] && GO_TO_PROJECT_EXCLUDE_DIRS=""

_GO_TO_PROJECT_FILE_NAME_CUTOFF_LENGTH=`expr ${#GO_TO_PROJECT_ROOT} + 1`

IFS=',' read -r -a _GO_TO_PROJECT_EXCLUDE_DIRS_ARRAY <<< "$GO_TO_PROJECT_EXCLUDE_DIRS"
if [[ ${#_GO_TO_PROJECT_EXCLUDE_DIRS_ARRAY[@]} -eq 0 ]]; then
    _GO_TO_PROJECT_EXCLUDE_ARGS=( )
else
    _GO_TO_PROJECT_EXCLUDE_ARGS=( -type d \( )
    for index in "${!_GO_TO_PROJECT_EXCLUDE_DIRS_ARRAY[@]}"; do
        if [[ $index -gt 0 ]]; then
            _GO_TO_PROJECT_EXCLUDE_ARGS+=( -o )
        fi
        _GO_TO_PROJECT_EXCLUDE_ARGS+=( -name ${_GO_TO_PROJECT_EXCLUDE_DIRS_ARRAY[$index]} )
    done
    _GO_TO_PROJECT_EXCLUDE_ARGS+=( \) -prune -false -o )
fi

go_to_project() {
	local query="$@"
	local query_arr=("$@")

	local quality_A="$query"
	local quality_B='(\b|[/_.-])'"$query"'(\b|[/_.-])'
	local quality_C='(\b|/)'"$query"'(\b|/)'
	local quality_D="^$query$"
	local debug_info=""
	local res_quality=0

	local fuzzy_match=
	local fuzzy_word=
	local i=
	local j=
	for (( i=0; i<${#query_arr[@]}; i++ )); do
		for (( j=0; j<${#query_arr[$i]}; j++ )); do
			fuzzy_match="${fuzzy_match}(.*)${query_arr[$i]:$j:1}"
			fuzzy_word="${fuzzy_word}([^/]*)${query_arr[$i]:$j:1}"
		done
	done
	fuzzy_match="${fuzzy_match}(.*)"
	fuzzy_word="${fuzzy_word}([^/]*)"

	[[ $GD_DEBUG > 0 ]] && echo "Fuzzy match: $fuzzy_match" && echo "Fuzzy word: $fuzzy_word" && echo "----------------------------------"

	export go_to_project_res_dir="."
	while read dir; do
		# Remove the timestamp prefix: "1382563122 /a/b/c" -> "/a/b/c"
		dir="${dir:11}"

		debug_info=""

		local file_name="${dir:$_GO_TO_PROJECT_FILE_NAME_CUTOFF_LENGTH}"
		file_name=${file_name,,}

		local quality=0

		if [[ -z "$query" ]]; then
			# Empty query, just hardcode some value here
			quality=$((1000))
			debug_info="${debug_info}[EMPTY->$quality]"
		else
			# Check through each quality class
			if [[ $file_name =~ $quality_A ]]; then
				quality=$((100))
				debug_info="${debug_info}[A->$quality]"
			fi

			if [[ $file_name =~ $quality_B ]]; then
				quality=$((103))
				debug_info="${debug_info}[B->$quality]"
			fi

			if [[ $file_name =~ $quality_C ]]; then
				quality=$((107))
				debug_info="${debug_info}[C->$quality]"
			fi

			if [[ $file_name =~ $quality_D ]]; then
				quality=$((110))
				debug_info="${debug_info}[D->$quality]"
			fi
		fi

		# If nothing is found so far, try to match a fuzzy word
		# This only checks in between path separators (/)
		if [[ $quality -le 0 ]] && [[ $file_name =~ $fuzzy_word ]]; then
			local remaining_chars="${BASH_REMATCH[@]:1}"
			quality=$((100 - ${#remaining_chars}))
			debug_info="${debug_info}[FUZZY_WORD:${remaining_chars}(${#remaining_chars})->$quality]"
		fi

		# If there is still no match, try to get a fuzzy match using the entire path.
		# This match is penalized x2. We want pretty much anything else to win.
		if [[ $quality -le 0 ]] && [[ $file_name =~ $fuzzy_match ]]; then
			local remaining_chars="${BASH_REMATCH[@]:1}"
			quality=$((100 - ${#remaining_chars} * 2))
			debug_info="${debug_info}[FUZZY_MATCH:${remaining_chars}(${#remaining_chars})->$quality]"
		fi

		# Give a little boost to git repositories
		if [[ -d "$dir/.git" ]] && [[ $quality -gt 0 ]]; then
			quality=$(expr $quality + 11)
			debug_info="${debug_info}[GIT->$quality]"
		fi

		[[ $GD_DEBUG > 0 ]] && printf "%-60s | %-30s | %s\n" "$dir" "$debug_info" "$quality"

		# If better quality than existing, replace
		if [[ $quality -gt $res_quality ]]; then
			res_quality="$quality"
			export go_to_project_res_dir="$dir"
		fi
	done < <(find $GO_TO_PROJECT_ROOT -maxdepth $GO_TO_PROJECT_DEPTH ${_GO_TO_PROJECT_EXCLUDE_ARGS[@]} -type d -exec $GO_TO_PROJECT_STAT --format '%Y %n' '{}' + | sort -gr)

	[[ $GD_DEBUG > 0 ]] && echo "----------------------------------" && echo "Destination: $go_to_project_res_dir"
	cd "$go_to_project_res_dir"
}
