typedef long long int64_t;
typedef int int32_t;
typedef unsigned int uint32_t;

uint32_t count_leading_zeros(uint32_t x) {
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);

    /* count ones (population count) */
    x -= ((x >> 1) & 0x55555555);
    x = ((x >> 2) & 0x33333333) + (x & 0x33333333);
    x = ((x >> 4) + x) & 0x0f0f0f0f;
    x += (x >> 8);
    x += (x >> 16);

    return (32 - (x & 0x7f));
}

static inline int64_t getbit(int64_t value, int n) { return (value >> n) & 1; }
/* 24 bit mantissa multiply */
static int32_t imul24(int32_t a, int32_t b) {
    uint32_t r = 0;
    for (; b; b >>= 1)
        r = (r >> 1) + (a & -getbit(b, 0));
    return r;
}

/* float32 multiply */
float fmul32(float a, float b) {
    /* TODO: Special values like NaN and INF */
    int32_t ia = *(int32_t *)&a, ib = *(int32_t *)&b;
    if (ia == 0 || ib == 0) return 0;

    /* mantissa */
    int32_t ma = (ia & 0x7FFFFF) | 0x800000;
    int32_t mb = (ib & 0x7FFFFF) | 0x800000;

    int32_t sea = ia & 0xFF800000;
    int32_t seb = ib & 0xFF800000;

    /* result of mantissa */
    int32_t m = imul24(ma, mb);
    int32_t mshift = getbit(m, 24);
    m >>= mshift;

    int32_t r = ((sea - 0x3f800000 + seb) & 0xFF800000) +
                (m & (0x7fffff | mshift << 23));
    int32_t ovfl = (r ^ seb ^ sea) >> 31;
    r = r ^ ((r ^ 0x7f800000) & ovfl);
    return *(float *)&r;
}

/* 24 bit mantissa divide */
static int32_t idiv24(int32_t a, int32_t b) {
    uint32_t r = 0;
    for (int i = 0; i < 32; i++) {
        a -= b;
        r = (r << 1) | a >= 0;
        a = (a + (b & -(a < 0))) << 1;
    }

    return r;
}

float fdiv32(float a, float b) {
    int32_t ia = *(int32_t *)&a, ib = *(int32_t *)&b;
    if (a == 0) return a;
    if (b == 0) return *(float*)&(int){0x7f800000};
    /* mantissa */
    int32_t ma = (ia & 0x7FFFFF) | 0x800000;
    int32_t mb = (ib & 0x7FFFFF) | 0x800000;

    /* sign and exponent */
    int32_t sea = ia & 0xFF800000;
    int32_t seb = ib & 0xFF800000;

    /* result of mantissa */
    int32_t m = idiv24(ma, mb);
    int32_t mshift = !getbit(m, 31);
    m <<= mshift;

    int32_t r = ((sea - seb + 0x3f800000) - (0x800000 & -mshift)) |
                (m & 0x7fffff00) >> 8;
    int32_t ovfl = (sea ^ seb ^ r) >> 31;
    r = r ^ ((r ^ 0x7f800000) & ovfl);

    return *(float *)&r;
}

#define iswap(x, y) ((x) ^= (y), (y) ^= (x), (x) ^= (y))

float fadd32(float a, float b) {
    int32_t ia = *(int32_t *)&a, ib = *(int32_t *)&b;

    int32_t cmp_a = ia & 0x7fffffff;
    int32_t cmp_b = ib & 0x7fffffff;

    if (cmp_a < cmp_b)
        iswap(ia, ib);
    /* exponent */
    int32_t ea = (ia >> 23) & 0xff;
    int32_t eb = (ib >> 23) & 0xff;

    /* mantissa */
    int32_t ma = ia & 0x7fffff | 0x800000;
    int32_t mb = ib & 0x7fffff | 0x800000;

    int32_t align = (ea - eb > 24) ? 24 : (ea - eb);

    mb >>= align;
    if ((ia ^ ib) >> 31) {
        ma -= mb;
    } else {
        ma += mb;
    }

    int32_t clz = count_leading_zeros(ma);
    int32_t shift = 0;
    if (clz <= 8) {
        shift = 8 - clz;
        ma >>= shift;
        ea += shift;
    } else {
        shift = clz - 8;
        ma <<= shift;
        ea -= shift;
    }

    int32_t r = ia & 0x80000000 | ea << 23 | ma & 0x7fffff;
    float tr = a + b;
    return *(float *)&r;
}

int f2i32(float x) {
    int32_t a = *(int *)&x;
    int32_t ma = (a & 0x7FFFFF) | 0x800000;
    int32_t ea = ((a >> 23) & 0xFF) - 127;
    if (ea < 0)
        return 0;
    else if (ea <= 23)
        ma >>= (23 - ea);
    else
        ma <<= (ea - 23);

    return ma;
}

float i2f32(int x) {
    if (x == 0) return 0;

    int32_t s = x & 0x80000000;
    if (s) x = -x;

    int32_t clz = count_leading_zeros(x);
    int32_t e = 31 - clz + 127;

    if (clz <= 8) {
        x >>= 8 - clz;
    } else {
        x <<= clz - 8;
    }

    int r = s | e << 23 | x & 0x7fffff;
    return *(float *)&r;
}

float myPow(float x, int n) {
    float r = 1.0;
    while (n) {
        if (n & 0x1) {
            r = fmul32(r, x);
            n -= 1;
        } else {
            x = fmul32(x, x);
            n >>= 1;
        }
    }
    return r;
}

// n!
float factorial(int n) {
    float r = 1.0;
    for (int i = 1; i <= n; i++) {
        r = fmul32(r, i2f32(i));
    }
    return r;
}

// Sine by Taylor series
float mySin(float x) {
    float r = 0.0;
    for (int n = 0; n < 5;
         n++) {
        int k = f2i32(fadd32(fmul32(i2f32(2), i2f32(n)), i2f32(1)));
        int s = 1 ^ ((-2) & -(n & 0x1));
        r = fadd32(r, fdiv32(fmul32(i2f32(s), myPow(x, k)), factorial(k)));
    }
    return r;
}

#include <math.h>
#include <stdio.h>
int main() {
    float degree = 45.0;  // Angle in degrees
    float radians =
        degree * 3.14159265359 / 180.0;  // Convert degrees to radians

    float sinev = mySin(radians);  // Calculate sine
    float rs = sinf(radians);
    printf("%.10f\n%.10f\n", sinev, rs);
    return 0;
}
