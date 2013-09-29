-- # Robot finds kitten - Corona edition
--
-- In robot finds kitten (rfk) a robot strikes out to find his lost kitten.
-- The goal is to travel the map searching obstacles for the kitten.


--## The main game function.

-- This function contains the entire code to start and run the game. We put
-- it all inside a function so that when the player finishes, they can start
-- over without closing and restarting the game.

function play()

	-- Gather some information about the current screen.

	local screenWidth = display.contentWidth
	local screenHeight = display.contentHeight

	-- We want to make the main map as big as possible, but we need to
	-- have room for controls on the left side, so we'll portion out one
	-- sixth (1 / 6) of the screen width for the controller.
	local controllerWidth = screenWidth / 6

	-- We also want to leave a bit of room on the right side so the map doesn't
	-- touch the edge of the screen.
	local rightMargin = 30

	--### Build the map grid.

	-- Games need a field of play. One type of field is a two-dimensional grid.
	-- It's like taking graph paper and laying it over a section of your screen
	-- then you allow your game pieces to move between the grid squares based
	-- on the rules of the game. Chess and Checkers are board games that work
	-- this way. The Legend of Zelda (on old Nintendo) is a video game that
	-- works this way and there are lots of others. Can you think of a few?

	-- We want to make a grid. To do this in Lua we'll use an object. Let's
	-- start with an empty one.
	local grid = {}

	-- Grids can be described by the number of squares across as well as the
	-- number of squares up and down. We call the squares from left to right
	-- "the *x* direction and squares up and down the *y* direction.
	grid.xSquares = 10
	grid.ySquares = 7

	-- The total width of our grid is going to be the width of the screen
	-- without the space taken up by the controller and without the space we
	-- decided to leave for our margin.
	grid.totalWidth = screenWidth - controllerWidth - rightMargin

	-- Since we already decided how big our whole grid will be and how many
	-- squares it will have, we can figure out how big our squares are using
	-- basic algebra. The size of each square is equal to the width of the whole
	-- map divided by the width of each square.
	grid.squareSize = grid.totalWidth / grid.xSquares

	-- We're going to start our map at the edge of our controller. The last
	-- pixel of our controller area is going to be the first pixel of our map
	-- grid.
	grid.xStart = controllerWidth

	-- Just like we wanted to leave a bit of room along the right edge, we want
	-- to leave some room on top of the screen. I found this to be a good
	-- size but you can change it if you want.
	grid.yStart = 60

	-- Lastly, we want to create a group for all the grid tiles and objects on
	-- our map so we can move them around all at once. This is going to help us
	-- with positioning elements on screen later on.
	grid.displayGroup = display.newGroup()

	-- The map is going to be shown on screen with its (0, 0) being the
	-- (xStart, yStart) of the total screen.
	grid.displayGroup.x = grid.xStart
	grid.displayGroup.y = grid.yStart

	-- So our players can see how big the map is, we want to fill the map area
	-- with a background. We'll use a rounded rectangle. It's a rectangular
	-- shape with the corners rounded off so they're not as sharp. Just like
	-- rounded edges make things easier to sit on, they also make things easier
	-- to look at.
	--
	-- The rectangle belongs to our grid's display group and it starts at the
	-- origin or (0, 0), which in computer grids is usually the top left corner
	-- of the grid.
	--
	-- The width of the map is equal to the number of squares in the *x*
	-- direction times the size of one square. The height is similarly the
	-- number of squares in the *y* direction times the size of one square.
	grid.area = display.newRoundedRect(grid.displayGroup, 0, 0, grid.xSquares *
	grid.squareSize, grid.ySquares * grid.squareSize, 50)

	-- Let's make the grid a bright grey color so it's easy to see.
	grid.area:setFillColor(218, 218, 218)

	--### Grid functions

	-- These functions will be placed on our grid squares. They'll help us find
	-- adjacent squares when we need them.
	grid.functions = {
		-- This function looks for the square to the left of the current one. If
		-- this square's *x* coordinate is 0, that means it must be the leftmost
		-- square in that row, so we just say that the square to the left of this
		-- one is the same as this one. Otherwise, we find the square in this same
		-- row whose *x* coordinate is one less than our current square.
		left = function(gridSquare)
			if gridSquare.x == 0 then
				return gridSquare
			else
				return grid[gridSquare.x - 1][gridSquare.y]
			end
		end,

		-- When trying to find the square to the right, we need to watch out for
		-- the rightmost square. Since we started counting squares at 0, the
		-- rightmost square's *x* coordinate will be one less than the number of
		-- grid squares in the *x* direction. So if the next square would be equal
		-- to that number, we're at the end, and we give back the same square we
		-- got, just like before otherwise, we return the square whose *x*
		-- coordinate is one more than our current square.
		right = function(gridSquare)
			if gridSquare.x + 1 == grid.xSquares then
				return gridSquare
			else
				return grid[gridSquare.x + 1][gridSquare.y]
			end
		end,

		-- If we're looking for the square above our current one. If we're in
		-- the top row, that means we give back this square, otherwise we take
		-- the square whose *y* coordinate is one less than the current square.
		above = function(gridSquare)
			if gridSquare.y == 0 then
				return gridSquare
			else
				return grid[gridSquare.x][gridSquare.y - 1]
			end
		end,

		-- Just one more! To find the square below, we add one to the *y*
		-- coordinate. Unless of course we're in the last row, in which case we
		-- return the given square.
		below = function(gridSquare)
			if gridSquare.y + 1 == grid.ySquares then
				return gridSquare
			else
				return grid[gridSquare.x][gridSquare.y + 1]
			end
		end,
	}

	-- ## Setting up the map grid.

	-- In order to set up a grid, we'll loops to avoid repeating out similar code
	-- for each of the grid squares. Because we have *x* coordinates and *y*
	-- coordinates we'll use nested loops. One within another. This means that
	-- each time we change the *x* coordinate we'll go through a whole column of
	-- *y* values, then start a new column.

	-- This loop will count x coordinates from 0 to 9. How many columns will
	-- that create?
	for x = 0, 9 do

		-- The first thing we do is create a column for this coordinate.
		-- We use `[]` to "index" the column with its coordinate and set the
		-- x field for this column to be the *x* coordinate value.
		grid[x] = {x = x}

		-- Now that we've set up our column it's time to make our way down the
		-- *y* values starting from 0 and going to 5. How many rows will this
		-- create?
		for y = 0, 5 do

			-- For each grid square, we'll set it up to be indexed first by
			-- its *x* coordinate and next by its *y* coordinate. We also
			-- set the x and y fields of the square to match its coordinates.
			grid[x][y] = {x = x, y = y} -- Create grid element.

			-- Now we create a display object for the rectangle. This is what
			-- will allow us to actually draw the object on the screen.
			-- The rectangle is part of the grid's display group. Just like we
			-- are creating our own grid system, your computer has a grid system
			-- made up of individual pixels and the *x* and *y* coordinates of
			-- the display object aren't our *x* and *y* but we'll use our
			-- coordinates to compute the pixel coordinates.

			-- The pixel coordinate of a square will be our coordinate times the
			-- size in pixels of a single square, then the width and height will
			-- be that size alone.
			local rect = display.newRect(grid.displayGroup,
			grid.squareSize * x, grid.squareSize * y,
			grid.squareSize, grid.squareSize)

			-- We're going to make our grid invisible. If you want to see where
			-- it will be, add the lines
			-- ```lua
			-- rect:setStrokeColor(0, 0, 0, 0.25)
			-- rect.strokeWidth = 5
			-- ```
			-- to the end of this block.
			rect:setFillColor(0, 0, 0, 0)

			-- Now that we've created our display object, we attach it to our
			-- grid square.
			grid[x][y].displayObject = rect

			-- And finally we attach the functions we wrote earlier to each
			-- square so it is more convient to call on them later.
			grid[x][y].left = grid.functions.left
			grid[x][y].right = grid.functions.right
			grid[x][y].above = grid.functions.above
			grid[x][y].below = grid.functions.below

			-- The end of one column.
		end
		-- The end of one row.
	end


	--## Create the robot and kitten

	-- Finally we get to the stars of our game! We'll create a robot object
	-- and a kitten object and give each of them an image field that holds
	-- the name of the image we'll use to show them on the screen.
	local robot = { image = "robot.png" }
	local kitten = { image = "kitten.png" }


	-- Now we need a function to allow the robot and kitten to move to a
	-- particular square 
	local function enter(character, gridSquare)
		-- The first time we show the character, there won't be a display object,
		-- so we'll have to create one.
		if character.displayObject == nil then
			character.displayObject = display.newImageRect(grid.displayGroup,
			character.image, grid.squareSize, grid.squareSize)
		end

		-- Now our character's display object should be in the same position on
		-- the screen as the grid square that character is in.
		character.displayObject.x = gridSquare.displayObject.x
		character.displayObject.y = gridSquare.displayObject.y

		-- We'll keep track of the grid square each character is in. It will come
		-- in handy when they want to move.
		character.gridSquare = gridSquare

		-- we'll also save the *x* and *y* coordinate of the character just like
		-- the grid square.
		character.x = gridSquare.x
		character.y = gridSquare.y
	end

	-- It's convenient for us to attach this function directly to each
	-- character.
	robot.enter = enter
	kitten.enter = enter

	-- The robot can only enter squares that don't have obstacles. Even though
	-- all this method does is check for the presence of an obstacle, we'll do
	-- it like this because it controls the actions of the robot.
	function robot:canEnter(gridSquare)
		return gridSquare.obstacle == nil
	end

	-- The robot starts off in the top left square. The kitten starts off
	-- hidden, so we don't have it enter any square.
	robot:enter(grid[0][0])


	--##  Creating the controls.

	-- Our controls will be composed of an on-screen directional pad, just like
	-- the one on a video game controller. Pressing the up, down, left, and
	-- right buttons will move the robot around the map grid 

	-- The center of our control pad will be at the halfway point of the control
	-- area width...
	local controlCenterX = controllerWidth / 2

	-- and one fifth of the way from the bottom of the screen.
	local controlCenterY = screenHeight - screenHeight / 5

	-- The radius of the control pad will be just slightly smaller than half
	-- the width of the controller area. This will leave a margin on the left
	-- side, as well as some distance from the map grid.
	local controlCenterRadius = controllerWidth / 2 - rightMargin

	-- Now create a circle to house our directional pad.
	local circlePad = display.newCircle(controlCenterX, controlCenterY, controlCenterRadius)
	-- Let's make it stand out from the background.
	circlePad:setFillColor(128, 128, 128)

	-- The size of our control buttons. The up and down
	local upDownWidth = 27
	local upDownHeight = 60

	-- The size of the left and right control buttons.
	local leftRightWidth = 60
	local leftRightHeight = 27

	-- Container tables for the controls.
	local controls = {
		up    = {},
		down  = {},
		right = {},
		left  = {},
	}

	-- Here we create the display objects for the controls and place them on the
	-- screen inside our control circle. Each one is then assigned to the display
	-- object field of the control table.
	local up = display.newImageRect("arrow_up.png", upDownWidth, upDownHeight)
	up.x = controlCenterX
	up.y = controlCenterY - upDownHeight / 2
	controls.up.displayObject = up

	local down = display.newImageRect("arrow_down.png", upDownWidth, upDownHeight)
	down.x = controlCenterX
	down.y = controlCenterY + upDownHeight / 2
	controls.down.displayObject = down

	local right = display.newImageRect("arrow_right.png", leftRightWidth, leftRightHeight)
	right.x = controlCenterX + leftRightWidth / 2
	right.y = controlCenterY
	controls.right.displayObject = right

	local left = display.newImageRect("arrow_left.png", leftRightWidth, leftRightHeight)
	left.x = controlCenterX - leftRightWidth / 2
	left.y = controlCenterY
	controls.left.displayObject = left

	--## Display the saying

	-- This is the saying that appears at the bottom of the screen whenever a
	-- new obstacle is encountered.

	local saying = {
		font = native.systemFont,
		x = 100, y = 700,
		fontSize = 48
	}

	-- We need a method that allows us update the saying's text with some new
	-- text.
	function saying:update(newText)
		-- If no saying has ever been displayed, we need to create a display
		-- object for the text.
		if self.displayText == nil then
			self.displayText = display.newText(newText,
			self.x, self.y,
			self.font, self.fontSize)
			-- Otherwise, we just update the text of the existing display object.
		else
			self.displayText.text = newText
		end
	end

	-- Now we can set the starting message using the method we just wrote.
	saying:update("Where is the kitten?")

	--## Display obstacles

	-- Our kitten needs some obstacles to hide behind. Each obstacle will have
	-- an image, which is the name of the image file that we'll use to display
	-- the obstacle. Each obstacle should also have a saying associated with it
	-- the sayings can be anything you want but they should make you feel happy
	-- and thoughtful.

	-- We'll start out with an empty table to put our obstacles in.
	local obstacles = {}

	-- This function is going to be used as a method for each of our obstacles.
	-- It will check if there's a kitten hiding behind this obstacle and send
	-- back true or false. We'll associate this function with each table as the
	-- hasKitten method.
	local function obstacleHasKitten(obstacle)
		return obstacle.kitten == true
	end

	-- This function will be used to place the obstacle on the grid somewhere.
	-- It will be attached to each obstacle as the put method.
	local function putObstacle(obstacle, gridSquare)
		obstacle.x = gridSquare.x
		obstacle.y = gridSquare.y
		obstacle.displayObject = display.newImageRect(grid.displayGroup, obstacle.image,
		grid.squareSize, grid.squareSize)
		obstacle.displayObject.x = gridSquare.displayObject.x
		obstacle.displayObject.y = gridSquare.displayObject.y
		gridSquare.obstacle = obstacle
	end


	-- One of the obstacles will be a rock.
	obstacles.rock = {
		image = "rock.png",
		saying = "There is no spoon.. or cat",
		hasKitten = obstacleHasKitten,
		put = putObstacle,
	}
	-- In addition to giving each obstacle a name, we're also going to keep them
	-- in a list. Remember that you can use tables as lists if you use numbers
	-- for the field names.
	obstacles[0] = obstacles.rock

	obstacles.trashcan = {
		image = "trash.png",
		saying = "Hmm. What was I looking for?",
		hasKitten = obstacleHasKitten,
		put = putObstacle,
	}
	obstacles[1] = obstacles.trashcan

	obstacles.bush = {
		image = "bush.png",
		saying = "The sky is nice today.",
		hasKitten = obstacleHasKitten,
		put = putObstacle,
	}
	obstacles[2] = obstacles.bush

	-- Now we can put our obstacles on the screen.
	obstacles.rock:put(grid[4][1])
	obstacles.bush:put(grid[6][3])
	obstacles.trashcan:put(grid[2][5])

	-- Now that our obstacles are all placed, let's hide the kitten behind a
	-- different one each time using a random number generator.
	obstacles[math.random(0, 2)].kitten = true

	--## Make the robot move

	-- Now it's time to create functions that will move our robot into new grid
	-- squares. We'll define functions for moving left, right, up, and down.
	-- The function will check that the grid square has no obstacle before 
	-- moving into it. If the square is free, the robot will move there.
	-- Otherwise we'll see if the kitten is hiding in this obstacle. If there is
	-- a kitten, then the game is over. If there's not we just update the saying
	-- to be whichever one is associated with this obstacle.

	-- This function will run when we press the left arrow.
	local function pressLeft(event)
		if event.phase == "began" then
			local nextSquare = robot.gridSquare:left()
			if robot:canEnter(nextSquare) then
				robot:enter(nextSquare)
			elseif nextSquare.obstacle:hasKitten() then
				robotfindskitten()
			else
				saying:update(nextSquare.obstacle.saying)
			end
		end
	end

	-- This function will run when we press the right arrow.
	local function pressRight(event)
		if event.phase == "began" then
			local nextSquare  = robot.gridSquare:right()
			if robot:canEnter(nextSquare) then
				robot:enter(nextSquare)
			elseif nextSquare.obstacle:hasKitten() then
				robotfindskitten()
			else
				saying:update(nextSquare.obstacle.saying)
			end
		end
	end

	-- This function will run when we press the up arrow.
	local function pressUp(event)
		if event.phase == "began" then
			local nextSquare  = robot.gridSquare:above()
			if robot:canEnter(nextSquare) then
				robot:enter(nextSquare)
			elseif nextSquare.obstacle:hasKitten() then
				robotfindskitten()
			else
				saying:update(nextSquare.obstacle.saying)
			end
		end
	end

	-- This function will run when we press the down arrow.
	local function pressDown(event)
		if event.phase == "began" then
			local nextSquare  = robot.gridSquare:below()
			if robot:canEnter(nextSquare) then
				robot:enter(nextSquare)
			elseif nextSquare.obstacle:hasKitten() then
				robotfindskitten()
			else
				saying:update(nextSquare.obstacle.saying)
			end
		end
	end

	-- Now we register each function as an event listener for the touch
	-- event on the display object associated with each arrow.
	controls.left.displayObject:addEventListener("touch", pressLeft)
	controls.right.displayObject:addEventListener("touch", pressRight)
	controls.up.displayObject:addEventListener("touch", pressUp)
	controls.down.displayObject:addEventListener("touch", pressDown)


	--## Robot finds kitten!

	-- This function will be used to move the robot and kitten together. Each
	-- time you run it, they get one square closer to eachother.
	local function animatedReunion()
		robot:enter(grid[robot.x + 1][robot.y])
		kitten:enter(grid[kitten.x - 1][kitten.y])
	end

	-- We'll create a button that allows you to play again. It will appear where
	-- the control arrows used to be.
	local function showPlayAgain()
		local playAgainButton = display.newCircle(controlCenterX, controlCenterY, controlCenterRadius)
		-- We'll give the button some color and accent.
		playAgainButton.strokeWidth = 6
		playAgainButton:setStrokeColor(244, 244, 64)

		-- Write what the button does.
		local playAgainText = display.newText("Again", controlCenterX - controlCenterRadius + 20,
		controlCenterY - 18, native.systemFont, 24)
		playAgainText:setTextColor(0, 0, 0)

		-- This function will run whenever you hit the play again button. It will
		-- remove the button from existence and then play the game again.
		local function playAgainButtonActivate(event)
			if event.phase == "began" then
				display.remove(playAgainButton)
				display.remove(playAgainText)
				playAgainButton = nil
				playAgainText = nil
				play()
			end
		end
		-- We'll add the activate function as the event listener for the play
		-- again button.
		playAgainButton:addEventListener("touch", playAgainButtonActivate)
	end

	-- This function will run when the game is over.
	function robotfindskitten()
		-- Remove all obstacles.
		for i = 0, 2 do
			grid.displayGroup:remove(obstacles[i].displayObject)
			obstacles[i].displayObject = nil
		end

		-- Create a display object for the kitten.
		kitten.displayObject = display.newImageRect(grid.displayGroup, "kitten.png",
		grid.squareSize, grid.squareSize)
		-- Set the enter method for the kitten.
		kitten.enter = robot.enter

		-- Move the robot into the 4th row.
		robot:enter(grid[0][4])
		-- Move the kitten onto the grid, across from the robot.
		kitten:enter(grid[9][4])

		-- We need to hide all of the controls, so the player can't interrupt the
		-- reunion.
		display.remove(circlePad)
		circlePad = nil
		display.remove(controls.up.displayObject)
		controls.up.displayObject = nil
		display.remove(controls.down.displayObject)
		controls.down.displayObject = nil
		display.remove(controls.left.displayObject)
		controls.left.displayObject = nil
		display.remove(controls.right.displayObject)
		controls.right.displayObject = nil

		-- Remove the saying.
		display.remove(saying.displayText)
		saying.displayText = nil

		-- Now we animate the robot and kitten getting closer and closer until they
		-- finally reunite.
		timer.performWithDelay(1000, animatedReunion, 4)
		-- Lastly, we show the play again button after the animation is over.
		timer.performWithDelay(4000, showPlayAgain, 1)
	end
end

play()
