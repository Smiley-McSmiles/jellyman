#!/bin/bash

promptDir=null
promptFile=null
promptNum=null
promptUsr=null
promptStr=null
Prompt_user()
{
	# prompt types = [Yn,yN,dir,file,num,usr,str]
	_promptType=$1
	_promptText="$2"
	_minNumber=$3
	_maxNumber=$4
	_yesOrNo=null
	_dir=null
	_file=null
	_num=null
	_usr=NULL
	_str=
	echo "$_promptText"
	
	case $_promptType in
		"Yn")
			while [[ ! $_yesOrNo == [yY][eE][sS] ]] || [[ ! $_yesOrNo == [yY] ]] || [[ ! $_yesOrNo == [nN][oO] ]] || [[ ! $_yesOrNo == [nN] ]] || [[ ! $_yesOrNo == "" ]]; do
				read -p "[Y/n] >>> " _yesOrNo
				if [[ $_yesOrNo == "" ]] || [[ $_yesOrNo == [yY][eE][sS] ]] || [[ $_yesOrNo == [yY] ]]; then
					return 0
				elif [[ $_yesOrNo == [nN][oO] ]] || [[ $_yesOrNo == [nN] ]]; then
					return 1
				else
					_yesOrNo=null
					echo
					echo "ERROR: Invalid input, please enter Yes or No!"
				fi
			done
		;;
		"yN")
			while [[ ! $_yesOrNo == [yY][eE][sS] ]] || [[ ! $_yesOrNo == [yY] ]] || [[ ! $_yesOrNo == [nN][oO] ]] || [[ ! $_yesOrNo == [nN] ]] || [[ ! $_yesOrNo == "" ]]; do
				read -p "[y/N] >>> " _yesOrNo
				if [[ $_yesOrNo == [yY][eE][sS] ]] || [[ $_yesOrNo == [yY] ]]; then
					return 0
				elif [[ $_yesOrNo == "" ]] || [[ $_yesOrNo == [nN][oO] ]] || [[ $_yesOrNo == [nN] ]]; then
					return 1
				else
					_yesOrNo=null
					echo
					echo "ERROR: Invalid input, please enter Yes or No!"
				fi
			done
		;;
		"dir")
			while [[ ! -d $_dir ]]; do
				read -p "[/path/to/directory] >>> " "_dir"
				if [[ -d $_dir ]]; then
					promptDir="$_dir"
					return 0
				else
					echo
					echo "ERROR: Input directory does not exist!"
				fi
			done
		;;
		"file")
			while [[ ! -f $_file ]]; do
				read -p "[/path/to/file] >>> " "_file"
				if [[ -f $_file ]]; then
					promptFile="$_file"
					return 0
				else
					echo
					echo "ERROR: Input file does not exist!"
				fi
			done
		;;
		"num")
			while [[ ! $_num =~ ^[0-9]+$ ]]; do
				read -p "[number] >>> " _num
				if [[ $_num -lt $_minNumber ]] || [[ $_num -gt $_maxNumber ]]; then
					echo
					_num=null
					echo "ERROR: Input must be between $_minNumber and $_maxNumber"
				elif [[ $_num =~ ^[0-9]+$ ]]; then
					promptNum=$_num
					return 0
				else
					echo
					echo "ERROR: Input is not a number!"
				fi
			done
		;;
		"usr")
			while [[ "$_usr" =~ [A-Z] ]] || [[ "$_usr" =~ \ |\' ]]; do
				read -p "[username] >>> " "_usr"
				if [[ ! "$_usr" =~ [A-Z] ]] && [[ ! "$_usr" =~ \ |\' ]]; then
					promptUsr=$_usr
					return 0
				else
					echo
					echo "ERROR: Inputted username has a space or a capital letter!"
				fi
			done
		;;
		"str")
			while [[ ! -n $_str ]]; do
				read -p "[string] >>> " "_str"
				if [[ -n $_str ]]; then
					promptUsr=$_str
					return 0
				else
					echo
					echo "ERROR: No input detected!"
				fi
			done
		;;
		*)
			echo "ERROR: Invalid prompt type $_promptType"
		;;
	esac
# Default yes
# if Prompt_user Yn "Example yes or no question?"; then
#	echo "pass"
# else
#	echo "fail"
# fi

# Default no
# if Prompt_user yN "Example yes or no question?"; then
#	echo "pass"
# else
#	echo "fail"
# fi

# Check for directory, return directory
# Prompt_user dir "Enter a valid directory"
# echo "Directory entered = $promptDir"

# Check for file, return file
# Prompt_user file "Enter a valid file"
# echo "File entered = $promptFile"

# Check if number, return number entered
# Prompt_user num "Enter a valid number" minNumber maxNumber
# echo "Number entered = $promptNum"

# Check username for uppercase or spaces, return username
# Prompt_user usr "Enter a valid username"
# echo "Username entered = $promptUsr"

# Check if string variable is not empty, return string
# Prompt_user str "Enter a string"
# echo "String entered = $promptStr"
}

Change_variable()
{
	# Change_variable testVar "newVarContent" varType "fileToChange"
	varToChange=$1
	newVarContent=$2
	fileToChange=$3
	varType=$4
	if [[ ! -n $varToChange ]] || [[ ! -n $newVarContent ]]; then
		echo "Function Change_variable requires 3 parameters: varToChange newVarContent fileToChange"
		exit
	elif [[ $varType == "array" ]]; then
		sed -i "s|$varToChange=.*|$varToChange=\($newVarContent\)|g" $fileToChange
	else
		sed -i "s|$varToChange=.*|$varToChange=$newVarContent|g" $fileToChange
	fi
	
}

Change_xml_variable()
{
	# Change_xml_variable testVar "newVarContent" "fileToChange"
	varToChange=$1
	newVarContent=$2
	fileToChange=$3
	if [[ ! -n $varToChange ]] || [[ ! -n $newVarContent ]] && [[ ! $fileToChange == *".xml" ]]; then
		echo "Function Change_xml_variable requires 3 parameters: varToChange newVarContent fileToChange"
		exit
	else
		sed -i "s|<$varToChange>.*</$varToChange>|<$varToChange>$newVarContent</$varToChange>|g" $fileToChange
	fi
}

isVideo()
{
	_video=$1
	if [[ $_video == *"."[mMaA][kKvVpP][iIvV4] ]]; then
		return 0
	else
		return 1
	fi
}

Countdown()
{
	_time=$1
	while [ $_time -gt 0 ]; do
		printf "\r $_time seconds"
		_time=$(($_time - 1))
		sleep 1
	done
	printf "\n Done!"
	printf "\n"
}

Has_sudo()
{
	if [ "$EUID" -ne 0 ]; then
		echo "ERROR: Permission denied for $USER"
		echo "This command requires root privileges"
		exit
    	fi
}

areDirectories()
{
	directoriesToCheck="$1"
	isDirectory=true
	for item in $directoriesToCheck
	do
		if [[ ! -d $item ]]; then
			isDirectory=false
			# echo "$item is not a directory"
		fi
	done
	if $isDirectory; then
		# echo "$directoriesToCheck are directories"
		return 0
	else
		# echo "$directoriesToCheck are not directories"
		return 1
	fi

# Directory variable
#if areDirectories "${defaultPath[*]}"; then
#	echo "Directories in array are directories."
#fi
# Directory array
#if areDirectories "/path/to/dir1 /path/to/dir2"; then
#	echo "Directories in array are directories."
#fi
}

