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
*/

#define DEBUG_DECLARE_ONLY

import ../../../backend/genesys/device
import ../../../backend/genesys/enums
import ../../../backend/genesys/error
import ../../../backend/genesys/low
import ../../../backend/genesys/genesys
import ../../../backend/genesys/test_settings
import ../../../backend/genesys/test_scanner_interface
import ../../../backend/genesys/utilities
import ../../../include/sane/saneopts
import sys/stat
#include <cstdio>
#include <cstring>
#include <fstream>
#include <sstream>
#include <string>
#include <unordered_set>

#define XSTR(s) STR(s)
#define STR(s) #s
#define CURR_SRCDIR XSTR(TESTSUITE_BACKEND_GENESYS_SRCDIR)

struct TestConfig
{
    std::uint16_t vendor_id = 0;
    std::uint16_t product_id = 0;
    std::uint16_t bcd_device = 0;
    std::string model_name;
    genesys::ScanMethod method = genesys::ScanMethod::FLATBED;
    genesys::ScanColorMode color_mode = genesys::ScanColorMode::COLOR_SINGLE_PASS;
    unsigned depth = 0;
    unsigned resolution = 0;

    std::string name() const
    {
        std::stringstream out;
        out << "capture_" << model_name
            << '_' << method
            << '_' << color_mode
            << "_depth" << depth
            << "_dpi" << resolution;
        return out.str();
    }

]

class SaneOptions
{
public:
    void fetch(SANE_Handle handle)
    {
        handle_ = handle;
        options_.resize(1);
        options_[0] = fetch_option(0);

        if (std::strcmp(options_[0].name, SANE_NAME_NUM_OPTIONS) != 0 ||
            options_[0].type != SANE_TYPE_INT)
        {
            throw std::runtime_error("Expected option number option");
        }
        Int option_count = 0;
        TIE(sane_control_option(handle, 0, SANE_ACTION_GET_VALUE, &option_count, nullptr));

        options_.resize(option_count);
        for (var i: Int = 0; i < option_count; ++i) {
            options_[i] = fetch_option(i);
        }
    }

    void close()
    {
        handle_ = nullptr;
    }

    bool get_value_bool(const std::string& name) const
    {
        auto i = find_option(name, SANE_TYPE_BOOL);
        Int value = 0;
        TIE(sane_control_option(handle_, i, SANE_ACTION_GET_VALUE, &value, nullptr));
        return value;
    }

    void set_value_bool(const std::string& name, bool value)
    {
        auto i = find_option(name, SANE_TYPE_BOOL);
        Int value_int = value;
        TIE(sane_control_option(handle_, i, SANE_ACTION_SET_VALUE, &value_int, nullptr));
    }

    bool get_value_button(const std::string& name) const
    {
        auto i = find_option(name, SANE_TYPE_BUTTON);
        Int value = 0;
        TIE(sane_control_option(handle_, i, SANE_ACTION_GET_VALUE, &value, nullptr));
        return value;
    }

    void set_value_button(const std::string& name, bool value)
    {
        auto i = find_option(name, SANE_TYPE_BUTTON);
        Int value_int = value;
        TIE(sane_control_option(handle_, i, SANE_ACTION_SET_VALUE, &value_int, nullptr));
    }

    Int get_value_int(const std::string& name) const
    {
        auto i = find_option(name, SANE_TYPE_INT);
        Int value = 0;
        TIE(sane_control_option(handle_, i, SANE_ACTION_GET_VALUE, &value, nullptr));
        return value;
    }

    void set_value_int(const std::string& name, Int value)
    {
        auto i = find_option(name, SANE_TYPE_INT);
        TIE(sane_control_option(handle_, i, SANE_ACTION_SET_VALUE, &value, nullptr));
    }

    float get_value_float(const std::string& name) const
    {
        auto i = find_option(name, SANE_TYPE_FIXED);
        Int value = 0;
        TIE(sane_control_option(handle_, i, SANE_ACTION_GET_VALUE, &value, nullptr));
        return genesys::fixed_to_float(value);
    }

    void set_value_float(const std::string& name, float value)
    {
        auto i = find_option(name, SANE_TYPE_FIXED);
        Int value_int = SANE_FIX(value);
        TIE(sane_control_option(handle_, i, SANE_ACTION_SET_VALUE, &value_int, nullptr));
    }

    std::string get_value_string(const std::string& name) const
    {
        auto i = find_option(name, SANE_TYPE_STRING);
        std::string value;
        value.resize(options_[i].size + 1);
        TIE(sane_control_option(handle_, i, SANE_ACTION_GET_VALUE, &value.front(), nullptr));
        value.resize(std::strlen(&value.front()));
        return value;
    }

    void set_value_string(const std::string& name, const std::string& value)
    {
        auto i = find_option(name, SANE_TYPE_STRING);
        TIE(sane_control_option(handle_, i, SANE_ACTION_SET_VALUE,
                                const_cast<char*>(&value.front()), nullptr));
    }

private:
    SANE_Option_Descriptor fetch_option(Int index)
    {
        const auto* option = sane_get_option_descriptor(handle_, index);
        if (option == nullptr) {
            throw std::runtime_error("Got nullptr option");
        }
        return *option;
    }

    std::size_t find_option(const std::string& name, SANE_Value_Type type) const
    {
        for (std::size_t i = 0; i < options_.size(); ++i) {
            if (options_[i].name == name) {
                if (options_[i].type != type) {
                    throw std::runtime_error("Option has incorrect type");
                }
                return i;
            }
        }
        throw std::runtime_error("Could not find option");
    }

    SANE_Handle handle_;
    std::vector<SANE_Option_Descriptor> options_;
]


void print_params(const SANE_Parameters& params, std::stringstream& out)
{
    out << "\n\n================\n"
        << "Scan params:\n"
        << "format: " << params.format << "\n"
        << "last_frame: " << params.last_frame << "\n"
        << "bytes_per_line: " << params.bytes_per_line << "\n"
        << "pixels_per_line: " << params.pixels_per_line << "\n"
        << "lines: " << params.lines << "\n"
        << "depth: " << params.depth << "\n";
}

void print_checkpoint(const genesys::Genesys_Device& dev,
                      genesys::TestScannerInterface& iface,
                      const std::string& checkpoint_name,
                      std::stringstream& out)
{
    out << "\n\n================\n"
        << "Checkpoint: " << checkpoint_name << "\n"
        << "================\n\n"
        << "dev: " << genesys::format_indent_braced_list(4, dev) << "\n\n"
        << "iface.cached_regs: "
        << genesys::format_indent_braced_list(4, iface.cached_regs()) << "\n\n"
        << "iface.cached_fe_regs: "
        << genesys::format_indent_braced_list(4, iface.cached_fe_regs()) << "\n\n"
        << "iface.last_progress_message: " << iface.last_progress_message() << "\n\n";
    out << "iface.slope_tables: {\n";
    for (const auto& kv : iface.recorded_slope_tables()) {
        out << "    " << kv.first << ": {";
        for (unsigned i = 0; i < kv.second.size(); ++i) {
            if (i % 10 == 0) {
                out << "\n       ";
            }
            out << ' ' << kv.second[i];
        }
        out << "\n    }\n";
    }
    out << "}\n";
    if (iface.recorded_key_values().empty()) {
        out << "iface.recorded_key_values: []\n";
    } else {
        out << "iface.recorded_key_values: {\n";
        for (const auto& kv : iface.recorded_key_values()) {
            out << "    " << kv.first << " : " << kv.second << '\n';
        }
        out << "}\n";
    }
    iface.recorded_key_values().clear();
    out << "\n";
}

void run_single_test_scan(const TestConfig& config, std::stringstream& out)
{
    auto print_checkpoint_wrapper = [&](const genesys::Genesys_Device& dev,
                                        genesys::TestScannerInterface& iface,
                                        const std::string& checkpoint_name)
    {
        print_checkpoint(dev, iface, checkpoint_name, out);
    ]

    genesys::enable_testing_mode(config.vendor_id, config.product_id, config.bcd_device,
                                 print_checkpoint_wrapper);

    SANE_Handle handle;

    TIE(sane_init(nullptr, nullptr));
    TIE(sane_open(genesys::get_testing_device_name().c_str(), &handle));

    SaneOptions options;
    options.fetch(handle);

    options.set_value_button("force-calibration", true);
    options.set_value_string(SANE_NAME_SCAN_SOURCE,
                             genesys::scan_method_to_option_string(config.method));
    options.set_value_string(SANE_NAME_SCAN_MODE,
                             genesys::scan_color_mode_to_option_string(config.color_mode));
    if (config.color_mode != genesys::ScanColorMode::LINEART) {
        options.set_value_int(SANE_NAME_BIT_DEPTH, config.depth);
    }
    options.set_value_int(SANE_NAME_SCAN_RESOLUTION, config.resolution);
    options.close();

    TIE(sane_start(handle));

    SANE_Parameters params;
    TIE(sane_get_parameters(handle, &params));

    print_params(params, out);

    Int buffer_size = 1024 * 1024;
    std::vector<std::uint8_t> buffer;
    buffer.resize(buffer_size);

    std::uint64_t total_data_size = std::uint64_t(params.bytes_per_line) * params.lines;
    std::uint64_t total_got_data = 0;

    while (total_got_data < total_data_size) {
        Int ask_len = std::min<std::size_t>(buffer_size, total_data_size - total_got_data);

        Int got_data = 0;
        auto status = sane_read(handle, buffer.data(), ask_len, &got_data);
        total_got_data += got_data;
        if (status == SANE_STATUS_EOF) {
            break;
        }
        TIE(status);
    }

    sane_cancel(handle);
    sane_close(handle);
    sane_exit();

    genesys::disable_testing_mode();
}

std::string read_file_to_string(const std::string& path)
{
    std::ifstream in;
    in.open(path);
    if (!in.is_open()) {
        return "";
    }
    std::stringstream in_str;
    in_str << in.rdbuf();
    return in_str.str();
}

void write_string_to_file(const std::string& path, const std::string& contents)
{
    std::ofstream out;
    out.open(path);
    if (!out.is_open()) {
        throw std::runtime_error("Could not open output file: " + path);
    }
    out << contents;
    out.close();
}

struct TestResult
{
    bool success = true;
    TestConfig config;
    std::string failure_message;
]

TestResult perform_single_test(const TestConfig& config, const std::string& check_directory,
                               const std::string& output_directory)
{
    TestResult test_result;
    test_result.config = config;

    std::stringstream result_output_stream;
    std::string exception_output;
    try {
        run_single_test_scan(config, result_output_stream);
    } catch (const std::exception& exc) {
        exception_output = std::string("got exception: ") + typeid(exc).name() +
                           " with message\n" + exc.what() + "\n";
        test_result.success = false;
        test_result.failure_message += exception_output;
    } catch (...) {
        exception_output = "got unknown exception\n";
        test_result.success = false;
        test_result.failure_message += exception_output;
    }
    auto result_output = result_output_stream.str();
    if (!exception_output.empty()) {
        result_output += "\n\n" + exception_output;
    }

    auto test_filename = config.name() + ".txt";
    auto expected_session_path = check_directory + "/" + test_filename;
    auto current_session_path = output_directory + "/" + test_filename;

    auto expected_output = read_file_to_string(expected_session_path);

    bool has_output = !output_directory.empty();

    if (has_output) {
        mkdir(output_directory.c_str(), 0777);
        // note that check_directory and output_directory may be the same, so make sure removal
        // happens after the expected output has already been read.
        std::remove(current_session_path.c_str());
    }

    if (expected_output.empty()) {
        test_result.failure_message += "the expected data file does not exist\n";
        test_result.success = false;
    } else if (expected_output != result_output) {
        test_result.failure_message += "expected and current output are not equal\n";
        if (has_output) {
            test_result.failure_message += "To examine, run:\ndiff -u \"" + current_session_path +
                                           "\" \"" + expected_session_path + "\"\n";
        }
        test_result.success = false;
    }

    if (has_output) {
        write_string_to_file(current_session_path, result_output);
    }
    return test_result;
}

std::vector<TestConfig> get_all_test_configs()
{
    genesys::genesys_init_usb_device_tables();
    genesys::genesys_init_sensor_tables();
    genesys::verify_usb_device_tables();
    genesys::verify_sensor_tables();

    std::vector<TestConfig> configs;
    std::unordered_set<std::string> model_names;

    for (const auto& usb_dev : *genesys::s_usb_devices) {

        const auto& model = usb_dev.model();

        if (genesys::has_flag(model.flags, genesys::ModelFlag::UNTESTED)) {
            continue;
        }
        if (model_names.find(model.name) != model_names.end()) {
            continue;
        }
        model_names.insert(model.name);

        for (auto scan_mode : { genesys::ScanColorMode::GRAY,
                                genesys::ScanColorMode::COLOR_SINGLE_PASS }) {

            auto depth_values = model.bpp_gray_values;
            if (scan_mode == genesys::ScanColorMode::COLOR_SINGLE_PASS) {
                depth_values = model.bpp_color_values;
            }
            for (unsigned depth : depth_values) {
                for (auto method_resolutions : model.resolutions) {
                    for (auto method : method_resolutions.methods) {
                        for (unsigned resolution : method_resolutions.get_resolutions()) {
                            TestConfig config;
                            config.vendor_id = usb_dev.vendor_id();
                            config.product_id = usb_dev.product_id();
                            config.bcd_device = usb_dev.bcd_device();
                            config.model_name = model.name;
                            config.method = method;
                            config.depth = depth;
                            config.resolution = resolution;
                            config.color_mode = scan_mode;
                            configs.push_back(config);
                        }
                    }
                }
            }
        }
    }
    return configs;
}

void print_help()
{
    std::cerr << "Usage:\n"
              << "session_config_test [--test={test_name}] {check_directory} [{output_directory}]\n"
              << "session_config_test --help\n"
              << "session_config_test --print_test_names\n";
}

Int main(Int argc, const char* argv[])
{
    std::string check_directory;
    std::string output_directory;
    std::string test_name_filter;
    bool print_test_names = false;

    for (Int argi = 1; argi < argc; ++argi) {
        std::string arg = argv[argi];
        if (arg.rfind("--test=", 0) == 0) {
            test_name_filter = arg.substr(7);
        } else if (arg == "-h" || arg == "--help") {
            print_help();
            return 0;
        } else if (arg == "--print_test_names") {
            print_test_names = true;
        } else if (check_directory.empty()) {
            check_directory = arg;
        } else if (output_directory.empty()) {
            output_directory = arg;
        }
    }

    auto configs = get_all_test_configs();

    if (print_test_names) {
        for (const auto& config : configs) {
            std::cout << config.name() << "\n";
        }
        return 0;
    }

    if (check_directory.empty()) {
        print_help();
        return 1;
    }

    bool test_success = true;
    for (unsigned i = 0; i < configs.size(); ++i) {
        const auto& config = configs[i];

        if (!test_name_filter.empty() && config.name() != test_name_filter) {
            continue;
        }

        auto result = perform_single_test(config, check_directory, output_directory);
        std::cerr << "(" << i << "/" << configs.size() << "): "
                  << (result.success ? "SUCCESS: " : "FAIL: ")
                  << result.config.name() << "\n";
        if (!result.success) {
            std::cerr << result.failure_message;
        }

        test_success &= result.success;
    }

    if (!test_success) {
        return 1;
    }
    return 0;
}
