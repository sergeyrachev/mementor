
#include <chrono>
#include <mutex>
#include <condition_variable>
#include <functional>

class interruption_t {
public:
    bool done();
    void wait(const std::chrono::milliseconds& delay);
    void interrupt();
    void notify(const std::function<void()>&);

private:
    std::mutex guard;
    std::condition_variable condition;
    bool has_signaled{false};
    std::function<void()> handler{[]{}};
};


