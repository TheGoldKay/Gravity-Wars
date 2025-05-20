function drawPlayerAngleAndForce(playerN)

    -- large black circle
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.ellipse('fill', playerN.x, playerN.y, 100, 100)

    -- red arc showing force
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.arc('fill', 'pie', playerN.x, playerN.y, playerN.force * 20, 0.0174533 * playerN.angle - 0.1, 0.0174533 * playerN.angle + 0.1)

    -- smaller red circle showing force
    love.graphics.setColor(1, 0, 0, 0.4)
    love.graphics.ellipse('line', playerN.x, playerN.y, playerN.force * 20, playerN.force * 20)

    -- love.graphics.setColor(1, 0, 0, 1)
    -- love.graphics.line(playerN.x, playerN.y,
    --                     playerN.x + math.cos(0.0174533 * playerN.angle) * 100 * playerN.force / 5,
    --                     playerN.y + math.sin(0.0174533 * playerN.angle) * 100 * playerN.force / 5)

    -- large white circle showing maximum
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.ellipse('line', playerN.x, playerN.y, 100, 100)

    -- long line showing angle
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.ellipse('line', playerN.x, playerN.y, 10, 10)
    love.graphics.line(playerN.x, playerN.y,
                        playerN.x + math.cos(0.0174533 * playerN.angle) * 100,
                        playerN.y + math.sin(0.0174533 * playerN.angle) * 100)

end


function drawAngleDiff(playerN, playerOffsetHack)

    angleDiff = playerN.lastAngle - playerN.angle

    forceDiff = playerN.force - playerN.lastForce

    if angleDiff > 180 then
        angleDiff = angleDiff - 360
    end

    if angleDiff < -180 then
        angleDiff = angleDiff + 360
    end

    if angleDiff < 10 and angleDiff > -10 then

        xOffset = playerN.x - 76 + playerOffsetHack * 90

        fontOpacity = math.pow((10 - math.abs(angleDiff))/10, 0.5)
        love.graphics.setFont(pixelFont)

        if (angleDiff ~= 0) then
            -- rectangle
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle('fill', xOffset + 5, playerN.y - 6, 56, 12, 4, 4)
            -- text
            love.graphics.setColor(1, 1, 1, fontOpacity)
            love.graphics.printf(string.format("%.5f", angleDiff), xOffset, playerN.y - 7, 60, 'right')
        end

        love.graphics.setColor(1, 0, 0, fontOpacity)

        if (forceDiff ~= 0) then
            -- rectangle
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle('fill', xOffset + 5, playerN.y + 6, 56, 12, 4, 4)
            -- text
            love.graphics.setColor(1, 0, 0, fontOpacity)
            love.graphics.printf(string.format("%.5f", forceDiff), xOffset, playerN.y + 5, 60, 'right')
        end

        love.graphics.setColor(1, 1, 1, 1)
    end

end

function drawBullet(b)
    ball = allBullets[b]
    local x, y = ball.body:getPosition()
    love.graphics.setColor(1, 1, 1)  -- White ball
    love.graphics.circle("fill", x, y, ball.radius)
    
    -- Draw velocity vector
    local vx, vy = ball.body:getLinearVelocity()
    love.graphics.setColor(1, 0, 0)
    love.graphics.line(x, y, x + vx/5, y + vy/5)
end