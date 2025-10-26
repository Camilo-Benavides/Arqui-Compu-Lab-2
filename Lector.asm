.globl main                                                             # Declarar main como símbolo global
.data                                                                   # Sección de datos
	filename: .asciiz "C:/Users/CamiloBena/Documents/Arqui Compu/Practica 2/prueba.txt"  # Ruta del archivo de entrada
	output_filename: .asciiz "C:/Users/CamiloBena/Documents/Arqui Compu/Practica 2/rle_compress.bin"  # Ruta del archivo de salida
	error_open_message: .asciiz "Ocurrio un error al abrir el archivo\n"  # Mensaje de error al abrir archivo
	error_range_message: .asciiz "El archivo contiene caracteres fuera del rango permitido\n"  # Mensaje de error de rango ASCII
	bad_compression_message: .asciiz "La compresión ha sido ineficiente"   # Mensaje cuando la compresión no reduce tamaño
	rc_message: .asciiz "RC: "                                              # Etiqueta para mostrar relación de compresión
	space_msg: .asciiz " "                                                  # Espacio para formateo de salida
	newline: .asciiz "\n"                                                   # Salto de línea
	buff_size: .word 4096                                                   # Tamaño del buffer (4KiB)
	buffer: .space 4096                                                     # Buffer para leer archivo de entrada
	buffer_compresion: .space 4096                                          # Buffer para datos comprimidos (4KiB + 4 bytes checksum)
	memory_space_checksum: .word 0				      # 32 Bits para guardar el checksum
	characters_start: .word 0x20                                            # Código ASCII del primer carácter válido (espacio)
	characters_end: .word 0x7e                                              # Código ASCII del último carácter válido (~)
	checksum_hex: .asciiz "0x--------"  # Buffer para formato hexadecimal
	hex_digits: .asciiz "0123456789abcdef"

.text                                                                   # Sección de código
main:                                                                   # Punto de entrada del programa
    li $t3, 0x0a                                                        # Cargar código ASCII de LF (Line Feed)
    li $t4, 0x0d                                                        # Cargar código ASCII de CR (Carriage Return)
    lw $s2, characters_start                                            # Cargar límite inferior del rango ASCII
    lw $s3, characters_end                                              # Cargar límite superior del rango ASCII
    la $t2, buffer                                                      # Cargar dirección del buffer de entrada
    la $t7, buffer_compresion                                           # Cargar dirección del buffer de compresión
    la $t0, buffer_compresion                                           # Cargar dirección base del buffer de compresión
    li $t1, 0                                                           # Inicializar contador de posición en 0
    la $a0, filename                                                    # Cargar dirección del nombre del archivo
    la $a2, buffer                                                      # Cargar dirección del buffer como argumento
    la $a3, buff_size                                                   # Cargar dirección del tamaño del buffer
    jal open_and_read_file                                              # Llamar a procedimiento para abrir y leer archivo
    j for_document                                                      # Saltar a bucle principal de procesamiento

#---------------------------------------------------------------------------------------------
# Procedimiento para abrir y leer el archivo de entrada
# int open_and_read_file(string filename, space buffer)
open_and_read_file:                                                     # Etiqueta del procedimiento
    li $v0, 13                                                          # Syscall 13: open file
    li $a1, 0                                                           # Modo lectura (flag 0)
    syscall                                                             # Ejecutar syscall para abrir archivo
    bltz $v0, handle_open                                               # Si v0 < 0, hubo error al abrir
    move $s0, $v0                                                       # Guardar descriptor de archivo en $s0
    li $v0, 14                                                          # Syscall 14: read file
    move $a0, $s0                                                       # Mover descriptor de archivo a $a0
    la $a1, ($a2)                                                       # Cargar dirección del buffer
    la $a2, ($a3)                                                       # Cargar tamaño máximo a leer
    syscall                                                             # Ejecutar syscall para leer archivo
    move $s1, $v0                                                       # Guardar número de caracteres leídos en $s1
    # jr $ra                                                            # Retornar (comentado porque se usa jal)

#-------------------------------------------------------------------------------------------------
# Procedimiento para calcular el checksum
calculate_checksum:                                                     # Etiqueta del procedimiento
    li $s5, 0                                                           # Inicializar suma en 0
    move $s6, $t0                                                       # Copiar puntero inicial (después del checksum)
checksum_loop:                                                          # Bucle para sumar bytes
    bge $s6, $t7, end_checksum                                          # Si llegamos al final, terminar bucle
    lb $s7, 0($s6)                                                      # Leer byte actual
    add $s5, $s5, $s7                                                   # Sumar byte al acumulador
    addi $s6, $s6, 1                                                    # Avanzar al siguiente byte
    j checksum_loop                                                     # Repetir bucle
end_checksum:                                                           # Fin del cálculo
    andi $s5, $s5, 0xFF                                                 # RC = suma % 256 (quedarse con byte menos significativo)
    la $s6, memory_space_checksum                                       # Cargar dirección base del buffer
    sb $s5, 0($s6)                                                      # Guardar checksum en byte 0
    sb $zero, 1($s6)                                                    # Poner byte 1 en cero
    sb $zero, 2($s6)                                                    # Poner byte 2 en cero
    sb $zero, 3($s6)                                                    # Poner byte 3 en cero
    jr $ra                                                              # Retornar al llamador
    
   
#-------------------------------------------------------------------------------------------------
# Procedimiento para convertir checksum a hexadecimal (8 dígitos)
checksum_to_hex:
    la $t8, checksum_hex      # Carga la dirección de "0x--------"
    addi $t8, $t8, 2          # Salta los caracteres "0x" para escribir los 8 dígitos
    la $t9, hex_digits        # Carga la tabla "0123456789abcdef"
    
    li $a1, 8                 # Contador: 8 dígitos hexadecimales
    move $a2, $s5             # Copia el valor del checksum
	
hex_loop:
   beqz $a1, end_hex
	
	# Obtener los últimos 4 bits del checksum
   andi $a3, $a2, 0xF
	
	# Buscar el carácter hexadecimal correspondiente en la tabla
   add $s6, $t9, $a3
   lb $s7, 0($s6)
		# Guardar en el buffer checksum_hex (de derecha a izquierda)
   addi $a1, $a1, -1
   add $s6, $t8, $a1
   sb $s7, 0($s6)
	
	# Desplazar 4 bits a la derecha para procesar el siguiente dígito
   srl $a2, $a2, 4
	
   j hex_loop
	
end_hex:
   jr $ra

#-------------------------------------------------------------------------------------------------
# Procedimiento para mostrar la relación de compresión
show_compression_ratio:                                                 # Etiqueta del procedimiento
    sub $s7, $t7, $t0                                                   # Calcular tamaño comprimido (puntero_final - puntero_inicial)
    bge $s7, $s1, bad_compression                                       # Si comprimido >= original, compresión ineficiente
    
    li $v0, 4                                                           # Syscall 4: print string
    la $a0, rc_message                                                  # Cargar mensaje "RC: "
    syscall                                                             # Imprimir mensaje
    li $v0, 1                                                           # Syscall 1: print integer
    li $a0, 1                                                           # Cargar valor 1
    syscall                                                             # Imprimir 1
    li $v0, 4                                                           # Syscall 4: print string
    la $a0, space_msg                                                   # Cargar espacio
    syscall                                                             # Imprimir espacio
    li $v0, 1                                                           # Syscall 1: print integer
    move $a0, $s5                                                       # Cargar checksum
    syscall                                                             # Imprimir checksum
    # Imprimir checksum en hexadecimal (0x--------)
    li $v0, 4
    la $a0, checksum_hex
    syscall
    
    li $v0, 4                                                           # Syscall 4: print string
    la $a0, space_msg                                                   # Cargar espacio
    syscall                                                             # Imprimir espacio
    li $v0, 1                                                           # Syscall 1: print integer
    move $a0, $s1                                                       # Cargar tamaño original
    syscall                                                             # Imprimir tamaño original
    li $v0, 4                                                           # Syscall 4: print string
    la $a0, space_msg                                                   # Cargar espacio
    syscall                                                             # Imprimir espacio
    li $v0, 1                                                           # Syscall 1: print integer
    move $a0, $s7                                                       # Cargar tamaño comprimido
    syscall                                                             # Imprimir tamaño comprimido
    li $v0, 4                                                           # Syscall 4: print string
    la $a0, space_msg                                                   # Cargar espacio
    syscall                                                             # Imprimir espacio
    li $v0, 1                                                           # Syscall 1: print integer
    move $a0, $s5                                                       # Cargar checksum nuevamente
    syscall                                                             # Imprimir checksum
    li $v0, 4                                                           # Syscall 4: print string
    la $a0, newline                                                     # Cargar salto de línea
    syscall                                                             # Imprimir salto de línea
    jr $ra                                                              # Retornar al llamador
bad_compression:                                                        # Etiqueta para compresión ineficiente
    li $v0, 4                                                           # Syscall 4: print string
    la $a0, bad_compression_message                                     # Cargar mensaje de compresión ineficiente
    syscall                                                             # Imprimir mensaje
    j exit                                                              # Saltar a salida del programa

#-------------------------------------------------------------------------------------------------
# Procedimiento para abrir y escribir sobre el archivo de salida
open_and_write_file:                                                    # Etiqueta del procedimiento
    jal calculate_checksum                                              # Llamar a calcular checksum
    jal show_compression_ratio                                          # Llamar a mostrar relación de compresión
    li $v0, 13                                                          # Syscall 13: open file
    la $a0, output_filename                                             # Cargar dirección del archivo de salida
    li $a1, 1                                                           # Modo escritura (flag 1)
    syscall                                                             # Ejecutar syscall para abrir archivo
    move $s4, $v0                                                       # Guardar descriptor de archivo en $s4
    bltz $v0, handle_open                                               # Si v0 < 0, hubo error al abrir
    sub $a2, $t7, $t0                                                   # Calcular tamaño de datos comprimidos
    addi $a2, $a2, 4                                                    # Agregar 4 bytes del checksum al tamaño
    li $v0, 15                                                          # Syscall 15: write file
    la $a1, buffer_compresion                                           # Cargar dirección del buffer con datos a escribir
    move $a0, $s4                                                       # Mover descriptor de archivo a $a0
    syscall                                                             # Ejecutar syscall para escribir archivo
    li $v0, 16                                                          # Syscall 16: close file
    move $a0, $s4                                                       # Mover descriptor de archivo a $a0
    syscall                                                             # Ejecutar syscall para cerrar archivo
    j exit                                                              # Saltar a salida del programa

#-------------------------------------------------------------------------------------------------------------
# Procedimiento para recorrer el archivo
for_document:                                                           # Etiqueta del bucle principal
    bge $t1, $s1, end_for                                               # Si contador >= tamaño leído, terminar bucle
    lb $a0, 0($t2)                                                      # Cargar byte actual del buffer
    beq $a0, $t3, advance_pointer                                       # Si es LF, avanzar puntero
    beq $a0, $t4, advance_pointer                                       # Si es CR, avanzar puntero
    blt $a0, $s2, handle_range_ascii_error                              # Si carácter < límite inferior, error
    bgt $a0, $s3, handle_range_ascii_error                              # Si carácter > límite superior, error
    li $t5, 1                                                           # Inicializar contador de repeticiones en 1
    j counter_characters                                                # Saltar a contar caracteres repetidos

#-------------------------------------------------------------------------------------------------------------
# Procedimiento para manejar errores abriendo los archivos
handle_open:                                                            # Etiqueta del manejador de error
    li $v0, 4                                                           # Syscall 4: print string
    la $a0, error_open_message                                          # Cargar mensaje de error
    syscall                                                             # Imprimir mensaje de error
    j exit                                                              # Saltar a salida del programa

#-------------------------------------------------------------------------------------------------------------
# Procedimiento para manejar el rango ASCII
handle_range_ascii_error:                                               # Etiqueta del manejador de error de rango
    li $v0, 4                                                           # Syscall 4: print string
    la $a0, error_range_message                                         # Cargar mensaje de error de rango
    syscall                                                             # Imprimir mensaje de error
    j exit                                                              # Saltar a salida del programa

#-------------------------------------------------------------------------------------------------------------
# Procedimiento para acabar el bucle
end_for:                                                                # Etiqueta de fin del bucle
    j open_and_write_file                                               # Saltar a escribir archivo de salida
    li $v0, 16                                                          # Syscall 16: close file (nunca se ejecuta)
    move $a0, $s0                                                       # Mover descriptor de archivo a $a0
    syscall                                                             # Ejecutar syscall para cerrar archivo

#-------------------------------------------------------------------------------------------------------------
# Procedimiento para acabar el programa
exit:                                                                   # Etiqueta de salida del programa
    li $v0, 10                                                          # Syscall 10: exit
    syscall                                                             # Terminar programa

#-------------------------------------------------------------------------------------------------------------
# Procedimiento para avanzar el puntero al siguiente valor cuando se detecta los caracteres LF y CR
advance_pointer:                                                        # Etiqueta del procedimiento
    addi $t1, $t1, 1                                                    # Incrementar contador de posición
    addi $t2, $t2, 1                                                    # Incrementar puntero del buffer
    j for_document                                                      # Volver al bucle principal

#-------------------------------------------------------------------------------------------------------------
counter_characters:                                                     # Etiqueta del contador de caracteres repetidos
    li $t8, 255                                                         # Cargar límite máximo de repeticiones (255)
    beq $t5, $t8, save_and_continue                                     # Si contador == 255, guardar y continuar
    addi $t1, $t1, 1                                                    # Incrementar contador de posición
    addi $t2, $t2, 1                                                    # Incrementar puntero del buffer
    bge $t1, $s1, save_character                                        # Si llegamos al final, guardar carácter
    lb $t6, 0($t2)                                                      # Cargar siguiente byte
    bne $a0, $t6, save_character                                        # Si siguiente != actual, guardar carácter
    addi $t5, $t5, 1                                                    # Incrementar contador de repeticiones
    j counter_characters                                                # Repetir bucle

#-------------------------------------------------------------------------------------------------------------
# Guardar cuando llegamos a 255 y hay más del mismo carácter
save_and_continue:                                                      # Etiqueta para guardar bloque de 255
    addi $sp, $sp, -4                                                   # Reservar espacio en pila
    sw $a0, 0($sp)                                                      # Guardar carácter en pila
    sb $t5, 0($t7)                                                      # Guardar contador (255) en buffer compresión
    addi $t7, $t7, 1                                                    # Avanzar puntero de buffer compresión
    sb $a0, 0($t7)                                                      # Guardar carácter en buffer compresión
    addi $t7, $t7, 1                                                    # Avanzar puntero de buffer compresión
    lw $a0, 0($sp)                                                      # Restaurar carácter desde pila
    addi $sp, $sp, 4                                                    # Liberar espacio en pila
    addi $t1, $t1, 1                                                    # Incrementar contador de posición
    addi $t2, $t2, 1                                                    # Incrementar puntero del buffer
    bge $t1, $s1, for_document                                          # Si llegamos al final, volver al bucle principal
    lb $t6, 0($t2)                                                      # Cargar siguiente byte
    bne $a0, $t6, for_document                                          # Si siguiente != actual, volver al bucle principal
    li $t5, 1                                                           # Reiniciar contador de repeticiones en 1
    j counter_characters                                                # Continuar contando caracteres

#-------------------------------------------------------------------------------------------------------------
save_character:                                                         # Etiqueta para guardar carácter
    addi $sp, $sp, -4                                                   # Reservar espacio en pila
    sw $a0, 0($sp)                                                      # Guardar carácter en pila
    sb $t5, 0($t7)                                                      # Guardar contador en buffer compresión
    addi $t7, $t7, 1                                                    # Avanzar puntero de buffer compresión
    sb $a0, 0($t7)                                                      # Guardar carácter en buffer compresión
    addi $t7, $t7, 1                                                    # Avanzar puntero de buffer compresión
    lw $a0, 0($sp)                                                      # Restaurar carácter desde pila
    addi $sp, $sp, 4                                                    # Liberar espacio en pila
    j for_document                                                      # Volver al bucle principal
