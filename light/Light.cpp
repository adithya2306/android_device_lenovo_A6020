/*
 * Copyright (C) 2017 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Author := dev_harsh1998 and ghostrider-reborn

#define LOG_TAG "LightService-A6020"
#include <log/log.h>
#include "Light.h"
#include <fstream>

#define LEDS            "/sys/class/leds/"
#define LCD_LED         LEDS "lcd-backlight/"
#define GREEN_LED       LEDS "green/"
#define RED_LED         LEDS "red/"
#define BRIGHTNESS      "brightness"

namespace {

/*
 * Write value to path and close file.
 */
static void set(std::string path, std::string value) {
    std::ofstream file(path);

    if (!file.is_open()) {
        ALOGE("failed to write %s to %s", value.c_str(), path.c_str());
        return;
    }

    file << value;
}

static void set(std::string path, int value) {
    set(path, std::to_string(value));
}

static void handleBacklight(Type, const LightState& state) {
    uint32_t color = state.color & 0x00ffffff;
    uint32_t brightness = ((77 * ((color >> 16) & 0xff))
            + (150 * ((color >> 8) & 0xff))
            + (29 * (color & 0xff))) >> 8;

    set(LCD_LED BRIGHTNESS, brightness);
}

static void setNotification(const LightState& state) {
    uint32_t redBrightness, greenBrightness, brightness;

    /*
     * Extract brightness from AARRGGBB.
     */
    redBrightness = (state.color >> 16) & 0xFF;
    greenBrightness = (state.color >> 8) & 0xFF;

    brightness = (state.color >> 24) & 0xFF;

    /*
     * Scale RGB brightness if the Alpha brightness is not 0xFF.
     */
    if (brightness != 0xFF) {
        redBrightness = (redBrightness * brightness) / 0xFF;
        greenBrightness = (greenBrightness * brightness) / 0xFF;
    }

    set(GREEN_LED BRIGHTNESS, greenBrightness);
    set(RED_LED BRIGHTNESS, redBrightness);
}

static inline bool isLit(const LightState& state) {
    return state.color & 0x00ffffff;
}

/*
 * Keep sorted in the order of importance.
 */
static const LightState offState = {};
static std::vector<std::pair<Type, LightState>> notificationStates = {
    { Type::ATTENTION, offState },
    { Type::NOTIFICATIONS, offState },
    { Type::BATTERY, offState },
};

static void handleNotification(Type type, const LightState& state) {
    for(auto it : notificationStates) {
        if (it.first == type) {
            it.second = state;
        }

        if  (isLit(it.second)) {
            setNotification(it.second);
            return;
        }
    }

    setNotification(offState);
}

static std::map<Type, std::function<void(Type type, const LightState&)>> lights = {
    { Type::ATTENTION, handleNotification },
    { Type::NOTIFICATIONS, handleNotification },
    { Type::BATTERY, handleNotification },
    { Type::BACKLIGHT, handleBacklight },
};

} // anonymous namespace

namespace android {
namespace hardware {
namespace light {
namespace V2_0 {
namespace implementation {

Return<Status> Light::setLight(Type type, const LightState& state) {
    auto it = lights.find(type);

    if (it == lights.end()) {
        return Status::LIGHT_NOT_SUPPORTED;
    }

    /*
     * Lock global mutex until light state is updated.
    */

    std::lock_guard<std::mutex> lock(globalLock);
    it->second(type, state);
    return Status::SUCCESS;
}

Return<void> Light::getSupportedTypes(getSupportedTypes_cb _hidl_cb) {
    std::vector<Type> types;

    for (auto const& light : lights) types.push_back(light.first);

    _hidl_cb(types);

    return Void();
}

}  // namespace implementation
}  // namespace V2_0
}  // namespace light
}  // namespace hardware
}  // namespace android
