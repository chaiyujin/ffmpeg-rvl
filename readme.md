## Acknowledge
RVL algorithm from paper **Fast Lossless Depth Image Compression**. The Original source code is licensed under the MIT License.

This is a ffmpeg version (based on ffmpeg 3.4.4, other 3.4.* should be ok).

## Files
- `codec_path`: contains codes and a script `install.py` to patch codes to ffmpeg.
- `install_ffmpeg*.sh`: configure and build ffmpeg on different system. (Dependences should be installed before.)
- `FindFFmpeg.cmake`: include in CMakeLists.txt, it helps to find built ffmpeg.
