// This is an open source non-commercial project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++ and C#: http://www.viva64.com
#include "logging_boost.h"

#include <boost/log/trivial.hpp>

void logging::boost_sink_t::put(logging::verbosity_t verbosity, const std::string &message) {
    switch (verbosity) {
        case verbosity_t::debug: {
            //BOOST_LOG_TRIVIAL(debug) << message;
            break;
        }
        case verbosity_t::info: {
            BOOST_LOG_TRIVIAL(info) << message;
            break;
        }
        case verbosity_t::error: {
            BOOST_LOG_TRIVIAL(error) << message;
            break;
        }
        default:
            assert(false && "No such verbosity level");
    }
}
