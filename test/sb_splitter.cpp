#include "source.h"
#include "version.h"
#include "birthday.h"
#include "logging.h"
#include "logging_boost.h"
#include "options.h"
#include "sighandler.h"

#include <string>
#include <iostream>
#include <csignal>

#include <boost/program_options.hpp>

int main(int argc, char *argv[]) {
    std::string media_filename;

    std::cout << std::string(argv[0]) << " :: " << version << " :: " << birthday << std::endl;
    namespace po = boost::program_options;
    po::options_description opt_desc("Options");
    opt_desc.add_options()
                ("help,h", "Produce this message")
                ("input-media,i", po::value(&media_filename)->required(), "Input media clip to detect A/V sync")
                ;

    logging::info::sink() = std::make_shared<logging::boost_sink_t>();

    po::positional_options_description pos_opt_desc;
    po::variables_map varmap;
    if (!options::is_args_valid(argc, argv, opt_desc, pos_opt_desc, varmap, std::cerr, std::cout)) {
        if (varmap.count("help") || varmap.empty()) {
            return 0;
        }
        return 1;
    }

    auto src = std::unique_ptr<source_t> {new source_t(
        media_filename,
        [](ffmpeg::frame_ptr au) {
            logging::info() << "Video: " << au->pts;
        },
        [](ffmpeg::frame_ptr au) {
            logging::info() << "Audio: " << au->pts;
        })};

    threads::interruption_t interruption;
    posix::sighandler_t<SIGINT>::assign([&interruption](int signal) { interruption.interrupt(); });
    posix::sighandler_t<SIGTERM>::assign([&interruption](int signal) { interruption.interrupt(); });

    src->run(interruption);
}
