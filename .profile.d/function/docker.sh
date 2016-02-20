docker-list() {
	  echo "------------------------------------";
	  docker images;
	  echo "------------------------------------";
	  docker ps -a;
	  echo "------------------------------------";
}

docker-root() {
    current=`pwd`;
    directory=$current;

    # argument
    if [ -n "$1" ] && [ -d "$1" ]; then
        directory=$1;
    fi

    # root directory
    if [ "/" = "$directory" ];then
        return;
    fi

    result=`find $directory -maxdepth 1 -name Dockerfile`;
    if [ -n "$result" ]; then
        echo "$directory";
    else
        docker-root $(dirname $directory);
    fi
}


docker-image() {
    root="$(docker-root)";
    current=`pwd`;
    if [ -n "$root" ]; then
        cd "$root";
        application=$(basename `pwd`);
        version=$(git rev-parse --abbrev-ref HEAD | sed -e 's/\//_/');
        cd "$current";
        echo "$application:$version";
    else
        return;
    fi
}

docker-container() {
    current=`pwd`;
    cd "$(docker-root)";
    application=$(basename `pwd`);
    cd "$current";
    echo "$application";
}

docker-build() {
    current=`pwd`;
    cd "$(docker-root)";
    docker build -t "$(docker-image)" .;
    cd "$current";
}

docker-stop() {
    container=""
    if [ -n "$1" ]; then
        container="$1";
    else
        container="$(docker-container)";
    fi
    docker rm -f "$container";
}

docker-attach() {
    container=""
    if [ -n "$1" ]; then
        container="$1"
    else
        container="$(docker-container)"
    fi
    docker exec -it "$container" /bin/bash
}

docker-log() {
    container="";
    if [ -n "$1" ]; then
        container="$1";
    else
        container="$(docker-container)";
    fi
    docker logs "$container";
}

docker-tail() {
    container="";
    if [ -n "$1" ]; then
        container="$1";
    else
        container="$(docker-container)";
    fi
    docker logs -f "$container";
}

docker-clean() {
    containers=$(docker ps -q -a -f "status=exited");
    if [ -n "$containers" ]; then
        docker rm $(docker ps -q -a -f "status=exited")
    fi
    images=$(docker images | sed -e '1d' | awk '/^<none>/ { print $3 }');
    if [ -n "$images" ]; then
        docker rmi $(docker images | sed -e '1d' | awk '/^<none>/ { print $3 }');
    fi
}
