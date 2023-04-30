SCREEN_WIDTH = love.graphics.getWidth()
SCREEN_HEIGHT = love.graphics.getHeight()

lst_laser = {}
lst_meteor = {}
lst_health_icons = {}
lst_shield_icons = {}

alpha = 0.5

local isMainMenu = true

function fLaser()
    local laser = {}
    laser.img = love.graphics.newImage("img/laser.png")
    laser.width = laser.img:getWidth()
    laser.height = laser.img:getHeight()
    laser.x = ship.x + ship.width/2 - laser.width/2
    laser.y = ship.y - ship.height/2 - laser.height/3
    laser.vy = 3
    laser.isVisible = false
    return laser
end

function fShip()
    local ship = {}
    ship.img = love.graphics.newImage("img/ship.png")
    ship.width = ship.img:getWidth()
    ship.height = ship.img:getHeight()
    ship.x = 0 + ship.width
    ship.y = SCREEN_HEIGHT - ship.height - 10
    ship.vx = 5
    ship.energy = 10
    ship.health = 3
    return ship
end

function fMeteor()
    img_meteor = {}
    img_meteor.img1 = love.graphics.newImage("img/meteor1.png")
    img_meteor.img2 = love.graphics.newImage("img/meteor2.png")
    img_meteor.img3 = love.graphics.newImage("img/meteor3.png")
    meteor = {}
    img_random = love.math.random(1,3)
    if img_random == 1 then
        meteor.img = img_meteor.img1
    elseif img_random == 2 then
        meteor.img = img_meteor.img2
    elseif img_random == 3 then
        meteor.img = img_meteor.img3
    end
    meteor.width = meteor.img:getWidth()
    meteor.height = meteor.img:getHeight()
    meteor.x = love.math.random(0,SCREEN_WIDTH - meteor.width)
    meteor.y = 0 - meteor.height
    meteor.vy = 2
    table.insert(lst_meteor, meteor)
    return meteor
end

function fHeart_icon()
    for i=1,3 do
        heart_icon = {}
        heart_icon.img = love.graphics.newImage("img/love_icon.png")
        heart_icon.width = heart_icon.img:getWidth()
        heart_icon.height = heart_icon.img:getHeight()
        heart_icon.x = 100
        heart_icon.y = 30
        table.insert(lst_health_icons, heart_icon)
    end
end

function fShield_icon()
    for i=1,10 do
        shield_icon = {}
        shield_icon.img = love.graphics.newImage("img/shield_icon.png")
        shield_icon.width = shield_icon.img:getWidth()
        shield_icon.height = shield_icon.img:getHeight()
        shield_icon.x = 100
        shield_icon.y = 10
        table.insert(lst_shield_icons, shield_icon)
    end
end

function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 < x2+w2 and
           x2 < x1+w1 and
           y1 < y2+h2 and
           y2 < y1+h1
  end

function love.load()

    font = love.graphics.newFont(30)

    countdown = 0
    time_since_last_meteor = 0
    time_between_meteors = 5 -- générer un météore toutes les 5 sec.  
    ship = fShip()
    laser = fLaser()
    num_lasers = 0 -- variable qui me sert pour la contrainte de pas plus de 2 lasers à l'écran simultanément

    fHeart_icon()
    fShield_icon()

    snd_sound = love.audio.newSource("snd/laser_shoot.mp3", "static")
    snd_ship = love.audio.newSource("snd/ship_collision.mp3", "static")
    background_music = love.audio.newSource("snd/super_bass_8_bits.mp3", "stream")
    background_music:setVolume(0.5)

end

function love.update(dt)

    -- Si on est dans le menu principal ET qu'on appuie sur la touche espace
    if isMainMenu and love.keyboard.isDown("space") then
        isMainMenu = false
        alpha = 0.5
        countdown = 0
        time_since_last_meteor = 0
        time_between_meteors = 5 -- générer un météore toutes les 5 sec.  
        ship.energy = 10
        ship.health = 3
            if #lst_health_icons ~= 3 then
                fHeart_icon()
            end
            if #lst_shield_icons ~= 10 then
                for i=1,#lst_shield_icons do
                    table.remove(lst_shield_icons)
                end
                fShield_icon()
            end
    end

    if not isMainMenu then
        countdown = countdown + dt
        time_since_last_meteor = time_since_last_meteor + dt
        

        if love.keyboard.isDown("right") and ship.x <= SCREEN_WIDTH - ship.width then
            ship.x = ship.x + ship.vx
        elseif love.keyboard.isDown("left") and ship.x >= 0 then
            ship.x = ship.x - ship.vx
        end

        for i = #lst_laser,1,-1 do
            local laser = lst_laser[i]
            if laser.isVisible then
                laser.y = laser.y - laser.vy
            end
            if laser.y < 0 - laser.img:getHeight()  then
                table.remove(lst_laser, i)
                num_lasers = num_lasers - 1 -- décrémenter le nombre de lasers à l'écran lorsque l'un d'eux est supprimé
            end
        end

        -- Gestion des météores en fonction du temps [début]
        if time_since_last_meteor >= time_between_meteors then
            fMeteor()
            time_since_last_meteor = 0
            if countdown >= 5 then
                -- countdown = 0
                if time_between_meteors > 1 then
                    time_between_meteors = time_between_meteors - 0.1
                end
            end
        end

        for i=#lst_meteor,1,-1 do
            local meteor = lst_meteor[i]
            meteor.y = meteor.y + meteor.vy
            if CheckCollision(ship.x,ship.y,ship.width,ship.height,meteor.x,meteor.y,meteor.width,meteor.height) then
                table.remove(lst_meteor, i)
                if #lst_health_icons>0 then
                    table.remove(lst_health_icons)
                end
                ship.health = ship.health - 1
                love.audio.play(snd_ship)
            end
            if meteor.y > SCREEN_HEIGHT then
                table.remove(lst_meteor, i)
                ship.energy = ship.energy - 1
                alpha = alpha - alpha/(ship.energy + 1)
                if #lst_shield_icons>0 then
                    table.remove(lst_shield_icons)
                end
                if (ship.energy <= 0) and ((ship.health == 2) or (ship.health == 1)) then
                    ship.energy = 0
                    ship.health = ship.health - 1
                    if #lst_health_icons>0 then
                        table.remove(lst_health_icons)
                    end
                end
            end
        end
        -- Gestion des météores en fonction du temps [fin]
    
        for i = #lst_meteor,1,-1 do
            local meteor = lst_meteor[i]
            for j = #lst_laser,1,-1 do
                local laser = lst_laser[j]
                if CheckCollision(laser.x,laser.y,laser.width,laser.height,meteor.x,meteor.y,meteor.width,meteor.height) then
                    table.remove(lst_meteor, i)
                    table.remove(lst_laser, j)
                    num_lasers = 0
                end
            break
            end
        break
        end  

        if (ship.energy <= 0) and (ship.health == 3) then
            ship.energy = 0
            ship.health = 2
        end

        love.audio.play(background_music)
    end

    if isMainMenu and love.keyboard.isDown("return") then
        love.event.quit()
    end

end

function love.draw()

    if isMainMenu then
        love.graphics.printf("Appuyez sur ESPACE pour continuer", 0, 250, love.graphics.getWidth(), "center")
        love.graphics.printf("Appuyez sur ENTREE pour quitter", 0, 300, love.graphics.getWidth(), "center")

    else

        love.graphics.setFont(font)
        love.graphics.print(tostring(math.ceil(countdown)), love.graphics.getWidth()/2 - 9, 0)

        love.graphics.draw(ship.img,ship.x,ship.y)

        for i=1, #lst_laser do
            local laser = lst_laser[i]
            if laser.isVisible == true then
                love.graphics.draw(laser.img,laser.x,laser.y)
            end
        end

        for i=1,#lst_meteor do
            local meteor = lst_meteor[i]
            love.graphics.draw(meteor.img,meteor.x,meteor.y)
        end
        
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.print("Vies : "..ship.health, 5, 35)
        love.graphics.print("Energie : "..ship.energy, 5, 15)
        love.graphics.print("lasers : "..#lst_laser, SCREEN_WIDTH - 100, 5)
        love.graphics.print("nb de météores : "..#lst_meteor, SCREEN_WIDTH - 100, 25)
        love.graphics.print("intervalle : "..time_between_meteors,SCREEN_WIDTH - 100, 50)

        love.graphics.setColor(0,1,0,alpha)
        love.graphics.circle("fill",ship.x + ship.width/2, ship.y + ship.height/2, ship.width/2) 
        love.graphics.setColor(1,1,1,1)

        love.graphics.print("Alpha : "..alpha, SCREEN_WIDTH - 100, 75)

        if ship.health == 0 then
            isMainMenu =true
        end

        for i=1,#lst_health_icons do
            heart_icon = lst_health_icons[i]
            love.graphics.draw(heart_icon.img,heart_icon.x*i/5 + 30,heart_icon.y)
        end

        for i=1,#lst_shield_icons do
            shield_icon = lst_shield_icons[i]
            love.graphics.draw(shield_icon.img,shield_icon.x*i/7 + 55, shield_icon.y)
        end
    end
end

function love.keypressed(key)
    if key == "space" and num_lasers < 2 then -- limiter la génération de lasers si le nombre de lasers actuellement affichés est inférieur à 2
        local newLaser = fLaser()
        newLaser.isVisible = true
        table.insert(lst_laser, newLaser)
        num_lasers = num_lasers + 1 -- incrémenter le nombre de lasers affichés à l'écran
        love.audio.play(snd_sound)
    end
end