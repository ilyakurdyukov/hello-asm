# -*- tab-width: 8 -*-
# cc -m64 linux_x86_64.S -c -o hello.o && objcopy -O binary hello.o hello && chmod +x hello

	.intel_syntax noprefix
	.text

#ifndef PIE
#define PIE 1
#endif

# args: rax rdi rsi rdx r10 r8 r9
# clobbers: rcx r10

#define SYS_read 0
#define SYS_write 1
#define SYS_mmap 9
#define SYS_exit 60

#if PIE
#define _base _elf
#else
#define _base (_elf - 0x400000)
#endif

_code_seg:
_elf:	.byte 0x7f
	.ascii "ELF"
	.byte 2,1,1,0		# e_ident
	.quad 0
	.short 2 + PIE		# e_type
	.short 62		# e_machine (EM_X86_64)
	.long 1			# e_version
	.quad _start - _base	# e_entry
	.quad .ph - _elf	# e_phoff
	.quad 0			# e_shoff
	.long 0			# e_flags
	.short 0x40		# e_ehsize
	.short 0x38, 1		# e_phentsize, e_phnum
	.short 0x40, 0		# e_shentsize, e_shnum
	.short 0		# e_shstrndx
.ph:	.long 1, 5		# p_type, p_flags
	.quad 0			# p_offset
	.quad _code_seg - _base		# p_vaddr
	.quad _code_seg - _base		# p_paddr
	.quad _code_end - _code_seg	# p_filesz
	.quad _code_end - _code_seg	# p_memsz
	.quad 0x1000			# p_align

_hello:	.ascii "Hello, World!\n"
_hello_len = . - _hello

	.align 8, 0
_start:
	mov	edx, _hello_len
#if PIE
	lea	rsi, [rip + _hello]
#else
	mov	esi, _hello - _base
#endif
	mov	edi, 1		# stdout
	mov	eax, SYS_write
	syscall

	xor	edi, edi
	mov	eax, SYS_exit
	syscall
_code_end:

