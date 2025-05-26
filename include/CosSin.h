#pragma once

#include <assert.h>

#define MAX_CIRCLE_ANGLE 512
#define HALF_MAX_CIRCLE_ANGLE (MAX_CIRCLE_ANGLE / 2)
#define QUARTER_MAX_CIRCLE_ANGLE (MAX_CIRCLE_ANGLE / 4)
#define MASK_MAX_CIRCLE_ANGLE (MAX_CIRCLE_ANGLE - 1)
#define PI 3.14159265358979323846f


namespace {
    float fast_cossin_table[MAX_CIRCLE_ANGLE + 1];

    inline float fastcos(float n) {
        float f = n * HALF_MAX_CIRCLE_ANGLE / PI;
        int i = static_cast<int>(f);
        if (i < 0) {
            return fast_cossin_table[((-i) + QUARTER_MAX_CIRCLE_ANGLE) & MASK_MAX_CIRCLE_ANGLE];
        } else {
            return fast_cossin_table[(i + QUARTER_MAX_CIRCLE_ANGLE) & MASK_MAX_CIRCLE_ANGLE];
        }

        assert(0);
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

        assert(0);
    }

    inline void BuildSinCosTable() {
        long i;

        for (i = 0; i <= MAX_CIRCLE_ANGLE; i++) {
            fast_cossin_table[i] = (float)sin((double)i * PI / HALF_MAX_CIRCLE_ANGLE);
        }
    }
}

