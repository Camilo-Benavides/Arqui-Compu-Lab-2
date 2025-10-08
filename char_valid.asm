.text
character_valid:
	li $v0, 11 
	syscall

	# Incremento (visto en clase)
	addi $t1, $t1, 1 # i++
	addi $t2, $t2, 1
		
#	j for_document

#.globl character_valid
