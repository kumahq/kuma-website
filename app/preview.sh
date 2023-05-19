: "${BRANCH:=master}"
: "${REPO:=kumahq/kuma}"
: "${PRODUCT_NAME:=Kuma}"

curl -s https://kuma.io/installer.sh | BRANCH=${BRANCH} REPO=${REPO} PRODUCT_NAME=${PRODUCT_NAME} VERSION=preview sh -
