#!/bin/bash
set -eo pipefail
# build
if [[ "$(uname)" == 'Linux' && "$DOCKER" != 'true' ]]; then # linux host > run this script in docker
    .cicd/docker.sh '.cicd/build.sh' $@
else # mac host or linux guest > build
    echo '--- :evergreen_tree: Configuring Environment'
    [[ -z "$JOBS" ]] && export JOBS="$(getconf _NPROCESSORS_ONLN)"
    [[ ! -d build ]] && mkdir build
    cd build
    # cmake
    CMAKE_COMMAND='cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_TESTS=ON'
    [[ "$(uname)" == 'Linux' ]] && CMAKE_COMMAND="$CMAKE_COMMAND -DCMAKE_TOOLCHAIN_FILE=$GIT_ROOT/.cicd/clang.make"
    CMAKE_COMMAND="$CMAKE_COMMAND .."
    # make
    MAKE_COMMAND="make -j $JOBS"
    # build
    echo '+++ :hammer_and_wrench: Building'
    echo "$ $CMAKE_COMMAND"
    $CMAKE_COMMAND
    echo "$ $MAKE_COMMAND"
    $MAKE_COMMAND
fi
# upload artifacts on host
if [[ "$BUILDKITE" == 'true' && "$DOCKER" != 'true' ]]; then
    '--- :arrow_up: Uploading Artifacts'
    tar -pczf build.tar.gz build
    buildkite-agent artifact upload build.tar.gz
fi