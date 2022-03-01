function onCreate()
	-- background shit
	makeLuaSprite('Outside', 'characters/non', -550, 100);
	setScrollFactor('Outside', 0.9, 0.9);
	
	makeLuaSprite('BACKGROUND', 'BACKGROUND', -650, -400);
	setScrollFactor('BACKGROUND', 0.9, 0.9);
	scaleObject('stagefront', 1.1, 1.1);

	addLuaSprite('Outside', false);
	addLuaSprite('BACKGROUND', false);

	close(true); --For performance reasons, close this script once the stage is fully loaded, as this script won't be used anymore after loading the stage
end