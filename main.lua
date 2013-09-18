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

      up = function(gridSquare)
        if gridSquare.y == 0 then
          return gridSquare
        else
          return grid[gridSquare.x][gridSquare.y - 1]
        end
      end,

      down = function(gridSquare)
        if gridSquare.y + 1 == grid.ySquares then
          return gridSquare
        else
          return grid[gridSquare.x][gridSquare.y + 1]
        end
      end,
    }

    for x = 0, 9 do
        grid[x] = {x = x} -- Create grid row table.
    
        for y = 0, 5 do
            grid[x][y] = {x = x, y = y} -- Create grid element.
            local rect = display.newRect(grid.displayGroup,
                grid.squareSize * x, grid.squareSize * y,
                grid.squareSize, grid.squareSize)
    
            rect:setFillColor(0, 0, 0, 0)
            grid[x][y].displayObject = rect
            grid[x][y].left = grid.functions.left
            grid[x][y].right = grid.functions.right
            grid[x][y].above = grid.functions.up
            grid[x][y].below = grid.functions.down
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
    saying:update("Where is the kitten?")
    
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
    
    function animatedReunion()
        robot:enter(grid[robot.x + 1][robot.y])
        kitten:enter(grid[kitten.x - 1][kitten.y])
    end
    
    local playAgainButton
    local function showPlayAgain()
        local playAgainButton = display.newCircle(controlCenterX, controlCenterY, controlCenterRadius)
        playAgainButton.strokeWidth = 6
        playAgainButton:setStrokeColor(244, 244, 64)
        local playAgainText = display.newText("Again", controlCenterX - controlCenterRadius + 20,
            controlCenterY - 18, native.systemFont, 24)
        playAgainText:setTextColor(0, 0, 0)

        local function playAgainButtonActivate(event)
            if event.phase == "began" then
                display.remove(playAgainButton)
                display.remove(playAgainText)
                playAgainButton = nil
                playAgainText = nil
                play()
            end
        end
        playAgainButton:addEventListener("touch", playAgainButtonActivate)
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
        robot:enter(grid[0][4])
        display.remove(saying.displayText)
        saying.displayText = nil
        timer.performWithDelay(1000, animatedReunion, 4)
        timer.performWithDelay(4000, showPlayAgain, 1)
    end
end
play()
