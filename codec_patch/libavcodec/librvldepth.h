#ifndef AVCODEC_LIBRVLDEPTH_H
#define AVCODEC_LIBRVLDEPTH_H
#include "libavutil/common.h"

#ifndef AV_MY_DepthImageInfo
#define AV_MY_DepthImageInfo
typedef struct DepthImageInfo {
    int32_t compressed_size;
    int32_t width;
    int32_t height;
} DepthImageInfo;
#endif

extern int DepthImageInfoSize;

int  ff_librvldepth_compress_rvl(const short *input, char *output, int numPixels);
void ff_librvldepth_decompress_rvl(const char *input, short *output, int numPixels);

#endif  /* AVCODEC_LIBRVLDEPTH_H */