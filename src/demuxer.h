
#include "packet_adapter.h"
#include "interruption.h"
#include "track_adapter.h"

#include <map>


typedef std::function<void(AVFormatContext *p)> dmx_ctx_deleter_t;
typedef std::unique_ptr<AVFormatContext, dmx_ctx_deleter_t> dmx_ctx_ptr;
typedef std::function<void(std::unique_ptr<access_unit_adapter>)> output;

class demuxer{
    typedef std::function<void(AVFormatContext *p)> dmx_ctx_deleter_t;
    typedef std::unique_ptr<AVFormatContext, dmx_ctx_deleter_t> dmx_ctx_ptr;

public:
    explicit demuxer(const std::string& filename);
    ~demuxer() = default;
    std::vector<track_adapter> tracks() const;
    access_unit_adapter::ptr get( );

private:
    dmx_ctx_ptr dmx_ctx;
    std::chrono::microseconds start_time;
};

