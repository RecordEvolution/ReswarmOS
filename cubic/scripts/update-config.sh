#!/bin/bash

cubicPath=$(realpath $1)
sed="sed"
os=$(uname -s)

if [ $os == "Darwin" ]; then

	has_gsed=$(gsed --version)
	if [ $? == "1" ]; then
   	 	printf "Error: gsed needs to be installed on MacOS\nType 'brew install gsed' to install gsed\n" >&2
    		exit 1
	fi

    	sed="gsed"
fi

${sed} -i 's#directory = .*/git#directory = '"$HOME"'/git#g#' $cubicPath
${sed} -i 's#is_success_copy = True#is_success_copy = False#g#' $cubicPath
${sed} -i 's#is_success_extract = True#is_success_extract = False#g#' $cubicPath
