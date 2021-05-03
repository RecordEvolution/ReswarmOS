#!/bin/bash

# specify input .svg and output files
input="$1"
outpt="$2"
#width="$3"
#heigh="$4"

usage=$(cat << EOF

Usage:  ./svg2img.sh <svg-input-file> <png-or-jpg-output-file>
        where <output-file> must feature either .png or .jpg extension
EOF
)


if [[ -z ${input} ]]; then
  echo "no input file provided" >&2
  echo "${usage}"
  exit 1
else
  svgext=$(echo ${input} | grep "\.svg")
  if [[ -z ${svgext} ]]; then
    echo "input file does not feature .svg extension" >&2
    echo "${usage}"
    exit 1
  fi
fi

if [[ -z ${outpt} ]]; then
  echo "no output file provided" >&2
  echo "${usage}"
  exit 1
else
  pngjpgext=$(echo ${outpt} | grep "\.png\|\.jpg")
  if [[ -z ${pngjpgext} ]]; then
    echo "input file does not feature .png/.jpg extension" >&2
    echo "${usage}"
    exit 1
  fi
fi


#if [[ -z ${width} ]]; then
#  echo "no width provided" >&2
#  echo "${usage}"
#  exit 1
#fi
#
#if [[ -z ${heigh} ]]; then
#  echo "no height provided" >&2
#  echo "${usage}"
#  exit 1
#fi

# define command for conversion
#cmd="inkscape -z --export-png ${outpt} -w ${width} -h ${heigh} ${input}"
cmd="convert ${input} ${outpt}"
echo ${cmd}

# execute commnand
${cmd}

