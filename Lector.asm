.data
	filename: .asciiz "C:/Users/CamiloBena/Documents/Arqui Compu/prueba.txt"
	buffer: .space 4096 # 4KiB
	characters_start: .byte 0x20 # Código en hexadecimal del caracter de Inicio
	characters_end: .byte 0x7e # Código en hexadecimal del caracter Final
	error_open_message: .asciiz "Ocurrió un error al abrir el archivo"
	error_range_message: .asciiz "El archivo contiene carácteres fuera del rango permitido"
.text	

.globl main
main:
	la $t2, buffer
	li $t1, 0 # Contador
	jal load_txt
	j for_document
	
load_txt:
	li $v0, 13 # Syscall 13, open file
	la $a0, filename # Cargar dirección 
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


exit:
	li $v0, 10 # Código syscall para terminar un programa
	syscall

for_document:
	bge $t1, $s1, end_for
	
	lb $a0, 0($t2)
	li $v0, 11
	syscall
	
	# Incremento (visto en clase)
	addi $t1, $t1, 1 # i++
	addi $t2, $t2, 1	
	
	j for_document

handle_open:
	li $v0, 4 # Código syscall para imprimir un String
	la $a0, error_open_message # Cargamos dirección de memoria con el contenido del mensaje
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
