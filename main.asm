;########################################
;#	     COAL PROJECT	   													#
;#         CANDY CRUSH GAME	   									#
;#	Authors:		   																#
;#	1. Mizrab Sheikh (20I-0453)										#
;#	2. Talha Atif (20I-0486)												#
;########################################

include Drawings.lib
include Util.lib

.model small
.stack 100h
.data

	;Important Arrays
	candyArray dw 0, 0, 0, 0, 0 ; 	index:    x  y  id i  j
	
	;Using 'textequ' to make accessing array easier
	x textequ <candyArray[0]>
	y textequ <candyArray[2]>
	id textequ <candyArray[4]>
	i textequ <candyArray[6]>
	j textequ <candyArray[8]>

	;Important constants with respect to board & boxes dimensions
	gridSize = 25
	gridXoffset = 30
	gridYoffset = 15
	padding = 5
	
	;Arrays to store coordinates of boxes 
	xCoordsArray dw 49 dup(0)
	yCoordsArray dw 49 dup(0)
	candyIDsArray dw 49 dup(0)
		
	;We need these variable to traverse through the board
	xC dw gridXoffset 	; initially pointing to the first block of the matrix (needed for iteration)
	yC dw gridYoffset + gridSize
	candyId dw 1
	boxNum dw 0
	
	;Variables to store info related to mouse movement
	mouseX dw 0 ;Stores X coordinate of last mouse click
	mouseY dw 0 ;Stores Y coordinate of last mouse click
	mouseClickValid dw 0 ;using this as a boolean variable*
	firstClickBox dw 0
	secondClickBox dw 0
	
	;Variables to store players satistics & information
	playerName db 16 dup(?); 'Lord Mizzi     $'  
	playerScore dw 0
	playerMoves dw 0
	currLevel dw 1
	playerHighestScore dw 0
	playerScoreL1 dw 0
	playerScoreL2 dw 0
	playerScoreL3 dw 0
	threshScoreL1 = 20 ; Change value of these variables to modify 'Threshold Score for each level'
	threshScoreL2 = 15	
	threshScoreL3 = 12	
	allowedMoves = 4 ; Change value of this variable to modify Number of Moves per level
	
	;Variables to manage file handling
	file dw ?
	fileName db 'Scores.txt', 0	
		
	;Miscellaneous variables
	retAddress dw 0
	comboBoxes dw 49 dup(99)
	comboBoxIndex dw 0
	numComboBoxes dw 0
	selectedChoice db 0
	combo dw 0
	randomNum dw 0
	comboFound dw 0
	levelCleared dw 0
	bombPresent dw 0
	candiesDestroyedByBomb dw 0
	colNum dw 0
	rowNum dw 0
	
	;These are all the strings used
	welcomeStr db 'WELCOME$'
	toStr db 'TO$'
	candyCrushStr db 'CANDY CRUSH$'
	enterNameStr db 'Enter Name: $'
	greetingStr db 'Greetings, $'
	playGameStr db 'Start Game$'
	gameRulesStr db 'View Rules$'
	viewHighScores db 'View High Scores$'
	exitStr db 'Exit$'
	workInProgressStr db 'Check Scores.txt file!$'
	pressAnyKeyToContinueStr db 'Press any key to continue...$'
	pressEnterFailStr db 'Press ENTER to restart...$'
	pressEnterPassStr db 'Press ENTER to proceed ahead...$'
	pressSpaceStr db 'Press SPACE to exit...$'
	levelFailStrA db 'Level Failed!$'
	levelFailStrB db 'Score was not enough!$'
	levelPassStrA db 'LEVEL PASSED!$'
	levelPassStrB db 'Well Done! Great Job!$'
	ruleStr db '-->Game Rules<--$'
	rule1Str db '1. Candy Crush is a "Match-Three" game,$'
	rule2Str db	'where the core game is based on swapping$' 
	rule3Str db 'two adjacent random candies.$'
	rule4Str db '2. The game consists of 3 Levels.$'
	rule5Str db '3. Make row or column of three candies.$'
	rule6Str db '4. More combinations means more score.$'
	infoStatsStr db 'STATISTICS $'
	infoScoreStr db 'Score: $'
	infoMovesStr db 'Moves: $'
	infoLevelStr db 'Level: $'
	scoreL1Str db 'Level 1: $'
	scoreL2Str db 'Level 2: $'
	scoreL3Str db 'Level 3: $'
	playerScoreL1Str db  ?,?,?,?,'$'
	playerScoreL2Str db ?,?,?,?,'$'
	playerScoreL3Str db ?,?,?,?,'$'
	playerHighestScoreStr db ?,?,?,?,'$'
	
	highestScoreStr db 'Highest Score: $'
	newline db 10,'$'   
	crushingStr db 'CRUSHING!$'
	explosionStr db 'EXPLOSION$'
	
.code

;-----------------------------------------------------
;			 			 MAIN
;-----------------------------------------------------

main proc

	;Initialising data segment
	mov ax, @data
	mov ds, ax	
			
	;Calling function to display title page
	call displayTitlePage
	
	START_GAME:
	call displayMenu
	
	initialiseMouse
	START_NEW_LEVEL:

	call populateBoard
	
	mov playerScore, 00
	mov playerMoves, 00
	call displayInformation
	
	CURR_LEVEL:
		call takeInput
		call findCombo
		cmp playerMoves, allowedMoves
	jne CURR_LEVEL
	
	call checkIfLevelCleared

	.if (currLevel == 4)
		mov currLevel, 1
		jmp START_GAME
	.else
		jmp START_NEW_LEVEL
	.endif

main endp

;-----------------------------------------------------
;			 			 PROCEDURES
;-----------------------------------------------------

;--------------------------------------------------------------------------
;Function to check if player has completed a particular level
checkIfLevelCleared proc

	hideCursor
	call displayInformation
	
	;Comparing score in current level with the highest score & swapping if curr is greater
	mov ax, playerScore
	.if (ax > playerHighestScore)
		move playerHighestScore, playerScore
	.endif
	

	;Checking is the player has managed to clear a certain level i.e 1, 2 or 3
	mov levelCleared, 0
	.if (currLevel == 1)
			.if (playerScore > threshScoreL1)
					move playerScoreL1, playerScore
					call storeScoreInFile
					mov levelCleared, 1
					inc currLevel
			.endif	
	.elseif (currLevel == 2)
			.if (playerScore > threshScoreL2)
					move playerScoreL2, playerScore
					call storeScoreInFile
					mov levelCleared, 1
					inc currLevel
			.endif	
	.elseif (currLevel == 3)
			.if (playerScore > threshScoreL3)
					move playerScoreL3, playerScore
					call storeScoreInFile
					mov levelCleared, 1
					inc currLevel
			.endif	
	.endif

	.if (levelCleared == 0)
	
		drawStringSC levelFailStrA, candyArray, 12, 8, 4, 200 
		drawStringSC levelFailStrB, candyArray, 13, 4, 4, 200 
		
		drawStringSC pressSpaceStr, candyArray, 19, 4, 15, 150
		drawStringSC pressEnterFailStr, candyArray, 20, 4, 15, 150 
		
		CHECK_KEY:
			mov ah, 0
			int 16h
			.if (al == 32) 
				quitGame
			.elseif (al == 13)
				showCursor
				ret
			.endif
		jmp CHECK_KEY	
	
	.else
		
		drawRect 
		drawStringSC levelPassStrA, candyArray, 12, 8, 10, 200 
		
		drawStringSC pressSpaceStr, candyArray, 19, 4, 15, 150
		drawStringSC pressEnterPassStr, candyArray, 20, 4, 15, 150 
		
		CHECK_KEY_:
			mov ah, 0
			int 16h
			.if (al == 32) 
				quitGame
			.elseif (al == 13)
				showCursor
				ret
			.endif
		jmp CHECK_KEY_	
	
	.endif
	showCursor
	ret

checkIfLevelCleared endp

;--------------------------------------------------------------------------
;Function to draw starting candies on board and store their coordinates in arrays
populateBoard proc
	
	;Setting video mode using macro (See Util.lib)
	
	mov playerScore, 00
	mov playerMoves, 00
	call displayInformation
	.if (currLevel != 3)
		setBackground 0
	.endif
	;Using macro to draw the 7*7 grid
	drawBoard gridXoffset, gridYoffset, 7,1
	
	;Writing Stats (Not using function because it doesn't has delay)
	drawStringSC infoStatsStr, candyArray, 8, 28, 15, 100
	drawStringSC infoLevelStr, candyArray, 12, 29, 15,100
	printChar currLevel
	drawStringSC infoMovesStr, candyArray, 14, 29, 15,100
	push playerMoves
	print
	drawStringSC infoScoreStr, candyArray, 16, 29, 15,100
	push playerScore
	print
	
	;Setting up initial positions to loop correctly
	mov yC, gridYoffset + gridSize
	mov xC, gridXoffset
	mov boxNum, 0
	
	.if (currLevel == 2)
		jmp POPULATE_LEVEL_2
	.elseif (currLevel == 3)
		jmp POPULATE_LEVEL_3
	.endif
	
	;################
	POPULATE_LEVEL_1:
	;################

	.while (yC != gridSize*8 + gridYoffset) 
		.while (xC != gridSize*7 + gridXoffset) 
		
				genRandom candyId, 0, 7
			
				mov bx, boxNum			
				mov ax, yC
				mov yCoordsArray[bx], ax
				
				mov bx, boxNum			
				mov ax, xC
				mov xCoordsArray[bx], ax
				
				mov bx, boxNum			
				mov ax, candyId
				mov candyIDsArray[bx], ax
		
			setCandy xCoordsArray[bx] , yCoordsArray[bx] , candyIDsArray[bx]
			drawCandy candyArray, gridSize, padding
			
			add boxNum, 2
			add xC, gridSize
					
		.endw
	
	mov xC, gridXoffset
	add yC, gridSize
	.endw
	ret
	
	;################
	POPULATE_LEVEL_2:
	;################
	
	.while (yC != gridSize*8 + gridYoffset) 
		.while (xC != gridSize*7 + gridXoffset) 	
		
				genRandom candyId, 0, 7
				.if ((boxNum == 0) || (boxNum == 6) || (boxNum == 12) || (boxNum == 14) || (boxNum ==26) || (boxNum == 42) || (boxNum == 54) || (boxNum == 70) || (boxNum == 82) || (boxNum == 84) || (boxNum == 90) || (boxNum ==96))
					mov candyId, 10 
				.endif
				
				mov bx, boxNum			
				mov ax, yC
				mov yCoordsArray[bx], ax
				
				mov bx, boxNum			
				mov ax, xC
				mov xCoordsArray[bx], ax
				
				mov bx, boxNum			
				mov ax, candyId
				mov candyIDsArray[bx], ax
		
			setCandy xCoordsArray[bx] , yCoordsArray[bx] , candyIDsArray[bx]
			drawCandy candyArray, gridSize, padding
			
			add boxNum, 2
			add xC, gridSize
					
		.endw
	
	mov xC, gridXoffset
	add yC, gridSize
	.endw
	ret

	;################	
	POPULATE_LEVEL_3:
	;################	
	
	
	;Setting video mode using macro (See Util.lib)
	setBackground 8
	;Using macro to draw the 7*7 grid
	drawBoard gridXoffset, gridYoffset, 15,1
	
	;Writing Stats (Not using function because it doesn't has delay)
	drawStringSC infoStatsStr, candyArray, 8, 28, 15, 100
	drawStringSC infoLevelStr, candyArray, 12, 29, 15,100
	printChar currLevel
	drawStringSC infoMovesStr, candyArray, 14, 29, 15,100
	push playerMoves
	print
	drawStringSC infoScoreStr, candyArray, 16, 29, 15,100
	push playerScore
	print
	
	.while (yC != gridSize*8 + gridYoffset) 
		.while (xC != gridSize*7 + gridXoffset) 
		
				genRandom candyId, 0, 7	
				.if ((boxNum == 6) || (boxNum == 20) || (boxNum == 34) || (boxNum == 48) || (boxNum ==62) || (boxNum == 76) || (boxNum == 90) || (boxNum == 42) || (boxNum == 44) || (boxNum == 46) || (boxNum == 48) || (boxNum ==50)|| (boxNum ==52)|| (boxNum ==54))
					mov candyId, 10 
				.endif
			
				mov bx, boxNum			
				mov ax, yC
				mov yCoordsArray[bx], ax
				
				mov bx, boxNum			
				mov ax, xC
				mov xCoordsArray[bx], ax
				
				mov bx, boxNum			
				mov ax, candyId
				mov candyIDsArray[bx], ax
				
			setCandy xCoordsArray[bx] , yCoordsArray[bx] , candyIDsArray[bx]
			drawCandy candyArray, gridSize, padding
			
			add boxNum, 2
			add xC, gridSize
		.endw
	
	mov xC, gridXoffset
	add yC, gridSize
	.endw
	ret
		
populateBoard endp

;--------------------------------------------------------------------------
;Function which waits for user input and calls appropriate function to verify them
takeInput proc

	showCursor
		
	;It will keep taking input until the input is valid	
	RESTART:
		
	;These 4 macros are called to correctly deselect a box. DONT CHANGE ANYTHING!
	hideCursor ;Otherwise some part of highlight box is left over so cursor has to be hidden
	highlightbox candyArray, gridSize, firstClickBox, 7 ;'De-Selecting'
	delay 500 ;Otherwise previous click is detected
	showCursor
	
	;Taking first mouse input from user	
	takeMouseInput
	findMouseCoordinates mouseX, mouseY
	
	call findBoxFromCoords
	pop firstClickBox
	
	call verifyFirstClick
	cmp mouseClickValid, 0
	je RESTART
	
	hideCursor
	highlightbox candyArray, gridSize, firstClickBox, 4
	delay 500 ; ;Without the delay below, previous values taken as input! Don't change the value of this delay! Crucial Delay!!!
	showCursor
	
	;Now we will take second mouse input from the user
	takeMouseInput
	findMouseCoordinates mouseX, mouseY
		
	call findBoxFromCoords
	pop secondClickBox

	call verifySecondClick
	
	cmp mouseClickValid, 0
	je RESTART
		
	swapCandies firstClickBox, secondClickBox, candyIDsArray
	
	call updateBoard
	
	;Checking if the swap initiated by user results in combo or not. If not, then don't swap
	call verifySwap
	
	.if (combo == 0)
		delay 650
		swapCandies  secondClickBox, firstClickBox, candyIDsArray
		call updateBoard
		jmp RESTART
	.endif
	
	inc playerMoves
	
	ret
takeInput endp

;--------------------------------------------------------------------------
;Function which searches for possible combos after player makes a move
findCombo proc

	hideCursor

	FIND_COMBOS_AGAIN:
		
	mov combo, 0	; stores only row/ column score
	mov boxNum, 0 ; to store the first candy of the new row
	mov comboFound, 0	
	mov comboBoxIndex, 0
	mov numComboBoxes, 0
	
	call displayInformation	

	mov i, 1
	mov j, 1
	
	.while (i <= 7) 
		mov j, 1
		;Moving to new Row
		.while (j <= 5) 
			
			mov bx, boxNum
			mov cx, candyIDsArray[bx]
			mov candyId, cx
			
			.if (candyId == 10)
				jmp SKIP_THIS_BOX
			.endif
			
			.while(candyId ==  cx)
				inc combo		
				moveVarToArr comboBoxes, comboBoxIndex, bx
				add comboBoxIndex, 2
				inc numComboBoxes
				add bx, 2				
				mov cx, candyIDsArray[bx]
			.endw		
		
			.if (combo < 3)	
				mov cx, combo
				REMOVE_COMBO_BOXES:
					sub comboBoxIndex, 2
					moveVarToArr comboBoxes, comboBoxIndex, 99
					dec numComboBoxes
					mov combo,  0	
				loop REMOVE_COMBO_BOXES	
			.endif
			
			mov bx, combo
			add playerScore, bx
			
			
			SKIP_THIS_BOX:
			mov combo,  0		
			add boxNum,  2
			inc j
		.endw
	add boxNum, 4
	inc i
	.endw

	;Now checking from Top -> Bottom Vertically for combos
	
	mov boxNum, 0 ; to store the first candy of the new row
	mov combo, 0	; stores only row/ column score
		
	mov i, 1
	mov j, 1
	
	.while (i <= 7) 
	
		mov j, 1
		;Moving to new Column
		.while (j <= 5) 
			
			mov bx, boxNum
			mov cx, candyIDsArray[bx]
			mov candyId, cx
			
			.if (candyId == 10)
				jmp SKIP_THIS_BOX_
			.endif
			
			.while(candyId ==  cx)
				inc combo		

				moveVarToArr comboBoxes, comboBoxIndex, bx
				add comboBoxIndex, 2
				inc numComboBoxes

				add bx, 14
				mov cx, candyIDsArray[bx]
				.endw	
		
			.if (combo < 3)	
				mov cx, combo
				REMOVE_COMBO_BOXES_:
			
					sub comboBoxIndex, 2
					moveVarToArr comboBoxes, comboBoxIndex, 99
					dec numComboBoxes
					mov combo,  0	
					
				loop REMOVE_COMBO_BOXES_
			.endif
			
			mov bx, combo
			add playerScore, bx
			
			SKIP_THIS_BOX_:
			mov combo,  0		
			add boxNum,  14
			inc j
		.endw
		
		sub boxNum, 5*14 ; going back on top of column	
		add boxNum, 2
		
	inc i
	.endw

	mov i, 0
	mov ax, numComboBoxes
	shl ax, 1
	
	.if (numComboBoxes > 0)
		drawCrushingOutline 15
		drawStringSC crushingStr, candyArray, 4, 28, 9, 1 ; Crushing text (appears)
	.endif	
	
	; Removing all the candies involved in combo (From Array)	
	.while (i <= ax)
			moveArrToVar boxNum, comboBoxes, i	
			moveVarToArr candyIDsArray, boxNum, 0
			
			push i
			push boxNum
			;----------------DRAWING BLACK BOXES MANUALLY-----------------
			delay 400
			mov bx,  boxNum
			setCandy xCoordsArray[bx] , yCoordsArray[bx] , candyIDsArray[bx]
			drawCandy candyArray, gridSize, padding
			;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
			pop boxNum
			pop i

		add i, 2
	.endw
	
	drawCrushingOutline 0
	drawStringSC crushingStr, candyArray, 4, 28, 0, 1 ; Crushing text (disappears)
	
	mov i, 0
	.while (i <= 96) 
		moveArrToVar candyId, candyIDsArray, i
		push i
		.if (candyId == 0)
			;----------------DRAWING BLACK BOXES MANUALLY-----------------
			.if (bombPresent == 0)
					genRandom randomNum, 0, 8
					.if (randomNum == 7)
						mov bombPresent, 1
					.endif
			.else
					genRandom randomNum, 0, 6
			.endif
		
			moveVarToArr candyIDsArray, i, randomNum
			delay 400
			mov bx,  i
			setCandy xCoordsArray[bx] , yCoordsArray[bx] ,randomNum
			drawCandy candyArray, gridSize, padding
			mov comboFound, 1
			;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
		.endif
		pop i
		add i, 2	
	.endw
		
	;Now reset the comboBoxes Array
	mov i, 0
	.while (i <= 96)
			moveVarToArr comboBoxes, i, 99
		add i, 2
	.endw
	
	 .if (comboFound == 1)
		 jmp FIND_COMBOS_AGAIN
	 .endif

	showCursor
	ret
	
findCombo endp

;--------------------------------------------------------------------------
;Checks for a minimum of 3 combo to check if swap is valid or not
verifySwap proc

	mov combo, 1
	mov boxNum, 1 ;Here it stores the number of boxes checked
	mov bx, firstClickBox
	mov cx, candyIDsArray[bx]
	mov candyId, cx
	
	
	; Checking if the candy was swapped with a bomb
	.if (candyId == 7)
		push  secondClickBox
		call bombFound
		ret
	.endif 

	mov combo, 1
	mov boxNum, 1 ;Here it stores the number of boxes checked
	
	mov bx, secondClickBox
	mov cx, candyIDsArray[bx]
	mov candyId, cx

	CHECK_COMBO_MIDDLE:
	
		;If in top row, only check left & right
		.if ((bx == 0) || (bx == 2)  || (bx == 4) || (bx == 6) || (bx == 8) || (bx == 10)  || (bx == 12))
			;Checking left
			.if (bx == 0) 
				jmp CHECK_PAIRS
			.else
				sub bx, 2
				mov cx, candyIDsArray[bx]
				.if (candyId == cx)
					;Checking right
					add bx, 2
					.if (bx == 12) 
						jmp CHECK_PAIRS
					.else
						add bx, 2
						mov cx, candyIDsArray[bx]
						.if (candyId == cx)
							ret
						.endif
					.endif
				.endif
			.endif
		.endif
			
		;If in last row, then again only check left & right
		.if ((bx == 84) || (bx == 86)  || (bx == 88) || (bx == 90) || (bx == 92) || (bx == 94)  || (bx == 96))
				;Checking left
				.if (bx == 84) 
					jmp CHECK_PAIRS
				.else
					sub bx, 2
					mov cx, candyIDsArray[bx]
					.if (candyId == cx)
						;Checking right
						add bx, 2
						.if (bx == 96) 
							jmp CHECK_PAIRS
						.else
							add bx, 2
							mov cx, candyIDsArray[bx]
							.if (candyId == cx)
								ret
							.endif
						.endif
					.endif
				.endif
			.endif
	
		;If in first column, only check up & down
		.if ((bx == 0) || (bx == 14)  || (bx == 28) || (bx == 42) || (bx == 56) || (bx == 70)  || (bx == 84))
				;Checking up
				.if (bx == 0) 
					jmp CHECK_PAIRS
				.else
					sub bx, 14
					mov cx, candyIDsArray[bx]
					.if (candyId == cx)
						;Checking down
						add bx, 14
						.if (bx == 84) 
							jmp CHECK_PAIRS
						.else
							add bx, 14
							mov cx, candyIDsArray[bx]
							.if (candyId == cx)
								ret
							.endif
						.endif
					.endif
				.endif
			.endif
		
		;If in last column, again only check up & down	
		.if((bx == 12) || (bx == 26)  || (bx == 40) || (bx == 54) || (bx == 68) || (bx == 82)  || (bx == 96))
				;Checking down
				.if (bx == 96) 
					jmp CHECK_PAIRS
				.else
					add bx, 14
					mov cx, candyIDsArray[bx]
					.if (candyId == cx)
						;Checking up
						sub bx, 14
						.if (bx == 12) 
							jmp CHECK_PAIRS
						.else
							sub bx, 14
							mov cx, candyIDsArray[bx]
							.if (candyId == cx)
								ret
							.endif
						.endif
					.endif
				.endif
			.endif

	;If in middle
	mov combo, 1
	mov boxNum, 1 ;Here it stores the number of boxes checked
	
	mov bx, secondClickBox
	mov cx, candyIDsArray[bx]
	mov candyId, cx
	
	
	;Checking Up/Down
	sub bx, 14
	moveArrToVar cx, candyIDsArray, bx
	.if (candyId == cx)
		add bx, 14*2
		moveArrToVar cx, candyIDsArray, bx
		.if (candyId == cx)
			ret
		.endif
	.endif
	
	mov bx, secondClickBox
	mov cx, candyIDsArray[bx]
	mov candyId, cx
	
	;Checking Left/Right
	add bx, 2
	moveArrToVar cx, candyIDsArray, bx
	.if (candyId == cx)
		sub bx, 2*2
		moveArrToVar cx, candyIDsArray, bx
		.if (candyId == cx)
			ret
		.endif
	.endif
	
	CHECK_PAIRS:
	
	CHECK_COMBO_RIGHT:
		
		;Base condition
		.if (combo == 3)
			ret
		.endif
		
		;Checking the next box
		add bx, 2
		mov cx, candyIDsArray[bx]
		
		.if (candyId == cx)
			inc combo
		.endif
		.if (candyId != cx)
			mov bx, secondClickBox
			mov combo, 1
			jmp CHECK_COMBO_LEFT
		.endif
		
		.if (((bx == 12) || (bx == 26)  || (bx == 40) || (bx == 54) || (bx == 68) || (bx == 82)  || (bx == 96)) && (combo < 3))
			mov bx, secondClickBox
			mov combo, 1
			jmp CHECK_COMBO_LEFT
		.endif
		
		jmp CHECK_COMBO_RIGHT

	CHECK_COMBO_LEFT:
	
		.if (combo == 3)
			ret
		.endif
		
		sub bx, 2
		mov cx, candyIDsArray[bx]
		
		.if (candyId == cx)
			inc combo
		.endif
		.if (candyId != cx)
			mov bx, secondClickBox
			mov combo, 1
			jmp CHECK_COMBO_UP
		.endif
		
		.if (((bx == 0) || (bx == 14)  || (bx == 28) || (bx == 42) || (bx == 56) || (bx == 70)  || (bx == 84)) && (combo < 3))
			mov bx, secondClickBox
			mov combo, 1
			jmp CHECK_COMBO_UP
		.endif
		
		jmp CHECK_COMBO_LEFT
	
	CHECK_COMBO_UP:
				
		.if (combo == 3)
			ret
		.endif
		
		sub bx, 14
		mov cx, candyIDsArray[bx]

		
		.if (candyId == cx)
			inc combo
		.endif
		
		.if (candyId != cx)
			mov bx, secondClickBox
			mov combo, 1
			jmp CHECK_COMBO_DOWN
		.endif
		
		.if (((bx == 0) || (bx == 2)  || (bx == 4) || (bx == 6) || (bx == 8) || (bx == 10)  || (bx == 12)) && (combo < 3))
			mov bx, secondClickBox
			mov combo, 1
			jmp CHECK_COMBO_DOWN
		.endif
		
		jmp CHECK_COMBO_UP
	
	CHECK_COMBO_DOWN:
	
	;Base condition
		.if (combo == 3)
			ret
		.endif
		
		;Checking the next box
		add bx, 14
		mov cx, candyIDsArray[bx]
		
		.if (candyId == cx)
			inc combo
		.endif
		.if (candyId != cx)
			mov bx, secondClickBox
			mov combo, 1
			mov boxNum, 1
			jmp NO_COMBOS
		.endif
		
		.if (((bx == 84) || (bx == 86)  || (bx == 88) || (bx == 90) || (bx == 92) || (bx == 94)  || (bx == 96)) && (combo < 3))
			mov bx, secondClickBox
			mov combo, 1
			mov boxNum, 1
			jmp NO_COMBOS
		.endif
		
		jmp CHECK_COMBO_DOWN
	
	NO_COMBOS:
	;No combo was found in any direction
	mov combo, 0
	ret
	
verifySwap endp

;--------------------------------------------------------
;Function which performs the necessary actions when a candy is swapped with bomb
bombFound proc
	pop retAddress
	pop boxNum
	
	hideCursor
	mov candiesDestroyedByBomb, 0
	mov bx, boxNum
	mov cx, candyIDsArray[bx]
	mov candyId, cx ; candyId now contains the type of candies that need to be exploded
	
	moveVarToArr candyIDsArray, firstClickBox,  candyId
	
	drawCrushingOutline 14
	drawStringSC explosionStr, candyArray, 4, 28, 15, 1 ; Crushing text (disappears)
	
	;Highlighting the box which is to be destroyed
	mov i, 0
	.while (i <= 96) 
		moveArrToVar j, candyIDsArray, i
		mov ax, j
		.if (candyId == ax)
			highlightBox candyArray, gridSize, i, 9
			delay 300
		.endif		
		add i, 2	
	.endw
	
	mov i, 0
	mov j, 0
	.while (i <= 96) 
		moveArrToVar j, candyIDsArray, i
		push i
		mov ax, j
		.if (candyId == ax)
			;----------------------DRAWING BLACK BOXES CANDIES MANUALLY------------------
			inc candiesDestroyedByBomb		
			moveVarToArr candyIDsArray, i, 0
			delay 400
			mov bx,  i
			highlightBox candyArray, gridSize, i, 9
			setCandy xCoordsArray[bx] , yCoordsArray[bx] , 0
			drawCandy candyArray, gridSize, padding
			;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
		.endif
		pop i
		
		add i, 2	
	.endw
	
		mov bombPresent, 0
		delay 300
		
		drawCrushingOutline 0
		drawStringSC explosionStr, candyArray, 4, 28, 0, 1 ; Crushing text (disappears)
	
		mov i, 0
		.while (i <= 96) 
		moveArrToVar candyId, candyIDsArray, i
		push i
		.if (candyId == 0)
			;----------------------DRAWING ACTUAL CANDIES MANUALLY---------------------------
			genRandom randomNum, 0, 6
			moveVarToArr candyIDsArray, i, randomNum
			mov bx,  i
			highlightBox candyArray, gridSize, bx, 7
			delay 400
			setCandy xCoordsArray[bx] , yCoordsArray[bx] ,randomNum
			drawCandy candyArray, gridSize, padding
			;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
		.endif
		pop i
		 
		add i, 2	
	.endw
	
	mov ax, candiesDestroyedByBomb
	
	.if (candyId == 1)
		add playerScore,  ax
	.elseif (candyId == 2)
		shl ax, 1
		add playerScore,  ax
	.elseif (candyId == 3)
		shl ax, 1
		shl ax, 1
		add playerScore,  ax
	.elseif (candyId == 4)
		shl ax, 1
		shl ax, 1
		shl ax, 1
		add playerScore,  ax
	.elseif (candyId == 5)
		shl ax, 1
		shl ax, 1
		shl ax, 1
		shl ax, 1
		add playerScore,  ax
	.elseif (candyId == 6)
		shl ax, 1
		shl ax, 1
		shl ax, 1
		shl ax, 1
		shl ax, 1
		add playerScore,  ax
	.endif
	
	push retAddress	
	showCursor
	ret
bombFound endp

;--------------------------------------------------------------------------
;Function which verifies the first click performed by the user (primarily used for level 2 & 3)
verifyFirstClick proc

		mov mouseClickValid, 1
		mov bx, firstClickBox
		mov cx, candyIDsArray[bx]
		.if (cx == 10)
			mov mouseClickValid, 0
		.endif
		ret
	
verifyFirstClick endp

;--------------------------------------------------------------------------
;Checking if the second click performed is within +-1 box (L,R,U,D) of the first click
verifySecondClick proc
	
	;Checking if first click and second click aren't on the same box
	mov ax, firstClickBox
	mov mouseClickValid, 1
	
	.if (secondClickBox == ax)
		mov mouseClickValid, 0 ; deselect first selected box
		ret
	.endif
	
	;Condition for level 2 and 3
	mov bx, secondClickBox
		mov cx, candyIDsArray[bx]
		.if (cx == 10)
			mov mouseClickValid, 0
			ret
		.endif

	
	;Without this, first row doesn't function correctly
	mov bx, firstClickBox
	.if (firstClickBox >=0) && (firstClickBox <=12)
		jmp SKIP_UP
	.endif
	
	;Up
	mov bx, firstClickBox
	mov ax, yCoordsArray[bx]
	sub ax, gridSize*2
	.if (mouseY < ax)
		mov mouseClickValid, 0
		ret
	.endif
	
	SKIP_UP:
	;Down	
	mov bx, firstClickBox
	mov ax, yCoordsArray[bx]
	add ax, gridSize
	.if (mouseY > ax)
		mov mouseClickValid, 0
		ret
	.endif
	
	;Right	
	mov bx, firstClickBox
	mov ax, xCoordsArray[bx]
	add ax, gridSize*2
	.if (mouseX > ax)
		mov mouseClickValid, 0
		ret
	.endif
	
	;Left	
	mov bx, firstClickBox
	mov ax, xCoordsArray[bx]
	sub ax, gridSize
	.if (mouseX < ax)
		mov mouseClickValid, 0
		ret
	.endif
	
	ret
	
verifySecondClick endp

;--------------------------------------------------------
;Function which re-redraws the board (not randomly)
updateBoard proc

	.if (currLevel == 3)
		setBackground 8
	.else
	setBackground 0
	.endif
	drawBoard gridXoffset, gridYoffset, 7,1
	call displayInformation
	
	mov yC, gridYoffset + gridSize
	mov xC, gridXoffset
	mov boxNum, 0

	.while (yC != gridSize*8 + gridYoffset) 
		.while (xC != gridSize*7 + gridXoffset)
			
			mov bx, boxNum
		
			setCandy xCoordsArray[bx] , yCoordsArray[bx] , candyIDsArray[bx]
			drawCandy candyArray, gridSize, padding
			
			add boxNum, 2
			add xC, gridSize	
		.endw
	
	mov xC, gridXoffset
	add yC, gridSize
	.endw

	showCursor
	ret
	
updateBoard endp 

;--------------------------------------------------------
; Pushes the box number on x,y coordinates to stack
findBoxFromCoords proc

	pop retAddress
	
	;Traversing through the Board and finding the box on which user clicked
	mov boxNum, 0
	.while (boxNum <= 49*2)
	
		mov bx, boxNum
		
		mov ax, xCoordsArray[bx]
		add ax, gridSize
		mov cx, xCoordsArray[bx]
		
		.if ((mouseX >= cx) && (mouseX < ax))
		
			mov ax, yCoordsArray[bx]
			sub ax, gridSize
			mov cx, yCoordsArray[bx]
						
			.if ((mouseY <= cx) && (mouseY > ax))
				push bx  ; box number required is pushed into stack
				mov dx, candyIDsArray[bx]
				mov candyId, dx
			.endif	
			
		.endif
		add boxNum, 2
	.endw
	push retAddress
	ret
findBoxFromCoords endp

;--------------------------------------------------------------------------
;Storing score in textFile
storeScoreInFile proc
	
	;File doesn't exist, creating a new one
	CREATE_NEW_FILE:
	mov ah, 3ch ;Function number
	mov dx, offset (fileName)
	mov cl, 1 ;Selecting appropriate mode
	int 21h
	mov file, ax
	
	writeToFile file, playerName
	writeToFile file, newline
	
	writeToFile file, scoreL1Str
	convertIntToStr  playerScoreL1Str, playerScoreL1, i
	writeToFile file, playerScoreL1Str
	writeToFile file, newline
	
	writeToFile file, scoreL2Str
	convertIntToStr  playerScoreL2Str, playerScoreL2, i
	writeToFile file, playerScoreL2Str
	writeToFile file, newline
	
	writeToFile file, scoreL3Str
	convertIntToStr  playerScoreL3Str, playerScoreL3, i
	writeToFile file, playerScoreL3Str
	writeToFile file, newline
	
	writeToFile file, highestScoreStr
	convertIntToStr  playerHighestScoreStr, playerHighestScore, i
	writeToFile file, playerHighestScoreStr

	CLOSE_FILE:
	;Closing openeed file
	mov ah, 3eh
	mov dx, file
	int 21h
	ret
	
storeScoreInFile endp


;--------------------------------------------------------------------------
;Function to display the title page
displayTitlePage proc 
	
	setBackground 0
	DrawLogo candyArray
		
	drawStringSC welcomeStr, candyArray, 7,17, 15, 200			;Welcome
	drawStringSC toStr, candyArray, 9, 20, 15, 200						;to
	drawStringRC candyCrushStr, candyArray, 11, 10, 2, 380		;Candy Crush
	drawStringSC enterNameStr, candyArray, 20, 8, 15, 150		;Enter Name: 
	
    mov si, offset playerName
	mov j, 0
	
	;Taking user name in a similar fashion as we used to take input of numbers
	INPUT_NAME:
		mov ah, 01h
		int 21h
		cmp al, 13 ;Keep taking input of name until enter key is not pressed
		je NAME_ENTER_SUCCESS
		
		mov [si], al
		inc j
		
		.if ( j == 15) ; Maximum length of name can be 15 chars
			jmp NAME_ENTER_SUCCESS	; 16th index reserved for $ so jump if 15 characters are entered by user
		.endif
		inc si
	jmp INPUT_NAME		
		
	NAME_ENTER_SUCCESS:
	mov si, offset playerName
	add si, 16
	mov al, '$' ;Manually appending dollar sign to the last index of array which stores string
	mov [si], al
	
	ret
displayTitlePage endp

;--------------------------------------------------------------------------
;Function to display the menu page
displayMainPage proc

	setBackground 0 ; Setting up video mode (resetting)
	
	drawRandomCandies ;Drawing random candies in background aesthetics
	drawBorder candyArray ;Drawing border for aesthetics
	
	drawStringSC greetingStr, candyArray, 3,10, 15, 150
	drawStringSC playerName, candyArray, 3, 21, 9, 150
	drawChar 1, 10, 19
	
	drawStringSC playGameStr, candyArray, 12, 15, 15, 100
	drawStringSC gameRulesStr, candyArray, 14, 15, 15, 100
	drawStringSC viewHighScores, candyArray, 16, 12, 15, 100
	drawStringSC exitStr, candyArray, 18, 18, 15, 100

		;Please see Drawings.lib file for better explanation of macros
		; Known bug: for any case, if user presses any key other than enter, it still proceeds forward.
		CHOICE_1:
			drawTriangle candyArray, 100, 95, 15 ; x,y, colour
			drawTriangle candyArray, 100, 110, 0 ; Over-riding any previously drawn triangle on any other option
			drawTriangle candyArray, 75, 125, 0
			drawTriangle candyArray, 122, 143, 0
			
			drawStringSC playGameStr, candyArray, 12, 15, 7, 1 ; row, column, colour, delay time
			drawStringSC gameRulesStr, candyArray, 14, 15, 15, 1 ; Over-riding any previously highlighted option
			drawStringSC viewHighScores, candyArray, 16, 12, 15, 1
			drawStringSC exitStr, candyArray, 18, 18, 15, 1

			mov selectedChoice, 1 ; Setting active choice
			
			mov ah, 0
			int 16h
			cmp ah, 80
				jz CHOICE_2
			cmp ah, 72
				jz CHOICE_4
			cmp al, 13
				jz CHOICE_SELECTED_SUCCESS
						
		CHOICE_2:
			drawTriangle candyArray, 100, 95, 0
			drawTriangle candyArray, 100, 110, 15
			drawTriangle candyArray, 75, 125, 0
			drawTriangle candyArray, 122, 143, 0
			
			drawStringSC playGameStr, candyArray, 12, 15, 15, 1
			drawStringSC gameRulesStr, candyArray, 14, 15, 7, 1
			drawStringSC viewHighScores, candyArray, 16, 12, 15, 1
			drawStringSC exitStr, candyArray, 18, 18, 15, 1
			
			mov selectedChoice, 2
			
			mov ah, 0
			int 16h
			cmp ah, 80
				jz CHOICE_3
			cmp ah, 72
				jz CHOICE_1
			cmp al, 13
				jz CHOICE_SELECTED_SUCCESS
		
		CHOICE_3:
			drawTriangle candyArray, 100, 95, 0
			drawTriangle candyArray, 100, 110, 0
			drawTriangle candyArray, 75, 125, 15
			drawTriangle candyArray, 122, 143, 0
			
			drawStringSC playGameStr, candyArray, 12, 15, 15, 1
			drawStringSC gameRulesStr, candyArray, 14, 15, 15, 1
			drawStringSC viewHighScores, candyArray, 16, 12, 7, 1
			drawStringSC exitStr, candyArray, 18, 18, 15, 1
		
			mov selectedChoice, 3
			
			mov ah, 0
			int 16h
			cmp ah, 80
				jz CHOICE_4
			cmp ah, 72
				jz CHOICE_2
			cmp al, 13
				jz CHOICE_SELECTED_SUCCESS
		
		CHOICE_4:
			drawTriangle candyArray, 100, 95, 0
			drawTriangle candyArray, 100, 110, 0
			drawTriangle candyArray, 75, 125, 0
			drawTriangle candyArray, 122, 143, 15
			
			drawStringSC playGameStr, candyArray, 12, 15, 15, 1
			drawStringSC gameRulesStr, candyArray, 14, 15, 15, 1
			drawStringSC viewHighScores, candyArray, 16, 12, 15, 1
			drawStringSC exitStr, candyArray, 18, 18, 7, 1

			mov selectedChoice, 4
			
			mov ah, 0
			int 16h
			cmp ah, 80
				jz CHOICE_1
			cmp ah, 72
				jz CHOICE_3
			cmp al, 13
				jz CHOICE_SELECTED_SUCCESS				
				
	CHOICE_SELECTED_SUCCESS:	

	ret
displayMainPage endp

;--------------------------------------------------------------------------
;Function to display the rules page
displayRulesPage proc

	setBackground 0	
	
	drawStringSC ruleStr, candyArray, 2,12, 9, 30
	drawStringSC rule1Str, candyArray, 6,0, 15, 30
	drawStringSC rule2Str, candyArray, 8,0, 15, 50
	drawStringSC rule3Str, candyArray, 10,0, 15, 70
	drawStringSC rule4Str, candyArray, 12,0, 15, 90
	drawStringSC rule5Str, candyArray, 14,0, 15, 110
	drawStringSC rule6Str, candyArray, 16,0, 15, 130
	
	drawStringSC pressAnyKeyToContinueStr, candyArray, 23,0, 7, 200
	
	mov ah, 0
	int 16h ; Interrupt to wait for keyboard input
	
	ret
displayRulesPage endp

;--------------------------------------------------------------------------
;Function to display the high scores
displayHighScores proc

	setBackground 0	

	drawStringSC workInProgressStr, candyArray, 13, 12, 4, 150
	drawStringSC pressAnyKeyToContinueStr, candyArray, 23,0, 7, 200
	
	mov ah, 0
	int 16h ; Interrupt to wait for keyboard input
	ret

displayHighScores endp

;--------------------------------------------------------------------------
;Function which displays the current user statistics 
displayInformation proc

	;Values are hard coded right now, they would be dynamic later!
	drawStringSC infoStatsStr, candyArray, 8, 28, 15, 1
	drawStringSC infoLevelStr, candyArray, 12, 29, 15,1
	printChar currLevel
	drawStringSC infoMovesStr, candyArray, 14, 29, 15,1
	push playerMoves
	print
	drawStringSC infoScoreStr, candyArray, 16, 29, 15,1
	push playerScore
	print 
	ret
	
displayInformation endp

;--------------------------------------------------------------------------
displayMenu proc
	
	;Need label so we can loop in menu (in-case user decides to view high score or rules)
	MAIN_PAGE:
	
		;Calling function to display menu page
		call displayMainPage
		
		;What happens next depends on the choice selected by user in menu
		cmp selectedChoice, 1
			jz PLAY_GAME
		cmp selectedChoice, 2
			jz VIEW_RULES
		cmp selectedChoice, 3
			jz VIEW_HIGH_SCORE
		cmp selectedChoice, 4
			jz QUIT
			
	VIEW_RULES:
		call displayRulesPage
		jmp MAIN_PAGE
		
	VIEW_HIGH_SCORE:
		call displayHighScores
		jmp MAIN_PAGE
		
		
	QUIT:
		quitGame
	
	PLAY_GAME:
	
	ret
displayMenu endp

end


comment !

	Notes:

	MouseClickValid:
		0 = input is invalid
		1 = input is perfectly fine
		
	
	Board Design:
	
	-----------------------------
	| 00 | 02 | 04 | 06 | 08 | 10 | 12   |
	| 14  | 16 | 14  | 20 | 22 | 24 | 26 |
	| 28 | 30 | 32 | 34 | 36 | 38 | 40 |
	| 42 | 44 | 46| 48 | 50 | 52 | 54 |
	| 56 | 58 | 60 | 62 | 64 | 66 | 68 |
	| 70 | 72 | 74 | 76 | 78 | 80 | 82 |
	| 84 | 86 | 88 | 90 | 92 | 94 | 96 |
    -----------------------------
	
	
		;Top Row
		.if ((bx == 0) || (bx == 2)  || (bx == 4) || (bx == 6) || (bx == 8) || (bx == 10)  || (bx == 12))
		
		;Bottom Row
		.if ((bx == 84) || (bx == 86)  || (bx == 88) || (bx == 90) || (bx == 92) || (bx == 94)  || (bx == 96))
		
		;Left-most column
		.if ((bx == 0) || (bx == 14)  || (bx == 28) || (bx == 42) || (bx == 56) || (bx == 70)  || (bx == 84))
			
		;Right-most column	
		.if((bx == 12) || (bx == 26)  || (bx == 40) || (bx == 54) || (bx == 68) || (bx == 82)  || (bx == 96))
					
!		

		
		