#!/usr/bin/env bash
set -x
set -eo pipefail

# shellcheck disable=SC2120
setup_circle() {
  echo "=====> setup_circle on CIRCLE_NODE_INDEX: $CIRCLE_NODE_INDEX"
  sudo -E CI=true make -e sshcommand

  HEROKUISH_VERSION=$(grep HEROKUISH_VERSION deb.mk | head -n1 | cut -d' ' -f3)
  HEROKUISH_PACKAGE_NAME="herokuish_${HEROKUISH_VERSION}_amd64.deb"
  docker run --rm --entrypoint cat "dokku:build" "/data/${HEROKUISH_PACKAGE_NAME}" > "build/$HEROKUISH_PACKAGE_NAME"

  PLUGN_VERSION=$(grep PLUGN_VERSION deb.mk | head -n1 | cut -d' ' -f3)
  PLUGN_PACKAGE_NAME="plugn_${PLUGN_VERSION}_amd64.deb"
  docker run --rm --entrypoint cat "dokku:build" "/data/${PLUGN_PACKAGE_NAME}" > "build/$PLUGN_PACKAGE_NAME"

  SSHCOMMAND_VERSION=$(grep SSHCOMMAND_VERSION deb.mk | head -n1 | cut -d' ' -f3)
  SSHCOMMAND_PACKAGE_NAME="sshcommand_${SSHCOMMAND_VERSION}_amd64.deb"
  docker run --rm --entrypoint cat "dokku:build" "/data/${SSHCOMMAND_PACKAGE_NAME}" > "build/$SSHCOMMAND_PACKAGE_NAME"

  SIGIL_VERSION=$(grep SIGIL_VERSION deb.mk | head -n1 | cut -d' ' -f3)
  SIGIL_PACKAGE_NAME="gliderlabs_sigil_${SIGIL_VERSION}_amd64.deb"
  docker run --rm --entrypoint cat "dokku:build" "/data/${SIGIL_PACKAGE_NAME}" > "build/$SIGIL_PACKAGE_NAME"

  sudo dpkg -i "build/$HEROKUISH_PACKAGE_NAME"
  sudo dpkg -i "build/$PLUGN_PACKAGE_NAME"
  sudo dpkg -i "build/$SSHCOMMAND_PACKAGE_NAME"
  sudo dpkg -i "build/$SIGIL_PACKAGE_NAME"

  sudo add-apt-repository -y ppa:nginx/stable
  sudo apt-get -qq -y install nginx

  sudo dpkg -i "$(cat build/deb-filename)"
  # need to add the dokku user to the docker group
  sudo usermod -G docker dokku
  [[ "$1" == "buildstack" ]] && BUILD_STACK=true make -e stack
  # sudo -E CI=true make -e install
  sudo -E make -e setup-deploy-tests
  bash --version
  docker version
  lsb_release -a
  # setup .dokkurc
  sudo -E mkdir -p /home/dokku/.dokkurc
  sudo -E chown dokku:ubuntu /home/dokku/.dokkurc
  sudo -E chmod 775 /home/dokku/.dokkurc
  # pull node:4 image for testing
  sudo docker pull node:4
}

# shellcheck disable=SC2119
setup_circle
exit $?
