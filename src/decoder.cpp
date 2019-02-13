// This is an open source non-commercial project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++ and C#: http://www.viva64.com
#include "decoder.h"

#include "logging.h"

#include <cassert>
#include <chrono>

extern "C"{
#include <libavutil/avutil.h>
#include <libavformat/avformat.h>
}

decoder::decoder(const AVCodecParameters &codecpar) {
    dec_ctx_deleter_t dec_ctx_deleter = [](AVCodecContext *p) {
        avcodec_free_context(&p);
    };
    const AVCodec *i_codec = avcodec_find_decoder(codecpar.codec_id);
    dec_ctx = dec_ctx_ptr(avcodec_alloc_context3(i_codec), dec_ctx_deleter);
    int err = avcodec_parameters_to_context(dec_ctx.get(), &codecpar);
    dec_ctx->flags |= AV_CODEC_FLAG_OUTPUT_CORRUPT;
    dec_ctx->flags2 |= AV_CODEC_FLAG2_SHOW_ALL;

    logging::info() << "Set param to decoder with return code " << err;

    AVDictionary *opts = NULL;
    dec_ctx->thread_count = 0;
    dec_ctx->thread_type = FF_THREAD_FRAME;
    err = avcodec_open2(dec_ctx.get(), i_codec, &opts);
    logging::info() << "Opened decoder " << std::hex << dec_ctx.get()
                    << " returned " << err;
    assert(err == 0);
}

void decoder::put(const AVPacket* const packet) const {

    int err = avcodec_send_packet(dec_ctx.get(), packet);
    logging::info() << "Put packet'" << std::hex << packet << "' returned " << err;
}

frame_ptr decoder::get() const {
    frame_ptr frame({av_frame_alloc(), [](AVFrame *p) { av_frame_free(&p); }});
    int res = avcodec_receive_frame(dec_ctx.get(), frame.get());
    if (AVERROR(EAGAIN) == res) {
        logging::info() << "Decoder expect more data";
        return {};
    } else if (AVERROR_EOF == res) {
        logging::info() << "Decoder reached EOF";
        return {};
    } else if (AVERROR(EINVAL) == res) {
        logging::debug() << "Decoder returned an error: " << errno;
        assert((0, "It is very unlikely to be here!"));
        return {};
    }

    logging::info() << "Get frame "
                    << " Dts: " << frame->pkt_dts
                    << " Dts(msec): " << std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::microseconds(frame->pkt_dts)).count()
                    << " Pts: " << frame->pts
                    << " PktPts(msec): " << std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::microseconds(frame->pts)).count()
                    << " Size: " << frame->pkt_size
                    << " Pos: " << frame->pkt_pos;

    return frame;
}

const AVCodecContext &decoder::parameters() const {
    return *dec_ctx;
}
