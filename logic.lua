----------------------------------------------------------------------------------------------------
-- Code related to creating new game, planets, collision check, and draw shot
----------------------------------------------------------------------------------------------------
function newGame()
    resetBullets()

    setInitialPositions()

    player1.angle = 0
    player2.angle = 180

    player1.lastAngle = nil
    player2.lastAngle = nil

    player1.health = 100
    player2.health = 100

    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    drawPlanets()
    drawShips()
    drawUI()
    love.graphics.setCanvas()

    setPlanets()

    print("New Game Started")

end

function resetBullets()
    for i, v in pairs(allBullets) do
        resetShot(i)
    end
end

-- returns `player1` or `player2` table (object) depending on whose turn it is
function currentPlayer()

    if turn == 1 then
        return player1
    else
        return player2
    end
end

-- Randomize placement of planets & ships
-- check for overlap, retry if check fails
function setInitialPositions()
    repeat 
        print('randomizing planets attempt')

        allPlanets = {} -- reset whatever we had before first

        -- include parameters for max and min planet locations

        -- TODO: experiment with mass
        -- having the mass depend on radius is less fun - small planets stop mattering
        -- mass = (math.pow(allPlanets[i].r,3)/25) -- MASS depends on radius^3 *** this affects speed of drawing

        for i = 1, numOfPlanets do
            allPlanets[i] = {
                x = math.random(100, WIDTH - 100),
                y = math.random(150, HEIGHT - 250),
                r = math.random(15, 50),
                mass = math.random(10, 50) * 10,
                id = i,
            }
        end

        -- reposition ships
        player1.x = math.random(200, WIDTH / 2 - 100)
        player1.y = math.random(200, HEIGHT - 200)
        player2.x = math.random(WIDTH / 2 + 100, WIDTH - 200)
        player2.y = math.random(200, HEIGHT - 200)
        
    until isValidPosition()
end

function isValidPosition()
    -- TODO - compute distance with square roots - not just x & y distance
    -- check for planet overlap
    -- check for ship overlapping with planet too
    -- space them out by 50 px at least
    for i = 1, numOfPlanets do
        for j = 1, numOfPlanets do
            if allPlanets[i].id == allPlanets[j].id then
                -- do nothing: the same planet
                goto continue
            elseif planetDistCheck(allPlanets[i], allPlanets[j]) then
                -- if any planet touches another planet, try again
                return false
            elseif math.abs(allPlanets[i].x - player1.x) < 90 and
                math.abs(allPlanets[i].y - player1.y) < 90 then
                return false
            elseif math.abs(allPlanets[i].x - player2.x) < 90 and
                math.abs(allPlanets[i].y - player2.y) < 90 then
                return false
            end
            ::continue::
        end
    end
    return true
end 

function planetDistCheck(planet1, planet2)
    x1, y1, r1 = planet1.x, planet1.y, planet1.r
    x2, y2, r2 = planet2.x, planet2.y, planet2.r
    dist = math.pow(math.pow((x1 - x2), 2) + math.pow((y1 - y2), 2), 0.5)
    if dist < r1 + r2 then
        return true
    else
        return false
    end
end

-- check collisions with every shot that is drawn
-- dims trails after every collision
function collisonCheck(b)

    -- insert code that will set shotInProgress = false if all bullets are gone and end the turn with it

    -- whenever the bullet hits the planet - remove from drawing & computing
    for i = 1, numOfPlanets do

        if (math.sqrt(math.pow(allPlanets[i].x - allBullets[b].x, 2) +
                          math.pow(allPlanets[i].y - allBullets[b].y, 2))) <
            allPlanets[i].r then

            -- remove the bullet from the playing field
            -- as long as it's placed outside the cutoff set in the drawShot()
            -- it will not compute!!! no wasted CPU cycles!
            allBullets[b].x = 0
            allBullets[b].y = 0
            allBullets[b].vx = 0
            allBullets[b].vy = 0

            -- this dims the trails on every collision -- probably should disable
            -- dimTrails()
            love.graphics.setCanvas(canvas)
            drawPlanets() -- draw planets because a collision overlaps with a planet :(
            love.graphics.setCanvas()
        end
    end

    -- grace period when your bullet can't kill you
    if benign > 50 then
        didYouHitPlayer(player1, b)
        didYouHitPlayer(player2, b)
        if turn == 1 then
            updateHealthBar(player2, player1, b)
        else
            updateHealthBar(player1, player2, b)
        end
    end

end

-- don't forget `b` the bullet index
function didYouHitPlayer(playerN, b)

    if (math.sqrt(math.pow(playerN.x - allBullets[b].x, 2) +
                      math.pow(playerN.y - allBullets[b].y, 2))) < 10 then
        print("you hit someone!")

        -- only decrease 1 life!
        if endOfRound == false then playerN.lives = playerN.lives - 1 end

        endOfRound = true
        
        playerN.health = 0
        
        -- store location where player is
        explodeX = playerN.x
        explodeY = playerN.y
        
        -- hide player from the board
        playerN.x = -100
        playerN.y = -100
        
        -- explode this location !!!
        explode(explodeX, explodeY)

        if playerN.lives == 0 then print("GAME OVER, SOMEONE WON!") end
    end

end

-- don't forget `b` the bullet index
function updateHealthBar(playerN, opponent, b)

    distanceFromShot = math.sqrt(math.pow(playerN.x - allBullets[b].x, 2) +
                                     math.pow(playerN.y - allBullets[b].y, 2))

    if opponent.health > distanceFromShot then
        opponent.health = distanceFromShot
        love.graphics.setCanvas(canvas)
        drawUI()
        love.graphics.setCanvas()
    end

end

-- TODO: figure out a sensible default for resolution of the shot and speed of the shot
-- warning: planets with all the small radii may allow bullets to pass through
--          because the shot rosolution is LOW

-- TODO: allow shot to be outside the border by at least a little bit
-- TODO: include code so it doesn't do the calculation if the shot is too far from border
--       if shot is within bounds of the screen, draw it

--[[

THE MOST IMPORTANT FUNCTION - draws the lines for the shot "b" where b (think "bullet") is the shot name

1) if shot is outside some boundary, discard it
2) if the shot is outside drawing area, compute, but don't draw (TODO: this is not implemented yet)
3) if the shot is within screen:
    a) compute x and y components from each planet on the current bullet (store in fpx & fpy variables)
    b) sum up all the forces into a single vfx & vfy
    c) add final force to bullet's initial force
    d) draw the small segment
    e) update bullet's 'initial' velocity for next iteration

--]]
function drawShot(b)

    -- Variables involved:
    -- b - bulletIndex `[b]`

    -- (1)
    -- set the shot outside if it hits outside the play border
    --print(b, allBullets[b].x)
    if allBullets[b].x > WIDTH - 10 or allBullets[b].x < 10 or allBullets[b].y >
        HEIGHT - 10 or allBullets[b].y < 10 then
        allBullets[b].x = 0
        allBullets[b].y = 0
    end

    -- (3)
    if allBullets[b].x < WIDTH - 10 and allBullets[b].x > 10 and allBullets[b].y <
        HEIGHT - 10 and allBullets[b].y > 10 then

        -- array to store forces from each planet to each shot (temp use always)
        fpx = {}
        fpy = {}

        -- (a)
        -- calculate force of planet on x1 and y1
        for i = 1, numOfPlanets do
            xDiff = allPlanets[i].x - allBullets[b].x
            yDiff = allPlanets[i].y - allBullets[b].y

            fpx[i] = xDiff /
                         (math.pow(math.sqrt((xDiff * xDiff) + (yDiff * yDiff)),
                                   3));
            fpy[i] = yDiff /
                         (math.pow(math.sqrt((xDiff * xDiff) + (yDiff * yDiff)),
                                   3));
        end

        -- reset velocity -- TEMPORARY VARIABLES
        vfx = 0
        vfy = 0

        -- (b)
        -- for each planet add all forces multiplied by gravity of each planet
        for i = 1, numOfPlanets do
            vfx = vfx + fpx[i] * allPlanets[i].mass
        end

        for i = 1, numOfPlanets do
            vfy = vfy + fpy[i] * allPlanets[i].mass
        end

        -- (c)
        -- add initial velocity to the final velocity
        vfx = vfx + allBullets[b].vx
        vfy = vfy + allBullets[b].vy

        -- set velocity of each bullet to its final velocity
        allBullets[b].vx = vfx
        allBullets[b].vy = vfy

        -- (d)
        -- Draw shot to canvas
        love.graphics.setCanvas(canvas)
        love.graphics.line(allBullets[b].x, allBullets[b].y,
                           allBullets[b].x + vfx, allBullets[b].y + vfy)
        love.graphics.setCanvas()

        -- (e)
        allBullets[b].x = allBullets[b].x + vfx
        allBullets[b].y = allBullets[b].y + vfy

    end

end

function setPlanets()
    for i = 1, numOfPlanets do 
        planet_body = love.physics.newBody(world, allPlanets[i].x, allPlanets[i].y, "static")
        planet_shape = love.physics.newCircleShape(allPlanets[i].r)
        planet_fixture = love.physics.newFixture(planet_body, planet_shape, 1)
        planet_fixture:setDensity(1 / math.pi)
        planet_body:resetMassData()
        allPlanets[i].body = planet_body
        allPlanets[i].shape = planet_shape
        allPlanets[i].fixture = planet_fixture
        allPlanets[i].fixture:setDensity(1 / math.pi)
        allPlanets[i].fixture:setSensor(true)
        allPlanets[i].body:resetMassData()
    end
end

function calculateGravitationalForce(bullet_x, bullet_y, planet_x, planet_y, planet_mass)
    local G = 6674 -- Gravitational constant (scaled for gameplay)
    local dx = planet_x - bullet_x
    local dy = planet_y - bullet_y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Prevent division by zero and extreme forces at very close distances
    if distance < 10 then distance = 10 end
    
    -- Calculate force magnitude using F = G * (m1 * m2) / r^2
    -- Note: bullet mass is assumed to be 1 for simplicity
    local force = G * planet_mass / (distance * distance)
    
    -- Calculate force components
    local force_x = force * (dx / distance)
    local force_y = force * (dy / distance)
    
    return force_x, force_y
end

function drawBetterShot(b)
    -- Variables involved:
    -- b - bulletIndex `[b]`

    -- (1)
    -- set the shot outside if it hits outside the play border
    --print(b, allBullets[b].x)
    allBullets[b].x = allBullets[b].body:getX()
    allBullets[b].y = allBullets[b].body:getY()
    if allBullets[b].x > WIDTH - 10 or allBullets[b].x < 10 or allBullets[b].y >
        HEIGHT - 10 or allBullets[b].y < 10 then
        allBullets[b].x = 0
        allBullets[b].y = 0
    end

    -- (3)
    if allBullets[b].x < WIDTH - 10 and allBullets[b].x > 10 and allBullets[b].y <
        HEIGHT - 10 and allBullets[b].y > 10 then

        -- Get the current physics body position
        -- Get current bullet position
        local bullet_x, bullet_y = allBullets[b].body:getPosition()

        -- array to store forces from each planet to each shot (temp use always)
        fpx = {}
        fpy = {}

        -- (a)
        -- calculate force of planet on x1 and y1
        for i = 1, numOfPlanets do
            xDiff = allPlanets[i].x - allBullets[b].x
            yDiff = allPlanets[i].y - allBullets[b].y

            fpx[i] = xDiff /
                         (math.pow(math.sqrt((xDiff * xDiff) + (yDiff * yDiff)),
                                   3));
            fpy[i] = yDiff /
                         (math.pow(math.sqrt((xDiff * xDiff) + (yDiff * yDiff)),
                                   3));
        end

        -- reset velocity -- TEMPORARY VARIABLES
        vfx = 0
        vfy = 0
        full_x_force = 0
        full_y_force = 0

        -- (b)
        -- for each planet add all forces multiplied by gravity of each planet
        for i = 1, numOfPlanets do
            vfx = vfx + fpx[i] * allPlanets[i].body:getMass()
            full_x_force = full_x_force + fpx[i]
        end

        for i = 1, numOfPlanets do
            vfy = vfy + fpy[i] * allPlanets[i].body:getMass()
            full_y_force = full_y_force + fpy[i]
        end

        -- (c)
        -- add initial velocity to the final velocity
        vfx = vfx + allBullets[b].vx
        vfy = vfy + allBullets[b].vy

        -- set velocity of each bullet to its final velocity
        --allBullets[b].vx = vfx
        --allBullets[b].vy = vfy

            -- Calculate and apply gravitational forces from all planets
        fx, fy = 0, 0
        for i = 1, numOfPlanets do
            local force_x, force_y = calculateGravitationalForce(
                bullet_x, 
                bullet_y,
                allPlanets[i].x,
                allPlanets[i].y,
                allPlanets[i].body:getMass() * 10
            )
            fx = fx + force_x
            fy = fy + force_y
            -- Apply gravitational force to bullet
            --allBullets[b].body:applyForce(force_x, force_y)
        end
        allBullets[b].body:applyLinearImpulse(fx , fy )
        --allBullets[b].body:applyForce(full_x_force * 10, full_y_force * 10)

        -- After applying force, update the bullet's position from physics body
        allBullets[b].x, allBullets[b].y = allBullets[b].body:getPosition()

        -- (d)
        -- Draw shot to canvas
        --love.graphics.setCanvas(canvas)
        --love.graphics.line(allBullets[b].x, allBullets[b].y,
        --                   allBullets[b].x + vfx, allBullets[b].y + vfy)
        --love.graphics.setCanvas()
        -- Draw trajectory line
        local vx, vy = allBullets[b].body:getLinearVelocity()
        love.graphics.setCanvas(canvas)
        love.graphics.line(bullet_x, bullet_y,
                        bullet_x + vx * 0.1, bullet_y + vy * 0.1)
        love.graphics.setCanvas()

        -- (e)
        --allBullets[b].x = allBullets[b].x + vfx
        --allBullets[b].y = allBullets[b].y + vfy

    end
end