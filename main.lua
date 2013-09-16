-----------------------------------------------------------------------------------------
--
-- Robot finds kitten - Corona edition
--
-----------------------------------------------------------------------------------------

-- 1. build the game grid
local screenWidth = display.actualContentWidth
local screenHeight = display.actualContentHeight
local controllerWidth = screenWidth / 10
local gridWidth = screenWidth - controllerWidth
local gridYBegin = 20
local gridXBegin = controllerWidth
local gridSquareSize = 100

-- Fill a background for the grid area.
local gridArea = display.newRect(gridXBegin, gridYBegin,
	gridSquareSize * 10, gridSquareSize * 6)
gridArea:setFillColor(254, 215, 0)
for x = 0, 9 do
	for y = 0, 5 do
		xPosition = (x * gridSquareSize) + gridXBegin + 5
		yPosition = (y * gridSquareSize) + gridYBegin + 5
		local rectangle = display.newRect(xPosition, yPosition,
			gridSquareSize - 10, gridSquareSize - 10)
		rectangle:setFillColor(0, 0, 0, 0)
		rectangle:setStrokeColor(196, 128, 0, 128)
		rectangle.strokeWidth = 5
	end
end

-- 2. display controls
local upRect = display.newRect(-50, 480, 30, 50)
local downRect = display.newRect(-50, 570, 30, 50)
local rightRect = display.newRect(-15, 535, 50, 30)
local leftRect = display.newRect(-105, 535, 50, 30)

-- 3. display the robot

local robot = display.newCircle(gridXBegin + 50, gridYBegin + 50, 45);

-- 4. display the saying

local fontOptions = { font = native.systemFont, text = "This is where the text will go", x = 100, y = 700, fontSize = 48 }
display.newText(fontOptions.text, fontOptions.x, fontOptions.y, fontOptions.font, fontOptions.fontSize)

-- 5. dispay obstacles

-- 6. make the robot move when controlled

function upRect:touch(event)
	if event.phase == "began" then
        if robot.y - gridSquareSize > gridYBegin then
		  robot.y = robot.y - gridSquareSize
        end
	end
end
upRect:addEventListener("touch", upRect)


function rightRect:touch(event)
	if event.phase == "began" then
        if robot.x + gridSquareSize < gridXBegin + gridSquareSize * 10 then
		  robot.x = robot.x + gridSquareSize
        end
	end
end
rightRect:addEventListener("touch", rightRect)

function downRect:touch(event)
    if event.phase == "began" then
        if robot.y + gridSquareSize < gridYBegin + gridSquareSize * 6 then
            robot.y = robot.y + gridSquareSize
        end
    end
end
downRect:addEventListener("touch", downRect)

local function pressLeft(event)
    if event.phase == "began" and robot.x - gridSquareSize > gridXBegin then
        robot.x = robot.x - gridSquareSize
    end
end

leftRect:addEventListener("touch", pressLeft)