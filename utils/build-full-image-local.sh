PKGS=(pkgs/*/)
TOTAL=${#PKGS[@]}
i=0
echo "" > build.log
for pkg in ${PKGS[@]} ; do
  i=$(( i + 1 ))
  echo "------ PKG $pkg ------" >> build.log
  gum spin --show-error --spinner moon --title "($i/$TOTAL) Building $pkg" -- bash -c "docker run --rm -v $(pwd):/workdir --entrypoint=/workdir/pkgs/build-package.sh -v $(pwd)/.cache:/home/build/.cache:Z --ulimit nofile=1024:1048576 chimera-full-local:latest $pkg 2>&1 | tee -a build.log"
done

PKGS=($(source ./manifest ; echo ${AUR_PACKAGES} | jq -R -s -c 'split(" ") | .[] | gsub("[\\n\\t]"; "") | select( . != "" )' -r))
TOTAL=${#PKGS[@]}
i=0
for pkg in ${PKGS[@]}; do
  echo "------ AUR $pkg ------" >> build.log
  i=$(( i + 1 ))
  gum spin --show-error --spinner moon --title "($i/$TOTAL) Building AUR $pkg" -- bash -c "docker run --rm -v $(pwd):/workdir --entrypoint=/workdir/aur-pkgs/build-aur-package.sh -v $(pwd)/.cache:/home/build/.cache:Z --ulimit nofile=1024:1048576 chimera-full-local:latest $pkg 2>&1 | tee -a build.log"
done

echo "------ System Image ------" >> build.log
gum spin --show-error --spinner moon --title "Building system image" -- bash -c "docker run --rm -u root --privileged=true --entrypoint /workdir/build-image.sh -v $(pwd):/workdir:Z -v $(pwd)/output:/output:z chimera-full-local:latest $(echo local-$(git rev-parse HEAD | cut -c1-7)) 2>&1 | tee -a build.log"
