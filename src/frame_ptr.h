#pragma once

#include <functional>
#include <memory>

extern "C"{
#include <libavutil/frame.h>
}

typedef std::function<void(AVFrame *p)> frame_deleter_t;
typedef std::shared_ptr<AVFrame> frame_ptr;

