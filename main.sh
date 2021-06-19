#!/bin/bash

_header="-NAME-----------------CMD--------------------PID-----STIME-----"
_footer="---------------------------------------------------------------"
declare -i _cursor_process=-1
declare -i _cursor_name=0 
declare -i _index=0 
_sort_by_name=""
_sort_by_pid="-"

Display() {
	# ensure pid_list <= 20
	if [ ${#PID_LIST[@]} -le 20 ]; then
		if [ $_cursor_process -ge ${#PID_LIST[@]} ]; then
			_cursor_process=$((${#PID_LIST[@]} - 1))
		fi
	else
		if [ $_index -gt $((${#PID_LIST[@]} - 20)) ]; then
			_index=$((${#PID_LIST[@]} - 20))
		fi
	fi

	# clear executed result so far 
	clear

	echo "______                     _    _             "
	echo "| ___ \                   | |  (_)            "
	echo "| |_/ / _ __   __ _   ___ | |_  _   ___   ___ "
	echo "|  __/ |  __| / _  | / __|| __|| | / __| / _ \""
	echo "| |    | |   | (_| || (__ | |_ | || (__ |  __/"
	echo "\_|    |_|    \__ _| \___| \__||_| \___| \___|"
	echo " _         _      _                           "
	echo "(_)       | |    (_)                          "
	echo " _  _ __  | |     _  _ __   _   _ __  __      "
	echo "| ||  _ \ | |    | ||  _ \ | | | |\ \/ /      "
	echo "| || | | || |___ | || | | || |_| | >  <       "
	echo "|_||_| |_|\_____/|_||_| |_| \__,_|/_/\_\      "
	echo "                                              "		

	echo "$_header"

	for i in {0..19}
	do
		printf '|'

		if [ $i -eq $_cursor_name ]; then
			printf '\e[41m'
		fi

		printf '%20s\e[0m|' ${NAME_LIST[$i]:0:20}

		if [ $i -eq $_cursor_process ]; then
			printf '\e[42m'
		fi

		declare -i j
		curr_stat=''
		j=$_index+$i
		
		if [ ${STAT_LIST[$j]} ]; then
			[ "${STAT_LIST[$j]}" = '+' ] && curr_stat='F' || curr_stat='B'
		fi

		printf '%s %-20s|' $curr_stat ${CMD_LIST[$j]:0:19}
		printf '%7s|' ${PID_LIST[$j]:0:7}
		printf '%9s\e[0m|\n' ${STIME_LIST[$j]:0:9}
	done

	echo "$_footer"
}


while true
do
	# Get result of 'ps' command
	PS_RESULT=`ps aux --sort=${_sort_by_pid}pid`

	# Get position of 'CMD'
	CMD_POSITION=`echo "$PS_RESULT" | head -1 | grep -bo COMMAND | cut -d ':' -f 1`

	# Delete header of PS_RESULT
	NAME_LIST=(`echo "$PS_RESULT" | awk '{print $1}' | sort -${_sort_by_name}u`)

	# Get process list by 'NAME'
	PROCESS_RESULT=`echo "$PS_RESULT" | grep ^${NAME_LIST[$_cursor_name]} | grep -v 'ps aux'`

	# Get 'PID', 'STIME' from PROCESS_RESULT
	PID_LIST=(`awk '{print $2}' <<< "$PROCESS_RESULT"`)
	STIME_LIST=(`awk '{print $9}' <<< "$PROCESS_RESULT"`)

	# Get 'STAT' from PROCESS_RESULT (Only to check if it is 'Foreground' or 'Background')
	STAT_LIST=(`echo "$PROCESS_RESULT" | awk '{print $8}' | rev | cut -c 1`)
	
	# Get 'CMD' from PROCESS_RESULT
	CMD_LIST=(`echo "$PROCESS_RESULT"`)


	for i in $(seq 0 ${#CMD_LIST[@]})
	do
		CMD_LIST[$i]=${CMD_LIST[$i]:$CMD_POSITION}
	done

	# show current details
	Display

	echo "If you want to exit, please type 'q' or 'Q'."

	# enter key
	if read -n 3 -t 3 key; then
		if [ -z "$key" -a $_cursor_process -gt -1 ]; then
			if [ "${NAME_LIST[$_cursor_name]}" = `whoami` ]; then
				kill -9 ${PID_LIST[$_index+$_cursor_process]}		
			else 	
			   clear
				echo " _   _  ___                                            "
				echo "| \ | |/ _ \                                           "
				echo "|  \| | | | |                                          "
				echo "| |\  | |_| |                                          "
				echo "|_| \_|\___/                                           "
				echo " ____  _____ ____  __  __ ___ ____ ____ ___ ___  _   _ "
				echo "|  _ \| ____|  _ \|  \/  |_ _/ ___/ ___|_ _/ _ \| \ | |"
				echo "| |_) |  _| | |_) | |\/| || |\___ \___ \| | | | |  \| |"
				echo "|  __/| |___|  _ <| |  | || | ___) |__) | | |_| | |\  |"
				echo "|_|   |_____|_| \_\_|  |_|___|____/____/___\___/|_| \_|"
				echo "																		 "
				read -n 1 -s
			fi
		fi
	fi

	# exit program
	if [ "$key" = 'q' -o "$key" = 'Q' ]; then
		exit

	# sort 'NAME' in ascending
	elif [ "$key" = '+n' ]; then
		_sort_by_name=''
	   _cursor_name=0
		_cursor_process=-1
	
	# sort 'PID' in descending
	elif [ "$key" = '-p' ]; then
		_sort_by_pid='-'
		_cursor_name=0
	:	_cursor_process=-1

	# key up
	elif [ "$key" = $'\e[A' ]; then
		if [ $_cursor_process -eq -1 ]; then
			if [ $_cursor_name -gt 0 ]; then
				_cursor_name=$_cursor_name-1
				_index=0
			fi
		else
			if [ $_cursor_process -gt 0 ]; then
				_cursor_process=$_cursor_process-1
			else
				if [ $_index -gt 0 ]; then
					_index=$_index-1
				fi
			fi
		fi

	# key down 
	elif [ "$key" = $'\e[B' ]; then
		if [ $_cursor_process -eq -1 ]; then
			if [ $_cursor_name -lt $((${#NAME_LIST[@]} - 1)) -a $_cursor_name -lt 19 ]; then
				_cursor_name=$_cursor_name+1
				_index=0
			fi
		else
			if [ $_cursor_process -lt $((${#PID_LIST[@]} - 1)) -a $_cursor_process -lt 19 ]; then
				_cursor_process=$_cursor_process+1
			else
				if [ $_index -lt $((${#PID_LIST[@]} - 20)) ]; then
					_index=$_index+1
				fi
			fi
		fi

	# key right
	elif [ "$key" = $'\e[C' ]; then
		if [ $_cursor_process -eq -1 ]; then
			_cursor_process=0
		fi

	# key left
	elif [ "$key" = $'\e[D' ]; then
		if [ $_cursor_process -ge 0 ]; then
			_cursor_process=-1
		fi
	fi

done









































