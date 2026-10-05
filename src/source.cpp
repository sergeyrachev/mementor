// This is an open source non-commercial project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++ and C#: http://www.viva64.com
#include "mementor/source.h"

#include <condition_variable>
#include <list>
#include <map>
#include <spdlog/spdlog.h>
#include <stdexcept>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
}

source_t::source_t(const std::string &filename, consumer video, consumer audio)
: dmx{new ffmpeg::demuxer(filename)}
{
    setup(*dmx, video, audio);
}

source_t::~source_t() = default;

void source_t::setup(ffmpeg::demuxer& dmx, const consumer &video, const consumer &audio) {
    auto tracks = dmx.tracks();
    //assert(tracks.size() == 2 && "Single Audio / Video streams only");

    bool has_video = false;
    bool has_audio = false;
    for (auto &&track : tracks) {

        if(track.parameters.codec_type == AVMEDIA_TYPE_VIDEO){
            vdec = std::make_shared<ffmpeg::decoder>(track.parameters);
            decoders[track.index] = vdec;
            consumers[track.index] = video;
            has_video = true;
        } else if(track.parameters.codec_type == AVMEDIA_TYPE_AUDIO){
            adec = std::make_shared<ffmpeg::decoder>(track.parameters);
            decoders[track.index] = adec;
            consumers[track.index] = audio;
            has_audio = true;
        }
    }

    if (!has_video || !has_audio) {
        throw std::runtime_error("The input file must contain Audio and Video tracks");
    }
}

void source_t::run(threads::interruption_t& interruption) {
    auto au = dmx->get();
    while( !interruption.done() && au ){

        auto idx = au->packet->stream_index;

        if (decoders.find(idx) != decoders.end()) {
            auto&& dec = decoders[idx];
            dec->put(au->packet.get());
            while(auto frame = dec->get()){
                consumers[idx](std::move(frame));
            }
        }
        au = dmx->get();
    }

    for (auto &&dec : decoders) {
        dec.second->put(nullptr);
        while(auto frame = dec.second->get()){
            consumers[dec.first](std::move(frame));
        }
    }
}
