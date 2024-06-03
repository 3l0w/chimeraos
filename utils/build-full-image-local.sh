echo "Building packages"

for pkg in pkgs/*/ ; do
  docker run --rm -it -v $(pwd):/workdir --entrypoint=/workdir/pkgs/build-package.sh -v $(pwd)/.cache:/home/build/.cache:Z --ulimit "nofile=1024:1048576" chimera-full-local:latest $pkg
done

echo "Building aur packages"
PKGS=$(source ./manifest ; echo ${AUR_PACKAGES} | jq -R -s -c 'split(" ") | .[] | gsub("[\\n\\t]"; "") | select( . != "" )' -r)
for pkg in $PKGS; do
  docker run --rm -it -v $(pwd):/workdir --entrypoint=/workdir/aur-pkgs/build-aur-package.sh -v $(pwd)/.cache:/home/build/.cache:Z --ulimit "nofile=1024:1048576" chimera-full-local:latest $pkg
done

echo "Building images"
docker run -it --rm -u root --privileged=true --entrypoint /workdir/build-image.sh -v $(pwd):/workdir:Z -v $(pwd)/output:/output:z chimera-full-local:latest $(echo local-$(git rev-parse HEAD | cut -c1-7))
