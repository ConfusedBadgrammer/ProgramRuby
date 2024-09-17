require 'gosu'
require "matrix"

module ZOrder
  BACKGROUND, MIDDLE, TOP = *0..2
end

WIDTH = 660
HEIGHT = 900
PLAYER_DIM = 50
MAX_PROJECTILES = 50
MAX_ENEMIES = 50
ALLY = true
ENEMY = false
MAX_POWERUPS = 20

class Entity
  attr_accessor :health, :xPos, :yPos, :velocity, :team, :isActive, :width, :height, :entityImage
#reduce health
  def ReduceHealth(damage)
    @health -= damage
  end

end

class Base < Entity
  attr_accessor :health, :baseHealthImage

  def initialize
    @health = 5
    @entityImage = Gosu::Image.new("media/images/base.png")
    @baseHealthImage = Gosu::Image.new("media/images/basehealth.png")
  end

end

class PowerUps < Entity
  attr_accessor :powerUpType

  def initialize
    @isActive = false
    @isPowerUp = true
    @width = 50
    @height = 50
    @powerUpFireRate = Gosu::Sample.new("media/sounds/powerup1.mp3")
    @powerUpHealth = Gosu::Sample.new("media/sounds/powerup2.mp3")
    @powerUpIncreaseMovement = Gosu::Sample.new("media/sounds/powerup3.mp3")
    @powerUpIncreaseStamina = Gosu::Sample.new("media/sounds/powerup4.mp3")
  end
  #set parameters when activate power up is called
  def ActivatePowerUp(xPos, yPos, velocity)
    @xPos = xPos
    @yPos = yPos
    @velocity = velocity
    @isActive = true
    @powerUpType = rand(1...5)

    if @powerUpType == 1
      @entityImage = Gosu::Image.new("media/images/increasefirerate.png")

    elsif @powerUpType == 2
      @entityImage = Gosu::Image.new("media/images/increasehealth.png")

    elsif @powerUpType == 3
      @entityImage = Gosu::Image.new("media/images/increasemovement.png")

    elsif @powerUpType == 4
      @entityImage = Gosu::Image.new("media/images/increasestamina.png")
    end
  end

  #play sound depending on power up type
  def playPowerUpSound
    if @powerUpType == 1
      @powerUpFireRate.play(0.5)
    elsif @powerUpType == 2
      @powerUpHealth.play(0.5)
    elsif @powerUpType == 3
      @powerUpIncreaseMovement.play(0.5)
    elsif @powerUpType == 4
      @powerUpIncreaseStamina.play(0.5)
    end
  end


  def update
    MovePowerUp()
    CheckBaseHit()
  end

  def MovePowerUp
    @xPos += @velocity[0]
    @yPos += @velocity[1]
  end

  def CheckBaseHit()
    if @yPos > 820
      PowerUpDie()
    end
  end

  def PowerUpDie
    @isActive = false
  end

end

class Player < Entity
  attr_accessor :healthImage

  def initialize(xPos, yPos)
    @xPos = xPos
    @yPos = yPos
    @entityImage = Gosu::Image.new("media/images/player.png")
    @width = 50
    @height = 50
    @health = 3
    @healthImage = Gosu::Image.new("media/images/heartpixel.png")
    @team = ALLY
  end
end

class Enemy < Entity
  attr_accessor :baseHit

  def initialize
    @isActive = false
    @entityImage = Gosu::Image.new("media/images/burger.png")
    @width = 50
    @height = 15
    @health = 1
    @baseHit = false
  end

  def ActivateEnemy(xPos, yPos, velocity, team)
    @xPos = xPos
    @yPos = yPos
    @velocity = velocity
    @team = team
    @isActive = true
  end

  def update
    MoveEnemy()
    CheckBaseHit()
    CheckHealth()
  end

  def MoveEnemy
    @xPos += @velocity[0]
    @yPos += @velocity[1]
  end

  def CheckBaseHit()
    if @yPos > 820
      EnemyDie()
      @baseHit = true
    end
  end

  def CheckHealth()
    if @health == 0
      EnemyDie()
      @health = 1
    end
  end

  def EnemyDie()
    @isActive = false
  end


end



class Projectile < Entity
  attr_accessor :damage
  def initialize
    @isActive = false;
    @entityImage = Gosu::Image.new("media/images/bullet.png")
    @width = 10
    @height = 10
    @damage = 1
  end

  def ActivateProjectile(xPos, yPos, velocity, team)
    @xPos = xPos
    @yPos = yPos
    @velocity = velocity
    @team = team
    @isActive = true
  end

  def update
    MoveProjectile()
    CheckEdgeHit()
  end

  # Checks if the projectile has hit the end of the screen, if so, projectileDIe
  def CheckEdgeHit()
    if @yPos < 0 || @yPos > HEIGHT
      ProjectileDie()
    end
  end


  def MoveProjectile
    @xPos += @velocity[0]
    @yPos += @velocity[1]
  end

  def ProjectileDie
    @isActive = false
  end

end

class Animation < Entity
  attr_accessor :images, :maxAnimationFrames, :ticksPerFrame

  def initialize(path, maxAnimationFrames, ticksPerFrame, xPos, yPos)
    @currentAnimationFrame = 0
    @currentTickCount = 0
    @isActive = true
    @xPos = xPos
    @yPos = yPos
    @maxAnimationFrames = maxAnimationFrames
    @ticksPerFrame = ticksPerFrame
    @spriteSheet = Gosu::Image.new(path)
    LoadSprites()
  end
  #used to increment through frames and how long before iterating to the next one, once done set isActive to false
  def update
    @currentTickCount += 1
    if @currentTickCount >= @ticksPerFrame
      @currentTickCount = 0
      @currentAnimationFrame += 1
      if @currentAnimationFrame >= @maxAnimationFrames-1
        @isActive = false
      end
    end
  end
#create an array of sprite
  def LoadSprites
    @images = Array.new()
    for i in 0..maxAnimationFrames-1
      image = @spriteSheet.subimage(127 * i, 0, 127, 127)
      @images << image
    end
  end
#get the image out of the array and draw the current frame
  def GetImageToDraw
    return @images[@currentAnimationFrame]
  end
end

class Game
  attr_accessor :Projectiles, :Enemies, :PowerUps, :score, :background, :highscore,
  :explodeSound, :boostSound, :deathSound, :newGameSound , :newHighScoreSound, :gameStartMusic, :gameLobbyMusic, :fireRateBoostOffSound, :fireRateBoostOnSound,
  :fireRatePowerUp, :powerUpIncreaseMovement, :powerUpIncreaseStamina, :powerUpStaminaThreshold, :fireRateBonus, :lobbyAliens
  def initialize

    CreateProjectiles()
    CreateEnemies()
    CreatePowerUps()
    @score = 0

    #game sounds
    @background = Gosu::Image.new('media/images/background.png')
    @explodeSound = Gosu::Sample.new("media/sounds/sfx_explosionNormal.ogg")
    @boostSound = Gosu::Sample.new("media/sounds/sfx_toggle.ogg")
    @deathSound = Gosu::Sample.new("media/sounds/sfx_death.ogg")
    @hurtSound = Gosu::Sample.new("media/sounds/sfx_hurt.ogg")
    @enemyExplode = Gosu::Sample.new("media/sounds/explosion_1.wav")
    @newGameSound = Gosu::Sample.new("media/sounds/sfx_resurrect.ogg")
    @newHighScoreSound = Gosu::Sample.new("media/sounds/gmae.wav")
    @fireRateBoostOnSound = Gosu::Sample.new("media/sounds/firerateboost.wav")
    @fireRateBoostOffSound = Gosu::Sample.new("media/sounds/steamhisses.wav")
    @gameStartMusic = Gosu::Song.new("media/sounds/music_gamestart.ogg")
    @gameLobbyMusic = Gosu::Song.new("media/sounds/music_lobby.ogg")
    @lobbyAliens = Gosu::Image.new("media/images/burger.png")
    #power up parameters
    @fireRatePowerUp = 0
    @powerUpIncreaseMovement = 0
    @powerUpIncreaseStamina = 0
    @powerUpStaminaThreshold = 0
    @animations = Array.new()
    #read file and get highscore
    @highscore = ReadFile()

  end
#read contents of file
  def ReadFile()
    file = File.open("save/highscore.txt", "r")
    contents = file.read
    file.close
    contents.to_i
  end
#play sound at 50% volume
  def playSound(sound)
    sound.play(0.5)
  end
#create an array of enemies
  def CreateEnemies()
    @Enemies = Array.new()
    for i in 0...MAX_ENEMIES
      @Enemies << Enemy.new
    end
  end
#create an array of power ups
  def CreatePowerUps()
    @PowerUps = Array.new()
    for i in 0...MAX_POWERUPS
      @PowerUps << PowerUps.new
    end
  end
#set first inactive power up to active
  def SpawnPowerUps(xPos, yPos, velocity)
    for powerup in @PowerUps
      if(!powerup.isActive)
        powerup.ActivatePowerUp(xPos, yPos, velocity)
        break
      end
    end
  end

  #set first inactive enemy to active
  def SpawnEnemy(xPos, yPos, velocity, team)
    for enemy in @Enemies
      if(!enemy.isActive)
        enemy.ActivateEnemy(xPos, yPos, velocity, team)
        break
      end
    end
  end

  def update
    #run update functions for each class for each active object
    for projectile in @Projectiles
      if(projectile.isActive)
        projectile.update()
      end
    end

    for enemy in @Enemies
      if(enemy.isActive)
        enemy.update()
      end
    end

    for powerup in @PowerUps
      if(powerup.isActive)
          powerup.update()
      end
    end


    #Remove inactive animations from the array
    @animations = @animations.delete_if{|animation| !animation.isActive}

    for animation in @animations
      animation.update()
    end
  end

  #draw animations set to active
  def draw
    for animation in @animations
      if animation.isActive
        animation.GetImageToDraw.draw(animation.xPos, animation.yPos,ZOrder::TOP, 0.6, 0.6)
      end
    end
  end

  #create the projectiles front end
  def CreateProjectiles
    @Projectiles = Array.new()
    for i in 0..MAX_PROJECTILES
      @Projectiles << Projectile.new
    end
  end

  # Finds and activates the next inactive projectile
  def SpawnProjectile(xPos, yPos, velocity, team)
    for projectile in @Projectilesn
      if(!projectile.isActive)
        projectile.ActivateProjectile(xPos, yPos, velocity, team)
        break
      end
    end
  end

  # Checks projectile against enemies
  def checkProjectilesCollisions(entity)
    if entity.nil?
      return
    end

    for projectile in @Projectiles
      if projectile.isActive && IsOverlapping(entity, projectile)
         entity.ReduceHealth(projectile.damage)
         projectile.ProjectileDie()
         if entity.is_a?(Enemy) && entity.isActive
          IncreaseScore()
          playSound(@enemyExplode)
          SpawnExplosion(entity.xPos - 10, entity.yPos - 10)
        end
      end
    end
  end

  #check entity to enemy collisions
  def checkEnemyCollisions (entity)
    if entity.nil?
      return
    end

    for enemy in @Enemies
      if enemy.isActive && IsOverlapping(entity, enemy) && entity.team != enemy.team
        entity.ReduceHealth(enemy.health)
        enemy.EnemyDie()
        playSound(@hurtSound)
        playSound(@enemyExplode)
        SpawnExplosion(enemy.xPos - 10, enemy.yPos - 10)
      end
    end
  end

    #for each active powerup, depending on power up increment certain attributes of player
  def checkPowerUpCollisions (entity)
    if entity.nil?
      return
    end

    for powerup in @PowerUps
      if powerup.isActive && IsOverlapping(entity, powerup)
        powerup.playPowerUpSound()
        if powerup.powerUpType == 1
          @fireRatePowerUp += 0.5
          @fireRateBonus += 1
        elsif powerup.powerUpType == 2
          if entity.health < 5
          entity.health += 1
          end
        elsif powerup.powerUpType == 3
          if @powerUpIncreaseMovement < 5
          @powerUpIncreaseMovement += 0.2
          end
        elsif powerup.powerUpType == 4
          if @powerUpStaminaThreshold < 100
          @powerUpIncreaseStamina += 10
          @powerUpStaminaThreshold += 10
          @powerUpIncreaseStamina = @powerUpStaminaThreshold
          end
        end
        powerup.PowerUpDie()
      end
    end
  end

  # Checks if the two objects are overlapping
  def IsOverlapping(object1, object2)
    #puts "object1: x=#{object1.xPos}, y=#{object1.yPos}, width=#{object1.width}, height=#{object1.height}"
    #puts "object2: x=#{object2.xPos}, y=#{object2.yPos}, width=#{object2.width}, height=#{object2.height}"
    if (object1.xPos < object2.xPos + object2.width &&
      object1.xPos + object1.width > object2.xPos &&
      object1.yPos < object2.yPos + object2.height &&
      object1.yPos + object1.height > object2.yPos)
      return true
    else
    return false
    end
  end
  #increase score when called
  def IncreaseScore()
    @score += 1
  end
  #spawn explosions and sets frames and ticks per frame
  def SpawnExplosion(xPos, yPos)
    maxAnimationFrames = 6
    ticksPerFrame = 3
    @animations << Animation.new("media/images/boom.png", maxAnimationFrames, ticksPerFrame, xPos, yPos)
  end
end

class GameWindow < Gosu::Window

  def initialize
    super(WIDTH, HEIGHT, false)
    self.caption = "Space Defenders"
    @gameStart = false
    @gameOver = false
    @lobby = true
    @startFont = Gosu::Font.new(30)
    @keyPressFrames = 0
    @game = Game.new
    @game.gameLobbyMusic.volume = 0.2
    @game.gameLobbyMusic.play(true)
    @lobbybackground = Gosu::Image.new("media/images/background.png")
    @startTime = Gosu.milliseconds
  end

  def update
    #increment the keypressframes used in function below
    @keyPressFrames += 1
    if @keyPressFrames > 50
      @keyPressFrames = 50
    end

    #initialize parameters when game is started or restarted
    if button_down?(Gosu::KbSpace) && @gameOver == true && @keyPressFrames >= 50
      @gameOver = false
      @game.playSound(@game.newGameSound)
      @startTime = Gosu.milliseconds
    end
    #initialize parameters when game is started or restarted
    if button_down?(Gosu::KbSpace) && @gameStart == false && @keyPressFrames >= 50
      @base = Base.new
      @game = Game.new
      @player = Player.new(300, 700)
      @firerateFrameDelay = 0
      @fireRight = false
      @fireyOffset = -7
      @fireRate = 15

      @smallEnemySpawnInterval = rand(20...30)
      @smallEnemySpawnFrameCount = 0

      @PowerUpSpawnInterval = rand(200...300)
      @PowerUpSpawnFrameCount = 0

      @gameStart = true
      @Font = Gosu::Font.new(20)

      @game.gameStartMusic.volume = 0.15
      @game.gameStartMusic.play(true)

      @boost = 0
      @fireBoost = 0
      @togglefireBoost = false
      @fuel = 100
      @boostFrameDelay = 10
      @keyPressFrames = 0
      @boostSoundFrameDelay = 100
      @boostSoundDelay = 100
      @game.fireRateBonus = 0
    end


    if @gameStart == true && @gameOver == false
      #variables and functions for game
      @smallEnemySpawnFrameCount += 1
      @PowerUpSpawnFrameCount += 1
      @firerateFrameDelay += 1
      @boostSoundFrameDelay += 1
      @game.update()
      @game.checkProjectilesCollisions(@player)
      @game.checkEnemyCollisions(@player)
      @game.checkPowerUpCollisions(@player)
      @gameDifficultyModifier = @game.score/4
      @currentTime = Gosu.milliseconds
      @elapsedTime = @currentTime - @startTime
      @timerSeconds = @elapsedTime/ 1000
      @fireRate = 15 - @game.fireRatePowerUp

      # Buttons to move around
      if button_down?(Gosu::KbUp) && (@player.yPos > 0)
        @player.yPos -= 4 + (@boost + @game.powerUpIncreaseMovement)
      end

      if button_down?(Gosu::KbDown) && (@player.yPos < HEIGHT - PLAYER_DIM - 100)
        @player.yPos += 4 + (@boost + @game.powerUpIncreaseMovement)
      end

      if button_down?(Gosu::KbRight) && (@player.xPos < WIDTH - PLAYER_DIM)
        @player.xPos += 4 + (@boost + @game.powerUpIncreaseMovement)
      end

      if button_down?(Gosu::KbLeft) && (@player.xPos > -50)
        @player.xPos -= 5 + (@boost + @game.powerUpIncreaseMovement)
      end

      if @fireRate < 3
        @fireRate = 3
      end
      #fire bullets based on frames, firerate and fireboost
      if button_down?(Gosu::KbSpace) && (@firerateFrameDelay > (@fireRate  - @fireBoost))
        if (@fireRight)
          offset = 20
          @fireRight = false
        else
          offset = 30
          @fireRight = true
        end
        @game.SpawnProjectile(@player.xPos + offset, @player.yPos + @fireyOffset, Vector[0, -15], ALLY)
        @firerateFrameDelay = 0
      end
      #boost and drain fuel
      if button_down?(Gosu::KbLeftShift) && @fuel > 0
        @boost = 2
        if @game.powerUpIncreaseStamina > 0
          @game.powerUpIncreaseStamina -= 1
        else
          @fuel = @fuel - 1
        end
        if @boostSoundFrameDelay > @boostSoundDelay
          @game.playSound(@game.boostSound)
          @boostSoundFrameDelay = 0
        end
      else
        @boost = 0
      end
      #add stamina if fireboost and speedboost is off
      if @fuel < 100 && !button_down?(Gosu::KbLeftShift) && !@togglefireBoost
        @fuel += 1
      elsif @game.powerUpIncreaseStamina < @game.powerUpStaminaThreshold && !@togglefireBoost && !button_down?(Gosu::KbLeftShift)
          @game.powerUpIncreaseStamina += 1.5
        end

      #reduce stamina when fireboost is on
      if @togglefireBoost == true && @fuel > 0
        if @game.powerUpIncreaseStamina > 0
          @game.powerUpIncreaseStamina -= 0.3
        else
        @fuel = @fuel - 0.3
      end
    end
      #maximum difficulty
      if @gameDifficultyModifier > 49
        @gameDifficultyModifier = 49
      end
      #spawn enemies based on frames
      if (@smallEnemySpawnFrameCount > @smallEnemySpawnInterval)
        @game.SpawnEnemy(rand(WIDTH - PLAYER_DIM), 0, Vector[0, rand(1...5)], ENEMY)
        @smallEnemySpawnInterval = rand(50...80) - @gameDifficultyModifier
        @smallEnemySpawnFrameCount = 0
      end
      #spawn power up based on updates
      if (@PowerUpSpawnFrameCount > @PowerUpSpawnInterval)
        @game.SpawnPowerUps(rand(WIDTH - PLAYER_DIM), 0, Vector[0, 1])
        @PowerUpSpawnInterval = rand(350...420)
        @PowerUpSpawnFrameCount = 0
      end

      #stops player from boosting when fuel is less than 1
      if @fuel < 1
        @fireBoost = 0
        @togglefireBoost = false
      end

      #if Z is pressed modify certain parameters, play sound and increase firerate
      if button_down?(Gosu::KbZ) && @boostFrameDelay < @keyPressFrames
        @keyPressFrames = -20
        if !@togglefireBoost
          @game.playSound(@game.fireRateBoostOnSound)
        @fireBoost = 5
        @togglefireBoost = true
        elsif @togglefireBoost
          @game.playSound(@game.fireRateBoostOffSound)
          @fireBoost = 0
          @togglefireBoost = false
        end
      end
      #calls checkprojectilescollisions
      for enemy in @game.Enemies
        if enemy.isActive
          @game.checkProjectilesCollisions(enemy)
        end
      end
      #Check if health of player or base is 0 and end game
      if @player.health <= 0 || @base.health <= 0
        @game.gameStartMusic.stop()
        @game.playSound(@game.deathSound)
        @gameOver = true
        @gameStart = false
        @keyPressFrames = 0
        @startTime = Gosu.milliseconds
      end
      #Check each enemy if they hit the base
      for enemy in @game.Enemies
        if enemy.baseHit == true
          @base.health = @base.health - 1
          enemy.baseHit = false
          @game.playSound(@game.explodeSound)
          @game.SpawnExplosion(enemy.xPos - 10, enemy.yPos - 10)
        end
      end
    end


  def draw
    #play lobby music
    @lobbybackground.draw(0, 0, ZOrder::BACKGROUND, 1.0, 1.0)
    #draws the lobby information on how to start
    if @gameStart == false && @gameOver == false
      @startFont.draw_markup("PRESS SPACE TO START!", 155, HEIGHT/2, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
    end
    #draw game over screen
    if @gameOver == true
      if @game.score > @game.highscore
        @game.highscore = @game.score

        file = File.open("save/highscore.txt", "w")
        file.write("#{@game.score}")
        file.close
        @game.playSound(@game.newHighScoreSound)
      end
      #draw aliens for gameover screen
      @game.lobbyAliens.draw(80, 200, 1, 1.4, 1.4)
      @game.lobbyAliens.draw(150, 200, 1, 1.4, 1.4)
      @game.lobbyAliens.draw(220, 200, 1, 1.4, 1.4)
      @game.lobbyAliens.draw(290, 200, 1, 1.4, 1.4)
      @game.lobbyAliens.draw(360, 200, 1, 1.4, 1.4)
      @game.lobbyAliens.draw(430, 200, 1, 1.4, 1.4)
      @game.lobbyAliens.draw(500, 200, 1, 1.4, 1.4)

      @startFont.draw_markup("GAME OVER", 245, 300, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      #draw gameover screen based on what was destroyed
      if @base.health <= 0
      @startFont.draw_markup("YOUR BASE WAS DESTROYED!", 125, 340, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      end
      if @player.health <= 0
      @startFont.draw_markup("YOU WERE DESTROYED!", 165, 340, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      end

      @Font.draw_markup("High Score: #{@game.highscore}", 268, 420, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      @Font.draw_markup("Your Score: #{@game.score}", 268, 460, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      @Font.draw_markup("Survival Time: #{@timerSeconds}s", 268, 500, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      #ensures game isnt restarted when holding down space and dying
      if @keyPressFrames >= 50
      @startFont.draw_markup("Press Space to retry", 198, 580, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      end
      Gosu.draw_rect(187, 650, (@keyPressFrames*5.4), 20, Gosu::Color::WHITE, ZOrder::TOP, mode=:default)
    end

    #draw if game has been started
    if @gameStart == true && @gameOver == false
      @player.entityImage.draw(@player.xPos, @player.yPos,ZOrder::TOP, 1, 1)
      #draw all active projectiles
      for projectile in @game.Projectiles
        if(projectile.isActive)
          projectile.entityImage.draw(projectile.xPos, projectile.yPos, 1, 1.3, 1.3)
        end
      end

      #draw all active enemies
      for enemy in @game.Enemies
        if(enemy.isActive)
          enemy.entityImage.draw(enemy.xPos, enemy.yPos, 1, 1.4, 1.4)
        end
      end

      #draw all active power ups
      for powerup in @game.PowerUps
        if(powerup.isActive)
          powerup.entityImage.draw(powerup.xPos, powerup.yPos, 1, 0.7, 0.7)
        end
      end

      #draw game animations
      @game.draw()
      @game.background.draw(0, 0, ZOrder::BACKGROUND, 1.0, 1.0)
      @base.entityImage.draw(-170, 770, 1, 1.0, 1.0)
      @Font.draw_markup("TIME: #{@timerSeconds}s", 150, 10, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      @Font.draw_markup("SCORE: #{@game.score}", 10, 10, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      @Font.draw_markup("HEALTH:", 10, 860, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      @Font.draw_markup("REPAIRS:", 10, 820, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      @Font.draw_markup("FUEL:", 285, 860, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      @Font.draw_markup("FIRE RATE BONUS:", 285, 820, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      @Font.draw_markup("#{@game.fireRateBonus}", 455, 820, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      @Font.draw_markup("BONUS SPEED:", 480, 820, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)
      @Font.draw_markup("#{@boost + @game.powerUpIncreaseMovement}", 620, 820, ZOrder::TOP, 1.0, 1.0, Gosu::Color::WHITE)

      #draws stamina bar based on fireboost status
      if !@togglefireBoost
            Gosu.draw_rect(340, 860, (@game.powerUpIncreaseStamina*2.9), 20, Gosu::Color::CYAN, ZOrder::TOP, mode=:default)
            Gosu.draw_rect(340, 860, (@fuel*2.9), 20, Gosu::Color::WHITE, ZOrder::MIDDLE, mode=:default)
        elsif @game.powerUpIncreaseStamina > 0 && @togglefireBoost
          Gosu.draw_rect(340, 860, (@fuel*2.9), 20, Gosu::Color::WHITE, ZOrder::MIDDLE, mode=:default)
          Gosu.draw_rect(340, 860, (@game.powerUpIncreaseStamina*2.9), 20, Gosu::Color::CYAN, ZOrder::TOP, mode=:default)
        else
          if @game.powerUpIncreaseStamina <= 0 && @togglefireBoost
            Gosu.draw_rect(340, 860, (@fuel*2.9), 20, Gosu::Color::RED, ZOrder::MIDDLE, mode=:default)
        end
      end

      #draws player health images
      if @player.health == 5
        @player.healthImage.draw(90, 850, 1, 0.75, 0.75)
        @player.healthImage.draw(120, 850, 1, 0.75, 0.75)
        @player.healthImage.draw(150, 850, 1, 0.75, 0.75)
        @player.healthImage.draw(180, 850, 1, 0.75, 0.75)
        @player.healthImage.draw(210, 850, 1, 0.75, 0.75)

      elsif @player.health == 4
        @player.healthImage.draw(90, 850, 1, 0.75, 0.75)
        @player.healthImage.draw(120, 850, 1, 0.75, 0.75)
        @player.healthImage.draw(150, 850, 1, 0.75, 0.75)
        @player.healthImage.draw(180, 850, 1, 0.75, 0.75)

      elsif @player.health == 3
        @player.healthImage.draw(90, 850, 1, 0.75, 0.75)
        @player.healthImage.draw(120, 850, 1, 0.75, 0.75)
        @player.healthImage.draw(150, 850, 1, 0.75, 0.75)

      elsif @player.health == 2
        @player.healthImage.draw(90, 850, 1, 0.75, 0.75)
        @player.healthImage.draw(120, 850, 1, 0.75, 0.75)

      elsif @player.health == 1
        @player.healthImage.draw(90, 850, 1, 0.75, 0.75)
      end

      #draws base wrenches
      if @base.health == 5
        @base.baseHealthImage.draw(100, 820, 1, 0.75, 0.75)
        @base.baseHealthImage.draw(130, 820, 1, 0.75, 0.75)
        @base.baseHealthImage.draw(160, 820, 1, 0.75, 0.75)
        @base.baseHealthImage.draw(190, 820, 1, 0.75, 0.75)
        @base.baseHealthImage.draw(220, 820, 1, 0.75, 0.75)

      elsif @base.health == 4
        @base.baseHealthImage.draw(100, 820, 1, 0.75, 0.75)
        @base.baseHealthImage.draw(130, 820, 1, 0.75, 0.75)
        @base.baseHealthImage.draw(160, 820, 1, 0.75, 0.75)
        @base.baseHealthImage.draw(190, 820, 1, 0.75, 0.75)

      elsif @base.health == 3
        @base.baseHealthImage.draw(100, 820, 1, 0.75, 0.75)
        @base.baseHealthImage.draw(130, 820, 1, 0.75, 0.75)
        @base.baseHealthImage.draw(160, 820, 1, 0.75, 0.75)

      elsif @base.health == 2
        @base.baseHealthImage.draw(100, 820, 1, 0.75, 0.75)
        @base.baseHealthImage.draw(130, 820, 1, 0.75, 0.75)

      elsif @base.health == 1
        @base.baseHealthImage.draw(100, 820, 1, 0.75, 0.75)
      end
    end
  end
end
end


window = GameWindow.new
window.show
