#Here's to hoping you use monospace fonts in your MIPS editor
#    ___                           _   _           
#   /   \__ _ _ __     /\/\   ___ | |_| | ___  ___ 
#  / /\ / _` | '_ \   /    \ / _ \| __| |/ _ \/ __|
# / /_// (_| | | | | / /\/\ \ (_) | |_| |  __/\__ \
#/___,' \__,_|_| |_| \/    \/\___/ \__|_|\___||___/
#		Dan Motles
#		seltom.dan@gmail.com
#=======Project #2=======
# "Catch-A-Fly"
# You are a little green dot, who shoots a tounge of fury at yellow dots.
# This is perhaps the most intense video gaming experience on MARS.
# Download MARS from http://courses.missouristate.edu/kenvollmar/mars/download.htm

.data 
#these values can be tweaked to modify gameplay. Note that this could have unintended results.
.align 2
GAME_TICK_DELAY:	.word	0x10
TOUNGE_STEP:		.byte	0x1
TOUNGE_MAX_LENGTH:	.byte	0x28	#40d
FROG_START_Y:		.byte	0x3
FROG_X:			.byte	0x3F	#63d
FLY_LSTART_X:		.byte	0x3
FLY_RSTART_X:		.byte	0x7C	#124d

#led colors
LED_OFF:		.byte 0x0
LED_RED:		.byte 0x1
LED_YELLOW:		.byte 0x2
LED_GREEN:		.byte 0x3

#Do not alter these values below this line
FROG_CUR_Y:	.byte	0x0
.align 2
PLAYER_SCORE:	.word	0x0
LAST_GAME_TICK:	.word	0x0
LED_ROW_LAST_UPDATED: .byte	0x0


##########################
# FLY DATA STRUCTURE:
# 0 byte: x position
# 1 byte: y position
# 2 byte: speed(pixels per tick)
# 3 byte: NA
#########################
ROWS_IN_USE:	.half 0x0	#16bit bitmask of rows in use
.align 2
LEFTFLY0:	.word 0x0
LEFTFLY1:	.word 0x0
LEFTFLY2:	.word 0x0
LEFTFLY3:	.word 0x0
LEFTFLY4:	.word 0x0
LEFTFLY5:	.word 0x0
LEFTFLY6:	.word 0x0
LEFTFLY7:	.word 0x0
RIGHTFLY0:	.word 0x0
RIGHTFLY1:	.word 0x0
RIGHTFLY2:	.word 0x0
RIGHTFLY3:	.word 0x0
RIGHTFLY4:	.word 0x0
RIGHTFLY5:	.word 0x0
RIGHTFLY6:	.word 0x0
RIGHTFLY7:	.word 0x0
FLIES:		.word LEFTFLY0 LEFTFLY1 LEFTFLY2 LEFTFLY3 LEFTFLY4 LEFTFLY5 LEFTFLY6 LEFTFLY7 RIGHTFLY0 RIGHTFLY1 RIGHTFLY2 RIGHTFLY3 RIGHTFLY4 RIGHTFLY5 RIGHTFLY6 RIGHTFLY7

PTR_BUTTON_POLL:	.word	0xFFFF0000
PTR_LED_START:		.word	0xFFFF0008
PTR_LED_END:		.word	0xFFFF0108

game_over_msg:	.asciiz	"GAME OVER! "
game_forfeit_msg: .asciiz "GAME FORFEIT! "
end_game_msg:	.asciiz " Your score was:"
.align 2
goodbye_msg:	.byte   0x0a, 0x47, 0x6f, 0x6f, 0x64, 0x62, 0x79, 0x65, 0x21, 0x20, 0x54, 0x68, 0x61, 0x6e, 0x6b, 0x73, 0x20, 0x66, 0x6f, 0x72, 0x20, 0x75, 0x73, 0x69, 0x6e, 0x67, 0x20, 0x74, 0x68, 0x69, 0x73, 0x20, 0x70, 0x72, 0x6f, 0x67, 0x72, 0x61, 0x6d, 0x20, 0x66, 0x72, 0x6f, 0x6d, 0x20, 0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x67, 0x69, 0x74, 0x68, 0x75, 0x62, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x64, 0x6d, 0x6f, 0x74, 0x6c, 0x65, 0x73, 0x0a, 0x00



.text
#boilerplate program start
init:
	jal	main
exit:
	addi	$v0, $0, 0xA		#exit execution syscall
	syscall


#==================================================================================================
# FUNCTION game_tick
#	This function will check to see if its time to update the game board. If it is, it will
#	run a subroutine to update the fly positions.
#
#==================================================================================================
game_tick:
	#prologue
	addi	$sp, $sp, -0xC
	sw	$ra, 0x0($sp)
	sw	$s0, 0x4($sp)
	sw	$s1, 0x8($sp)					

	#code
	lw	$s0, LAST_GAME_TICK		#s0 = last frame update
	lw	$s1, GAME_TICK_DELAY		#s1 = minimum time for a frame update to occur
	jal	time				#get current time
	sub	$t0, $v0, $s0			#get difference
	blt	$t0, $s1, _end_game_tick	#if time elapsed < FRAME_DELAY, don't update
	
	sw	$v0, LAST_GAME_TICK		#update game tick
	jal	update_flies			#update fly positions
		
_end_game_tick:
	#epilogue
	lw	$s1, 0x8($sp)
	lw	$s0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0xC

	#return
	jr	$ra
#-------------------------------    end game_tick      --------------------------------------------


#==================================================================================================
# FUNCTION update_flies
#	this function will update 2 flies per tick.
#==================================================================================================
update_flies:
	#prologue
	addi	$sp, $sp, -0xC
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$s0, 0x8($sp)
	#code
	lbu	$s0, LED_ROW_LAST_UPDATED	#get the last row that got updated
	move	$a0, $s0
	jal	row_in_use			#check left row in use
	beqz	$v0, _no_left_fly		#if there is no left fly, skip
	jal	update_fly			#else, update that individual fly.
_no_left_fly:
	addi	$a0, $a0, 0x8			
	jal	row_in_use			#check right row
	beqz	$v0, _no_right_fly
	jal	update_fly
_no_right_fly:
	addi	$s0, $s0, 0x1			#increment last row updated
	bgt	$s0, 0x7, _wrap_last_row_updated
	j	_end_update_flies
_wrap_last_row_updated:
	and	$s0, $s0, $0			#set s0 to 0
_end_update_flies:
	sb	$s0, LED_ROW_LAST_UPDATED
	#epilogue
	lw	$s0, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0xC
	
	#return
	jr	$ra
#-------------------------------    end update_flies   --------------------------------------------


#==================================================================================================
# FUNCTION update_fly
#	update a specific fly by row number. This also will check for collision with the frog.
#	
#	$a0 = the row we want.
#==================================================================================================
update_fly:
	#prologue
	addi	$sp, $sp, -0x10
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a1, 0x8($sp)
	sw	$s0, 0xC($sp)
	#code
	move	$s0, $a0
	jal	get_fly_object
	lbu	$t0, 2($v0)		#get the speed value
	blt	$a0, 0x8, _update_fly_left	#if the row is less than 8, fly is on left side and x must increase
	neg	$t0, $t0		#if on right side, negate speed because we need to move right
_update_fly_left:
	lbu	$t1, 0($v0)		#get the x value of the fly currently.
	add	$a1, $t1, $t0		#modify X value
	move	$a0, $v0		#move the address pointer to correct place
	jal	move_fly_to_x
	move	$a0, $s0		#move the row back to arg0
	jal	check_fly
	#epilogue
	lw	$s0, 0xC($sp)
	lw	$a1, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x10
	
	#return
	jr	$ra
#-------------------------------    end update_fly    ---------------------------------------------



#==================================================================================================
# FUNCTION check_fly
#	checks if the fly has crossed the path of the frog, and if so, ends the game
#	
#	$a0 = row
#	$a1 = x
#==================================================================================================
check_fly:
	#prologue
	addi	$sp, $sp, -0x8
	sw	$ra, 0x0($sp)
	sw	$s0, 0x4($sp)
	#code
	
	lbu	$s0, FROG_X		#get the frog's X value
	
	blt	$a0, 0x8, _check_left_fly
	ble	$a1, $s0, _fly_collision
	j	_no_fly_collision
_check_left_fly:
	bge	$a1, $s0, _fly_collision
	j	_no_fly_collision

_fly_collision:
	la	$a0, game_over_msg
	jal	print_str
	jal	game_over
_no_fly_collision:
	#epilogue
	lw	$s0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x8
	
	#return
	jr	$ra
#-------------------------------    end check_fly    -----------------------------------------------




#==================================================================================================
# FUNCTION play_game
#	This function runs the game as long as the player is not dead or the player hasn't opted
#	to quit.
#
#	$s0 = Is tounge being fired?
#	
#==================================================================================================
play_game:
	#prologue
	addi	$sp, $sp, -0x10
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a1, 0x8($sp)
	sw	$a2, 0xC($sp)
	
	#code
	jal	initialize_game				#sets up the basics
_main_game_loop:
	jal	poll					#go poll for button presses
	bgtz	$v0, _button_pressed			#if poll return value > 0, handle button press action
	j	_update_frame				#else, no button press, update the frame

_button_pressed:
	move	$a0, $v1				#put the value of the button pressed into v1
	jal	handle_button

_update_frame:
	jal	game_tick
	#check for death here?
	j	_main_game_loop
_end_main_game_loop:

	#epilogue
	lw	$a2, 0xC($sp)
	lw	$a1, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x10
	
	#return
	jr	$ra
#-------------------------------    end play_game   -----------------------------------------------

#==================================================================================================
# FUNCTION initialize_game
#	initializes the game board
#==================================================================================================
initialize_game:
	#prologue
	addi	$sp, $sp, -0x10
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a1, 0x8($sp)
	sw	$a2, 0xC($sp)
	#code
	
	jal	srand
	
	#init the led screen
	lbu	$a0, LED_OFF
	jal	clear_leds
	
	
	#init the frog
	lbu	$a0, FROG_X			#get the starting x value.
	lbu	$a1, FROG_START_Y			#get the y value the game should start at.
	sb	$a1, FROG_CUR_Y				#make sure we save the y value in the "current y" memory loc
	lbu	$a2, LED_GREEN				#set color to 3 (green)
	jal	set_led					#set the frog led
	
	#init random fly
	jal	new_fly
	
	#get start time
	jal	time
	sw	$v0, LAST_GAME_TICK
	
	#epilogue
	lw	$a2, 0xC($sp)
	lw	$a1, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x10
	
	#return
	jr	$ra
#-------------------------------    end initialize_game    -----------------------------------------------


#==================================================================================================
# FUNCTION launch_tounge
#	fires the tounge in given direction, keeping the animation flowing. Will check for
#	fly collisions as tounge is being extended.
#	
#	$a0 = direction to fire tounge. 0 = left, 1 = right
#	$a1 = frog cur x
#	$a2 = frog cur y
#==================================================================================================
launch_tounge:
	#prologue
	addi	$sp, $sp, -0x20
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a1, 0x8($sp)
	sw	$a2, 0xC($sp)
	sw	$a3, 0x10($sp)
	sw	$s0, 0x14($sp)
	sw	$s1, 0x18($sp)					
	sw	$s2, 0x1C($sp)
	
	#code
	move	$s0, $a0			#save direction
	lbu	$s1, TOUNGE_MAX_LENGTH
	move	$s2, $a1			#move x coord to the correct register
	beqz	$s0, _branch_tounge_left
	
	#going right
	addi	$a0, $a2, 0x8			#turn y value into "row" value
	jal	row_in_use
	move	$a3, $v0			#pass row in use
	move	$a1, $a2			#pass y coord
	add	$a2, $s2, $s1			#pass max x coord
	move	$a0, $s2			#pass x coord
	jal	launch_tounge_right
	j	_end_launch_tounge
	
_branch_tounge_left:
	move	$a0, $a2
	jal	row_in_use
	move	$a3, $v0			#pass row in use
	move	$a1, $a2			#pass y coord
	sub	$a2, $s2, $s1			#pass min x coord
	move	$a0, $s2			#pass x coord
	jal	launch_tounge_left

_end_launch_tounge:
	move	$a0, $v1			#pass x coor reached
	move	$a2, $v0			#pass if we had a fly collision or not
	jal	retract_tounge
	
	beqz	$a2, _player_missed
	jal	new_fly
	jal	new_fly
	lw	$t0, PLAYER_SCORE
	addi	$t0, $t0, 0x1
	sw	$t0, PLAYER_SCORE
_player_missed:
#retract here
	
	#epilogue
	lw	$s2, 0x1C($sp)
	lw	$s1, 0x18($sp)
	lw	$s0, 0x14($sp)
	lw	$a3, 0x10($sp)
	lw	$a2, 0xC($sp)
	lw	$a1, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x20
	
	#return
	jr	$ra
#-------------------------------    end launch_tounge    -----------------------------------------------


#==================================================================================================
# FUNCTION retract_tounge
#	does the retract tounge animation
#	
#	$a0 = x coord reached
#	$a1 = y coord
#	$a2 = boolean was there a collision?
#==================================================================================================
retract_tounge:
	#prologue
	addi	$sp, $sp, -0x28
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a1, 0x8($sp)
	sw	$a2, 0xC($sp)
	sw	$a3, 0x10($sp)
	sw	$s0, 0x14($sp)
	sw	$s1, 0x18($sp)					
	sw	$s2, 0x1C($sp)
	sw	$s3, 0x20($sp)
	sw	$s4, 0x24($sp)

	#code
	beqz	$a2, _tounge_tip_red		#if no collision, the tounge tip is red
	lbu	$a3, LED_YELLOW			#if there was a collision, tounge tip is yellow (fly)
	j	_init_retract_tounge
	
_tounge_tip_red:
	lbu	$a3, LED_RED

_init_retract_tounge:
	move	$s0, $a0
	lbu	$s3, TOUNGE_STEP
	lbu	$s4, FROG_X
	blt	$a0, $s4, _retract_from_left
	add	$s4, $s4, 0x1				#retracting from right means we need to start 1 px to the right
	neg	$s3, $s3				#if we are retracting from right, the step needs to be neg
	j	_retract_loop
_retract_from_left:
	add	$s4, $s4, -0x1				#set MAX pixel we shrink to to prevent killing our frog.
	
_retract_loop:
	beq	$a2, $s4, _end_retract_loop
	add	$s0, $s0, $s3
	move	$a2, $s0				#pass shrink tounge by this x amount
	bgtz	$s3, _check_retract_overflow_from_left	#if step is greater then 0, we are shrinking from left
	blt	$a2, $s4, _retract_overflow_detected	#if the x value is less then MIN x value, overflow
	j	_no_retract_overflow			#else no overflow
_check_retract_overflow_from_left:
	bgt	$a2, $s4, _retract_overflow_detected	#if x value is greater then MAX x value, overflow
	j	_no_retract_overflow			#else no overflow
	
_retract_overflow_detected:
	move	$a2, $s4				#set new x val to s4 to finish retract loop

_no_retract_overflow:	
	
	jal	shrink_tounge_section
	jal	game_tick
	j	_retract_loop
_end_retract_loop:	
	move	$a0, $s4				#get final led we need to turn off
	lbu	$a2, LED_OFF				#get off color
	jal	set_led					#kill led
	#epilogue
	
	lw	$s4, 0x24($sp)
	lw	$s3, 0x20($sp)
	lw	$s2, 0x1C($sp)
	lw	$s1, 0x18($sp)
	lw	$s0, 0x14($sp)
	lw	$a3, 0x10($sp)
	lw	$a2, 0xC($sp)
	lw	$a1, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x28
	
	#return
	jr	$ra
#-------------------------------    end retract_tounge    -----------------------------------------------


#==================================================================================================
# FUNCTION launch_tounge_right
#	We are going right, do right stuff
#	
#	$a0 = frog x
#	$a1 = frog y
#	$a2 = max X coord
#	$a3 = is the row in use? (i.e are we bothering to check for collisions?)
#	$v0 = boolean (did we successfully hit a frog?)
#	$v1 = x val of tounge
#
#==================================================================================================
launch_tounge_right:
	#prologue
	addi	$sp, $sp, -0x30
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a1, 0x8($sp)
	sw	$a2, 0xC($sp)
	sw	$a3, 0x10($sp)
	sw	$s0, 0x14($sp)
	sw	$s1, 0x18($sp)					
	sw	$s2, 0x1C($sp)
	sw	$s3, 0x20($sp)
	sw	$s4, 0x24($sp)
	sw	$s5, 0x28($sp)
	sw	$s6, 0x2c($sp)
	#code
	lbu	$s4, TOUNGE_STEP	#get tounge step length
	move	$s0, $a0		#save frog x
	move	$s1, $a1		#save frog y
	move	$s2, $a2		#save max X coord
	and	$s5, $s5, $0		#zero out our "collision" flag
	addi	$s0, $s0, 0x1		#move over 1 column to start drawing ze fly.
	move	$s6, $s0		#save the original start point to prevent bad tounge draws

	add	$a0, $s1, 0x8		#get fly object
	jal	get_fly_object
	move	$s3, $v0		#save the fly object
_launch_tounge_right_loop:
	bgt	$s0, $s2, _end_launch_tounge_right_loop
	add	$s0, $s0, $s4		#decrement x value by tounge step
	ble	$s0, $s2, _less_than_max_length_right
	addi	$s0, $s2, 0x1		#since we have exceededed the length we need to retract to the min x value
_less_than_max_length_right:
	beqz	$a3, _no_right_check_needed
	move	$a0, $s3		#pass fly obj
	move	$a1, $s0		#pass tounge x
	add	$a2, $s1, 0x8		#pass fly row
	jal 	check_collision
	beqz	$v0, _no_right_check_needed	#we didn't have a collision
	move	$s0, $v0
	
	add	$a0, $s1, 0x8		#pass y to clear fly
	jal	clear_fly_bitmap
	
	addi	$s5, $0, 0x1		#set collision flag
_no_right_check_needed:
	sub	$a0, $s0, $s4		#pass start x
	bge	$a0, $s6, _right_startx_ok		#if the start x is within a certain range, then we can safetly pass it
	move	$a0, $s6		#adjust for too low start x for passing
_right_startx_ok:
	move	$a1, $s1		#pass y
	move	$a2, $s0		#end y
	jal	draw_tounge_section		#draw tounge out
	jal	game_tick		#update game tick
	bgtz	$s5, _end_launch_tounge_right_loop
	j	_launch_tounge_right_loop	#loop back
_end_launch_tounge_right_loop:
	move	$v0, $s5		#return collision flag
	move	$v1, $s0		#return tip of tounge x value 
	#epilogue
	lw	$s6, 0x2c($sp)
	lw	$s5, 0x28($sp)
	lw	$s4, 0x24($sp)
	lw	$s3, 0x20($sp)
	lw	$s2, 0x1C($sp)
	lw	$s1, 0x18($sp)
	lw	$s0, 0x14($sp)
	lw	$a3, 0x10($sp)
	lw	$a2, 0xC($sp)
	lw	$a1, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x30
	
	#return
	jr	$ra
#-------------------------------    end launch_tounge_right    -----------------------------------------------



#==================================================================================================
# FUNCTION launch_tounge_left
#	We are going left, do left stuff
#	
#	$a0 = frog x
#	$a1 = frog y
#	$a2 = min X coord
#	$a3 = is the row in use? (i.e are we bothering to check for collisions?)
#	$v0 = boolean (did we successfully hit a frog?)
#	$v1 = x val of tounge
#
#==================================================================================================
launch_tounge_left:
	#prologue
	addi	$sp, $sp, -0x30
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a1, 0x8($sp)
	sw	$a2, 0xC($sp)
	sw	$a3, 0x10($sp)
	sw	$s0, 0x14($sp)
	sw	$s1, 0x18($sp)					
	sw	$s2, 0x1C($sp)
	sw	$s3, 0x20($sp)
	sw	$s4, 0x24($sp)
	sw	$s5, 0x28($sp)
	sw	$s6, 0x2c($sp)
	#code
	lbu	$s4, TOUNGE_STEP	#get tounge step length
	neg	$s4, $s4		#negate to go left
	move	$s0, $a0		#save frog x
	move	$s1, $a1		#save frog y
	move	$s2, $a2		#save min X coord
	and	$s5, $s5, $0		#zero out our "collision" flag
	addi	$s0, $s0, -0x1		#move over 1 column to start drawing ze fly.
	move	$s6, $s0		#save initial start position of tounge

	move	$a0, $s1		#get fly object
	jal	get_fly_object
	move	$s3, $v0		#save the fly object
_launch_tounge_left_loop:
	blt	$s0, $s2, _end_launch_tounge_left_loop
	add	$s0, $s0, $s4		#decrement x value by tounge step
	bge	$s0, $s2, _less_than_max_length_left
	addi	$s0, $s2, -0x1		#since we have exceededed the length we need to retract to the min x value
_less_than_max_length_left:
	beqz	$a3, _no_left_check_needed
	move	$a0, $s3		#pass fly obj
	move	$a1, $s0		#pass tounge x
	move	$a2, $s1		#pass fly row
	jal 	check_collision
	beqz	$v0, _no_left_check_needed	#we didn't have a collision
	move	$s0, $v0
	
	move	$a0, $s1		#pass y to clear fly
	jal	clear_fly_bitmap
	
	addi	$s5, $0, 0x1		#set collision flag
_no_left_check_needed:
	sub	$a0, $s0, $s4		#pass start x
	ble	$a0, $s6, _left_startx_ok		#if the start x is within a certain range, then we can safetly pass it
	move	$a0, $s6		#adjust for too low start x for passing
_left_startx_ok:
	move	$a1, $s1		#pass y
	move	$a2, $s0		#end y
	jal	draw_tounge_section		#draw tounge out
	jal	game_tick		#update game tick
	bgtz	$s5, _end_launch_tounge_left_loop
	j	_launch_tounge_left_loop	#loop back
_end_launch_tounge_left_loop:
	move	$v0, $s5		#return collision flag
	move	$v1, $s0		#return tip of tounge x value 
	#epilogue
	lw	$s6, 0x2c($sp)
	lw	$s5, 0x28($sp)
	lw	$s4, 0x24($sp)
	lw	$s3, 0x20($sp)
	lw	$s2, 0x1C($sp)
	lw	$s1, 0x18($sp)
	lw	$s0, 0x14($sp)
	lw	$a3, 0x10($sp)
	lw	$a2, 0xC($sp)
	lw	$a1, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x30
	
	#return
	jr	$ra
#-------------------------------    end launch_tounge_left    -----------------------------------------------


#==================================================================================================
# FUNCTION move_frog
#	Moves the frog up or down based on if a0 is 0 or 1, respectively.
#	
#	$a0 = direction (0 = up, 1 = down)
#==================================================================================================
move_frog:
	#prologue
	addi	$sp, $sp, -0x14
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a1, 0x8($sp)
	sw	$a2, 0xC($sp)
	sw	$s0, 0x10($sp)
	
	#code
	move	$s0, $a0			#save a0 in s0
	
	#clear old frog position
	lbu	$a0, FROG_X			#set X to frog X
	lbu	$a1, FROG_CUR_Y			#set y = current position
	lbu	$a2, LED_OFF			#set led to off
	jal	set_led				#turn off old led
	
	beqz	$s0, _move_frog_up		#s0 = 0, move frog up
	#Frog is moving down
	beq	$a1, 0x7, _frog_down_wrap	#if the current Y value = 7, wrap around to 0
	addi	$a1, $a1, 0x1			#else, just add one to Y value
	j	_end_move_frog
_frog_down_wrap:
	xor	$a1, $a1, $a1			#set Y = 0
	j	_end_move_frog
	
_move_frog_up:
	beqz	$a1, _frog_up_wrap		#if y = 0, wrap to 7
	addi	$a1, $a1, -0x1			# subtract 1 from frog y
	j	_end_move_frog
_frog_up_wrap:
	addi	$a1, $0, 0x7			# set y = 7
	
_end_move_frog:
	sb	$a1, FROG_CUR_Y			#save current frog height	
	lbu	$a2, LED_GREEN			#set led to green
	jal	set_led				#set the new frog position	
	
	#epilogue
	lw	$s0, 0x10($sp)
	lw	$a2, 0xC($sp)
	lw	$a1, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x14
	
	#return
	jr	$ra
#-------------------------------    end move_frog    ----------------------------------------------



#==================================================================================================
# FUNCTION new_fly
#	Adds a random new fly to the board in a free row
#==================================================================================================
new_fly:
	#prologue
	addi	$sp, $sp, -0x8
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	#code
	jal	get_random_free_row		#get a free row
	bgez	$v0, _rand_free_fly_found	#if we found a fly, WOOHOO
	
	#iterate to maybe find a free spot
	add	$a0, $0, 0xF			#start at end and seek towards front.
_iterate_through_flies_loop:
	bltz	$a0, _no_free_flies		#if we go through all the possible fly spots and they are in use, give up
	jal	row_in_use
	beqz	$v0, _end_iterate_through_flies_loop
	addi	$a0, $a0, -0x1			#decrement as we keep searching
	j	_iterate_through_flies_loop

_rand_free_fly_found:
	move	$a0, $v0			#move result to arg register
_end_iterate_through_flies_loop:
	jal	add_new_fly			#add the fly to the board
_no_free_flies:
	#epilogue
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x8
	
	#return
	jr	$ra
#-------------------------------    end new_fly    -----------------------------------------------



#==================================================================================================
# FUNCTION add_new_fly
#	adds a new fly to the game board at row specified by a0
#	
#	$a0 = the row to add the fly at.
#==================================================================================================
add_new_fly:
	#prologue
	addi	$sp, $sp, -0x10
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a1, 0x8($sp)
	sw	$s0, 0xc($sp)
	#code
	#load fly object address
	jal	get_fly_object		#get the object we want
	move	$s0, $v0		#store my address
	
	#update bitmap
	jal	set_fly_bitmap
	
	#pick correct starting X coord
	blt	$a0, 0x8, _add_new_left		#if a0<8, its on the left side
	
	addi	$a1, $a0, -0x8			#adjust to correct Y value on right side
	lbu	$a0, FLY_RSTART_X		#get the correct starting X coord
	j	_set_new_fly
_add_new_left:
	move	$a1, $a0			#just move the value since y is correct
	lbu	$a0, FLY_LSTART_X		#get the correct starting X coord
	
_set_new_fly:
	sb	$a0, 0($s0)			#store X value
	sb	$a1, 1($s0)			#store Y value
	addi	$t5, $0, 0x1			#speed.
	sb	$t5, 2($s0)
	
	lbu	$a2, LED_YELLOW			#get my green color
	jal	set_led				#set the fly LED
	
	#epilogue
	lw	$s0, 0xc($sp)
	lw	$a1, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x10
	
	#return
	jr	$ra
#-------------------------------    end add_new_fly    --------------------------------------------



#==================================================================================================
# FUNCTION get_random_free_row
#	Will return a random FREE row.
#	
#	$v0 = row
#==================================================================================================
get_random_free_row:
	#prologue
	addi	$sp, $sp, -0x10
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$s0, 0x8($sp)
	sw	$s1, 0xC($sp)
	#code
	and	$s1, $s1, $0		#0 out iterator
_while_row_in_use:
	addi	$a0, $0, 0x10		#set rand upper bound to 16
	jal	rand_int_range		#get int
	move	$s0, $v0		# save int for later
	move	$a0, $s0		#move int to arg
	jal	row_in_use		#check if row free
	beqz	$v0, _row_is_free	#if row free, end
	addi	$s1, $s1, 0x1		#increment iterator
	beq	$s1, 0x5, _no_free_rand	#if we've tried 5 times, give up.
	j	_while_row_in_use	#else, loop
_no_free_rand:
	addi	$v0, $0, -0x1		#indicate no rand found
	j	_end_get_random_free_row
_row_is_free:
	move	$v0, $s0		#return the free row #
_end_get_random_free_row:
	#epilogue
	lw	$s1, 0xC($sp)
	lw	$s0, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x10
	
	#return
	jr	$ra
#-------------------------------    end get_random_free_row    ------------------------------------


#==================================================================================================
# FUNCTION game_over
#	Ends the game and displays score
#==================================================================================================
game_over:
	#prologue
	addi	$sp, $sp, -0x4
	sw	$ra, 0x0($sp)
	
	#code
	la	$a0, end_game_msg
	jal	print_str	
	lw	$a0, PLAYER_SCORE
	jal	print_int
	la	$a0, goodbye_msg
	jal	print_str
	j	exit
	#epilogue
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x4
	
	#return
	jr	$ra
#-------------------------------    end game_over    -----------------------------------------------


####################################################################################################
####################################################################################################
####################################################################################################
######				HELPER FUNCTIONS					############
####################################################################################################
####################################################################################################
####################################################################################################



#==================================================================================================
# FUNCTION check_collision
#	Based on a fly object and tounge x value, we check to see if that fly would be hit by the
#	the tounge. X value of fly will be returned if so.
#	
#	$a0 = fly object
#	$a1 = x value
#	$a2 = row of fly (0-15)
#	$v0 = x val of fly if collision, 0 if no collsion
#==================================================================================================
check_collision:
	#prologue
	addi	$sp, $sp, -0xc
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$s0, 0x8($sp)
	#code
	move	$s0, $a0				#save fly object elsewhere
	move	$a0, $a2				#move row value into place
	jal	row_in_use
	beqz	$v0, _no_collision
	lbu	$t0, 0($s0)				#get fly's current x value
	blt	$a2, 0x8, _check_collision_left		#if row < 8, its on the left side
	ble	$t0, $a1, _collision_detected
	j	_no_collision
_check_collision_left:
	bge	$t0, $a1, _collision_detected
_no_collision:
	and	$v0, $v0, $0				#no collision, return 0
	j	_end_check_collision
_collision_detected:
	move	$v0, $t0				#since there was a collision, move the x val to return value
_end_check_collision:
	
	#epilogue
	lw	$s0, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0xc
	#return
	jr	$ra
#-------------------------------    end check_collision   -----------------------------------------


#==================================================================================================
# FUNCTION draw_tounge_section
#	draws a tounge from the starting x coord to end x coord.
#	
#	$a0 = start x
#	$a1 = y
#	$a2 = endx
#==================================================================================================
draw_tounge_section:
	#prologue
	addi	$sp, $sp, -0x14
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a2, 0x8($sp)
	sw	$s0, 0xC($sp)
	sw	$s1, 0x10($sp)					
	#code
	move	$s0, $a2			#save endx
	lbu	$a2, LED_RED			#get my purty red
	
	blt	$a0, $s0, _draw_tounge_right	#if startx < endx we are going right
	addi	$s1, $0, -0x1			#we are going left, we need to decrement
	j	_draw_tounge_pixel_loop
_draw_tounge_right:
	addi	$s1, $0, 0x1			#right, incrementing
_draw_tounge_pixel_loop:
	beq	$a0, $s0, _end_draw_tounge_pixel_loop
	jal	set_led				#set led to red
	add	$a0, $a0, $s1			#inc/dec the x value to paint next pixel
	j	_draw_tounge_pixel_loop		#loop
	
_end_draw_tounge_pixel_loop:
	#epilogue
	lw	$s1, 0x10($sp)
	lw	$s0, 0xC($sp)
	lw	$a2, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x14
	
	#return
	jr	$ra
#-------------------------------    end draw_tounge_section    -----------------------------------------------



#==================================================================================================
# FUNCTION shrink_tounge_section
#	shrinks a tounge from the starting x coord to end x coord.
#	
#	$a0 = start x
#	$a1 = y
#	$a2 = endx
#	$a3 = tounge tip color
#==================================================================================================
shrink_tounge_section:
	#prologue
	addi	$sp, $sp, -0x14
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a2, 0x8($sp)
	sw	$s0, 0xC($sp)
	sw	$s1, 0x10($sp)					
	#code
	move	$s0, $a2			#save endx
	lbu	$a2, LED_OFF			#pass off color
	
	blt	$a0, $s0, _shrink_from_left	#if startx < endx we are shrinking from the left
	addi	$s1, $0, -0x1			#if we are shrinking from right, we need to decrement
	j	_shrink_tounge_pixel_loop
_shrink_from_left:
	addi	$s1, $0, 0x1			#right, incrementing
_shrink_tounge_pixel_loop:
	beq	$a0, $s0, _end_shrink_tounge_pixel_loop
	jal	set_led				#set led to red
	add	$a0, $a0, $s1			#inc/dec the x value to paint next pixel
	j	_shrink_tounge_pixel_loop		#loop
_end_shrink_tounge_pixel_loop:
	move	$a0, $s0			#one mo time for the tip of the tounge!
	move	$a2, $a3			#get tip color
	jal	set_led
	#epilogue
	lw	$s1, 0x10($sp)
	lw	$s0, 0xC($sp)
	lw	$a2, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x14
	
	#return
	jr	$ra
#-------------------------------    end shrink_tounge_section   -----------------------------------



#==================================================================================================
# FUNCTION move_fly_to_x
#	Will move the flies position to the new X coord
#	
#	$a0 = the fly object
#	$a1 = X coord to move to
#==================================================================================================
move_fly_to_x:
	#prologue
	addi	$sp, $sp, -0x18
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a1, 0x8($sp)
	sw	$a2, 0xC($sp)
	sw	$s0, 0x10($sp)
	sw	$s1, 0x14($sp)					
	#code
	move	$s0, $a0	#save fly object
	move	$s1, $a1	#save new X location
	
	lbu	$a0, 0($s0)	#get current X
	lbu	$a1, 1($s0)	#get current Y
	lbu	$a2, LED_OFF	#turn off stupid LED
	jal	set_led
	
	sb	$s1, 0($s0)	#store new X
	move	$a0, $s1	#move new X to right register
	lbu	$a2, LED_YELLOW	#get that beautiful yellow color.
	jal	set_led
	
	#epilogue
	lw	$s1, 0x14($sp)
	lw	$s0, 0x10($sp)
	lw	$a2, 0xC($sp)
	lw	$a1, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x18
	
	#return
	jr	$ra
#-------------------------------    end move_fly_to_x    -----------------------------------------------



#==================================================================================================
# FUNCTION row_in_use
#	checks the fly bitmap to see if the row is free or not
#	
#	$a0 = the row we want to check
#	$v1 = 1 if in use, 0 if free
#==================================================================================================
row_in_use:
	#code
	
	lhu	$t0, ROWS_IN_USE	#get rows in use value
	addi	$t1, $0, 0x1		#set our mask bit
	sllv	$t1, $t1, $a0		#shift to correct bit position
	and	$t1, $t1, $t0		#mask bit
	srlv	$v0, $t1, $a0		#move bit all the way right
		
	#return
	jr	$ra
#-------------------------------    end row_in_use    ---------------------------------------------


#==================================================================================================
# FUNCTION set_fly_bitmap
#	Sets the bit on the fly bitmap for a particular row.
#	
#	$a0 = the row corresponding to the bit we are going to set.
#==================================================================================================
set_fly_bitmap:
	#code
	
	lhu	$t0, ROWS_IN_USE
	addi	$t1, $0, 0x1		#set my "mask" bit
	sllv	$t1, $t1, $a0		#move the bit into position
	or	$t0, $t0, $t1		#update the bitmap
	sh	$t0, ROWS_IN_USE
	
	#return
	jr	$ra
#-------------------------------    end set_fly_bitmap    -----------------------------------------






#==================================================================================================
# FUNCTION clear_fly_bitmap
#	Sets the bit on the fly bitmap for a particular row.
#	
#	$a0 = the row corresponding to the bit we are going to set.
#==================================================================================================
clear_fly_bitmap:
	#code
	
	lhu	$t0, ROWS_IN_USE
	addi	$t1, $0, 0x1		#set my "mask" bit
	sllv	$t1, $t1, $a0		#move the bit into position
	not	$t1, $t1		#invert
	and	$t0, $t0, $t1		#update the bitmap
	sh	$t0, ROWS_IN_USE
	
	#return
	jr	$ra
#-------------------------------    end clear_fly_bitmap    -----------------------------------------



#==================================================================================================
# FUNCTION get_fly_object
#	returns the fly object at row specified by a0
#	
#	$a0 = row of fly object.
#	$v0 = address of fly object.
#==================================================================================================
get_fly_object:
	#code
	
	sll	$t0, $a0, 2		#multiply row by 4 to get array offset
	la	$t1, FLIES		#get pointer to FLIES array
	add	$t0, $t1, $t0		#move to correct element in FLIES
	lw	$v0, 0($t0)		#get pointer to fly obj.
	
	#return
	jr	$ra
#-------------------------------    end get_fly_object    -----------------------------------------------


#==================================================================================================
# FUNCTION poll
#	determines if a button has been pressed. If so, also returns button that has been pressed
#	
#	$v0 = BOOLEAN 0/1 button is pressed
#	$v1 = The value of the button
#		buttons:
#			BE = B
#			E0 = Up
#			E1 = Down
#			E2 = Left
#			E3 = Right
#==================================================================================================
poll:
	#prologue
	addi	$sp, $sp, -0x8
	sw	$ra, 0($sp)
	sw	$a0, 4($sp)
	
	#code
	li	$t0, 0xFFFF0000			#load button press polling location
	lbu	$v0, 0($t0)			#load byte at polling location
	beqz	$v0, _exit_poll			#if poll'd byte = 0, exit.
	lbu	$v1, 4($t0)			#else, load button pressed into $v1
	
_exit_poll:
	#epilogue
	lw	$a0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 0x8
	
	#return
	jr	$ra
#-------------------------------    end poll   ----------------------------------------------------


#==================================================================================================
# FUNCTION handle_buttom
#	Handles a player's button press by performing the correct action
#	
#	$a0 = Value of button press
#==================================================================================================
handle_button:
	#prologue
	addi	$sp, $sp, -0x8
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	
	#code
	addi	$t0, $0, 0x42				#set t0 to button value of "B" center button
	beq	$a0, $t0, _center_button_pressed	#if center button pressed
	
	addi	$t0, $a0, -0xE2				#subtraction to demtermine button press value
	bltz	$t0, _updown_pressed
	
_leftright_pressed:
	move	$a0, $t0				#will be 0 (left) or 1 (right)
	lbu	$a1, FROG_X				#passes x val
	lbu	$a2, FROG_CUR_Y				#pass y value
	jal	launch_tounge				#call firetounge routine
	j	_exit_handle_button
	
_updown_pressed:
	addi	$a0, $a0, -0xE0				#re-subtract to get 0 for up or 1 for down
	jal	move_frog				#call move frog
	j	_exit_handle_button
	
_center_button_pressed:
	la	$a0, game_forfeit_msg
	jal	print_str
	jal	game_over
	
_exit_handle_button:
	#epilogue
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x8
	
	#return
	jr	$ra
#-------------------------------    end handle_button   -------------------------------------------


#==================================================================================================
# FUNCTION time
#	gets the current system time
#	
#	$v0 = lower bits of time
#	$v1 = high bits of time
#==================================================================================================
time:
	#prologue
	addi	$sp, $sp, -0x8
	sw	$a0, 0x0($sp)
	sw	$a1, 0x4($sp)
	
	#body
	addi	$v0, $0, 0x1E	#syscall value for get system time
	syscall
	move	$v0, $a0
	move	$v1, $a1
	
	#epilogue
	
	lw	$a1, 0x4($sp)
	lw	$a0, 0x0($sp)
	addi	$sp, $sp, 0x8
	
	#return
	jr	$ra
#-------------------------------    end main_game_loop    -----------------------------------------


#==================================================================================================
# FUNCTION print_str
#	prints string
#	
#	$a0 = address to string
#==================================================================================================
print_str:
	#prologue
	addi	$sp, $sp, -0x4
	sw	$ra, 0x0($sp)
	
	#code
	addi	$v0, $0, 0x4			#print string syscall
	syscall
	
	#epilogue
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x4
	
	#return
	jr	$ra
#-------------------------------    end print_str    -----------------------------------------------



#==================================================================================================
# FUNCTION print_int
#	prints integer
#	
#	$a0 = integer
#==================================================================================================
print_int:
	#prologue
	addi	$sp, $sp, -0x4
	sw	$ra, 0x0($sp)
	
	#code
	addi	$v0, $0, 0x1			#print integer syscall
	syscall
	
	#epilogue
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x4
	
	#return
	jr	$ra
#-------------------------------    end print_int    -----------------------------------------------




#==================================================================================================
# FUNCTION print_hex
#	prints hex representation of value
#	
#	$a0 = int to print in hex
#==================================================================================================
print_hex:
	#prologue
	addi	$sp, $sp, -0x4
	sw	$ra, 0x0($sp)
	
	#code
	addi	$v0, $0, 0x22			#	the syscall which prints something in hex
	syscall
	
	#epilogue
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x4
	
	#return
	jr	$ra
#-------------------------------    end print_hex    -----------------------------------------------


#==================================================================================================
# FUNCTION clear_leds
#	Sets all LED's to color passed in a0
#	
#	$a0 = color (0-3) to set led's to.
#==================================================================================================
clear_leds:
	#code
	and	$t0, $t0, $0				#clear t0
	addi	$t1, $0, 0x8				#set iterator
_clear_led_set_int:
	beqz	$t1, _end_clead_led_set_int
	or	$t0, $t0, $a0				#set led bits
	sll	$t0, $t0, 0x2
	addi	$t1, $t1, -0x1				#decrement iterator
_end_clead_led_set_int:
	
	lw	$t1, PTR_LED_START			#set t0 = the start of the LED memory space
	lw	$t2, PTR_LED_END			#set t1 = end of LED memory space
_clear_led_loop:
	sw	$t0, 0($t1)				#set current word to 0
	addi	$t1, $t1, 0x4				#move ahead 4 bytes
	bne	$t1, $t2, _clear_led_loop		#if ptr in t0 != end, continue loop
	#return
	jr	$ra
#-------------------------------    end clear_leds    -----------------------------------------------

#==================================================================================================
# FUNCTION get_led
#	Gets setting of a specific LED (algorithm used was the one provided by Childers/TA's)
#	
#	$a0 = x value
#	$a1 = y value
#	$v0 = the color value of byte
#==================================================================================================
get_led:
	#code
	sll  $t0,$a1,0x5     		# t0 = y * 32 bytes
	srl  $t1,$a0,0x2      		# t0 = x / 4
	add  $t0,$t0,$t1    		# t0 = byte offset from PTR_LED_START
	lw   $t2,PTR_LED_START		# t2 = PTR_LED_START
	add  $t0,$t2,$t0    		# t0 = byte with LED
	# compute how much byte needs to be shifted right to get the relevant bits
	andi $t1,$a0,0x3    		# t1 = last 2 bits of X coordinate
	neg  $t1,$t1        		# t1 = -t1
	addi $t1,$t1,3      		# t1 += 3
    	sll  $t1,$t1,1      		# t1 *= 2
	# load LED value, get the desired bits in the loaded byte
	lbu  $t2,0($t0)
	srlv $t2,$t2,$t1    		# shift LED value to lsb position
	andi $v0,$t2,0x3    		# mask off any remaining upper bits
	
	#return
	jr	$ra
#-------------------------------    end get_led    -----------------------------------------------


#==================================================================================================
# FUNCTION set_led
#	Sets a specific LED's color (algorithm used was the one provided by Childers/TA's)
#	
#	$a0 = x value
#	$a1 = y value
#	$a2 = color to set LED (0 = off, 1 = red, 2= orange, 3=green)
#==================================================================================================
set_led:
	#code
	# get byte offset from start of LED memory space
	sll	$t0,$a1,0x5      	# t0 = y * 32 bytes
	srl	$t1,$a0,0x2      	# t1 = x / 4
	add	$t0,$t0,$t1    		# t0 += t1 (byte offset into display)
	lw	$t2,PTR_LED_START	# t2 = start of led display
	add	$t0,$t2,$t0    		# t0 += t2 (address of byte with the LED)
	# now, compute led position in the byte and the mask for it
	andi	$t1,$a0,0x3    		# t1 = first 2 bits of X value
	neg	$t1,$t1        		# t1 = -t1
	addi	$t1,$t1,0x3      	# t1 += 3
	sll	$t1,$t1,0x1      	# t1 *= 2
	# compute two masks: one to clear field, one to set new color
	li	$t2,0x3			# t2 = 3
	sllv	$t2,$t2,$t1		# t2 * 2^$t1
	not	$t2,$t2        		# invert t2
	sllv	$t1,$a2,$t1    		# shift color value by t2
	# get current LED value, set the new field, store it back to LED
	lbu	$t3,0($t0)     		# read current LED value	
	and	$t3,$t3,$t2    		# clear the field for the color
	or	$t3,$t3,$t1    		# set color field
	sb	$t3,0($t0)     		# update display
	#return
	jr	$ra
#-------------------------------    end set_led    -----------------------------------------------



#==================================================================================================
# FUNCTION rand_int_range
#	get a random number
#	
#	$a0 = the max number+1 to get from rand_int_range
#	$v0 = the random int
#==================================================================================================
rand_int_range:
	#prologue
	addi	$sp, $sp, -0x8
	sw	$a0, 0x0($sp)
	sw	$a1, 0x4($sp)
	#code
	
	move	$a1, $a0		#move the upper bound to correct arg register
	and	$a0, $a0, $0		#set a0=0 to pick the "0th" random number generator.
	addi	$v0, $0, 0x2A		#0x2A(42d) is the syscall value for random int range
	syscall
	move	$v0, $a0
	
	#epilogue
	lw	$a1, 0x4($sp)
	lw	$a0, 0x0($sp)
	addi	$sp, $sp, 0x8
	
	#return
	jr	$ra
#-------------------------------    end rand_int_range    -----------------------------------------------

#==================================================================================================
# FUNCTION srand
#	seed random number generator
#==================================================================================================
srand:
	#prologue
	addi	$sp, $sp, -0xC
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a1, 0x8($sp)
	#code
	
	jal	time
	move	$a1, $v0
	and	$a0, $a0, $0
	addi	$v0, $0, 0x28
	syscall
	
	#epilogue
	lw	$a1, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0xC
	
	#return
	jr	$ra
#-------------------------------    end srand    -----------------------------------------------



#==================================================================================================
# FUNCTION main
#	execution starts here
#==================================================================================================
main:
	#prologue
	addi	$sp, $sp, -0x4
	sw	$ra, 0x0($sp)
	
	#code
	jal	play_game
	
	#epilogue
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x4
	
	#return
	jr	$ra
#-------------------------------    end main    ---------------------------------------------------





































#CODE BELOW THIS LINE IS NOT RUN, AND WAS SOLELY USED FOR DEV PURPOSES
###################################################################################################
#==================================================================================================
# FUNCTION template
#	description here
#	
#	$a0 = arg
#	$a1 = arg
#==================================================================================================
template:
	#prologue
	addi	$sp, $sp, -0x34
	sw	$ra, 0x0($sp)
	sw	$a0, 0x4($sp)
	sw	$a1, 0x8($sp)
	sw	$a2, 0xC($sp)
	sw	$a3, 0x10($sp)
	sw	$s0, 0x14($sp)
	sw	$s1, 0x18($sp)					
	sw	$s2, 0x1C($sp)
	sw	$s3, 0x20($sp)
	sw	$s4, 0x24($sp)
	sw	$s5, 0x28($sp)
	sw	$s6, 0x2C($sp)
	sw	$s7, 0x30($sp)
	#code
	
	#epilogue
	lw	$s7, 0x30($sp)
	lw	$s6, 0x2C($sp)
	lw	$s5, 0x28($sp)
	lw	$s4, 0x24($sp)
	lw	$s3, 0x20($sp)
	lw	$s2, 0x1C($sp)
	lw	$s1, 0x18($sp)
	lw	$s0, 0x14($sp)
	lw	$a3, 0x10($sp)
	lw	$a2, 0xC($sp)
	lw	$a1, 0x8($sp)
	lw	$a0, 0x4($sp)
	lw	$ra, 0x0($sp)
	addi	$sp, $sp, 0x34
	
	#return
	jr	$ra
#-------------------------------    end template    -----------------------------------------------
