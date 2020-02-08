#include "demuxer.h"
#include "logging.h"
#include "logging_boost.h"

#include <cassert>
#include <algorithm>

ffmpeg::demuxer::demuxer(const std::string &filename) {
    AVFormatContext *tmp_ctx(nullptr);
    int err = avformat_open_input(&tmp_ctx, filename.c_str(), NULL, NULL);
    assert(err == 0);

    logging::debug() << "Opened demuxer context with return code " << err;
    dmx_ctx = dmx_ctx_ptr(tmp_ctx, [](AVFormatContext *p) {
        avformat_close_input(&p);
    });
    dmx_ctx->flags |= AVFMT_FLAG_GENPTS;

    err = avformat_find_stream_info(dmx_ctx.get(), NULL);
    logging::debug() << "Detected streams info with return code " << err;
    av_dump_format(dmx_ctx.get(), 0, filename.c_str(), false);

    start_time = std::chrono::microseconds(av_rescale_q(dmx_ctx->start_time, {1, AV_TIME_BASE}, access_unit_adapter::Microseconds));
}

std::vector<track_adapter> ffmpeg::demuxer::tracks() const {
    std::vector<track_adapter> ret;
    std::transform(dmx_ctx->streams, dmx_ctx->streams + dmx_ctx->nb_streams,
                   std::back_inserter(ret),
                   [](const AVStream* stream){
                       return track_adapter(*stream);
                   });
    return ret;
}

std::unique_ptr<ffmpeg::access_unit_adapter> ffmpeg::demuxer::get() {

    packet_ptr packet(av_packet_alloc(), [](AVPacket *p) {av_packet_free(&p);});
    av_init_packet(packet.get());
    bool eos_occured = av_read_frame(dmx_ctx.get(), packet.get()) < 0;
    if(!eos_occured) {
        auto &stream = dmx_ctx->streams[packet->stream_index];
        std::unique_ptr<access_unit_adapter> au(new access_unit_adapter(std::move(packet), stream->time_base));

        au->packet->dts -= start_time.count();
        au->packet->pts -= start_time.count();

        logging::debug() << "Read packet "
                        << " Dts: " << au->packet->dts
                        << " Dts(msec): " << std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::microseconds(au->packet->dts)).count()
                        << " Pts: " << au->packet->pts
                        << " Pts(msec): " << std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::microseconds(au->packet->pts)).count()
                        << " Size: " << au->packet->size
                        << " Pos: " << au->packet->pos
                        << " from stream " << stream->index;
        return au;
    }
    return {};
}
