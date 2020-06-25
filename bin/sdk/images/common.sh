#!/bin/bash

require docker

function Images::pull() {
    docker pull "${SPRYKER_PLATFORM_IMAGE}" || true
}

function Images::destroy() {
    Console::verbose "Removing all Spryker images"

    docker images --filter "reference=${SPRYKER_DOCKER_PREFIX}_*:${SPRYKER_DOCKER_TAG}" --format "{{.ID}}" | xargs "${XARGS_NO_RUN_IF_EMPTY}" docker rmi -f

    docker rmi -f "${SPRYKER_DOCKER_PREFIX}_cli" || true
    docker rmi -f "${SPRYKER_DOCKER_PREFIX}_app" || true
    docker rmi -f "${SPRYKER_PLATFORM_IMAGE}" || true
}

function Images::_buildApp() {
    local folder=${1}
    local baseAppImage="${SPRYKER_DOCKER_PREFIX}_base_app:${SPRYKER_DOCKER_TAG}"
    local appImage="${SPRYKER_DOCKER_PREFIX}_app:${SPRYKER_DOCKER_TAG}"
    local runtimeImage="${SPRYKER_DOCKER_PREFIX}_run_app:${SPRYKER_DOCKER_TAG}"

    Console::verbose "${INFO}Building Application images${NC}"

    docker build \
        -t "${baseAppImage}" \
        -f "${DEPLOYMENT_PATH}/images/common/application/Dockerfile" \
        --progress="${PROGRESS_TYPE}" \
        --build-arg "SPRYKER_PLATFORM_IMAGE=${SPRYKER_PLATFORM_IMAGE}" \
        --build-arg "SPRYKER_LOG_DIRECTORY=${SPRYKER_LOG_DIRECTORY}" \
        --build-arg "SPRYKER_PIPELINE=${SPRYKER_PIPELINE}" \
        --build-arg "APPLICATION_ENV=${APPLICATION_ENV}" \
        --build-arg "SPRYKER_DB_ENGINE=${SPRYKER_DB_ENGINE}" \
        --build-arg "KNOWN_HOSTS=${KNOWN_HOSTS}" \
        --build-arg "SPRYKER_BUILD_HASH=${SPRYKER_BUILD_HASH:-"current"}" \
        --build-arg "SPRYKER_BUILD_STAMP=${SPRYKER_BUILD_STAMP:-""}" \
        "${DEPLOYMENT_PATH}/context" 1>&2

    docker build \
        -t "${appImage}" \
        -t "${runtimeImage}" \
        -f "${DEPLOYMENT_PATH}/images/${folder}/application/Dockerfile" \
        --progress="${PROGRESS_TYPE}" \
        --build-arg "SPRYKER_PARENT_IMAGE=${baseAppImage}" \
        --build-arg "SPRYKER_DOCKER_PREFIX=${SPRYKER_DOCKER_PREFIX}" \
        --build-arg "SPRYKER_DOCKER_TAG=${SPRYKER_DOCKER_TAG}" \
        --build-arg "USER_UID=${USER_FULL_ID%%:*}" \
        --build-arg "COMPOSER_AUTH=${COMPOSER_AUTH}" \
        --build-arg "DEPLOYMENT_PATH=${DEPLOYMENT_PATH}" \
        --build-arg "SPRYKER_PIPELINE=${SPRYKER_PIPELINE}" \
        --build-arg "APPLICATION_ENV=${APPLICATION_ENV}" \
        --build-arg "SPRYKER_DB_ENGINE=${SPRYKER_DB_ENGINE}" \
        --build-arg "SPRYKER_COMPOSER_MODE=${SPRYKER_COMPOSER_MODE}" \
        --build-arg "SPRYKER_COMPOSER_AUTOLOAD=${SPRYKER_COMPOSER_AUTOLOAD}" \
        --build-arg "SPRYKER_BUILD_HASH=${SPRYKER_BUILD_HASH:-"current"}" \
        --build-arg "SPRYKER_BUILD_STAMP=${SPRYKER_BUILD_STAMP:-""}" \
        . 1>&2

    docker build \
        -t "${runtimeImage}" \
        -f "${DEPLOYMENT_PATH}/images/debug/application/Dockerfile" \
        --progress="${PROGRESS_TYPE}" \
        --build-arg "SPRYKER_PARENT_IMAGE=${appImage}" \
        "${DEPLOYMENT_PATH}/context" 1>&2
}

function Images::_buildCli() {
    local folder=${1}
    local baseAppImage="${SPRYKER_DOCKER_PREFIX}_base_app:${SPRYKER_DOCKER_TAG}"
    local appImage="${SPRYKER_DOCKER_PREFIX}_app:${SPRYKER_DOCKER_TAG}"
    local baseCliImage="${SPRYKER_DOCKER_PREFIX}_base_cli:${SPRYKER_DOCKER_TAG}"
    local cliImage="${SPRYKER_DOCKER_PREFIX}_cli:${SPRYKER_DOCKER_TAG}"
    local runtimeCliImage="${SPRYKER_DOCKER_PREFIX}_run_cli:${SPRYKER_DOCKER_TAG}"

    Console::verbose "${INFO}Building CLI images${NC}"

    docker build \
        -t "${baseCliImage}" \
        -f "${DEPLOYMENT_PATH}/images/common/cli/Dockerfile" \
        --progress="${PROGRESS_TYPE}" \
        --build-arg "SPRYKER_PARENT_IMAGE=${baseAppImage}" \
        "${DEPLOYMENT_PATH}/context" 1>&2

    docker build \
        -t "${cliImage}" \
        -t "${runtimeCliImage}" \
        -f "${DEPLOYMENT_PATH}/images/${folder}/cli/Dockerfile" \
        --progress="${PROGRESS_TYPE}" \
        --build-arg "SPRYKER_PARENT_IMAGE=${baseCliImage}" \
        --build-arg "SPRYKER_APPLICATION_IMAGE=${appImage}" \
        --build-arg "DEPLOYMENT_PATH=${DEPLOYMENT_PATH}" \
        --build-arg "COMPOSER_AUTH=${COMPOSER_AUTH}" \
        --build-arg "SPRYKER_PIPELINE=${SPRYKER_PIPELINE}" \
        --build-arg "SPRYKER_BUILD_HASH=${SPRYKER_BUILD_HASH:-"current"}" \
        --build-arg "SPRYKER_BUILD_STAMP=${SPRYKER_BUILD_STAMP:-""}" \
        .  1>&2

    docker build \
        -t "${runtimeCliImage}" \
        -f "${DEPLOYMENT_PATH}/images/debug/cli/Dockerfile" \
        --progress="${PROGRESS_TYPE}" \
        --build-arg "SPRYKER_PARENT_IMAGE=${cliImage}" \
        "${DEPLOYMENT_PATH}/context" 1>&2
}

function Images::_buildFrontend() {
    local folder=${1}
    local cliImage="${SPRYKER_DOCKER_PREFIX}_cli:${SPRYKER_DOCKER_TAG}"
    local builderAssetsImage=$(Assets::getImageTag)
    local baseFrontendImage="${SPRYKER_DOCKER_PREFIX}_base_frontend:${SPRYKER_DOCKER_TAG}"
    local frontendImage="${SPRYKER_DOCKER_PREFIX}_frontend:${SPRYKER_DOCKER_TAG}"
    local runtimeFrontendImage="${SPRYKER_DOCKER_PREFIX}_run_frontend:${SPRYKER_DOCKER_TAG}"

    Console::verbose "${INFO}Building Frontend images${NC}"

    docker build \
        -t "${baseFrontendImage}" \
        -f "${DEPLOYMENT_PATH}/images/common/frontend/Dockerfile" \
        --progress="${PROGRESS_TYPE}" \
        --build-arg "SPRYKER_FRONTEND_IMAGE=${SPRYKER_FRONTEND_IMAGE}" \
        --build-arg "SPRYKER_BUILD_HASH=${SPRYKER_BUILD_HASH:-"current"}" \
        --build-arg "SPRYKER_BUILD_STAMP=${SPRYKER_BUILD_STAMP:-""}" \
        "${DEPLOYMENT_PATH}/context" 1>&2

    docker build \
        -t "${frontendImage}" \
        -t "${runtimeFrontendImage}" \
        -f "${DEPLOYMENT_PATH}/images/${folder}/frontend/Dockerfile" \
        --progress="${PROGRESS_TYPE}" \
        --build-arg "SPRYKER_PARENT_IMAGE=${baseFrontendImage}" \
        --build-arg "SPRYKER_ASSETS_BUILDER_IMAGE=${builderAssetsImage}" \
        "${DEPLOYMENT_PATH}/context" 1>&2

    docker build \
        -t "${runtimeFrontendImage}" \
        -f "${DEPLOYMENT_PATH}/images/debug/frontend/Dockerfile" \
        --progress="${PROGRESS_TYPE}" \
        --build-arg "SPRYKER_PARENT_IMAGE=${frontendImage}" \
        "${DEPLOYMENT_PATH}/context" 1>&2
}

function Images::_buildGateway() {
    local gatewayImage="${SPRYKER_DOCKER_PREFIX}_gateway:${SPRYKER_DOCKER_TAG}"

    Console::verbose "${INFO}Building Gateway image${NC}"

    docker build \
        -t "${gatewayImage}" \
        -f "${DEPLOYMENT_PATH}/images/common/gateway/Dockerfile" \
        --progress="${PROGRESS_TYPE}" \
        "${DEPLOYMENT_PATH}/context" 1>&2
}

function Images::_tagByApp() {
    local applicationName=$1
    local imageName=$2
    local baseImageName=${3:-${imageName}}
    local applicationPrefix=$(echo "$applicationName" | tr '[:upper:]' '[:lower:]')
    local tag="${imageName}-${applicationPrefix}"

    docker tag "${baseImageName}" "${tag}"
}

function Images::tagApplications() {
    local tag=${1:-${SPRYKER_DOCKER_TAG}}

    for application in "${SPRYKER_APPLICATIONS[@]}"; do
        Images::_tagByApp "${application}" "${SPRYKER_DOCKER_PREFIX}_app:${tag}" "${SPRYKER_DOCKER_PREFIX}_app:${SPRYKER_DOCKER_TAG}"
        Images::_tagByApp "${application}" "${SPRYKER_DOCKER_PREFIX}_run_app:${tag}" "${SPRYKER_DOCKER_PREFIX}_run_app:${SPRYKER_DOCKER_TAG}"
    done
}

function Images::tagFrontend() {
    local tag=${1:-${SPRYKER_DOCKER_TAG}}

    Images::_tagByApp frontend "${SPRYKER_DOCKER_PREFIX}_frontend:${tag}" "${SPRYKER_DOCKER_PREFIX}_frontend:${SPRYKER_DOCKER_TAG}"
}

function Images::printAll() {
    local tag=${1:-${SPRYKER_DOCKER_TAG}}

    for application in "${SPRYKER_APPLICATIONS[@]}"; do
        local applicationPrefix=$(echo "${application}" | tr '[:upper:]' '[:lower:]')
        printf "%s %s_app:%s\n" "${application}" "${SPRYKER_DOCKER_PREFIX}" "${tag}-${applicationPrefix}"
    done

    printf "%s %s_frontend:%s\n" "frontend" "${SPRYKER_DOCKER_PREFIX}" "${tag}-frontend"
}