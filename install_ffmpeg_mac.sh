# please install brew first !
brew install automake fdk-aac git lame libass libtool libvorbis libvpx \
             opus sdl shtool texi2html theora wget x264 x265 xvid nasm &&

cd ffmpeg &&\
PATH="$HOME/ffmpeg_build/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" pkg_config='pkg-config --static' ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm" \
  --bindir="$HOME/ffmpeg_build/bin" \
  --cc=clang --host-cflags= --host-ldflags= \
  --enable-static --enable-shared --enable-pthreads \
  --enable-hardcoded-tables --enable-avresample \
  --enable-gpl  --enable-libmp3lame --enable-libx264 --enable-libxvid --enable-opencl \
  --enable-videotoolbox \
  --disable-lzma &&
PATH="$HOME/ffmpeg_build/bin:$PATH" make -j 8 && \
make install && \
hash -r

# .dylib and .a should be generated in $HOME/ffmpeg_build