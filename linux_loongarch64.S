# -*- tab-width: 8 -*-
# Lots of hacks because the assembler is so dumb that it can't calculate the distance between labels during assembly.
# cc -nostartfiles -no-pie -Wl,--build-id=none linux_loongarch64.S -o hello.o && objcopy -O binary hello.o hello && chmod +x hello

	.text

#ifndef PIE
#define PIE 1
#endif

#define SYS_read 63
#define SYS_write 64
#define SYS_exit 93
#define SYS_mmap 222

#if PIE
#define _base _elf
#else
#define _base (_elf - 0x400000)
#endif

	# this is important for pc_hi20/pc_lo12 to work correctly
	.p2align 12, 0

_code_seg:
_elf:	.byte 0x7f
	.ascii "ELF"
	.byte 2,1,1,0		# e_ident
	.dword 0
	.half 2 + PIE		# e_type
	.half 258		# e_machine (EM_LOONGARCH)
	.word 1			# e_version
	.dword _start - _base	# e_entry
	.dword .ph - _elf	# e_phoff
	.dword 0		# e_shoff
	.word 0			# e_flags
	.half 0x40		# e_ehsize
	.half 0x38, 1		# e_phentsize, e_phnum
	.half 0x40, 0		# e_shentsize, e_shnum
	.half 0			# e_shstrndx
.ph:	.word 1, 5		# p_type, p_flags
	.dword 0		# p_offset
	.dword _code_seg - _base	# p_vaddr
	.dword _code_seg - _base	# p_paddr
	.dword _code_end - _code_seg	# p_filesz
	.dword _code_end - _code_seg	# p_memsz
	.dword 0x1000			# p_align

_hello:	.ascii "Hello, World!\n"
_hello_len = . - _hello

	.p2align 2, 0
	.globl _start
_start:
	addi.w		$a2, $r0, _hello_len

	pcalau12i	$a1, %pc_hi20(_hello)
	addi.d		$a1, $a1, %pc_lo12(_hello)

	addi.w  	$a0, $r0, 1	# stdout
	addi.w  	$a7, $r0, SYS_write
	syscall		0

	or  		$a0, $r0, $r0
	addi.w  	$a7, $r0, SYS_exit
	syscall		0
_code_end:

