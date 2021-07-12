set -eu
platex $1.tex
dvipng $1.dvi -D 600 -o $1.png
