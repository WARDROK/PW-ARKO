.eqv system_OpenFile	1024
.eqv system_ReadFile	63
.eqv system_WriteFile	64
.eqv system_CloseFile	57
.eqv system_PrintString	4
.eqv system_PrintInt	1

# bitmap data for image read from the bmp file. C definition:
#	struct {
#		char* filename;		// pointer to the filename
#		unsigned char* hdrData; // pointer to the bitmapheader (with the colour lookup table)
#		unsigned char* imgData; // pointer to the first image pixel in the memory
#		int width, height;	// width and height of the image in pixels
#		int bpp;		// number of bits per pixel
#		int pixelSpace;		// size of memory(Image Data) (witdh in bytes) * height
#		int linebytes;		// size of the image line in bytes
#	} imgInfo;

.eqv ImgInfo_fname		0
.eqv ImgInfo_hdrdat 		4
.eqv ImgInfo_imdat		8
.eqv ImgInfo_width		12
.eqv ImgInfo_height		16
.eqv ImgInfo_bpp		20	# bits per pixel
.eqv ImgInfo_pixelSpace		24
.eqv ImgInfo_lbytes		28

# https://en.wikipedia.org/wiki/BMP_file_format
.eqv BMPHeader_Size 54
.eqv BMPHeader_width_offset 18
.eqv BMPHeader_height_offset 22
.eqv BMPHeader_bpp_offset 28

# color
.eqv white_32b 0xFFFFFFFF
.eqv white_1b 0x1
.eqv black 0

# quadratic_function_init
.eqv scale 2	# divided each axis for two scale (2, 4, 8, 16) entered in bits (1, 2, 3, 4)
.eqv contsA 1
.eqv contsB 3
.eqv contsC -4

	.data

imgInfo: .space	32		# image descriptor

	.align 2		# word boundary alignment
dummy:		.space 2
bmpHeader:	.space	BMPHeader_Size

ifname:		.asciz "testA.bmp"
ofname: 	.asciz "result.bmp"
readError: 	.asciz "Read Error"
writeError: 	.asciz "Write Error"
endInfo: 	.asciz "Picture saved to "

	.text
main:
	# Initialize image descriptor
	la a0, imgInfo
	la t0, ifname
	sw t0, ImgInfo_fname(a0)
	la t0, bmpHeader
	sw t0, ImgInfo_hdrdat(a0)
	jal	read_bmp

	# Fill up background
	la a0, imgInfo		
	li a3, white_32b
	jal s0, set_image_color
    
	# Draw center horizontal line
	la a0, imgInfo		
	lw t6, ImgInfo_height(a0)
	srai t6, t6, 1
    
	mv a2, t6		
	li a3, black		
	jal set_horizontal_line_color
    
	# Draw center vertical line
	la a0, imgInfo		
	lw t6, ImgInfo_width(a0)
	srai t6, t6, 1
    
	mv a1, t6		
	li a3, black		
	jal s0, set_vertical_line_color
    
	# Draw scale on screen
	la a0, imgInfo
	li a3, black		
	jal s0, draw_scale
    
	# Quadratic function
	la a0, imgInfo		
	li a3, black		
	jal s0, quadratic_func
	
	# Save BMP
	la a0, imgInfo
	la t0, ofname
	sw t0, ImgInfo_fname(a0)
	jal save_bmp
	
	# Finish information
	la a0, endInfo
	li a7, system_PrintString
	ecall
	
	la a0, ofname
	li a7, system_PrintString
	ecall

end:
	li a7, 10
	ecall
	
#============================================================================
# read_bmp:
#	reads the content of a bmp file into memory
# arguments:
#	a0 - address of image descriptor structure
#		input filename pointer, header and image buffers should be set
# return value:
#	a0 - 0 if successful, error code in other cases
read_bmp:
	mv   t0, a0		# preserve imgInfo structure pointer

	# open file
	li   a7, system_OpenFile
	lw   a0, ImgInfo_fname(t0)
	li   a1, 0			# flags: 0-read file
	ecall

	blt  a0, zero, read_error
	mv   t1, a0			# save file handle for the future

	# read header
	li   a7, system_ReadFile
	lw   a1, ImgInfo_hdrdat(t0)
	li   a2, BMPHeader_Size
	ecall

	# extract image information from header
	lw   a0, BMPHeader_width_offset(a1)
	sw   a0, ImgInfo_width(t0)

	# compute line size in bytes - bmp line has to be multiple of 4

	# first: pixels_in_bits = width * bpp
	lhu  t2, BMPHeader_bpp_offset(a1)	# this word is not properly aligned
	sw   t2, ImgInfo_bpp(t0)
	mul  a0, a0, t2

	# last: ((pixels_in_bits + 31) / 32 ) * 4
	addi a0, a0, 31
	srai a0, a0, 5
	slli a0, a0, 2		# linebytes = ((pixels_in_bits + 31) / 32 ) * 4

	sw   a0, ImgInfo_lbytes(t0)

	lw   a0, BMPHeader_height_offset(a1)
	sw   a0, ImgInfo_height(t0)
	
	lw t6, ImgInfo_height(t0)
	lw t5, ImgInfo_lbytes(t0)
	mul a2, t5, t6		# size of memory (witdh in bytes) * height
	sw a2, ImgInfo_pixelSpace(t0)
	
	
	# Dynamic allocation memory with syscall sbrk
	lw a0, ImgInfo_pixelSpace(t0)
	li a7, 9		# sbrk syscall
	ecall
	
	sw a0, ImgInfo_imdat(t0)
	
	# read lookup table data
	li   a7, system_ReadFile
	mv   a0, t1
	lw   a1, ImgInfo_hdrdat(t0)
	addi a1, a1, BMPHeader_Size
	lw   t2, ImgInfo_bpp(t0)
	li   a2, 1
	sll  a2, a2, t2
	slli a2, a2, 2
	ecall
	

	# read image data
	li   a7, system_ReadFile
	mv   a0, t1
	lw   a1, ImgInfo_imdat(t0)
	lw   a2, ImgInfo_pixelSpace(t0)
	ecall

	# close file
	li   a7, system_CloseFile
	mv   a0, t1
	ecall

	mv   a0, zero
	jr   ra

read_error:
	la a0, readError
	li a7, system_PrintString
	ecall
    
	li a0, 1	# error opening file
	j end

# ============================================================================
# save_bmp - saves bmp file stored in memory to a file
# arguments:
#	a0 - address of ImgInfo structure containing description of the image`
# return value:
#	a0 - zero if successful, error code in other cases

save_bmp:
	mv   t0, a0	# preserve imgInfo structure pointer

	# open file
	li   a7, system_OpenFile
	lw   a0, ImgInfo_fname(t0)	#file name
	li   a1, 1	# flags: 1-write file
	ecall

	blt  a0, zero, write_error
	mv   t1, a0	# save file handle for the future

	# write header
	li   a7, system_WriteFile
	lw   a1, ImgInfo_hdrdat(t0)
	li   a2, BMPHeader_Size

	# add color lookup table
	lw   t3, ImgInfo_bpp(t0)
	li   t2, 1
	sll  t2, t2, t3
	slli t2, t2, 2	# each lookup table entry has four bytes
	add  a2, a2, t2
	ecall

	# write image data
	li   a7, system_WriteFile
	mv   a0, t1
	# compute image size (linebytes * height)
	lw   a2, ImgInfo_pixelSpace(t0)
	lw   a1, ImgInfo_imdat(t0)
	ecall

	# close file
	li a7, system_CloseFile
	mv a0, t1
	ecall

	mv a0, zero
	jr ra

write_error:
	la a0, writeError
	li a7, system_PrintString
	ecall
	
	li a0, 2 # error writing file
	j end


# ============================================================================
# set_pixel - sets the color of specified pixel
# arguments:
#	a0 - address of ImgInfo image descriptor
#	a1 - x coordinate
#	a2 - y coordinate
#	a3 - pixel color (0 - black, 1 - white)
#	(0,0) - bottom left corner
# return value: none

set_pixel:
	lw t1, ImgInfo_lbytes(a0)
	mul t0, t1, a2  # t0 = y * linebytes
	srai t1, a1, 3	# t1 = x / 8 (pixel offset in line)
	add t0, t0, t1  # t0 is offset of the pixel

	lw t1, ImgInfo_imdat(a0) # address of image data
	add t0, t0, t1 	# t0 is address of the pixel

	andi t1, a1, 0x7   # t1 = x % 8 (pixel offset within the byte)

	lbu t2,(t0)	# load 8 pixels

	sll  t2, t2, t1	# pixel bit on the msb of the lowest byte
	andi a3, a3, 1  # mask the color

	li t3, 0x80  # pixel mask
	beqz a3, set_pixel_black

set_pixel_white:
	or   t2, t2, t3
	srl  t2, t2, t1
	sb   t2, (t0)	# store 8 pixels
	jr   ra

set_pixel_black:
	not  t3, t3
	and  t2, t2, t3
	srl  t2, t2, t1
	sb   t2, (t0)	# store 8 pixels
	jr   ra


# ============================================================================
# set_horizontal_line_color - sets the hrizontal line of pixel to a given color
# arguments:
#	a0 - address of ImgInfo image descriptor
#	a2 - y coordinate of the line to be set
#	a3 - color to set (32-bit value)
# return value: none

set_horizontal_line_color:
	lw t1, ImgInfo_lbytes(a0)  # Load the number of bytes per line
	lw t2, ImgInfo_imdat(a0)   # Load the address of the image data

	# Compute the starting address of the line
	mul t0, t1, a2             # t0 = y * linebytes
	add t2, t2, t0             # t2 is the address of the first pixel in the line

	li t3, 0                   # Initialize offset within the line to 0

set_horizontal_line_color_loop:
	blt t3, t1, set_horizontal_line_color_store # If offset < linebytes, continue
	jr ra                            # Return if offset >= linebytes

set_horizontal_line_color_store:
	sw a3, 0(t2)                    # Store 32 bits (4 bytes) of the specified color
	addi t2, t2, 4                  # Move to the next 4 bytes
	addi t3, t3, 4                  # Increment offset by 4 bytes
	j set_horizontal_line_color_loop           # Repeat for the next 4 bytes

# ============================================================================
# set_image_color - sets the entire image to color
# arguments:
#	a0 - address of ImgInfo image descriptor
#	a3 - color to set (32-bit value) for set_horizontal_line_colo
# return value: none

set_image_color:
	lw t6, ImgInfo_height(a0)  # Load the height of the image
	li t5, 0                   # Initialize y coordinate to 0

set_image_color_loop:
	blt t5, t6, set_image_color_line # If y < height, continue
	jr s0                            # Return if y >= height

set_image_color_line:
	mv a2, t5            # Set y coordinate of the line
	jal set_horizontal_line_color   # Call set_horizontal_line_color to set the line to white

	addi t5, t5, 1       # Increment y
	j set_image_color_loop # Repeat for the next line
    
    
    
# ============================================================================
# set_vertical_line_color - sets a vertical line of pixels to a given color
# arguments:
#	a0 - address of ImgInfo image descriptor
#	a1 - x coordinate of the line to be set
#	a3 - color to set (1-bit value)
# return value: none

set_vertical_line_color:
	lw t6, ImgInfo_height(a0)  # Load the height of the image
	li t5, 0                   # Initialize y coordinate to 0

set_vertical_line_color_loop:
	bge t5, t6, set_vertical_line_color_done # If y >= height, stop
	mv a2, t5              # Set current y coordinate
	jal set_pixel          # Call set_pixel to set the pixel color

	addi t5, t5, 1         # Increment y
	j set_vertical_line_color_loop # Repeat for the next pixel

set_vertical_line_color_done:
	jr s0                 # Return from the function
    
    
    
# ============================================================================
# quadratic_func - sets points on the image based on a quadratic function
# arguments:
# 	a0 - address of ImgInfo image descriptor
#	a3 - color to set (1-bit value)
# return value: none

# used t5-t6 s3-s11

quadratic_func:
	# initialize A, B, C
	li s9, contsA		# A
	li s10, contsB		# B
	li s11, contsC		# C
	
	lw s8, ImgInfo_width(a0)
	srai s8, s8, 1		# width/2
	    
	lw s7, ImgInfo_height(a0)
	srai s7, s7, 1		# height/2
	
	srai s5, s8, scale		# width/2 / przedzia�  ==  skok	   (przedzia� < width/2)
	
	mul s11, s11, s5	# set c in scale
    
	lw t5, ImgInfo_width(a0)  # Load the width of the image
	li t6, 0                  # Initialize x coordinate to 0
    
quadratic_func_loop:
	sub s3, t6, s8		# offset =  x - ImgInfo_width/2
	bge s3, s8, quadratic_func_done # If x >= width/2, stop

	# y = ax^2
	mul s4, s3, s3            # s4 = x^2
	mul s4, s4, s9            # s4 = a * x^2
	
	# (a * x^2)/(scale)
	mv t1, s4	# dividend
	mv t2, s5	# divisor
	jal division
	mv s4, t0	# score

	# y = ax^2 + bx + c
	mul s2, s3, s10		# s2 = b * x
	add s4, s4, s2		# s4 = (a * x^2)/(scale) + b * x
	add s4, s4, s11		# s4 = (a * x^2)/(scale) + b * x + c
	
    	# Y > |height/2|
    	li s6, 0
	sub s6, s6, s7
	
	blt s4, s6, next_quardatic_x	# Y < -height/2
	bgt s4, s7, next_quardatic_x	# Y > height/2
    
	add s4, s4, s7		# s4 = (a * x^2)/(scale) + b * x + c + ImgInfo_height/2

	# Set pixel at (x, y)
	mv a1, t6                 # Set x coordinate
	mv a2, s4                 
	jal set_pixel             # Call set_pixel to set the pixel color

	next_quardatic_x:
	addi t6, t6, 1		# Increment x
	j quadratic_func_loop	# Repeat for the next x

quadratic_func_done:
	jr s0                     # Return from the function


# ============================================================================
# draw_scale - draw scale on the image
# arguments:
#	a0 - address of ImgInfo image descriptor
#	a3 - color to set (1-bit value)
# return value: none

draw_scale:

	li s1, 1		# for sub and add
	la a0, imgInfo
    
	lw t5, ImgInfo_width(a0)
	srai s3, t5, 1		# width/2
	srai s6, s3, scale		# width/2 / scale
    
	lw t6, ImgInfo_height(a0)
	srai s4, t6, 1		# height/2
    
	# O� X+
	mv a1, s3            # Coordinate x (width/2)
	add a1, a1, s6	# increment x by scale
draw_scale_x_plus:
	add a2, s4, s1            # Coordinate y  (height/2 + 1)
	jal set_pixel
   
	sub a2, s4, s1            # Coordinate y   (height/2 - 1)
	jal set_pixel
    
	add a1, a1, s6	# increment x by scale
	blt a1, t5, draw_scale_x_plus
    
	# O� X-
	mv a1, s3            # Coordinate x (width/2)
	sub a1, a1, s6	# decrement x by scale
draw_scale_x_minus:
	add a2, s4, s1            # Coordinate y  (height/2 + 1)
	jal set_pixel
   
	sub a2, s4, s1            # Coordinate y   (height/2 - 1)
	jal set_pixel 
    
	sub a1, a1, s6	# decrement x by scale
	bgt a1, zero, draw_scale_x_minus
    
	# O� Y+
	mv a2, s4            # Coordinate y  (height/2)
	add a2, a2, s6	# increment y by scale
draw_scale_y_plus:
	add a1, s3, s1            # Coordinate x  (width/2 + 1)
	jal set_pixel
    
	sub a1, s3, s1            # Coordinate x  (width/2 - 1)
	jal set_pixel
   
	add a2, a2, s6	# increment y by scale
	blt a2, t6, draw_scale_y_plus

	# O� Y-
	mv a2, s4            # Coordinate y  (height/2)
	sub a2, a2, s6	# decrement y by scale
draw_scale_y_minus:
	add a1, s3, s1            # Coordinate x  (width/2 + 1)
	jal set_pixel
    
	sub a1, s3, s1            # Coordinate x  (width/2 - 1)
	jal set_pixel
   
	sub a2, a2, s6	# decrement y by scale
	bgt a2, zero, draw_scale_y_minus   

draw_scale_done:
	jr s0
	
# ============================================================================
# draw_scale - draw scale on the image
# arguments:
#	t1 - dividend
#	t2 - divisor
# return value:
#	t0 - score

division:
	li t0, 0	# t0 = score
	
	# Check dividend sign 
	li t3, 1
	blt t1, zero, abs_dividend
	li t3, 0         # t3 = 0, when dividend >= 0
	j division_loop
    
abs_dividend:
	# Abstract dividend if negative
	bge t1, zero, division_loop
	neg t1, t1

division_loop:
	blt t1, t2, division_restore_sign
	sub t1, t1, t2       # dividend - divisor
	addi t0, t0, 1       # increment score
	j division_loop

division_restore_sign:
	beqz t3, divison_end	# if dividend addition skip
	neg t0, t0	

divison_end:
	jr ra
