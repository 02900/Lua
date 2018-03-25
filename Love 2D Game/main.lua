bump = require 'libs.bump.bump'
world = nil -- storage place for bump
collider = {}
art = {}
score = 0

-- Timers
-- We declare these here so we don't have to edit them multiple places
canShoot = true
initCanShootTimerMax = 0.25
canShootTimerMax = initCanShootTimerMax
canShootTimer = canShootTimerMax

-- Image Storage
bulletImg = nil
-- Entity Storage
bullets = {} -- array of current bullets being drawn and updated

--More timers
createEnemyTimerMax = 0.4
createEnemyTimer = createEnemyTimerMax
  
-- More images
enemyImg = nil -- Like other images we'll pull this in during out love.load function
  
-- More storage
enemies = {} -- array of current enemies on screen

-- The finished player object
player = {
	x = 16,
	y = 16,

	xVelocity = 0, -- current velocity on x axis
	yVelocity = 0, -- current velocity on y axis
	acc = 100, -- the acceleration of our player
	maxSpeed = 2200, -- the top speed
	friction = 10, -- slow our player down - we could toggle this situationally to create icy or slick platforms
	gravity = 75, -- we will accelerate towards the bottom
	jumpAcc = 200, -- how fast do we accelerate towards the top
	jumpMaxSpeed = 9.5, -- our speed limit while jumping
	img = nil, -- store the sprite we'll be drawing
	img2 = nil, -- store the sprite we'll be drawing
	energy = 100,
	powerUp = 100,
	life = 3,
	transformation = false;
}

-- Collision detection taken function from http://love2d.org/wiki/BoundingBox.lua
-- Returns true if two boxes overlap, false if they don't
-- x1,y1 are the left-top coords of the first box, while w1,h1 are its width and height
-- x2,y2,w2 & h2 are the same, but for the second box
function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

function love.load()
    -- set title
    love.window.setTitle( "Goku Escape Itachi No Jutsu" )
	
	-- Setup bump
	world = bump.newWorld(16)  -- 16 is our tile size
	
	-- Load images
	player.img = love.graphics.newImage('assets/Goku.png')
	player.img2 = love.graphics.newImage('assets/Goku2.png')
	art.bg = love.graphics.newImage('assets/bg.jpg')
	art.LP100 = love.graphics.newImage('assets/100LP.png')
	art.LP66 = love.graphics.newImage('assets/66LP.png')
	art.LP33 = love.graphics.newImage('assets/33LP.png')
  	art.LP00 = love.graphics.newImage('assets/00LP.png')

	world:add(player, player.x, player.y, player.img:getWidth(), player.img:getHeight())
	
	collider.ground = {}
	collider.top = {}
	
	-- Draw a level
	world:add(collider.ground, 0, 448, 640000, 4)
	world:add(collider.top, 0, 0, 640000, 4)
	
	bulletImg = love.graphics.newImage('assets/kiblast.png')
	enemyImg = love.graphics.newImage('assets/itachi.png')
	
	--load sounds
	bgMusic = love.audio.newSource("assets/bgSound.ogg")
	migate = love.audio.newSource("assets/migate.mp3")
	haaa = love.audio.newSource("assets/haaaa.mp3")
	love.audio.play(bgMusic)
end

function love.update(dt)
	PlayerControl(dt)
	Fire(dt)
	EnemySpawn(dt)
	CollisionDetection()
	Reset()
end

function PlayerControl(dt)
	Movement(dt)
	HealthUpdate()
	PowerUp(dt)
end

function Movement (dt)
	local goalX = player.x + player.xVelocity
	local goalY = player.y + player.yVelocity

	player.x, player.y = world:move(player, goalX, goalY)

	-- Apply Friction
	player.xVelocity = player.xVelocity * (1 - math.min(dt * player.friction, 1))
	player.yVelocity = player.yVelocity * (1 - math.min(dt * player.friction, 1))

	-- Apply gravity
	player.yVelocity = player.yVelocity + player.gravity * dt

	-- Movement on axis x
	player.xVelocity = player.xVelocity + player.acc * dt

	-- The Jump code gets a lttle bit crazy.  Bare with me.
	if love.keyboard.isDown("up", "w") then
	  player.yVelocity = player.yVelocity - player.jumpAcc * dt
	  player.hasReachedMax = true
	end
end

function HealthUpdate()
	if (player.life < 0 and not player.transformation) then
		love.audio.stop(bgMusic)
		love.audio.play(haaa)
		love.audio.play(migate)
		player.transformation = true
		
		canShootTimerMax = canShootTimerMax / 1.78
	end
end

function PowerUp (dt)
	-- time power up
	if (player.transformation and player.powerUp > 0) then
		player.powerUp = player.powerUp - dt * 2
	end
	
	if (player.powerUp < 1) then 
		player.life = -1
	end
end

function Fire (dt)
	-- Ki Charge
	if (player.energy < 100) then
		player.energy = player.energy + dt * 25
	end
	
	-- Time out how far apart our shots can be.
	canShootTimer = canShootTimer - (1 * dt)
	if canShootTimer < 0 then
		canShoot = true
	end
	
	InstanciateBullets(dt)
end

function InstanciateBullets (dt)

	if love.keyboard.isDown('space', 'rctrl', 'lctrl', 'ctrl') and canShoot 
	and player.life > -1 and (player.energy > 15 or player.transformation)then
		-- Create some bullets
		if not player.transformation then
			player.energy = player.energy - 15
		end
		
		newBullet = { x = player.x + player.img:getWidth()/4, y = player.y + 25, img = bulletImg }
		table.insert(bullets, newBullet)
		canShoot = false
		canShootTimer = canShootTimerMax
	end
	
	-- update the positions of bullets
	for i, bullet in ipairs(bullets) do
		bullet.x = bullet.x + (1600 * dt)

		if bullet.x > player.x + 700 then -- remove bullets when they pass off the screen
			table.remove(bullets, i)
		end
	end
end

function EnemySpawn (dt)
	-- Time out enemy creation
	createEnemyTimer = createEnemyTimer - (1 * dt)
	if createEnemyTimer < 0 then
		createEnemyTimer = createEnemyTimerMax

		-- Create an enemy
		randomNumber = math.random(0, 300)
		newEnemy = { x = player.x + 700, y = randomNumber, img = enemyImg }
		table.insert(enemies, newEnemy)
	end
	
	-- update the positions of enemies
	for i, enemy in ipairs(enemies) do
		enemy.x = enemy.x + (50 * dt)
		if enemy.x < 0 then -- remove enemies when they pass off the screen
			table.remove(enemies, i)
		end
	end
end

function CollisionDetection ()
	-- run our collision detection
	-- Since there will be fewer enemies on screen than bullets we'll loop them first
	-- Also, we need to see if the enemies hit our player
	for i, enemy in ipairs(enemies) do
		for j, bullet in ipairs(bullets) do
			if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(),
			bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
				table.remove(bullets, j)
				table.remove(enemies, i)
				score = score + math.floor(score * math.random (0.05, 0.1) + 10)
			end
		end

		if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(),
		player.x, player.y, player.img:getWidth(), player.img:getHeight()) and player.life > 0 then
			table.remove(enemies, i)
			player.life = player.life - 0.2
		end
	end
end

function Reset ()
	if player.life == -1 and love.keyboard.isDown('r') then
		-- remove all our bullets and enemies from screen
		bullets = {}
		enemies = {}

		-- reset timers
		canShootTimer = canShootTimerMax
		createEnemyTimer = createEnemyTimerMax

		-- move player back to default position
		player.x = 50
		player.y = 10

		-- reset our game state
		score = 0
		player.energy = 100
		player.life = 3
		player.powerUp = 100
		player.transformation = false;
		
	end
end

function love.draw(dt)
	DrawConfig()
	DrawPlayer()
	DrawLimits()
	DrawSpaws()
	DrawUI()
end

function DrawConfig ()
	if (player.life > 0) then
		love.graphics.setColor(251, 40, 75)
	else
		love.graphics.setColor(255, 255, 255)
	end
	
	love.graphics.draw(art.bg, 0, 0)
end

function DrawPlayer()
	love.graphics.translate( -player.x + 50, 100 )
	
	if player.life > 0 then
		love.graphics.draw(player.img, player.x, player.y)
	elseif player.life > -1 then
		love.graphics.draw(player.img2, player.x, player.y)
	else
		love.graphics.print("Press 'R' to restart", player.x - player.img:getWidth() - 20 + love.graphics:getWidth()/2, love.graphics:getHeight()/2-10)
	end
end

function DrawLimits ()
	love.graphics.rectangle('fill', world:getRect(collider.top))
end

function DrawSpaws ()
	
	if (player.life > -1) then
		for i, bullet in ipairs(bullets) do
		  love.graphics.draw(bullet.img, bullet.x, bullet.y)
		end
		
		for i, enemy in ipairs(enemies) do
			love.graphics.draw(enemy.img, enemy.x, enemy.y)
		end
	end
end

function DrawUI ()
	if (player.life > 2) then
		love.graphics.draw (art.LP100, player.x, -50- art.LP100:getHeight()/2)
	elseif (player.life > 1) then
		love.graphics.draw (art.LP66, player.x, -50- art.LP66:getHeight()/2)
	elseif (player.life > 0) then
		love.graphics.draw (art.LP33, player.x, -50 - art.LP33:getHeight()/2)
	else
		love.graphics.draw (art.LP00, player.x, -50 - art.LP00:getHeight()/2)
	end
	
	love.graphics.print("SCORE " .. score, player.x + 125, -50)
	if (not player.transformation) then
		love.graphics.setColor(255, 204, 0)
		love.graphics.rectangle('fill', player.x + 500, -50, player.energy * 2, 10)
	else
		love.graphics.setColor(240, 240, 240)
		love.graphics.rectangle('fill', player.x + 500, -50, player.powerUp * 2, 10)
	end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.push("quit")
  end
end