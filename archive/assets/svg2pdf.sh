#!/bin/bash

cairosvg reswarm-os-logo.svg -f pdf -o reswarm-os-icon.pdf
pdfcrop reswarm-os-icon.pdf reswarm-os-icon.pdf
