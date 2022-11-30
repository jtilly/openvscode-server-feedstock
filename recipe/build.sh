#!/bin/bash

set -exuo pipefail

if [[ "${target_platform}" == "linux-64" ]]; then
  ARCH_ALIAS=linux-x64
elif [[ "${target_platform}" == "linux-aarch64" ]]; then
  ARCH_ALIAS=linux-arm64
elif [[ "${target_platform}" == "osx-64" ]]; then
  ARCH_ALIAS=darwin-x64
elif [[ "${target_platform}" == "osx-arm64" ]]; then
  ARCH_ALIAS=darwin-arm64
fi

pushd src
git init
git add .
git config --local user.email 'noreply@example.com'
git config --local user.name 'conda smithy'
git commit -m "placeholder commit" --no-verify --no-gpg-sign
yarn install
yarn gulp vscode-reh-web-${ARCH_ALIAS}-min
popd

mkdir -p $PREFIX/share
cp -r vscode-reh-web-${ARCH_ALIAS} ${PREFIX}/share/openvscode-server
rm -rf $PREFIX/share/openvscode-server/bin

mkdir -p ${PREFIX}/bin

cat <<'EOF' >${PREFIX}/bin/openvscode-server
#!/bin/bash
PREFIX_DIR=$(dirname ${BASH_SOURCE})
# Make PREDIX_DIR absolute
if [[ $(uname) == 'Linux' ]]; then
  PREFIX_DIR=$(readlink -f ${PREFIX_DIR})
else
  pushd ${PREFIX_DIR}
  PREFIX_DIR=$(pwd -P)
  popd
fi
# Go one level up
PREFIX_DIR=$(dirname ${PREFIX_DIR})
node "${PREFIX_DIR}/share/openvscode-server/out/server-main.js" "$@"
EOF
chmod +x ${PREFIX}/bin/openvscode-server

# Remove unnecessary resources
find ${PREFIX}/share/openvscode-server -name '*.map' -delete
rm -rf ${PREFIX}/share/openvscode-server/node

# Directly check whether the openvscode-server call also works inside of conda-build
openvscode-server --help
