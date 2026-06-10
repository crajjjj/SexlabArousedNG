#pragma once

#include <array>
#include <assert.h>
#include <cmath>

#define MAX_CIRCLE_ANGLE 512
#define HALF_MAX_CIRCLE_ANGLE (MAX_CIRCLE_ANGLE / 2)
#define QUARTER_MAX_CIRCLE_ANGLE (MAX_CIRCLE_ANGLE / 4)
#define MASK_MAX_CIRCLE_ANGLE (MAX_CIRCLE_ANGLE - 1)
#define PI 3.14159265358979323846f

// Must be an inline variable so every translation unit shares one table built at
// static initialization. An anonymous-namespace array gave each TU its own
// zero-initialized copy unless that TU also called the (now removed) build function.
inline const std::array<float, MAX_CIRCLE_ANGLE + 1> fast_cossin_table = [] {
    std::array<float, MAX_CIRCLE_ANGLE + 1> table{};
    for (int i = 0; i <= MAX_CIRCLE_ANGLE; i++) {
        table[i] = static_cast<float>(std::sin(static_cast<double>(i) * PI / HALF_MAX_CIRCLE_ANGLE));
    }
    return table;
}();

inline float fastcos(float n) {
    float f = n * HALF_MAX_CIRCLE_ANGLE / PI;
    int i = static_cast<int>(f);
    if (i < 0) {
        return fast_cossin_table[((-i) + QUARTER_MAX_CIRCLE_ANGLE) & MASK_MAX_CIRCLE_ANGLE];
    } else {
        return fast_cossin_table[(i + QUARTER_MAX_CIRCLE_ANGLE) & MASK_MAX_CIRCLE_ANGLE];
    }
}

inline float fastsin(float n) {
    float f = n * HALF_MAX_CIRCLE_ANGLE / PI;
    int i = static_cast<int>(f);
    if (i < 0) {
        int idx = (-((-i) & MASK_MAX_CIRCLE_ANGLE)) + MAX_CIRCLE_ANGLE;
        assert(idx >= 0 && idx <= MAX_CIRCLE_ANGLE);
        return fast_cossin_table[idx];
    } else {
        int idx = i & MASK_MAX_CIRCLE_ANGLE;
        assert(idx >= 0 && idx <= MAX_CIRCLE_ANGLE);
        return fast_cossin_table[idx];
    }
}
