#include "libavutil/common.h"
#include "libavutil/fifo.h"
#include "libavutil/imgutils.h"
#include "libavutil/intreadwrite.h"
#include "libavutil/mathematics.h"
#include "libavutil/opt.h"

#include "avcodec.h"
#include "internal.h"
#include "librvldepth.h"

typedef struct DepthBuffer {
    const AVClass *av_class;
    char *buffer;
    int frame_size;
} DepthBuffer;

static const AVClass class = {
    "librvldepthenc", av_default_item_name, NULL, LIBAVUTIL_VERSION_INT
};

static av_cold int depth_encode_close(AVCodecContext *avctx) {
    DepthBuffer *b = avctx->priv_data;
    if (b->buffer) free(b->buffer);
    return 0;
}

static av_cold int depth_encode_init(AVCodecContext *avctx) {
    DepthBuffer *b = avctx->priv_data;
    b->buffer = NULL;
    b->frame_size = avctx->width * avctx->height;
    b->buffer = (char *)malloc(b->frame_size);
    av_log(avctx, AV_LOG_INFO, "DepthCodec buffer size: %d\n", b->frame_size);
    return 0;
}

static int depth_encode_frame(AVCodecContext *avctx, AVPacket *avpkt,
                            const AVFrame *frame, int *got_packet)
{
    int size, ret;
    int32_t fsize;
    DepthImageInfo info;
    DepthBuffer *b = avctx->priv_data;
    
    fsize = ff_librvldepth_compress_rvl(
        (const short *)frame->data[0],
        b->buffer,
        b->frame_size
    );
    size = fsize + DepthImageInfoSize;
    info.compressed_size = fsize;
    info.width = avctx->width;
    info.height = avctx->height;

    // av_log(avctx, AV_LOG_INFO, "%dx%d\n", info.width, info.height);

    if ((ret = ff_alloc_packet2(avctx, avpkt, size, size))) {
        av_log(avctx, AV_LOG_ERROR, "Error getting output packet\n");
        return ret;
    }
    memcpy(avpkt->data, (const void *)(&info), DepthImageInfoSize);
    memcpy(avpkt->data + DepthImageInfoSize, b->buffer, fsize);
    avpkt->pts = frame->pts;
    avpkt->flags |= AV_PKT_FLAG_KEY;
    *got_packet = 1;
    return 0;
}

AVCodec ff_librvldepth_encoder = {
    .name           = "librvldepth",
    .long_name      = NULL_IF_CONFIG_SMALL("RVLDepthCodec"),
    .type           = AVMEDIA_TYPE_VIDEO,
    .id             = AV_CODEC_ID_RVLDEPTH,
    .priv_data_size = sizeof(DepthBuffer),
    .init           = depth_encode_init,
    .encode2        = depth_encode_frame,
    .close          = depth_encode_close,
    .capabilities   = AV_CODEC_CAP_AUTO_THREADS,
    .caps_internal  = FF_CODEC_CAP_INIT_THREADSAFE | FF_CODEC_CAP_INIT_CLEANUP,
    .pix_fmts       = (const enum AVPixelFormat[]){ AV_PIX_FMT_YUYV422, AV_PIX_FMT_NONE }, 
                       // Important to add AV_PIX_FMT_NONE, which is used in avfilter
    .priv_class     = &class,
};
