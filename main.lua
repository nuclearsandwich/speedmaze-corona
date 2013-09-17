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


--[[ Fill a background for the grid area. ]]
grid.area = display.newRect(grid.displayGroup, 0, 0,
	grid.xSquares * grid.squareSize, grid.ySquares * grid.squareSize)
grid.area:setFillColor(218, 218, 218)
grid.displayGroup.x = grid.xStart
grid.displayGroup.y = grid.yStart

local function leftGrid(gridSquare)
    if gridSquare.x == 0 then
        return gridSquare
    else
        return grid[gridSquare.x - 1][gridSquare.y]
    end
end

local function rightGrid(gridSquare)
    if gridSquare.x + 1 == grid.xSquares then
        return gridSquare
    else
        return grid[gridSquare.x + 1][gridSquare.y]
    end
end

local function aboveGrid(gridSquare)
    if gridSquare.y == 0 then
        return gridSquare
    else
        return grid[gridSquare.x][gridSquare.y - 1]
    end
end

local function belowGrid(gridSquare)
    if gridSquare.y + 1 == grid.ySquares then
        return gridSquare
    else
        return grid[gridSquare.x][gridSquare.y + 1]
    end
end


for x = 0, 9 do
    grid[x] = {x = x} -- Create grid row table.

	for y = 0, 5 do
        grid[x][y] = {x = x, y = y} -- Create grid element.
        local rect = display.newRect(grid.displayGroup,
            grid.squareSize * x, grid.squareSize * y,
			grid.squareSize, grid.squareSize)

		rect:setFillColor(0, 0, 0, 0)
        grid[x][y].displayObject = rect
        grid[x][y].left = leftGrid
        grid[x][y].right = rightGrid
        grid[x][y].above = aboveGrid
        grid[x][y].below = belowGrid
	end
end


--[[ Create the robot ]]
robot = {}
robot.radius = grid.squareSize / 2

function robot:enter(gridSquare)
    local newX = gridSquare.displayObject.x - 100
    local newY = gridSquare.displayObject.y - 100
    if self.displayObject == nil then
        self.displayObject = display.newImage(grid.displayGroup, "robot.png", newX, newY)
        self.displayObject:setReferencePoint(display.TopLeftReferencePoint)
        self.displayObject.width = 100
        self.displayObject.height = 100
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

function obstacleHasKitten(obstacle)
    return obstacle.kitten == true
end

obstacles.rock = {
    image = "rock.png",
    saying = "There is no spoon.. or cat",
    hasKitten = obstacleHasKitten,
}
obstacles[0] = obstacles.rock
obstacles.trashcan = {
    image = "trash.png",
    saying = "Hmm. What was I looking for?",
    hasKitten = obstacleHasKitten,
}
obstacles[1] = obstacles.trashcan
obstacles.tree = {
    image = "tree.png",
    saying = "The sky is nice today.",
    hasKitten = obstacleHasKitten,
}
obstacles[2] = obstacles.tree

local function putObstacle(obstacle, gridSquare)
    obstacle.x = gridSquare.x
    obstacle.y = gridSquare.y
    obstacle.displayObject = display.newRect(grid.displayGroup,
        gridSquare.x * grid.squareSize, gridSquare.y * grid.squareSize,
        grid.squareSize, grid.squareSize)
    obstacle.displayObject:setFillColor(0, 0, 0)
    gridSquare.obstacle = obstacle
end

putObstacle(obstacles.rock, grid[4][1])
putObstacle(obstacles.tree, grid[6][3])
putObstacle(obstacles.trashcan, grid[2][5])

obstacles[math.random(0, 2)].kitten = true

--[[ Make the robot move when controlled ]]
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
controls.left.displayObject:addEventListener("touch", pressLeft)
controls.right.displayObject:addEventListener("touch", pressRight)
controls.up.displayObject:addEventListener("touch", pressUp)
controls.down.displayObject:addEventListener("touch", pressDown)


--[[ Robot finds kitten! ]]
function robotfindskitten()
    for i = 0, 2 do
        grid.displayGroup:remove(obstacles[i].displayObject)
        obstacles[i].displayObject = nil
    end
    robot.foundKitten = true
    local kitten = { displayObject = display.newImage(grid.displayGroup, "kitten.png") }
    kitten.enter = robot.enter
    kitten.displayObject:setReferencePoint(display.TopLeftReferencePoint)
    kitten.displayObject.width = 100
    kitten.displayObject.height = 100
    kitten:enter(grid[5][4])
    
    display.remove(controls.up.displayObject)
    controls.up.displayObject = nil
    display.remove(controls.down.displayObject)
    controls.down.displayObject = nil
    display.remove(controls.left.displayObject)
    controls.left.displayObject = nil
    display.remove(controls.right.displayObject)
    controls.right.displayObject = nil
    robot:enter(grid[4][4])
    saying:update("Robot finds kitten!")
end