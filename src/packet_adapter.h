
#include <chrono>
#include <memory>
#include <functional>

extern "C"{
#include <libavformat/avformat.h>
}

typedef std::function<void(AVPacket*)> packet_deleter_t;
typedef std::unique_ptr<AVPacket, packet_deleter_t> packet_ptr;

class access_unit_adapter {
public:
    static const AVRational Microseconds;

public:
    typedef std::unique_ptr<access_unit_adapter> ptr;
    typedef std::unique_ptr<const access_unit_adapter> cptr;

    explicit access_unit_adapter(packet_ptr packet,
                                 const AVRational& packet_timescale);

public:
    const packet_ptr packet{nullptr};
    const AVRational timescale = Microseconds;
};


