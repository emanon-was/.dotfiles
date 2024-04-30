#!/usr/bin/env sh

STORE=$1
STORE_ITEMS=$(cat $2)
IGNORE_ITEMS=""
DUPLICATE_ITEMS=""

for item in $STORE_ITEMS; do
    if [ ~/$item -ef $STORE/$item ]; then
        IGNORE_ITEMS+="$item ";
        echo "[ignore] ~/$item -> $STORE/$item";
    fi;
done;

for item in $STORE_ITEMS; do
    if [ -e "~/$item" ]; then
        DUPLICATE_ITEMS+="$item ";
        echo "[failure] ~/$item";
    fi;
done;

if [ -z "$DUPLICATE_ITEMS" ]; then
    for item in $STORE_ITEMS; do
        if [ ! -e "~/$item" ] && [ ! ~/$item -ef $STORE/$item ]; then
            mkdir -p $(dirname ~/$item);
            ln -sfn $STORE/$item ~/$item;
            echo "[success] ~/$item -> $STORE/$item";
        fi;
    done;
fi;
