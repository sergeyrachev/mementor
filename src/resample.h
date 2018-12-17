#include "frame_ptr.h"

#include <chrono>

extern "C"
{
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>
#include <libavutil/avutil.h>
#include <libavutil/imgutils.h>
#include <libavutil/samplefmt.h>
#include <libavcodec/avcodec.h>
}

#include "dlib/image_processing.h"

inline std::string averr(int ret){
    std::string str(100, '\0');
    auto p = av_strerror(ret, str.data(), 100);
    return str;
}

class audio_resample_t {
public:
    audio_resample_t(uint32_t channel_layout, AVSampleFormat format, uint32_t sample_rate, size_t sr)
        : sr(sr)
        , l(AV_CH_LAYOUT_MONO)
        , f(AV_SAMPLE_FMT_DBL)
        , sc{swr_alloc_set_opts(
            nullptr,
            l, f, sr,
            channel_layout, format, sample_rate, 0, nullptr
        ), [](SwrContext *p) { swr_free(&p); }}{
        swr_init(sc.get());
    }

    std::pair<std::vector<double>, std::chrono::microseconds> resample(frame_ptr input_frame) {

        frame_ptr resampled_frame{av_frame_alloc(), [](AVFrame *p) { av_frame_free(&p); }};
        av_frame_copy_props(resampled_frame.get(), input_frame.get());

        resampled_frame->sample_rate = sr;
        resampled_frame->channel_layout = l;
        resampled_frame->format = f;

        int64_t input_pts = input_frame->pts * (sr * input_frame->sample_rate) / 1'000'000;
        std::chrono::microseconds next_pts{  swr_next_pts(sc.get(), input_pts) * 1'000'000 / (sr * input_frame->sample_rate) };

        int ret = swr_convert_frame(sc.get(), resampled_frame.get(), input_frame.get());

        std::vector<double> frame(resampled_frame->nb_samples, 0);
        for (int i = 0; i < frame.size(); ++i) {
            frame[i] = *reinterpret_cast<double*>(&resampled_frame->data[0][i * av_get_bytes_per_sample(f)]);
        }

        return {frame, next_pts};
    }

private:
    size_t sr;
    uint32_t l;
    AVSampleFormat f;
    std::unique_ptr<SwrContext, std::function<void(SwrContext *)>> sc;
};

class video_resample_t {
public:
    video_resample_t(size_t width, size_t height, AVPixelFormat format, size_t w, size_t h)
        : w(w)
        , h(h)
        , f(AV_PIX_FMT_GRAY8)
        , sc{sws_getContext(width, height, format,
                            w, h, f,
                            SWS_BILINEAR, NULL, NULL, NULL), sws_freeContext} {
    }

    dlib::array2d<uint8_t> resample(frame_ptr frame) {

        frame_ptr out({av_frame_alloc(), [](AVFrame *p) { av_frame_free(&p); }});

        av_frame_copy_props(out.get(), frame.get());
        out->width = w;
        out->height = h;
        out->format = f;

        int ret = av_frame_get_buffer(out.get(), 0);

        int height = sws_scale(sc.get(), (const uint8_t *const *) frame->data, frame->linesize, 0, frame->height, out->data, out->linesize);

        dlib::array2d<uint8_t> picture(h, w);
        for (int i = 0; i < h; ++i) {
            for (int j = 0; j < w; ++j) {
                picture[i][j] = out->data[0][i * out->linesize[0] + j];
            }
        }

        return picture;
    }

private:
    size_t w;
    size_t h;
    AVPixelFormat f;
    std::unique_ptr<SwsContext, decltype(&sws_freeContext)> sc;
};


