# first open a cmd (not powershell or something else !)
# install VS2015 (VS2013 and later should be ok, but paths should be changed according to VS version)
# install msys2 (64bit) at c:/
# cmd -> cd c:/msys64
# cmd -> "C:/Program Files (x86)/Microsoft Visual Studio 14.0/VC/bin/amd64/vcvars64.bat"
# cmd -> ./msys2_shell.cmd -mingw64
# then, msys will open, all following cmds are typed in msys shell.

export PATH="/c/Program Files (x86)/Microsoft Visual Studio 14.0/VC/BIN/amd64/":$PATH &&
which link.exe && # should be `/c/Program Files (x86)/Microsoft Visual Studio 14.0/VC/BIN/amd64/link.exe`
which cl.exe &&   # should be `/c/Program Files (x86)/Microsoft Visual Studio 14.0/VC/BIN/amd64/cl.exe`
# if link.exe is not right, rename /usr/bin/link.exe to /usr/bin/link_backup.exe

cd ffmpeg &&
PATH="$HOME/ffmpeg_build/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --toolchain=msvc \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --bindir="$HOME/ffmpeg_build/bin" \
  --arch=x86_64 --enable-yasm --enable-asm --enable-shared --enable-static && \
PATH="$HOME/ffmpeg_build/bin:$PATH" make -j 8 && \
make install

# the ffmpeg_build should be in the msys home.