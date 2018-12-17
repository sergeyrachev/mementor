// This is an open source non-commercial project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++ and C#: http://www.viva64.com
#include "source.h"
#include "logging.h"

#include <cassert>
#include <chrono>
#include <mutex>
#include <condition_variable>
#include <map>
#include <list>



extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
}

using namespace neuon;

source_t::source_t(const std::string &filename, consumer video, consumer audio)
: dmx{std::make_unique<demuxer>(filename)}
{
    setup(*dmx, video, audio);
}

source_t::~source_t() = default;

void source_t::setup(demuxer& dmx, const consumer &video, const consumer &audio) {
    auto tracks = dmx.tracks();
    //assert(tracks.size() == 2 && "Single Audio / Video streams only");

    for (auto &&track : tracks) {

        if(track.parameters.codec_type == AVMEDIA_TYPE_VIDEO){
            vdec = std::make_shared<decoder>(track.parameters);
            decoders[track.index] = vdec;
            consumers[track.index] = video;
        } else if(track.parameters.codec_type == AVMEDIA_TYPE_AUDIO){
            adec = std::make_shared<decoder>(track.parameters);
            decoders[track.index] = adec;
            consumers[track.index] = audio;
        }
    }
}

void source_t::run() {
    while(auto au = dmx->get()){
        auto idx = au->packet->stream_index;
        auto&& dec = decoders[idx];

        dec->put(au->packet.get());
        while(auto frame = dec->get()){
            consumers[idx](frame);
        }
    }

    for (auto &&dec : decoders) {
        dec.second->put(nullptr);
        while(auto frame = dec.second->get()){
            consumers[dec.first](frame);
        }
    }
}
