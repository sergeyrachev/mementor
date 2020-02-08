#pragma once

#include "logging.h"

namespace logging{
    class boost_sink_t: public logging::sink_t{
    public:
        void put(verbosity_t verbosity, const std::string &message) override;
    };

    using info = logging::info_tt<boost_sink_t>;
    using debug = logging::debug_tt<boost_sink_t>;
    using error = logging::error_tt<boost_sink_t>;
}
