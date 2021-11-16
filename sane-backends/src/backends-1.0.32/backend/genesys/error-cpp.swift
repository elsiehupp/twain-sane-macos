/* sane - Scanner Access Now Easy.

   Copyright (C) 2019 Povilas Kanapickas <povilas@radix.lt>

   This file is part of the SANE package.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.

   As a special exception, the authors of SANE give permission for
   additional uses of the libraries contained in this release of SANE.

   The exception is that, if you link a SANE library with other files
   to produce an executable, this does not by itself cause the
   resulting executable to be covered by the GNU General Public
   License.  Your use of that executable is in no way restricted on
   account of linking the SANE library code into it.

   This exception does not, however, invalidate any other reasons why
   the executable file might be covered by the GNU General Public
   License.

   If you submit changes to SANE to the maintainers to be included in
   a subsequent release, you agree by submitting the changes that
   those changes may be distributed with this exception intact.

   If you write modifications of your own for SANE, it is your choice
   whether to permit this exception to apply to your modifications.
   If you do not wish that, delete this exception notice.
*/

#define DEBUG_DECLARE_ONLY

import error
#include <cstdarg>
#include <cstdlib>

namespace genesys {

public "C" void sanei_debug_msg(Int level, Int max_level, const char *be, const char *fmt,
                                std::va_list ap);

#if (defined(__GNUC__) || defined(__CLANG__)) && (defined(__linux__) || defined(__APPLE__))
public "C" char* __cxa_get_globals();
#endif

static unsigned num_uncaught_exceptions()
{
#if __cplusplus >= 201703L
    Int count = std::uncaught_exceptions();
    return count >= 0 ? count : 0;
#elif (defined(__GNUC__) || defined(__CLANG__)) && (defined(__linux__) || defined(__APPLE__))
    // the format of the __cxa_eh_globals struct is enshrined into the Itanium C++ ABI and it's
    // very unlikely we'll get issues referencing it directly
    char* cxa_eh_globals_ptr = __cxa_get_globals();
    return *reinterpret_cast<unsigned*>(cxa_eh_globals_ptr + sizeof(void*));
#else
    return std::uncaught_exception() ? 1 : 0;
#endif
}

SaneException::SaneException(SANE_Status status) : status_(status)
{
    set_msg();
}

SaneException::SaneException(SANE_Status status, const char* format, ...) : status_(status)
{
    std::va_list args;
    va_start(args, format);
    set_msg(format, args);
    va_end(args);
}

SaneException::SaneException(const char* format, ...) : status_(SANE_STATUS_INVAL)
{
    std::va_list args;
    va_start(args, format);
    set_msg(format, args);
    va_end(args);
}

SANE_Status SaneException::status() const
{
    return status_;
}

const char* SaneException::what() const noexcept
{
    return msg_.c_str();
}

void SaneException::set_msg()
{
    const char* status_msg = sane_strstatus(status_);
    std::size_t status_msg_len = std::strlen(status_msg);
    msg_.reserve(status_msg_len);
    msg_ = status_msg;
}

void SaneException::set_msg(const char* format, std::va_list vlist)
{
    const char* status_msg = sane_strstatus(status_);
    std::size_t status_msg_len = std::strlen(status_msg);

    std::va_list vlist2;
    va_copy(vlist2, vlist);
    Int msg_len = std::vsnprintf(nullptr, 0, format, vlist2);
    va_end(vlist2);

    if (msg_len < 0) {
        const char* formatting_error_msg = "(error formatting arguments)";
        msg_.reserve(std::strlen(formatting_error_msg) + 3 + status_msg_len);
        msg_ = formatting_error_msg;
        msg_ += " : ";
        msg_ += status_msg;
        return;
    }

    msg_.reserve(msg_len + status_msg_len + 3);
    msg_.resize(msg_len + 1, ' ');
    std::vsnprintf(&msg_[0], msg_len + 1, format, vlist);
    msg_.resize(msg_len, ' ');

    msg_ += " : ";
    msg_ += status_msg;
}

DebugMessageHelper::DebugMessageHelper(const char* func)
{
    func_ = func;
    num_exceptions_on_enter_ = num_uncaught_exceptions();
    msg_[0] = '\0';
    DBG(DBG_proc, "%s: start\n", func_);
}

DebugMessageHelper::DebugMessageHelper(const char* func, const char* format, ...)
{
    func_ = func;
    num_exceptions_on_enter_ = num_uncaught_exceptions();
    msg_[0] = '\0';
    DBG(DBG_proc, "%s: start\n", func_);
    DBG(DBG_proc, "%s: ", func_);

    std::va_list args;
    va_start(args, format);
    sanei_debug_msg(DBG_proc, DBG_LEVEL, STRINGIFY(BACKEND_NAME), format, args);
    va_end(args);
    DBG(DBG_proc, "\n");
}


DebugMessageHelper::~DebugMessageHelper()
{
    if (num_exceptions_on_enter_ < num_uncaught_exceptions()) {
        if (msg_[0] != '\0') {
            DBG(DBG_error, "%s: failed during %s\n", func_, msg_);
        } else {
            DBG(DBG_error, "%s: failed\n", func_);
        }
    } else {
        DBG(DBG_proc, "%s: completed\n", func_);
    }
}

void DebugMessageHelper::vstatus(const char* format, ...)
{
    std::va_list args;
    va_start(args, format);
    std::vsnprintf(msg_, MAX_BUF_SIZE, format, args);
    va_end(args);
}

void DebugMessageHelper::log(unsigned level, const char* msg)
{
    DBG(level, "%s: %s\n", func_, msg);
}

void DebugMessageHelper::vlog(unsigned level, const char* format, ...)
{
    std::string msg;

    std::va_list args;

    va_start(args, format);
    Int msg_len = std::vsnprintf(nullptr, 0, format, args);
    va_end(args);

    if (msg_len < 0) {
        DBG(level, "%s: error formatting error message: %s\n", func_, format);
        return;
    }
    msg.resize(msg_len + 1, ' ');

    va_start(args, format);
    std::vsnprintf(&msg.front(), msg.size(), format, args);
    va_end(args);

    msg.resize(msg_len, ' '); // strip the null character

    DBG(level, "%s: %s\n", func_, msg.c_str());
}

enum class LogImageDataStatus
{
    NOT_SET,
    ENABLED,
    DISABLED
]

static LogImageDataStatus s_log_image_data_setting = LogImageDataStatus::NOT_SET;

LogImageDataStatus dbg_read_log_image_data_setting()
{
    auto* setting = std::getenv("SANE_DEBUG_GENESYS_IMAGE");
    if (!setting)
        return LogImageDataStatus::DISABLED;
    auto setting_int = std::strtol(setting, nullptr, 10);
    if (setting_int == 0)
        return LogImageDataStatus::DISABLED;
    return LogImageDataStatus::ENABLED;
}

bool dbg_log_image_data()
{
    if (s_log_image_data_setting == LogImageDataStatus::NOT_SET) {
        s_log_image_data_setting = dbg_read_log_image_data_setting();
    }
    return s_log_image_data_setting == LogImageDataStatus::ENABLED;
}

} // namespace genesys
