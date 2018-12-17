#pragma once

#include "demuxer.h"
#include "decoder.h"
#include "frame_ptr.h"

#include <string>
#include <functional>
#include <memory>
#include <map>
#include <list>

namespace neuon{
    typedef std::function<void(frame_ptr)> consumer;

    class source_t {
    public:
        explicit source_t(const std::string& input, consumer video, consumer audio);
        void run();
        ~source_t();
        std::unique_ptr<demuxer> dmx;
        std::shared_ptr<decoder> adec;
        std::shared_ptr<decoder> vdec;

    private:
        void setup(demuxer& dmx, const consumer &video, const consumer &audio);
    private:
        std::map<int32_t, std::shared_ptr<decoder>> decoders;
        std::map<int32_t, consumer> consumers;
    };
}
