#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern uint64_t get_cycles();
extern uint64_t get_instret();

/*
 * Taken from the Sparkle-suite which is a collection of lightweight symmetric
 * cryptographic algorithms currently in the final round of the NIST
 * standardization effort.
 * See https://sparkle-lwc.github.io/
 */
extern int16_t zbytel(long long input);
extern int16_t zbyte(int a, int b);
extern int16_t mzbyte(int a, int b);

int main(void)
{
    long long input = 0x1120304455007788;
    int ia = input & 0xFFFFFFFF, ib = (input >> 32) & 0xFFFFFFFF;
    int ans = 0;

    /* measure cycles */
    // printf("passing 2 var\n");
    uint64_t instret = get_instret();
    uint64_t oldcount = get_cycles();
#ifdef ORIGIN_C
    ans = zbytel(input);
#elif ORIGIN_ASM
    ans = zbyte(ia, ib);
#elif MODIFY_ASM
    ans = mzbyte(ia, ib);
#endif
    uint64_t cyclecount = get_cycles() - oldcount;
    printf("return val: %d\n", ans);
    printf("cycle count: %u\n", (unsigned int) cyclecount);
    printf("instret: %x\n", (unsigned) (instret & 0xffffffff));

    return 0;
}
