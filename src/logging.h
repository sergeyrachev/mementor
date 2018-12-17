#pragma once

#include "ostream"

#include <cstdint>
#include <string>
#include <sstream>

namespace logging{
    namespace impl{
        class accumulator{
        protected:
            accumulator() = default;
            virtual ~accumulator() = default;

        public:
            template<class V>
            void put(const V& v) const {
                _stream << v;
            }

        protected:
            std::string get() const {
                return std::move(_stream.str());
            }
        private:
            mutable std::ostringstream _stream;
        };

        template<class C, class V>
        const C& put(const C& c, const V& v){
            c.put(v);
            return c;
        };
    }

    class debug : public impl::accumulator{
    public:
        debug() = default;
        ~debug();
    };
    template<class V>
    const debug& operator<<(const debug &i, const V& v){
        return impl::put(i, v);
    }

    class error : public impl::accumulator{
    public:
        error() = default;
        ~error();
    };
    template<class V>
    const error& operator<<(const error &i, const V& v){
        return impl::put(i, v);
    }

    class info : public impl::accumulator{
    public:
        info() = default;
        ~info();
    };
    template<class V>
    const info& operator<<(const info &i, const V& v){
        return impl::put(i, v);
    }
}
