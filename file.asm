.data
	error_open_message: .asciiz "Ocurrio un error al abrir el archivo\n"

.text

# Procedimiento para abrir y leer el archivo de entrada
# open_and_read_file(string filename, space buffer) (descriptor, bytes_read) 
file_open_and_read: # open_and_read_file
	li $v0, 13 				# Syscall 13, open file
	li $a1, 0 				
	syscall
	
	bltz $v0, file_open_error_msg 	# Si v0 es negativo entonces indica que hubo un error abriendo el archivo
	
	move $s0, $v0
	
	li $v0, 14
	move $a0, $s0
	la $a1, ($a2)		# Loads the buffer in the arg for the syscall
	la $a2, ($a3)		# li $a2, 4096 	# Número máximo de bits a leer
	syscall
	
	move $s1, $v0 	# No. caracteres leidos
	
	# jr $ra 	# Sobraria ya que se llego usando jal

#-------------------------------------------------------------------------------------------------
# Procedimiento para manejar errores abriendo los archivos
# void file_open_error_msg()
file_open_error_msg: # handle_open
	li $v0, 4 			# Codigo syscall para imprimir un String
	la $a0, error_open_message 	# Cargamos direccion de memoria con el contenido del mensaje
	syscall
	j exit 			# Saltamos a la salida del programa debido a un error
	
#-------------------------------------------------------------------------------------------------------------