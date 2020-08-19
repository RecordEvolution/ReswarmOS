#!/bin/bash

cat << EOF > myfile.txt
some file content
any number of lines

even with empty ones in between
EOF

if [[ ! -d "LFS" ]]; then
  echo "LFS directory exists"
else
  echo "LFS directory does not exist"
fi
