package editors;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.system.FlxSound;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.ui.FlxButton;
import MenuCharacter;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;

using StringTools;

class MenuCharacterEditorState extends MusicBeatState
{
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var characterFile:MenuCharacterFile = null;
	var txtOffsets:FlxText;
	var defaultCharacters:Array<String> = ['dad', 'bf', 'gf'];

	override function create() {
		characterFile = {
			image: 'Menu_Dad',
			scale: 1,
			position: [0, 0],
			idle_anim: 'M Dad Idle',
			confirm_anim: 'M Dad Idle'
		};
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Corrupting The Menu Characters...", "Corrupting: " + characterFile.image);
		#end

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, defaultCharacters[char]);
			weekCharacterThing.y += 70;
			weekCharacterThing.alpha = 0.2;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51));
		add(grpWeekCharacters);

		txtOffsets = new FlxText(20, 10, 0, "[0, 0]", 32);
		txtOffsets.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		txtOffsets.alpha = 0.7;
		add(txtOffsets);

		var tipText:FlxText = new FlxText(0, 540, FlxG.width,
			"Arrow Keys - Change Offset (Hold shift for 10x speed)
			\nSpace - Play \"Start Press\" animation (Boyfriend Character Type)", 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		tipText.scrollFactor.set();
		add(tipText);

		addEditorBox();
		FlxG.mouse.visible = true;
		updateCharTypeBox();

		#if mobileC
		addVirtualPad(FULL, NONE);
		#end

		super.create();
	}

	var UI_typebox:FlxUITabMenu;
	var UI_mainbox:FlxUITabMenu;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	function addEditorBox() {
		var tabs = [
			{name: 'Character Type', label: 'Character Type'},
		];
		UI_typebox = new FlxUITabMenu(null, tabs, true);
		UI_typebox.resize(120, 180);
		UI_typebox.x = 100;
		UI_typebox.y = FlxG.height - UI_typebox.height - 50;
		UI_typebox.scrollFactor.set();
		addTypeUI();
		add(UI_typebox);

		var tabs = [
			{name: 'Character', label: 'Character'},
		];
		UI_mainbox = new FlxUITabMenu(null, tabs, true);
		UI_mainbox.resize(240, 180);
		UI_mainbox.x = FlxG.width - UI_mainbox.width - 100;
		UI_mainbox.y = FlxG.height - UI_mainbox.height - 50;
		UI_mainbox.scrollFactor.set();
		addCharacterUI();
		add(UI_mainbox);

		var loadButton:FlxButton = new FlxButton(0, 480, "Load The Corrupted Character", function() {
			loadCharacter();
		});
		loadButton.screenCenter(X);
		loadButton.x -= 60;
		add(loadButton);
	
		var saveButton:FlxButton = new FlxButton(0, 480, "Corrupt The Character", function() {
			saveCharacter();
		});
		saveButton.screenCenter(X);
		saveButton.x += 60;
		add(saveButton);
	}

	var opponentCheckbox:FlxUICheckBox;
	var boyfriendCheckbox:FlxUICheckBox;
	var girlfriendCheckbox:FlxUICheckBox;
	var curTypeSelected:Int = 0; //0 = Dad, 1 = BF, 2 = GF
	function addTypeUI() {
		var tab_group = new FlxUI(null, UI_typebox);
		tab_group.name = "Character Type";

		opponentCheckbox = new FlxUICheckBox(10, 20, null, null, "Opponent", 100);
		opponentCheckbox.callback = function()
		{
			curTypeSelected = 0;
			updateCharTypeBox();
		};

		boyfriendCheckbox = new FlxUICheckBox(opponentCheckbox.x, opponentCheckbox.y + 40, null, null, "Boyfriend", 100);
		boyfriendCheckbox.callback = function()
		{
			curTypeSelected = 1;
			updateCharTypeBox();
		};

		girlfriendCheckbox = new FlxUICheckBox(boyfriendCheckbox.x, boyfriendCheckbox.y + 40, null, null, "Girlfriend", 100);
		girlfriendCheckbox.callback = function()
		{
			curTypeSelected = 2;
			updateCharTypeBox();
		};

		tab_group.add(opponentCheckbox);
		tab_group.add(boyfriendCheckbox);
		tab_group.add(girlfriendCheckbox);
		UI_typebox.addGroup(tab_group);
	}

	var imageInputText:FlxUIInputText;
	var idleInputText:FlxUIInputText;
	var confirmInputText:FlxUIInputText;
	var confirmDescText:FlxText;
	var scaleStepper:FlxUINumericStepper;
	function addCharacterUI() {
		var tab_group = new FlxUI(null, UI_mainbox);
		tab_group.name = "Character";
		
		imageInputText = new FlxUIInputText(10, 20, 80, characterFile.image, 8);
		imageInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;		
		blockPressWhileTypingOn.push(imageInputText);
		idleInputText = new FlxUIInputText(10, imageInputText.y + 35, 100, characterFile.idle_anim, 8);
		idleInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;		
		blockPressWhileTypingOn.push(idleInputText);
		confirmInputText = new FlxUIInputText(10, idleInputText.y + 35, 100, characterFile.confirm_anim, 8);
		confirmInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;		
		blockPressWhileTypingOn.push(confirmInputText);

		var reloadImageButton:FlxButton = new FlxButton(10, confirmInputText.y + 30, "Reload Char", function() {
			reloadSelectedCharacter();
		});
		
		scaleStepper = new FlxUINumericStepper(140, imageInputText.y, 0.05, 1, 0.1, 30, 2);

		confirmDescText = new FlxText(10, confirmInputText.y - 18, 0, 'Start Press animation on the .XML:');
		tab_group.add(new FlxText(10, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(10, idleInputText.y - 18, 0, 'Idle animation on the .XML:'));
		tab_group.add(new FlxText(scaleStepper.x, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(reloadImageButton);
		tab_group.add(confirmDescText);
		tab_group.add(imageInputText);
		tab_group.add(idleInputText);
		tab_group.add(confirmInputText);
		tab_group.add(scaleStepper);
		UI_mainbox.addGroup(tab_group);
	}

	function updateCharTypeBox() {
		opponentCheckbox.checked = false;
		boyfriendCheckbox.checked = false;
		girlfriendCheckbox.checked = false;

		switch(curTypeSelected) {
			case 0:
				opponentCheckbox.checked = true;
			case 1:
				boyfriendCheckbox.checked = true;
			case 2:
				girlfriendCheckbox.checked = true;
		}

		updateCharacters();
	}

	function updateCharacters() {
		for (i in 0...3) {
			var char:MenuCharacter = grpWeekCharacters.members[i];
			char.alpha = 0.2;
			char.character = '';
			char.changeCharacter(defaultCharacters[i]);
		}
		reloadSelectedCharacter();
	}
	
	function reloadSelectedCharacter() {
		var char:MenuCharacter = grpWeekCharacters.members[curTypeSelected];

		char.alpha = 1;
		char.frames = Paths.getSparrowAtlas('menucharacters/' + characterFile.image);
		char.animation.addByPrefix('idle', characterFile.idle_anim, 24);
		if(curTypeSelected == 1) char.animation.addByPrefix('confirm', characterFile.confirm_anim, 24, false);

		char.scale.set(characterFile.scale, characterFile.scale);
		char.updateHitbox();
		char.animation.play('idle');

		confirmDescText.visible = (curTypeSelected == 1);
		confirmInputText.visible = (curTypeSelected == 1);
		updateOffset();
		
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Menu Character Editor", "Editting: " + characterFile.image);
		#end
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == imageInputText) {
				characterFile.image = imageInputText.text;
			} else if(sender == idleInputText) {
				characterFile.idle_anim = idleInputText.text;
			} else if(sender == confirmInputText) {
				characterFile.confirm_anim = confirmInputText.text;
			}
		} else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if (sender == scaleStepper) {
				characterFile.scale = scaleStepper.value;
				reloadSelectedCharacter();
			}
		}
	}

	override function update(elapsed:Float) {
		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;

				if(FlxG.keys.justPressed.ENTER) inputText.hasFocus = false;
				break;
			}
		}

		if(!blockInput) {
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
			if(FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justReleased.BACK #end) {
				FlxG.mouse.visible = false;
				MusicBeatState.switchState(new editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}

			var shiftMult:Int = 1;
			if(FlxG.keys.pressed.SHIFT) shiftMult = 10;

			if(FlxG.keys.justPressed.LEFT #if mobileC || _virtualpad.buttonLeft.justPressed #end) {
				characterFile.position[0] += shiftMult;
				updateOffset();
			}
			if(FlxG.keys.justPressed.RIGHT #if mobileC || _virtualpad.buttonRight.justPressed #end) {
				characterFile.position[0] -= shiftMult;
				updateOffset();
			}
			if(FlxG.keys.justPressed.UP #if mobileC || _virtualpad.buttonUp.justPressed #end) {
				characterFile.position[1] += shiftMult;
				updateOffset();
			}
			if(FlxG.keys.justPressed.DOWN #if mobileC || _virtualpad.buttonDown.justPressed #end) {
				characterFile.position[1] -= shiftMult;
				updateOffset();
			}

			if(FlxG.keys.justPressed.SPACE && curTypeSelected == 1) {
				grpWeekCharacters.members[curTypeSelected].animation.play('confirm', true);
			}
		}

		var char:MenuCharacter = grpWeekCharacters.members[1];
		if(char.animation.curAnim != null && char.animation.curAnim.name == 'confirm' && char.animation.curAnim.finished) {
			char.animation.play('idle', true);
		}

		super.update(elapsed);
	}

	function updateOffset() {
		var char:MenuCharacter = grpWeekCharacters.members[curTypeSelected];
		char.offset.set(characterFile.position[0], characterFile.position[1]);
		txtOffsets.text = '' + characterFile.position;
	}

	function loadCharacter() {
                var path:String = Main.getDataPath() + "yourthings/yourmenucharacter.json";
		if (FileSystem.exists(path))
                {
                    LoadCheck();
                }
	}

	function LoadCheck():Void
	{
		var path:String = Main.getDataPath() + "yourthings/yourmenucharacter.json";
		if (FileSystem.exists(path))
                {
			var rawJson:String = File.getContent(path);
			if(rawJson != null) {
				var loadedChar:MenuCharacterFile = cast Json.parse(rawJson);
				if(loadedChar.idle_anim != null && loadedChar.confirm_anim != null) //Make sure it's really a character
				{
					characterFile = loadedChar;
					reloadSelectedCharacter();
					imageInputText.text = characterFile.image;
					idleInputText.text = characterFile.image;
					confirmInputText.text = characterFile.image;
					scaleStepper.value = characterFile.scale;
					updateOffset();
					return;
				}
			}
		}
	}

	function saveCharacter() {
		var data:String = Json.stringify(characterFile, "\t");
		if (data.length > 0)
		{
			openfl.system.System.setClipboard(data.trim());
		}
	}
}
