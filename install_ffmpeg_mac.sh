cd ffmpeg &&\
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" pkg_config='pkg-config --static' ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm" \
  --bindir="$HOME/bin" \
  --enable-gpl \
  --enable-static \
  --enable-shared \
  --enable-pthreads \
  --enable-hardcoded-tables\
  --enable-avresample \
  --cc=clang\
  --host-cflags= \
  --host-ldflags= \
  --enable-gpl \
  --enable-libmp3lame \
  --enable-libx264 \
  --enable-libxvid \
  --enable-opencl \
  --enable-videotoolbox \
  --disable-lzma &&
PATH="$HOME/bin:$PATH" make -j 8 && \
make install && \
hash -r