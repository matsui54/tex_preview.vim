{
    declare -pA addCommand=([action]="add" [identifier]="defx_preview" [x]="$2" [y]="$3" [width]="$4" [path]="$1.png")
    sleep 1000
} | ueberzug layer --parser bash
