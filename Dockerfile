FROM archlinux:base-devel
LABEL contributor="shadowapex@gmail.com"
COPY rootfs/etc/pacman.conf /etc/pacman.conf
RUN echo -e "keyserver-options auto-key-retrieve" >> /etc/pacman.d/gnupg/gpg.conf && \
    # Cannot check space in chroot
    sed -i '/CheckSpace/s/^/#/g' /etc/pacman.conf && \
    pacman-key --init && \
    pacman --noconfirm -Syyuu && \
    pacman --noconfirm -S \
    arch-install-scripts \
    btrfs-progs \
    fmt \
    xcb-util-wm \
    wget \
    pyalpm \
    python-build \
    python-installer \
    python-hatchling \
    python-markdown-it-py \
    python-setuptools \
    python-wheel \
    sudo \
    libretro-snes9x python-beaker python-psutil libretro-nestopia xorg-xdpyinfo python-pyusb python-rich innoextract python-pygments libretro-mgba python-bcrypt libretro-genesis-plus-gx python-filelock libretro-picodrive python-requests xorg-xwininfo retroarch libretro-flycast libretro-desmume yq python-xmltodict libretro-dolphin python-bottle python-urllib3 ttf-dejavu python-pyftpdlib libretro-beetle-psx-hw dolphin-emu miniupnpc libspng enet sfml libxrandr pugixml ffmpeg libmodplug libopenmpt portaudio libssh aom svt-av1 libwebp libiec61883 libass openjpeg2 libplacebo libjxl openexr imath v4l-utils srt libvpl rav1e x265 libbs2b libvpx vmaf mbedtls2 gsm libvdpau libva lcms2 openal libdeflate opencore-amr libtheora libbluray shaderc glslang qt6-svg qt6-base qt6-translations xcb-util-cursor vulkan-headers libb2 qt5-base xcb-util-renderutil libinput libwacom tslib libcups qt5-translations xcb-util-image libxcomposite libretro-mesen-s python-idna libgudev dav1d minizip-ng python-argcomplete mtdev python-pyudev boost-libs python-charset-normalizer libdovi libretro-kronos libxv jack2 giflib python-yaml bluez-libs flatpak libmalcontent xdg-dbus-proxy python-gobject gobject-introspection-runtime xdg-utils xorg-xset libxmu libxt bubblewrap appstream libxmlb libstemmer xdg-desktop-portal geoclue libsoup3 json-glib libmm-glib jq xorg-xprop glew python-plyvel mesa-utils libxkbcommon-x11 libdecor sdl2 libxcursor ostree libsodium fuse3 fuse-common composefs oniguruma double-conversion librsvg pango libthai libdatrie fribidi cairo pixman leveldb snappy pulseaudio rtkit polkit tdb orc libsm libice libsoxr webrtc-audio-processing-1 abseil-cpp gtest libpulse libasyncns highway gperftools libunibreak md4c xdotool libxtst libxi libxinerama libxkbcommon hicolor-icon-theme glu python-future libgirepository python-colorama rubberband libsndfile mpg123 lame opus libvorbis libsamplerate fftw libdvdnav xkeyboard-config avahi libdaemon hidapi xvidcore xcb-util flac libavc1394 libraw1394 vid.stab vapoursynth zimg python-tornado ocl-icd libnotify gdk-pixbuf2 libtiff jbigkit shared-mime-info libjpeg-turbo libsoup glib-networking gsettings-desktop-schemas dconf adobe-source-code-pro-fonts cantarell-fonts libproxy duktape python-tomlkit libretro-mupen64plus-next xxhash minizip speex libogg speexdsp x264 l-smash libevdev libxft fontconfig libxrender freetype2 libpng harfbuzz graphite pipewire libcamera libyaml libcamera-ipa libunwind libpipewire libdvdread libretro-beetle-pce-fast \
    && \
    pacman --noconfirm -S --needed git && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd build -G wheel -m && \
    su - build -c "git clone https://aur.archlinux.org/pikaur.git /tmp/pikaur" && \
    su - build -c "cd /tmp/pikaur && makepkg -f" && \
    pacman --noconfirm -U /tmp/pikaur/pikaur-*.pkg.tar.zst

# Auto add PGP keys for users
RUN mkdir -p /etc/gnupg/ && echo -e "keyserver-options auto-key-retrieve" >> /etc/gnupg/gpg.conf

# Add a fake systemd-run script to workaround pikaur requirement.
RUN echo -e "#!/bin/bash\nif [[ \"$1\" == \"--version\" ]]; then echo 'fake 244 version'; fi\nmkdir -p /var/cache/pikaur\n" >> /usr/bin/systemd-run && \
    chmod +x /usr/bin/systemd-run

# substitute check with !check to avoid running software from AUR in the build machine
# also remove creation of debug packages.
RUN sed -i '/BUILDENV/s/check/!check/g' /etc/makepkg.conf && \
    sed -i '/OPTIONS/s/debug/!debug/g' /etc/makepkg.conf

COPY manifest /manifest
# Freeze packages and overwrite with overrides when needed
RUN source /manifest && \
    echo "Server=https://archive.archlinux.org/repos/${ARCHIVE_DATE}/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist && \
    pacman --noconfirm -Syyuu; if [ -n "${PACKAGE_OVERRIDES}" ]; then wget --directory-prefix=/tmp/extra_pkgs ${PACKAGE_OVERRIDES}; pacman --noconfirm -U --overwrite '*' /tmp/extra_pkgs/*; rm -rf /tmp/extra_pkgs; fi

USER build
ENV BUILD_USER "build"
ENV GNUPGHOME  "/etc/pacman.d/gnupg"
# Built image will be moved here. This should be a host mount to get the output.
ENV OUTPUT_DIR /output

WORKDIR /workdir
