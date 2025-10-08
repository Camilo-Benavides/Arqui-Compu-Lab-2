.data
	filename: .asciiz "./test.txt"
	buffer: .space 4096 # 4KiB
	characters_start: .word 0x20 # Codigo en hexadecimal del caracter de Inicio
	characters_end: .word 0x7e # Codigo en hexadecimal del caracter Final
	error_open_message: .asciiz "Ocurrio un error al abrir el archivo"
	error_range_message: .asciiz "El archivo contiene carácteres fuera del rango permitido"
#	lf_code: .byte 0x0a
#	cr_code: .byte 0x0d
	caracters_range: 
.text	

.globl main
main:	
	li $t3, 0x0a
	li $t4, 0x0d
	lw $s2, characters_start
	lw $s3, characters_end
	la $t2, buffer
	li $t1, 0 # Contador
	jal load_txt
	j for_document
	
load_txt:
	li $v0, 13 # Syscall 13, open file
	la $a0, filename # Cargar direccion 
	li $a1, 0 # 
	syscall
	
	
	bltz $v0, handle_open
	
	move $s0, $v0
	
	li $v0, 14
	move $a0, $s0
	la $a1, buffer
	li $a2, 20
	syscall
	
	move $s1, $v0
	
	#li $v0, 4
	#la $a0, buffer
	#syscall
	
	jr $ra
#	li $v0, 16
#	move $a0, $t0
#	syscall
	
#	li $v0, 10
#	syscall

for_document:
	bge $t1, $s1, end_for
	
	lb $a0, 0($t2)
	
	beq $a0, $t3, character_valid
	
	beq $a0, $t4, character_valid
	
	blt $a0, $s2, handle_range_ascii_error

	bgt $a0, $s3, handle_range_ascii_error
	
	j character_valid
handle_open:
	li $v0, 4 # Codigo syscall para imprimir un String
	la $a0, error_open_message # Cargamos direccion de memoria con el contenido del mensaje
	syscall
	j exit # Saltamos a la salida del programa debido a un error
	
handle_range_ascii_error:
	li $v0, 4
	la $a0, error_range_message
	syscall
	j exit 
	
end_for: # Este es el cierre final del archivo, no el de arriba
	li $v0, 16
	move $a0, $v0
	syscall
	j exit
	
character_valid:
	li $v0, 11 
	syscall

	# Incremento (visto en clase)
	addi $t1, $t1, 1 # i++
	addi $t2, $t2, 1
		
	j for_document
	
exit:
	li $v0, 10 # Codigo syscall para terminar un programa
	syscall
