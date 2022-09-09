! -*- tab-width: 8 -*-
! cc -m32 -march=elbrus-v3 linux_e2k_32.S -c -o hello.o && objcopy -O binary hello.o hello && chmod +x hello

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

_code_seg:
_elf:	.byte 0x7f
	.ascii "ELF"
	.byte 1,1,1,0			! e_ident
	.uadword 0
	.uahalf 2 + PIE			! e_type
	.uahalf 175			! e_machine (EM_MCST_ELBRUS)
	.uaword 1			! e_version
	.uaword _start - _base		! e_entry
	.uaword .ph - _elf		! e_phoff
	.uaword 0			! e_shoff
	.uaword __iset__ << 24		! e_flags (min arch version)
	.uahalf 0x34			! e_ehsize
	.uahalf 0x20, 1			! e_phentsize, e_phnum
	.uahalf 0x28, 0			! e_shentsize, e_shnum
	.uahalf 0			! e_shstrndx
.ph:	.uaword 1			! p_type
	.uaword 0			! p_offset
	.uaword _code_seg - _base	! p_vaddr
	.uaword _code_seg - _base	! p_paddr
	.uaword _code_end - _code_seg	! p_filesz
	.uaword _code_end - _code_seg	! p_memsz
	.uaword 5, 0x1000		! p_flags, p_align

_hello:	.ascii "Hello, World!\n"
_hello_len = . - _hello

	ALIGN 8
_start:
	{
	  setwd wsz = 8, nfx = 1, dbl = 1
	  setbn rbs = 4, rsz = 3, rcur = 0
	}

#if PIE
_rrd:	{
	  rrd,0 %ip, %r0
	}
#endif

	{
	  nop 4
	  sdisp %ctpr1, 1; ipd 2
	  addd 0, SYS_write, %b[0]
	  addd 0, 1, %b[1]		! stdout
#if PIE
	  adds %r0, _hello - _rrd, %b[2]
#else
	  adds 0, _hello - _base, %b[2]
#endif
	  addd 0, _hello_len, %b[3]
	}
	{
	  call %ctpr1, wbs = 4; ipd 3
	}

	{
	  nop 4
	  sdisp %ctpr1, 1; ipd 2
	  addd 0, SYS_exit, %b[0]
	  addd 0, 0, %b[1]
	}
	{
	  call %ctpr1, wbs = 4; ipd 3
	}
_code_end:

