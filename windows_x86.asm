; -*- tab-width: 8 -*-
; nasm -f bin -O9 windows_x86.asm -o hello.exe

BITS 32
ORG 0
section .text

_mz_header:
db 'MZ'	; magic
dw 0, 0, 0, 0, 0, 0, 0
dw 0, 0, 0, 0, 0, 0, 0, 0
dw 0, 0, 0, 0, 0, 0, 0, 0
dw 0, 0, 0, 0, 0, 0
dd _pe_header - _mz_header

%define _image_base 0x400000
%define RVA(x) ((x - _text) + 0x1000)
%define VA(x) ((x - _text) + 0x1000 + _image_base)

_pe_header:
db 'PE',0,0
dw 0x14c	; i386
dw 1		; number of sections
dd 0		; time stamp
dd 0, 0		; symbol table (offset, count)
; size of optional header
dw _opt_header_end - _opt_header
dw 0x22e	; characteristics
_opt_header:
dw 0x10b	; magic
db 2, 25	; linker version (major, minor)
dd _text_end - _text		; size of code
dd 0		; size of initialized data
dd 0		; size of uninitialized data
dd RVA(_start)	; entry point
dd 0x1000	; base of code
dd 0		; base of data
dd _image_base	; image base
dd 0x1000	; section alignment
dd 0x200	; file alignment
dw 1, 0		; OS version (major, minor)
dw 0, 0		; image version (major, minor)
dw 4, 0		; subsystem version (major, minor)
dd 0		; Win32 version
dd ((_text_end - _text + 0xfff) & -0x1000) + 0x1000	; size of image
dd _text - _mz_header	; size of header
dd 0		; checksum
dw 3		; subsystem (1 - native, 2 - GUI, 3 - console)
dw 0		; DLL flag
dd 1 << 20, 0x1000	; stack reserve and commit
dd 1 << 20, 0x1000	; heap reserve and commit
dd 0		; loader flags
dd 2		; number of dirs

dd 0, 0		; export
dd RVA(_import), _import_end - _import
_opt_header_end:

db ".text",0,0,0
; virtual size and address
dd 0x1000, 0x1000
; file size and address
dd _text_end - _text, _text - _mz_header
dd 0, 0	; relocs, linenumbers
dw 0, 0	; relocs count, linenumbers count
dd 0x60000060	; attributes

align 512, db 0
_text:

_import:
	dd 0, 0, 0, RVA(_name_kernel32), RVA(_kernel32_tab)
	dd 0, 0, 0, 0, 0
_import_end:

align 8, db 0
_kernel32_tab:
	dd RVA(_name_ExitProcess)
	dd RVA(_name_VirtualAlloc)
	dd RVA(_name_ReadFile)
	dd RVA(_name_WriteFile)
	dd RVA(_name_GetStdHandle)
	dd 0

%macro def_export 1
align 2, db 0
_name_%1:
dw 0
%defstr export_temp %1
db export_temp, 0
%xdefine %1 dword [VA(_kernel32_tab)+export_next]
%assign export_next export_next+4
%endmacro

_name_kernel32:
db "kernel32.dll", 0

%assign export_next 0
def_export ExitProcess
def_export VirtualAlloc
def_export ReadFile
def_export WriteFile
def_export GetStdHandle

_hello:	db `Hello, World!\n`
_hello_len equ $ - _hello

_start:
	push	-11	; STD_OUTPUT_HANDLE
	call	GetStdHandle

	push	0	; lpOverlapped
	push	0	; lpNumberOfBytesWritten
	push	_hello_len
	push	VA(_hello)
	push	eax	; hFile
	call	WriteFile

	push	0
	call	ExitProcess

align 512, db 0
_text_end:

