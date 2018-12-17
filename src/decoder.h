#include "frame_ptr.h"

#include <functional>
#include <memory>

extern "C"{
#include <libavcodec/avcodec.h>
}

class decoder{
    typedef std::function<void(AVCodecContext *p)> dec_ctx_deleter_t;
    typedef std::unique_ptr<AVCodecContext, dec_ctx_deleter_t> dec_ctx_ptr;

public:
    typedef std::unique_ptr<decoder> ptr;
    typedef std::unique_ptr<const decoder> cptr;
public:
    decoder( const AVCodecParameters& codecpar );
    ~decoder() = default;

    void put(const AVPacket* const packet) const;
    frame_ptr get() const;
    const AVCodecContext& parameters()const;
private:
    dec_ctx_ptr dec_ctx;
};


