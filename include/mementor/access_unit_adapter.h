#pragma once

#include "mementor/packet_ptr.h"

#include <chrono>
#include <functional>
#include <memory>

extern "C"{
#include <libavformat/avformat.h>
}

namespace ffmpeg{
    class access_unit_adapter {
    public:
        static const AVRational Microseconds;

    public:
        explicit access_unit_adapter(packet_ptr packet,
                                     const AVRational &packet_timescale);

    public:
        const packet_ptr packet{nullptr};
        const AVRational timescale = Microseconds;
    };

}
