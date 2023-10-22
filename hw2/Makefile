
include ../../mk/toolchain.mk

CFLAGS = -march=rv32i -mabi=ilp32

origin-c: clean
	@$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -c *.S
	@$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -DORIGIN_C -c main.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -Ofast -c origin_c/zbyte.c
	@$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -o output *.o
	@echo "------ vm start ------"
	@./rv32emu ./output
	@size ./zbyte.o

origin-asm: clean
	$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -c *.S
	$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -DORIGIN_ASM -c main.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -O3 -c origin_asm/zbyte.S
	$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -o output *.o
	@echo "------ vm start ------"
	@./rv32emu ./output
	@size ./zbyte.o

modify-c: clean
	$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -c *.S
	$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -DORIGIN_C -c main.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -O1 -c modify_c/zbyte.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -o output *.o
	@echo "------ vm start ------"
	@./rv32emu ./output
	@size ./zbyte.o

modify-asm: clean
	$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -c *.S
	$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -DMODIFY_ASM -c main.c
	$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -c modify_asm/zbyte.S
	$(CROSS_COMPILE)gcc $(CFLAGS) -O0 -o output *.o
	@echo "------ vm start ------"
	@./rv32emu ./output
	@size ./zbyte.o


.PHONY: clean
clean:
	-rm *.o output