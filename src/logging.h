#pragma once

#include <cstdint>
#include <string>
#include <sstream>
#include <memory>

namespace logging{
    enum class verbosity_t{
        error,
        info,
        debug
    };

    class sink_t{
    public:
        virtual ~sink_t() = default;
        virtual void put(verbosity_t verbosity, const std::string& message){};
    };

    namespace impl{
        template<typename S = sink_t>
        class accumulator_tt{
        protected:
            accumulator_tt() = default;
            explicit accumulator_tt(verbosity_t level):level(level){};
            virtual ~accumulator_tt(){
                sink()->put(level, get());
            }

        public:
            template<class V>
            void put(const V& v) const {
                _stream << v;
            }

            static std::shared_ptr<S>& sink() {
                static std::shared_ptr<S> impl = std::make_shared<S>();
                return impl;
            }

        protected:
            std::string get() const {
                return std::move(_stream.str());
            }

        protected:
            verbosity_t level{verbosity_t::error};

        private:
            mutable std::ostringstream _stream;
        };

        template<class C, class V>
        const C& put(const C& c, const V& v){
            c.put(v);
            return c;
        };
    }

    template<typename S>
    class error_tt : public impl::accumulator_tt<S>{
    public:
        error_tt():impl::accumulator_tt<S>(verbosity_t::error){}
    };

    template<typename V, typename S>
    const error_tt<S>& operator<<(const error_tt<S> &i, const V& v){
        return impl::put(i, v);
    }

    template<typename S>
    class info_tt : public impl::accumulator_tt<S>{
    public:
        info_tt():impl::accumulator_tt<S>(verbosity_t::info){}
    };

    template<typename V, typename S>
    const info_tt<S>& operator<<(const info_tt<S> &i, const V& v){
        return impl::put(i, v);
    }

    template<typename S>
    class debug_tt : public impl::accumulator_tt<S>{
    public:
        debug_tt():impl::accumulator_tt<S>(verbosity_t::debug){}
    };

    template<typename V, typename S>
    const debug_tt<S>& operator<<(const debug_tt<S> &i, const V& v){
        return impl::put(i, v);
    }
}
