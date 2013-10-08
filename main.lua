-- # Speed Maze 
-- ## Corona SDK Game

-- In this game we'll have a tiny space invader who is trying to quickly
-- traverse a maze.

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

-- ## Set up the maze map

-- We'll describe our maze using list-style Lua tables. This will let us
-- convey a lot of information with less typing. Our maze will be made of
-- a grid of pathways and walls. We can choose to use any two different values
-- to specify which grid squares have walls, and which have paths. I'm going
-- to use `0` for paths and `1` for walls but you could just as easily use
-- `"w"` for walls and `"p"` for paths. I use 0 and 1 because it's less to
-- type. Each row of the the maze grid is one list and the entire maze is just
-- a list of lists.
local maze = {
	{ 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
	{ 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
	{ 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1 },
	{ 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1 },
	{ 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1 },
	{ 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 },
	{ 0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0 },
	{ 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1 },
	{ 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1 },
	{ 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1 },
	{ 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1 },
	{ 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1 },
}
maze.rows = table.getn(maze)
maze.columns = table.getn(maze[1])
maze.xStart, maze.yStart = 1, 1
maze.xFinish, maze.yFinish = 24, 7

--###### Alternative Maze storage possibilities


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
grid.xSquares = maze.columns
grid.ySquares = maze.rows

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
			return grid[gridSquare.y][gridSquare.x - 1]
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
			return grid[gridSquare.y][gridSquare.x + 1]
		end
	end,

	-- If we're looking for the square above our current one. If we're in
	-- the top row, that means we give back this square, otherwise we take
	-- the square whose *y* coordinate is one less than the current square.
	above = function(gridSquare)
		if gridSquare.y == 0 then
			return gridSquare
		else
			return grid[gridSquare.y - 1][gridSquare.x]
		end
	end,

	-- Just one more! To find the square below, we add one to the *y*
	-- coordinate. Unless of course we're in the last row, in which case we
	-- return the given square.
	below = function(gridSquare)
		if gridSquare.y + 1 == grid.ySquares then
			return gridSquare
		else
			return grid[gridSquare.y + 1][gridSquare.x]
		end
	end,
}
-- ## Setting up the map grid.

-- In order to set up a grid, we'll loops to avoid repeating out similar code
-- for each of the grid squares. Because we have *x* coordinates and *y*
-- coordinates we'll use nested loops. One within another. This means that
-- each time we change the *y* coordinate we'll go through a whole column of
-- *x* values, then start a new row.

-- We'll start with rows this time around. Previously we started with *x*
-- values in the outer loop but because it's easier to write lists in rows
-- than in columns, we've switched it here so it will line up with our maze
-- better.
for y = 0, grid.ySquares - 1 do
	-- The first thing we do is create a row for this coordinate. We use `[]`
	-- to "index" the column with its coordinate and set the x field for this
	-- column to be the *x* coordinate value.
	grid[y] = {y = y}

	-- Now we go column by column and set up the grid.
	for x = 0, grid.xSquares - 1 do

		-- For each grid square, we'll set it up to be indexed first by
		-- its *x* coordinate and next by its *y* coordinate. We also
		-- set the x and y fields of the square to match its coordinates.
		grid[y][x] = {x = x, y = y}

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

		-- Here we'll add in the maze elements to our grid. Because the maze uses
		-- a list that begins with 1, where we started at 0, we add 1 to the *x*
		-- and *y* values to get the correct maze square.
		if maze[y + 1][x + 1] == 0 then
			rect:setFillColor(245, 215, 98)
		else 
			grid[y][x].wall = true
			rect:setFillColor(32, 96, 32, 255)
		end

		-- Now that we've created our display object, we attach it to our
		-- grid square.
		grid[y][x].displayObject = rect

		-- And finally we attach the functions we wrote earlier to each
		-- square so it is more convient to call on them later.
		grid[y][x].left = grid.functions.left
		grid[y][x].right = grid.functions.right
		grid[y][x].above = grid.functions.above
		grid[y][x].below = grid.functions.below

		-- The end of one row.
	end
	-- The end of one column.
end

grid[maze.yStart - 1][maze.xStart - 1].start = true
grid[maze.yStart - 1][maze.xStart - 1].displayObject:setFillColor(192, 192, 255)
grid[maze.yFinish - 1][maze.xFinish - 1].displayObject:setFillColor(192, 128, 128)
grid[maze.yStart - 1][maze.xStart - 1].start = true
grid[maze.yFinish - 1][maze.xFinish - 1].finish = true

--## Create the runner

-- Now we'll create a runner.
local runner = { image = "runner.png" }

-- We need a function to allow the runner to move to a particular square.
function runner:enter(gridSquare)
	-- The first time we show the character, there won't be a display object,
	-- so we'll have to create one.
	if self.displayObject == nil then
		self.displayObject = display.newImageRect(grid.displayGroup,
		self.image, grid.squareSize, grid.squareSize)
		self.displayObject:setFillColor(92, 92, 92)
	end

	-- Now our self's display object should be in the same position on
	-- the screen as the grid square that self is in.
	self.displayObject.x = gridSquare.displayObject.x
	self.displayObject.y = gridSquare.displayObject.y

	-- We'll keep track of the grid square each self is in. It will come
	-- in handy when they want to move.
	self.gridSquare = gridSquare

	-- we'll also save the *x* and *y* coordinate of the self just like
	-- the grid square.
	self.x = gridSquare.x
	self.y = gridSquare.y

	if self.gridSquare.finish then
		finish()
	end
end

-- The runner can only enter squares that don't have obstacles. Even though
-- all this method does is check for the presence of an obstacle, we'll do
-- it like this because it controls the actions of the runner.
function runner:canEnter(gridSquare)
	return gridSquare.wall == nil
end

--##  Creating the controls.

-- Our controls will be composed of an on-screen directional pad, just like
-- the one on a video game controller. Pressing the up, down, left, and
-- right buttons will move the runner around the map grid 

-- The center of our control pad will be at the halfway point of the control
-- area width...
local controlCenterX = controllerWidth / 2

-- and one fifth of the way from the bottom of the screen.
local controlCenterY = screenHeight - screenHeight / 5

-- The radius of the control pad will be just slightly smaller than half
-- the width of the controller area. This will leave a margin on the left
-- side, as well as some distance from the map grid.
local controlCenterRadius = controllerWidth / 2 - rightMargin

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

-- Create a display group for the control pad.
controls.displayGroup = display.newGroup()

-- Now create a circle to house our directional pad.
local circlePad = display.newCircle(controls.displayGroup,
	controlCenterX, controlCenterY, controlCenterRadius)
-- Let's make it stand out from the background.
circlePad:setFillColor(128, 128, 128)

-- Here we create the display objects for the controls and place them on the
-- screen inside our control circle. Because there's a *lot* of typing in the
-- control name. (Think about typing `controls.up.displayObject` over and over)
-- We give each one a short, local name, then assign it to the field where it
-- belongs at the end. This is a very common strategy for creation blocks, but
-- whenver you do it, it makes the code just a little bit more confusing. So you
-- have to decide what is more important, saving yourself some typing or being
-- clearer so that the reader of the code knows what is going on.
local up = display.newImageRect(controls.displayGroup, "arrow_up.png",
	upDownWidth, upDownHeight)
up.x = controlCenterX
up.y = controlCenterY - upDownHeight / 2
controls.up.displayObject = up

local down = display.newImageRect(controls.displayGroup, "arrow_down.png",
  upDownWidth, upDownHeight)
down.x = controlCenterX
down.y = controlCenterY + upDownHeight / 2
controls.down.displayObject = down

local right = display.newImageRect(controls.displayGroup, "arrow_right.png",
	leftRightWidth, leftRightHeight)
right.x = controlCenterX + leftRightWidth / 2
right.y = controlCenterY
controls.right.displayObject = right

local left = display.newImageRect(controls.displayGroup, "arrow_left.png",
	leftRightWidth, leftRightHeight)
left.x = controlCenterX - leftRightWidth / 2
left.y = controlCenterY
controls.left.displayObject = left

-- We'll create a function to hide the controls so that at the end of the game
-- the player can't take the runner *out* of the finish area.
controls.hide = function(controls)
	controls.displayGroup.isVisible = false
end

-- We also need to create a show function so we can get the controls back at the
-- start of the game.
controls.show = function(controls)
	controls.displayGroup.isVisible = true
end

--### Make the runner move

-- It's time to create functions that will move our runner into new grid
-- squares. We'll define functions for moving left, right, up, and down.
-- The function will check that the grid square is free or has a wall before
-- moving into it. If the square is free, the runner will move there.
-- Otherwise the runner will stay where he is.

-- This function will run when we press the left arrow.
local function pressLeft(event)
	if event.phase == "began" then
		local nextSquare = runner.gridSquare:left()
		if runner:canEnter(nextSquare) then
			runner:enter(nextSquare)
		end
	end
end

-- This function will run when we press the right arrow.
local function pressRight(event)
	if event.phase == "began" then
		local nextSquare  = runner.gridSquare:right()
		if runner:canEnter(nextSquare) then
			runner:enter(nextSquare)
		end
	end
end

-- This function will run when we press the up arrow.
local function pressUp(event)
	if event.phase == "began" then
		local nextSquare  = runner.gridSquare:above()
		if runner:canEnter(nextSquare) then
			runner:enter(nextSquare)
		end
	end
end

-- This function will run when we press the down arrow.
local function pressDown(event)
	if event.phase == "began" then
		local nextSquare  = runner.gridSquare:below()
		if runner:canEnter(nextSquare) then
			runner:enter(nextSquare)
		end
	end
end

-- Now we register each function as an event listener for the touch
-- event on the display object associated with each arrow.
controls.left.displayObject:addEventListener("touch", pressLeft)
controls.right.displayObject:addEventListener("touch", pressRight)
controls.up.displayObject:addEventListener("touch", pressUp)
controls.down.displayObject:addEventListener("touch", pressDown)

-- Create the Start button

local startButton = {}
startButton.displayGroup = display.newGroup()
startButton.displayObject = display.newCircle(startButton.displayGroup,
	controlCenterX, controlCenterY, controlCenterRadius)

-- We'll give the button some color and accent.
startButton.displayObject.strokeWidth = 6
startButton.displayObject:setStrokeColor(244, 244, 64)

-- Write what the button does.
startButton.text = display.newText(startButton.displayGroup, 
	"Start", controlCenterX - controlCenterRadius + 20, controlCenterY - 18,
	native.systemFont, 24)
-- Make the text black
startButton.text:setTextColor(0, 0, 0)

-- This function will run whenever you hit the start button. It will
-- hide the button from view and then start the game.
startButton.touch = function(event)
	if event.phase == "began" then
		startButton:hide()
		start()
	end
end
startButton.displayGroup:addEventListener("touch", startButton.touch)

-- We need functions to show and hide the start button the game begins. We'll
-- write them as methods instead of explicitly naming the start button so
-- we can reuse them with the play again button.
startButton.show = function(button)
	button.displayGroup.isVisible = true
end

startButton.hide = function(button)
	button.displayGroup.isVisible = false
end

-- # Create the Play Again button

local playAgainButton = {}

playAgainButton.displayGroup = display.newGroup()

playAgainButton.displayObject = display.newCircle(playAgainButton.displayGroup,
	controlCenterX, controlCenterY, controlCenterRadius)

-- We'll give the button some color and accent.
playAgainButton.displayObject.strokeWidth = 6
playAgainButton.displayObject:setStrokeColor(244, 244, 64)

-- Write what the button does.
playAgainButton.text = display.newText(playAgainButton.displayGroup, 
	"Again", controlCenterX - controlCenterRadius + 20, controlCenterY - 18,
	native.systemFont, 24)
-- Make the text black
playAgainButton.text:setTextColor(0, 0, 0)

-- This function will run whenever you hit the play again button. It will
-- hide the button from view and then start the game over.
playAgainButton.touch = function(event)
	if event.phase == "began" then
		playAgainButton:hide()
		play()
	end
end
playAgainButton.displayGroup:addEventListener("touch", playAgainButton.touch)

-- Since we wrote the `startButton:show` and `startButton:hide` functions in the
-- method style, we can recycle it on our play again button.
playAgainButton.show = startButton.show
playAgainButton.hide = startButton.hide

-- ## Create the stopwatch

-- We've decided that one way to make this game more fun is to time the user
-- while they run the maze. To do this, we'll add a stopwatch to the game that
-- tracks the number of seconds from when when the player hits the start button
-- until the runner enters the finish square of the maze.

-- Create the stopwatch object.
local stopwatch = {}

-- The clock starts at 0.0
stopwatch.clock = 0.0

stopwatch.formatClock = function(watch)
	return string.format("%3.1f", watch.clock)
end



-- Create some text that will display the time on the watch.
stopwatch.displayText = display.newText(stopwatch:formatClock(), 100, 700,
	native.systemFont, 48)

-- This function runs each "tick" of the stopwatch. It will update the displayed
-- time. Note that this function is *not* a method. We have to name the
-- stopwatch exactly instead of using the method style with a `watch` as a first
-- argument. There are ways around this, but they overcomplicate things. Maybe
-- we'll explore them in the future.
stopwatch.increment = function(timerData)
	stopwatch.clock = stopwatch.clock + 0.1
	stopwatch.displayText.text = stopwatch:formatClock()
end

-- Write a method that starts the stopwatch.
stopwatch.start = function(watch)
	-- We use the perform with delay library function to have Corona call us
	-- when the timer runs out. We've set the timer to run ever 1000 milliseconds.
	-- A millisecond is 1/1000th of a second so if we wait 1000 1/1000ths of a
	-- second we wait exactly one second. Say that 10 times fast. We tell Corona
	-- to "call us" by running our watch increment function. The last 0 is the
	-- argument that tells Corona how many times to re-run the timer. By sending a
	-- zero we tell Corona to run forever.

	-- Since this function is going to call us when the time runs out. So what
	-- does it return *right now*? It returns a timer ID number that we can use
	-- to stop the timer later. We need to save this so we can stop the timer when
	-- the player's runner crosses the finish line.
	watch.timer = timer.performWithDelay(100, watch.increment, 0)
end

-- Now we need to stop the stopwatch when the runner finishes the maze. We can
-- do that by cancelling the timer.
stopwatch.stop = function(watch)
	timer.cancel(watch.timer)
end

-- All we have left to do is make sure we can reset the watch. to do so. We just
-- set the clock back to zero and update the display.
stopwatch.reset = function(watch)
	watch.clock = 0
	watch.displayText.text = watch:formatClock()
end


-- ## The main game function

-- This play function is much simpler than our last game because we took most
-- of the code out so it only ran once. This means that our game will start
-- over many more times without crashing, but it also means less can change
-- between restarts. The extra section will show you how to change the maze
-- between restarts. When the player finishes, they can still start over
-- without closing and restarting the game.

function play()

	-- The runner starts off in the maze start.
	runner:enter(grid[maze.yStart - 1][maze.xStart - 1])

	-- The play again button starts out hidden since we haven't started yet!
	playAgainButton:hide()

	-- The controls start out hidden because we want the player to call "start"
	-- first.
	controls:hide()
	stopwatch:reset()
	startButton:show()
end

-- ## Start the game

-- The start function hides teh start button and shows the controls. This
-- allows the player to start moving the runner.
function start()
	controls:show()
	stopwatch:start()
end

--## Finish!

-- Finish the game by hiding the controls and displaying the play again button.
function finish()
	controls:hide()
	stopwatch:stop()
	playAgainButton:show()
end

-- Play the game!
play()
