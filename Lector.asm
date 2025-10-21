.globl main

.data
	filename: .asciiz "C:/Users/CamiloBena/Documents/Arqui Compu/Practica 2/prueba.txt"
	output_filename: .asciiz "C:/Users/CamiloBena/Documents/Arqui Compu/Practica 2/rle_compress.bin"

	error_open_message: .asciiz "Ocurrio un error al abrir el archivo\n"
	error_range_message: .asciiz "El archivo contiene caracteres fuera del rango permitido\n"
	
	bad_compression_message: .asciiz "La compresión ha sido ineficiente"
	
	rc_message: .asciiz "RC: "
	space_msg: .asciiz " "
	newline: .asciiz "\n"

	buff_size: .word 4096
	buffer: .space 4096 # 4KiB
	buffer_compresion: .space 4100 # 4KiB + 4 bytes para checksum
	characters_start: .word 0x20 # Codigo en hexadecimal del caracter de Inicio
	characters_end: .word 0x7e # Codigo en hexadecimal del caracter Final
	
.text	
main:	
	li $t3, 0x0a		# Código Hexadecimal de LF
	li $t4, 0x0d		# Código Hexadecimal de CR
	lw $s2, characters_start	
	lw $s3, characters_end
	la $t2, buffer		
	la $t7, buffer_compresion
	addi $t7, $t7, 4		# Reservar 4 bytes al inicio para checksum
	la $t0, buffer_compresion
	addi $t0, $t0, 4		# Apuntar después del checksum
	li $t1, 0 				# Contador

	la $a0, filename		
	la $a2, buffer			
	la $a3, buff_size		
	jal open_and_read_file

	j for_document
	
	
#---------------------------------------------------------------------------------------------
# Procedimiento para abrir y leer el archivo de entrada
# int open_and_read_file(string filename, space buffer)
open_and_read_file:
	li $v0, 13 				# Syscall 13, open file
	li $a1, 0 				
	syscall
	
	bltz $v0, handle_open 	# Si v0 es negativo entonces indica que hubo un error abriendo el archivo
	
	move $s0, $v0
	
	li $v0, 14
	move $a0, $s0
	la $a1, ($a2)		# Loads the buffer in the arg for the syscall
	la $a2, ($a3)		# li $a2, 4096 	# Número máximo de bits a leer
	syscall
	
	move $s1, $v0 	# No. caracteres leidos
	
	# jr $ra 	# Sobraria ya que se llego usando jal

#-------------------------------------------------------------------------------------------------
# Procedimiento para calcular el checksum
calculate_checksum:
	li $s5, 0			# Inicializar suma en 0
	move $s6, $t0		# Copiar puntero inicial (después del checksum)
	
checksum_loop:
	bge $s6, $t7, end_checksum	# Si llegamos al final
	
	lb $s7, 0($s6)		# Leer byte
	add $s5, $s5, $s7		# Sumar al acumulador
	addi $s6, $s6, 1		# Siguiente byte
	j checksum_loop
	
end_checksum:
	andi $s5, $s5, 0xFF		# RC = suma % 256
	
	# Guardar checksum al inicio del buffer (primeros 4 bytes)
	la $s6, buffer_compresion
	sb $s5, 0($s6)		# Byte 0
	sb $zero, 1($s6)		# Bytes 1-3 en cero
	sb $zero, 2($s6)
	sb $zero, 3($s6)
	
	jr $ra

#-------------------------------------------------------------------------------------------------
# Procedimiento para mostrar la relación de compresión
show_compression_ratio:
	# Calcular tamaño comprimido (sin incluir los 4 bytes del checksum)
	sub $s7, $t7, $t0		# tamaño_comprimido = puntero_final - puntero_inicial
	
	bge $s7, $s1, bad_compression
	
	# Mostrar: RC:1 RC tamaño_entrada tamaño_comprimido RC
	li $v0, 4
	la $a0, rc_message
	syscall
	
	# Imprimir "1"
	li $v0, 1
	li $a0, 1
	syscall
	
	# Espacio
	li $v0, 4
	la $a0, space_msg
	syscall
	
	# Imprimir checksum (RC)
	li $v0, 1
	move $a0, $s5
	syscall
	
	# Espacio
	li $v0, 4
	la $a0, space_msg
	syscall
	
	# Imprimir tamaño original
	li $v0, 1
	move $a0, $s1
	syscall
	
	# Espacio
	li $v0, 4
	la $a0, space_msg
	syscall
	
	# Imprimir tamaño comprimido
	li $v0, 1
	move $a0, $s7
	syscall
	
	# Espacio
	li $v0, 4
	la $a0, space_msg
	syscall
	
	# Imprimir checksum otra vez
	li $v0, 1
	move $a0, $s5
	syscall
	
	# Nueva línea
	li $v0, 4
	la $a0, newline
	syscall
	
	jr $ra



bad_compression:
	li $v0, 4
	la $a0, bad_compression_message
	syscall
	
	j exit
#-------------------------------------------------------------------------------------------------
# Procedimiento para abrir y escribir sobre el archivo de salida

open_and_write_file:
	# Primero calcular checksum
	jal calculate_checksum
	
	# Mostrar relación de compresión
	jal show_compression_ratio
	
	li $v0, 13			# Syscall para abrir un archivo
	la $a0, output_filename	# Dirección del archivo de salida
	li $a1, 1 			# Modo escritura
	syscall
	move $s4, $v0		# Guardar Descriptor
	
	bltz $v0, handle_open		# Revisar si hubo errores abriendo el archivo
	
	# Calcular tamaño total: 4 bytes (checksum) + datos comprimidos
	sub $a2, $t7, $t0		# Tamaño de datos comprimidos
	addi $a2, $a2, 4		# + 4 bytes del checksum
	
	li $v0, 15
	la $a1, buffer_compresion  	# Dirección donde se almacenará el contenido (incluye checksum)
	move $a0, $s4  		# Descriptor del archivo 
	syscall
	
	li $v0, 16
	move $a0, $s4
	syscall
	
	j exit

#-------------------------------------------------------------------------------------------------------------
# Procedimiento para recorrer el archivo
for_document:
	bge $t1, $s1, end_for
	
	lb $a0, 0($t2)
	
	beq $a0, $t3, advance_pointer
	
	beq $a0, $t4, advance_pointer
	
	blt $a0, $s2, handle_range_ascii_error

	bgt $a0, $s3, handle_range_ascii_error
	
	li $t5, 1 # Iniciar el contador
	
	j counter_characters

#-------------------------------------------------------------------------------------------------------------
# Procedimiento para manejar errores abriendo los archivos
handle_open:
	li $v0, 4 			# Codigo syscall para imprimir un String
	la $a0, error_open_message 	# Cargamos direccion de memoria con el contenido del mensaje
	syscall
	j exit 			# Saltamos a la salida del programa debido a un error
	
#-------------------------------------------------------------------------------------------------------------
# Procedimiento para manejar el rango ASCII
handle_range_ascii_error:
	li $v0, 4
	la $a0, error_range_message
	syscall
	j exit 
	
#-------------------------------------------------------------------------------------------------------------
# Procedimiento para acabar el bucle
end_for:
	j open_and_write_file
	
	li $v0, 16
	move $a0, $s0
	syscall
	
#-------------------------------------------------------------------------------------------------------------
# Procedimiento para acabar el programa
exit:
	li $v0, 10 # Codigo syscall para terminar un programa
	syscall
	
#-------------------------------------------------------------------------------------------------------------
# Procedimiento para avanzar el puntero al siguiente valor cuando se detecta los caracteres LF y CR
advance_pointer:
	# Incremento (visto en clase)
	addi $t1, $t1, 1 
	addi $t2, $t2, 1 	# i++
	
	j for_document
	
#-------------------------------------------------------------------------------------------------------------

counter_characters:
	# Verificar límite ANTES de incrementar
	li $t8, 255
	beq $t5, $t8, save_and_continue
	
	addi $t1, $t1, 1 # i++
	addi $t2, $t2, 1
	
	bge $t1, $s1, save_character  # Si llegamos al final
	
	lb $t6, 0($t2)
	bne $a0, $t6, save_character
	
	addi $t5, $t5, 1
	
	j counter_characters

#-------------------------------------------------------------------------------------------------------------
# Guardar cuando llegamos a 255 y hay más del mismo carácter
save_and_continue:
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	
	# Guardar el bloque de 255
	sb $t5, 0($t7)        # Guardar 255
	addi $t7, $t7, 1
	
	sb $a0, 0($t7)        # Guardar carácter
	addi $t7, $t7, 1
	
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	
	# Avanzar punteros
	addi $t1, $t1, 1
	addi $t2, $t2, 1
	
	# Verificar si hay más del mismo carácter
	bge $t1, $s1, for_document  # Si llegamos al final
	
	lb $t6, 0($t2)
	bne $a0, $t6, for_document  # Si el siguiente es diferente
	
	# Si el siguiente es igual, reiniciar contador y continuar
	li $t5, 1
	j counter_characters
	
#-------------------------------------------------------------------------------------------------------------

save_character:
	
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	
	# Guardar contador y carácter
	sb $t5, 0($t7)
	addi $t7, $t7, 1
	
	sb $a0, 0($t7)
	addi $t7, $t7, 1
	
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	
	j for_document
