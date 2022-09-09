! -*- tab-width: 8 -*-
! cc -m128 -march=elbrus-v3 linux_e2k_128.S -c -o hello.o && objcopy -O binary hello.o hello && chmod +x hello
! cc -E linux_e2k_128.S -o hello.s && as -mptr128 -mcpu=elbrus-v3 hello.s -o hello.o && ...

	.ignore ld_st_style
	.ignore strict_delay
	.text

#ifndef PIE
#define PIE 1
#endif

! same as in x86_32
#define SYS_exit 1
#define SYS_read 3
#define SYS_write 4
#define SYS_mmap 90

#if PIE
#define _base _elf
#else
#define _base (_elf - 0x10000)
#endif

! ".align" doesn't allow to take the distance between the labels
.macro ALIGN n=8
	.zero (_elf - .) & (\n - 1)
.endm

#define CODE_VA(x) (x - _base + ((_rodata_end - _elf + 0xfff) & -0x1000))

_elf:	.byte 0x7f
	.ascii "ELF"
	.byte 2,1,1,0			! e_ident
	.uadword 0
	.uahalf 2 + PIE			! e_type
	.uahalf 175			! e_machine (EM_MCST_ELBRUS)
	.uaword 1			! e_version
	.uadword CODE_VA(_start)	! e_entry
	.uadword .ph - _elf		! e_phoff
	.uadword 0			! e_shoff
	.uaword (__iset__ << 24) | 0x60	! e_flags (min arch version)
	.uahalf 0x40			! e_ehsize
	.uahalf 0x38, 2			! e_phentsize, e_phnum
	.uahalf 0x40, 0			! e_shentsize, e_shnum
	.uahalf 0			! e_shstrndx
.ph:
	.uaword 1, 4			! p_type, p_flags
	.uadword 0			! p_offset
	.uadword _elf - _base		! p_vaddr
	.uadword _elf - _base		! p_paddr
	.uadword _rodata_end - _elf	! p_filesz
	.uadword _rodata_end - _elf	! p_memsz
	.uadword 0x1000			! p_align

	.uaword 1, 5			! p_type, p_flags
	.uadword 0			! p_offset
	.uadword CODE_VA(_elf) 		! p_vaddr
	.uadword CODE_VA(_elf)		! p_paddr
	.uadword _code_end - _elf	! p_filesz
	.uadword _code_end - _elf	! p_memsz
	.uadword 0x1000			! p_align

_hello:	.ascii "Hello, World!\n"
_hello_len = . - _hello
_rodata_end:

	ALIGN 8
_start:
	{
	  setwd wsz = 16, nfx = 1, dbl = 0
	  setbn rbs = 8, rsz = 7, rcur = 0
	}
	{
	  nop 4
	  sdisp %ctpr1, 8; ipd 2
	  addd 0, SYS_write, %b[0]
	  addd 0, 1, %b[2]
	  ! data cannot be read from the code segment
	  gdtoap _hello - _elf, %b[4]
	  addd 0, _hello_len, %b[6]
	}
	{
	  ! specifying the data size for the pointer
	  aptoapb %b[4], %b[6], %b[4]
	}
	{
	  call %ctpr1, wbs = 8; ipd 3
	}
	{
	  nop 4
	  sdisp %ctpr1, 8; ipd 2
	  addd 0, SYS_exit, %b[0]
	  addd 0, 0, %b[2]
	}
	{
	  call %ctpr1, wbs = 8; ipd 3
	}
_code_end:

