#include "libavutil/common.h"
#include "libavutil/fifo.h"
#include "libavutil/imgutils.h"
#include "libavutil/intreadwrite.h"
#include "libavutil/mathematics.h"
#include "libavutil/opt.h"

#include "avcodec.h"
#include "internal.h"
#include "librvldepth.h"


static av_cold int depth_decode_close(AVCodecContext *avctx)
{
    return 0;
}

static av_cold int depth_decode_init(AVCodecContext *avctx)
{

    avctx->pix_fmt = AV_PIX_FMT_YUYV422;

    return 0;
}


static int depth_decode_frame(AVCodecContext *avctx, void *data,
                            int *got_frame, AVPacket *avpkt)
{
    int ret;
    DepthImageInfo info;
    AVFrame *avframe = data;

    memcpy((void *)(&info), avpkt->data, DepthImageInfoSize);

    ret = ff_set_dimensions(avctx, info.width, info.height);
    if (ret < 0)
        return ret;
    if (ff_get_buffer(avctx, avframe, 0) < 0) {
        av_log(avctx, AV_LOG_ERROR, "Unable to allocate buffer\n");
        return AVERROR(ENOMEM);
    }

    ff_librvldepth_decompress_rvl(
        avpkt->data + DepthImageInfoSize,
        (short *)avframe->data[0],
        info.width * info.height);

    // av_log(avctx, AV_LOG_INFO, "decode depth frame %d\n", *(int32_t *)avpkt->data);

    avframe->pts     = avpkt->pts;
    avframe->pkt_dts = avpkt->dts;
#if FF_API_PKT_PTS
FF_DISABLE_DEPRECATION_WARNINGS
    avframe->pkt_pts = avpkt->pts;
FF_ENABLE_DEPRECATION_WARNINGS
#endif

    *got_frame = 1;
    return avpkt->size;
}


AVCodec ff_librvldepth_decoder = {
    .name           = "librvldepth",
    .long_name      = NULL_IF_CONFIG_SMALL("DepthCodec"),
    .type           = AVMEDIA_TYPE_VIDEO,
    .id             = AV_CODEC_ID_RVLDEPTH,
    .priv_data_size = 0,
    .init           = depth_decode_init,
    .decode         = depth_decode_frame,
    .close          = depth_decode_close,
    // The decoder doesn't currently support B-frames, and the decoder's API
    // doesn't support reordering/delay, but the BSF could incur delay.
    .capabilities   = 0,
    .caps_internal  = FF_CODEC_CAP_SETS_PKT_DTS | FF_CODEC_CAP_INIT_THREADSAFE |
                      FF_CODEC_CAP_INIT_CLEANUP
};
