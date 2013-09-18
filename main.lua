-----------------------------------------------------------------------------------------
--
-- Robot finds kitten - Corona edition
--
-----------------------------------------------------------------------------------------

-- 1. build the game grid
local screenWidth = display.contentWidth
local screenHeight = display.contentHeight
local controllerWidth = screenWidth / 6
local rightMargin = 30

local grid = {}
grid.xSquares = 10
grid.ySquares = 7


grid.totalWidth = screenWidth - controllerWidth - rightMargin
grid.squareSize = grid.totalWidth / grid.xSquares
grid.xStart = controllerWidth
grid.xEnd = grid.xStart + grid.squareSize * grid.xSquares
grid.yStart = 60
grid.xEnd = grid.yStart + grid.squareSize * grid.ySquares
grid.displayGroup = display.newGroup()


--[[ Fill a background for the grid area. ]]
grid.area = display.newRoundedRect(grid.displayGroup, 0, 0,
	grid.xSquares * grid.squareSize, grid.ySquares * grid.squareSize, 50)
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


--[[ Create the robot and kitten ]]
local robot = {}
local kitten = {}

function robot:enter(gridSquare)
    local newX = gridSquare.displayObject.x
    local newY = gridSquare.displayObject.y
    if self.displayObject == nil then
        self.displayObject = display.newImageRect(grid.displayGroup,
            "robot.png", grid.squareSize, grid.squareSize)
        self.displayObject.x = newX
        self.displayObject.y = newY
    else
        self.displayObject.x = newX
        self.displayObject.y = newY
    end
    self.gridSquare = gridSquare
    self.x = gridSquare.x
    self.y = gridSquare.y
end

function robot:canEnter(gridSquare)
    return gridSquare.obstacle == nil
end

robot:enter(grid[0][0]) -- Put the robot in the first square.


--[[ Display controls ]]
local controlCenterX = controllerWidth / 2
local controlCenterY = screenHeight - screenHeight / 5
local controlCenterRadius = controllerWidth / 2 - rightMargin
local circlePad = display.newCircle(controlCenterX, controlCenterY, controlCenterRadius)
circlePad:setFillColor(128, 128, 128)
local upDownWidth = 27
local upDownHeight = 60
local leftRightWidth = 60
local leftRightHeight = 27

local controls = {
    up    = {},
    down  = {},
    right = {},
    left  = {},
}

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
obstacles.bush = {
    image = "bush.png",
    saying = "The sky is nice today.",
    hasKitten = obstacleHasKitten,
}
obstacles[2] = obstacles.bush

local function putObstacle(obstacle, gridSquare)
    obstacle.x = gridSquare.x
    obstacle.y = gridSquare.y
    obstacle.displayObject = display.newImageRect(grid.displayGroup, obstacle.image,
        grid.squareSize, grid.squareSize)
    obstacle.displayObject.x = gridSquare.displayObject.x
    obstacle.displayObject.y = gridSquare.displayObject.y
    gridSquare.obstacle = obstacle
end

putObstacle(obstacles.rock, grid[4][1])
putObstacle(obstacles.bush, grid[6][3])
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

local function animatedReunion()
    robot:enter(grid[robot.x + 1][robot.y])
    kitten:enter(grid[kitten.x - 1][kitten.y])
end

function robotfindskitten()
    for i = 0, 2 do
        grid.displayGroup:remove(obstacles[i].displayObject)
        obstacles[i].displayObject = nil
    end
    robot.foundKitten = true
    kitten.displayObject = display.newImageRect(grid.displayGroup, "kitten.png",
        grid.squareSize, grid.squareSize)
    kitten.enter = robot.enter
    kitten:enter(grid[9][4])
    
    display.remove(controls.up.displayObject)
    controls.up.displayObject = nil
    display.remove(controls.down.displayObject)
    controls.down.displayObject = nil
    display.remove(controls.left.displayObject)
    controls.left.displayObject = nil
    display.remove(controls.right.displayObject)
    controls.right.displayObject = nil
    robot:enter(grid[0][4])
    saying:update("Robot finds kitten!")
    timer.performWithDelay(1000, animatedReunion, 4)
end

