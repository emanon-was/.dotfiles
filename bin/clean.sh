#!/usr/bin/env sh

STORE=$1
STORE_ITEMS=$(cat $2)
IGNORE_ITEMS=""
REMOVE_ITEMS=""

for item in $STORE_ITEMS; do
    if [ -e ~/$item ] && [ ! ~/$item -ef $STORE/$item ]; then
        IGNORE_ITEMS+="$item ";
        echo "[ignore] ~/$item";
    fi;
done;

for item in $STORE_ITEMS; do
    if [ ~/$item -ef $STORE/$item ]; then
        REMOVE_ITEMS+="$item ";
        rm ~/$item;
        echo "[delete] ~/$item -> $STORE/$item";
    fi;
done;
