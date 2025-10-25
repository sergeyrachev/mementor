#pragma once

#include "mementor/http_error_code.h"

#include <map>
#include <string>

namespace http{
    struct response_t {
        status_code_t code;
        std::string body;
        std::map<std::string, std::string> headers;
    };
}
