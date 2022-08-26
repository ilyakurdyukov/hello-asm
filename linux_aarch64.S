// -*- tab-width: 8 -*-
// cc linux_aarch64.S -c -o hello.o && objcopy -O binary hello.o hello && chmod +x hello

	.arch armv8-a
	.text

#ifndef PIE
#define PIE 1
#endif

// args: x8 x0 x1 x2 x3 x4 x5
// ret: x0

#define SYS_read 63
#define SYS_write 64
#define SYS_exit 93
#define SYS_mmap 222

#if PIE
#define _base _elf
#else
#define _base (_elf - 0x400000)
#endif

_code_seg:
_elf:	.byte 0x7f
	.ascii "ELF"
	.byte 2,1,1,0		// e_ident
	.xword 0
	.hword 2 + PIE		// e_type
	.hword 183		// e_machine (EM_AARCH64)
	.word 1			// e_version
	.xword _start - _base	// e_entry
	.xword .ph - _elf	// e_phoff
	.xword 0		// e_shoff
	.word 0			// e_flags
	.hword 0x40		// e_ehsize
	.hword 0x38, 1		// e_phentsize, e_phnum
	.hword 0x40, 0		// e_shentsize, e_shnum
	.hword 0		// e_shstrndx
.ph:	.word 1, 5		// p_type, p_flags
	.xword 0		// p_offset
	.xword _code_seg - _base	// p_vaddr
	.xword _code_seg - _base	// p_paddr
	.xword _code_end - _code_seg	// p_filesz
	.xword _code_end - _code_seg	// p_memsz
	.xword 0x1000			// p_align

_hello:	.ascii "Hello, World!\n"
_hello_len = . - _hello

	.align 2
_start:
	mov	w2, _hello_len
#if PIE
	adr	x1, _hello
#else
	ldr	x1, = _hello - _base
#endif
	mov	w0, 1		// stdout
	mov	w8, SYS_write
	svc	0

	mov	w0, 0
	mov	w8, SYS_exit
	svc	0
_code_end:

