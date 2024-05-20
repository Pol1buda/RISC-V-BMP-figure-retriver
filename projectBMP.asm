#---------------------------------------------------------------------------
#author: Matvii Ivashchenko
#description: programm retrives coordinates of L shaped objects in BMP file
# * (0,0) at left upper corner
# * Only 24-bits 320x240 pixels BMP files are supported
#---------------------------------------------------------------------------
.eqv BMP_FILE_SIZE 230522
.eqv BYTES_PER_ROW 960
  .data
left:   .asciz "("
right:  .asciz ")\n"
coma:  .asciz ","
file_error:  .asciz"Inccorect type of input file!\n"
.align 4

res:  .space 2
image:  .space BMP_FILE_SIZE

fname:  .asciz "source.bmp"
  .text
start:
	li s3, '.'
	la a5 fname
	lb a6, (a5)
	
# ============================================================================
Start:
#description: 
#	check type of input file
#arguments: none
#	
#return value: none
  
  	jal  read_bmp
  	jal check_format
  	li s0, 320	#width
  	li s1, 240	#height
  	li s2, 0x00000000	#black color
  	li s6, 2

  	la t0, image    # load image

      # loop for rows
  	li a5, 0        # rows counter
row_loop:
      # loop for pixels
      	li a6, 0    # pixels counter
pixel_loop:
        
  	mv a0, a6    
  	mv a1, a5    
  	jal get_pixel   #get pixel color 

  	beq a0, s2, same_color    # compare color with sample if same go to check


  	j continue    #if colors are different continie loop
  	
# ============================================================================
same_color:
#description: 
#	check pixeles around found according to this pattern:
#	 |B|
#	O|F|B
#        |O|
#	B-black
#	O- any other color
#	F-founde
#arguments: none
#	
#return value: none
  	addi a0, a6, -1 	#check left pixel
  	mv a1, a5
  	jal get_pixel
  	beq a0, s2, continue
  
  	addi a0, a6, 1		#check right pixel
  	mv a1, a5
  	jal get_pixel
  	bne a0, s2, continue
  
  	addi a1, a5, -1		#check pixel below
  	mv a0, a6
  	jal get_pixel
  	beq a0, s2, continue
  
  	addi a1, a5, 1		#check pixel above
  	mv a0, a6
  	jal get_pixel
  	bne a0, s2, continue
  
  	mv a4, a6  #pixels
  	mv a3, a5  #rows
  	
 # ============================================================================
check_horz:
#description: 
#	calculate width of the object
#arguments: none
#	
#return value: none
  	addi a4, a4, 1
  	mv a0, a4
  	mv a1, a5
  	jal get_pixel
  	beq a0, s2, check_horz
  	sub s4, a4, a6
  
  	li s9, 0
  	addi a4, a4, -1
  	
 # ============================================================================
found_right_height:
#description: 
#	calculate height of the elemnt shown on the scheme below:
#	 _
#	| |
#	| |
#	| |__
#	| ___| <- this part
#arguments: none
#	
#return value: none
  	addi s9, s9, 1
  	mv a0, a4
  	mv a1, a3
  	jal get_pixel
  	addi a3, a3, 1
  	beq a0, s2 found_right_height
  	addi s9, s9, -1
  	mv a4, a6  #pixels
  	mv a3, a5  #rows
  
# ============================================================================
check_vert:
#description: 
#	calculate heigt of the object
#arguments: none
#	
#return value: none
  	addi a3, a3, 1
  	mv a0, a6
  	mv a1, a3
  	jal get_pixel
  	beq a0, s2, check_vert
  	sub s5, a3, a5
  	
 # ============================================================================
check_size:
#description: 
#	check if the proportion height/width = 2 is kept
#arguments: none
#	
#return value: none
	
  	sub s7, s5, s4
  	bne s4, s7, continue
  	
# ============================================================================
check_border:
#description: 
#	check if border of L is "clen"(only non black colors)
#	which block of code check wich segment of object will be shown
#	on schems bellow
#arguments: none
#	
#return value: none
  	mv a4, a6  #pixels
  	mv a3, a5  #rows.
  
  
  	addi a3, a3, -1
  	addi a4, a4, -1
  	li s7, 1
                         	#  	 _
  	mv s10, s4	  	#	| |	
  	addi s10, s10, 2	#	| |_
  	jal hborder_check	#	|___|
  	beqz s11, continue	#	  ^
  
  	mv s10, s9        	#	 _
  	addi s10, s10, 2	#	| |
  	jal vborder_check	#	| |_
  	beqz s11, continue	#	|___|<
  
  
  	sub, s10, s4, s9	#	  _
  	addi s10, s10, 1	#	 | |v
  	li s7, -1         	#	 | |_
  	jal hborder_check	#	 |___|
  	beqz s11, continue
  
  	sub s10, s5, s9		#	  _
  	addi s10, s10, 1	#	 | |<
  	li s7, 1         	#	 | |_
  	jal vborder_check	#	 |___|
  	beqz s11, continue
                             	#	  v
  	mv s10, s9       	#	  _
  	addi s10, s10, 2	#	 | |
  	li s7, -1        	#	 | |_
  	jal hborder_check	#	 |___|
  	beqz s11, continue
  
  	mv s10, s5       	#	  _
  	addi s10, s10, 2	#	 | |
  	li s7, -1         	#	>| |_
  	jal vborder_check	#	 |___|
  	beqz s11, continue
  
  	mv a4, a6  #pixels
  	mv a3, a5  #rows
  	mv t5, s9
  	
# ============================================================================
check_horz_integrity:
#description: 
#	check integrity of horizontal part of L (only black color inside)
#arguments: none
#	
#return value: none
  	addi a4, a4, 1
  	mv a0, a4
  	mv a1, a3
  	jal get_pixel
  	beq a0, s2, check_horz_integrity
  	sub s8, a4, a6
  	bne s8, s4, continue
  
  	addi t5, t5, -1
  	beqz t5, vert_init
  	addi a3, a3, 1
  	mv a4, a6
  	b check_horz_integrity
  	
vert_init:	#preparetion before check_vert_integrity
  	mv a4, a6  	#pixels
  	mv a3, a5  	#rows
  	mv t5, s9
  	
 # ============================================================================
check_vert_integrity:
#description: 
#	check integrity of vertical part of L (only black color inside)
#arguments: none
#	
#return value: none
  	addi a3, a3, 1
  	mv a0, a4
  	mv a1, a3
  	jal get_pixel
  	beq a0, s2, check_vert_integrity
  	sub s8, a3, a5
  	bne s8, s5, continue
  	addi t5, t5, -1
  	beqz t5, print
  	addi a4, a4, 1
  	mv a3, a5
  	b check_vert_integrity
  	
# ============================================================================
print:
#description: 
#	print coordinates of intersection point
#arguments: none
#	
#return value: none
	la a0, left	#print "("
  	li a7, 4
  	ecall
  
  	mv a0, a6	# print X
  	li a7, 1
  	ecall
  
  	la a0, coma	#print ","
  	li a7, 4
  	ecall
  
  	li s3, 240	#converte Y to the propriet format 
  	sub s3, s3, a5
  
  	mv a0, s3	#print y
  	li a7, 1
  	ecall
  
  	la a0, right	#print ")'
  	li a7, 4
  	ecall

# ============================================================================
continue:
#description: 
#	skip pixel if it hasn`t passed all checks
#arguments: none
#	
#return value: none
  	addi a6, a6, 1    
        blt a6, s0, pixel_loop    
	addi a5, a5, 1    
      	blt a5, s1, row_loop    
      	b end

# ============================================================================
hborder_check:
#description: 
#	hborder_check, hcheck, hcolor_check are functions that check some 
#	horizontal pixel segment whether it contains black color
#arguments:
#	$a4 - X coordinate
#	$a3 - Y coordinate
#	Ss7 - direction of movement (1 - right, -1 - left)
#	$s10 - distance of movemnt
#return value:
#	$s11 - result of checking(1 - no black pixels were found,
#	       0 - at least one black pixel was found)
  	mv t6, ra	#save return adrress
  	li s11, 1
hcheck:
  	addi s10, s10, -1    
  	bgtz s10, hcolor_check
  	jr t6
hcolor_check:
  	add a4, a4, s7
  	mv a0, a4
  	mv a1, a3
  	jal get_pixel
  	bne a0, s2, hcheck
  	li s11, 0
  	jr t6
  
# ============================================================================
vborder_check:
#description: 
#	vborder_check, vcheck, vcolor_check are functions that check some 
#	vertical pixel segment whether it contains black color
#arguments:
#	$a4 - X coordinate
#	$a3 - Y coordinate
#	Ss7 - direction of movement (1 - right, -1 - left)
#	$s10 - distance of movemnt
#return value:
#	$s11 - result of checking(1 - no black pixels were found,
#	       0 - at least one black pixel was found)
  	mv t6, ra	#save return adrress
  	li s11, 1

vcheck:
  	addi s10, s10, -1    
  	bgtz s10, vcolor_check
  	jr t6
vcolor_check:
  	add a3, a3, s7
  	mv a0, a4
  	mv a1, a3
  	jal get_pixel
  	bne a0, s2, vcheck
  	li s11, 0
  	jr t6

# ============================================================================
read_bmp:
#description: 
#  reads the contents of a bmp file into memory
#arguments:
#  none
#return value: none
  	addi sp, sp, -4    #push $s1
  	sw s1, 0(sp)
#open file
  	li a7, 1024
        la a0, fname    #file name 
        li a1, 0    #flags: 0-read file
        ecall
  	mv s1, a0      # save the file descriptor
  
#read file
  	li a7, 63
  	mv a0, s1
  	la a1, image
  	li a2, BMP_FILE_SIZE
  	ecall

#close file
  	li a7, 57
  	mv a0, s1
        ecall
  
  	lw s1, 0(sp)    #restore (pop) s1
  	addi sp, sp, 4
  	jr ra

# ============================================================================
get_pixel:
#description: 
#  returns color of specified pixel if color out of range of image, return white
#arguments:
#  a0 - x coordinate
#  a1 - y coordinate - (0,0) - bottom left corner
#return value:
#  a0 - 0RGB - pixel color
  
  	li t1, 0
  	blt a0, t1, out_of_border
  
  	li t1, 319
  	bgt a0, t1, out_of_border

  	li t1, 0
  	blt a1, t1, out_of_border
  
  	li t1, 239
  	bgt a1, t1, out_of_border
  
  	la t1, image    #adress of file offset to pixel array
  	addi t1,t1,10
  	lw t2, (t1)    #file offset to pixel array in $t2
  	la t1, image    #adress of bitmap
  	add t2, t1, t2    #adress of pixel array in $t2
  
  #pixel address calculation
  	li t4,BYTES_PER_ROW
  	mul t1, a1, t4     #t1= y*BYTES_PER_ROW
  	mv t3, a0    
  	slli a0, a0, 1
  	add t3, t3, a0    #$t3= 3*x
  	add t1, t1, t3    #$t1 = 3x + y*BYTES_PER_ROW
  	add t2, t2, t1  #pixel address 
  
  #get color
  	lbu a0,(t2)    #load B
  	lbu t1,1(t2)    #load G
  	slli t1,t1,8
  	or a0, a0, t1
  	lbu t1,2(t2)    #load R
  	slli t1,t1,16
  	or a0, a0, t1
          
  	jr ra
out_of_border:
  	li a0, 0x00FFFFFF
  	jr ra
  	
# ============================================================================
check_format:
	la t1, image
	lbu t2, (t1)
	li a2, 'B'
	bne t2, a2, wrong_file
	lbu t2,1(t1)
	li a2, 'M'
	bne t2, a2, wrong_file
	jr ra

wrong_file:
#description: 
#	print message if detected wrong type of input file
#arguments: none
#	
#return value: none
  	la a0, file_error
  	li a7, 4
  	ecall
 
 # ============================================================================
end:
#description: 
#	end programm
#arguments: none
#	
#return value: none
  	li a7, 10
  	ecall
