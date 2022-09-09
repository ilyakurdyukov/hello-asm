# -*- tab-width: 8 -*-
# cc -m32 linux_x86.s -c -o hello.o && objcopy -O binary hello.o hello && chmod +x hello
# as --32 linux_x86.s -o hello.o && ...

	.intel_syntax noprefix
	.text

.ifndef PIE
PIE = 1
.endif

# args: eax ebx ecx edx esi edi ebp
# ret: eax edx

SYS_exit = 1
SYS_read = 3
SYS_write = 4
SYS_mmap = 90

.if PIE
_base = _elf
.else
_base = _elf - 0x400000
.endif

_code_seg:
_elf:	.byte 0x7f
	.ascii "ELF"
	.byte 1,1,1,0		# e_ident
	.quad 0
	.short 2 + PIE		# e_type
	.short 3		# e_machine (EM_386)
	.long 1			# e_version
	.long _start - _base	# e_entry
	.long .ph - _elf	# e_phoff
	.long 0			# e_shoff
	.long 0			# e_flags
	.short 0x34		# e_ehsize
	.short 0x20, 1		# e_phentsize, e_phnum
	.short 0x28, 0		# e_shentsize, e_shnum
	.short 0		# e_shstrndx
.ph:	.long 1			# p_type
	.long 0			# p_offset
	.long _code_seg - _base		# p_vaddr
	.long _code_seg - _base		# p_paddr
	.long _code_end - _code_seg	# p_filesz
	.long _code_end - _code_seg	# p_memsz
	.long 5, 0x1000			# p_flags, p_align

_hello:	.ascii "Hello, World!\n"
_hello_len = . - _hello

	.align 8, 0
_start:

.if PIE
	call	_ip
_ip:	pop	ebp
.endif

	mov	edx, _hello_len
.if PIE
	lea	ecx, [ebp + (_hello - _ip)]
.else
	mov	ecx, _hello - _base
.endif
	mov	ebx, 1		# stdout
	mov	eax, SYS_write
	int	0x80

	xor	ebx, ebx
	mov	eax, SYS_exit
	int	0x80
_code_end:

