-----------------------------------------------------------------------------------------
--
-- Robot finds kitten - Corona edition
--
-----------------------------------------------------------------------------------------

-- 1. build the game grid
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight
local controllerWidth = screenWidth / 10

local grid = {}
grid.xSquares = 10
grid.ySquares = 6
grid.squareSize = 100

grid.totalWidth = screenWidth - controllerWidth

grid.xStart = screenWidth / 10
grid.xEnd = grid.xStart + grid.squareSize * grid.xSquares
grid.yStart = 60
grid.xEnd = grid.yStart + grid.squareSize * grid.ySquares
grid.displayGroup = display.newGroup()


-- Fill a background for the grid area.
grid.area = display.newRect(grid.displayGroup, 0, 0,
	grid.xSquares * grid.squareSize, grid.ySquares * grid.squareSize)
grid.area:setFillColor(254, 215, 0)
grid.displayGroup.x = grid.xStart
grid.displayGroup.y = grid.yStart


for x = 0, 9 do
    grid[x] = {x = x} -- Create grid row table.
    
	for y = 0, 5 do
        grid[x][y] = {x = x, y = y} -- Create grid element.
        local rect = display.newRect(grid.displayGroup,
            grid.squareSize * x, grid.squareSize * y,
			grid.squareSize, grid.squareSize)
        
		rect:setFillColor(0, 0, 0, 0)
		rect:setStrokeColor(196, 128, 0, 128)
		rect.strokeWidth = 5
        grid[x][y].displayObject = rect
	end
end


--[[ Create the robot ]]
robot = {}
robot.radius = grid.squareSize / 2

function robot:enter(gridSquare)
    local newX = gridSquare.displayObject.x
    local newY = gridSquare.displayObject.y
    if self.displayObject == nil then
        self.displayObject = display.newCircle(grid.displayGroup, newX, newY, self.radius)
    else
        self.displayObject.x = newX
        self.displayObject.y = newY
    end
    robot.gridSquare = gridSquare
end

function robot:canEnter(gridSquare)
    return gridSquare.obstacle == nil
end

robot:enter(grid[0][0]) -- Put the robot in the first square.


--[[ Display controls ]]
local controls = {
    up    = { displayObject = display.newRect(-50, 480, 30, 50) },
    down  = { displayObject = display.newRect(-50, 570, 30, 50) },
    right = { displayObject = display.newRect(-15, 535, 50, 30) },
    left  = { displayObject = display.newRect(-105, 535, 50, 30) },
}

--[[ Display the saying ]]

local saying = {
    font = native.systemFont,
    x = 100, y = 700,
    fontSize = 48
}

function saying:update(newText)
    if self.displayText == nil then
        self.displayText = display.newText(newText,
            self.x, self.y,
            self.font, self.fontSize)
    else
        self.displayText.text = newText
    end
end
saying:update("This is the first saying")

--[[ Display obstacles ]]

local obstacles = {}

obstacles.rock = {
    saying = "There is no spoon.. or cat",
}
obstacles.trashcan = {
    saying = "Hmm. What was I looking for?"
}
obstacles.tree = {
    saying = "The sky is nice today."
}

local function putObstacle(obstacle, gridSquare)
    obstacle.x = gridSquare.x
    obstacle.y = gridSquare.y
    obstacle.displayObject = display.newRect(grid.displayGroup,
        gridSquare.displayObject.x, gridSquare.displayObject.y,
        gridSquare.displayObject.width, gridSquare.displayObject.height)
    obstacle.displayObject:setFillColor(0, 0, 0)
    print(gridSquare.displayObject.x, gridSquare.displayObject.xOrigin)
end

putObstacle(obstacles.rock, grid[4][1])
putObstacle(obstacles.tree, grid[6][3])

--[[ Make the robot move when controlled


local function pressLeft(event)
    if event.phase == "began" and robot.x - gridSquareSize > gridXBegin then
        robot.x = robot.x - gridSquareSize
    end
end
leftRect:addEventListener("touch", pressLeft)

]]