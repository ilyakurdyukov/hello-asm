// -*- tab-width: 8 -*-
// cc -march=armv7-a linux_arm.S -c -o hello.o && objcopy -O binary hello.o hello && chmod +x hello

	.arch armv7-a
	.text

#ifndef PIE
#define PIE 1
#endif

// args: r7 r0 r1 r2 r3 r4 r5
// ret: r0

#define SYS_exit 1
#define SYS_read 3
#define SYS_write 4
#define SYS_mmap2 192

#if PIE
#define _base _elf
#else
#define _base (_elf - 0x400000)
#endif

_code_seg:
_elf:	.byte 0x7f
	.ascii "ELF"
	.byte 1,1,1,0		// e_ident
	.word 0, 0
	.hword 2 + PIE		// e_type
	.hword 40		// e_machine (EM_ARM)
	.word 1			// e_version
	.word _start - _base	// e_entry
	.word .ph - _elf	// e_phoff
	.word 0			// e_shoff
	.word (5 << 24) + 0x200	// e_flags (abi=5, softfp)
	.hword 0x34		// e_ehsize
	.hword 0x20, 1		// e_phentsize, e_phnum
	.hword 0x28, 0		// e_shentsize, e_shnum
	.hword 0		// e_shstrndx
.ph:	.word 1			// p_type
	.word 0			// p_offset
	.word _code_seg - _base		// p_vaddr
	.word _code_seg - _base		// p_paddr
	.word _code_end - _code_seg	// p_filesz
	.word _code_end - _code_seg	// p_memsz
	.word 5, 0x1000			// p_flags, p_align

_hello:	.ascii "Hello, World!\n"
_hello_len = . - _hello

	.align 2
_start:
	mov	r2, $_hello_len
#if PIE
	adr	r1, _hello
#else
	ldr	r1, = _hello - _base
#endif
	mov	r0, $1		// stdout
	mov	r7, $SYS_write
	swi	$0

	mov	r0, $0
	mov	r7, $SYS_exit
	swi	$0
_code_end:

