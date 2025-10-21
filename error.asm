
.text
#
# void print_error(string error_msg)
print_error:
	li $v0, 4
	# la $a0, error_range_message
	syscall
	j exit 