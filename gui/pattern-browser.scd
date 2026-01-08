/*
═══════════════════════════════════════════════════════════════════
PATTERN BROWSER - GUI Window
═══════════════════════════════════════════════════════════════════

Pop-up window for browsing and loading sequencer patterns.
Minimal aesthetic with waveform previews.

Requirements:
- ~patternLibrary must be initialized
- ~trackManager must be available

Usage:
~patternBrowser.open;
*/

~patternBrowser = (
	window: nil,
	currentPattern: nil,
	currentCategory: \all,

	// UI elements
	categoryMenu: nil,
	searchField: nil,
	patternList: nil,
	previewView: nil,
	descriptionText: nil,
	codeView: nil,
	loadButtons: nil,

	// Open the browser window
	open: { arg self;
		if(self.window.notNil and: { self.window.isClosed.not }, {
			self.window.front;
			^self;
		});

		self.createWindow;
		self;
	},

	// Create the main window
	createWindow: { arg self;
		var win, categoryLabel, categoryMenu, searchLabel, searchField;
		var listView, previewView, descLabel, descText;
		var loadTrack1, loadTrack2, loadTrack3, loadTrack4;
		var showCodeBtn, closeBtn;
		var bgColor = Color.gray(0.15);
		var fgColor = Color.gray(0.9);
		var accentColor = Color(0.4, 0.6, 0.8);

		win = Window("Pattern Browser", Rect(200, 100, 800, 650))
			.background_(bgColor)
			.alwaysOnTop_(true);

		// ═══════════════════════════════════════════════════
		// TOP BAR: Category and Search
		// ═══════════════════════════════════════════════════

		categoryLabel = StaticText(win, Rect(20, 15, 70, 20))
			.string_("Category:")
			.stringColor_(fgColor)
			.font_(Font("Monaco", 11));

		categoryMenu = PopUpMenu(win, Rect(95, 13, 150, 25))
			.items_(["All", "Yoshimura", "Eno", "Terrestrial", "Microtonal", "Rhythmic", "Mathematical"])
			.background_(Color.gray(0.25))
			.stringColor_(fgColor)
			.action_({ |menu|
				var cats = [\all, \yoshimura, \eno, \terrestrial, \microtonal, \rhythmic, \mathematical];
				self.currentCategory = cats[menu.value];
				self.updatePatternList;
			});

		searchLabel = StaticText(win, Rect(270, 15, 50, 20))
			.string_("Search:")
			.stringColor_(fgColor)
			.font_(Font("Monaco", 11));

		searchField = TextField(win, Rect(330, 13, 200, 25))
			.background_(Color.gray(0.25))
			.stringColor_(fgColor)
			.font_(Font("Monaco", 11))
			.action_({ |field|
				self.updatePatternList(field.string);
			});

		closeBtn = Button(win, Rect(750, 13, 30, 25))
			.states_([["X", fgColor, Color.gray(0.3)]])
			.action_({ win.close });

		// ═══════════════════════════════════════════════════
		// LEFT PANEL: Pattern List
		// ═══════════════════════════════════════════════════

		StaticText(win, Rect(20, 50, 250, 25))
			.string_("Pattern List")
			.stringColor_(accentColor)
			.font_(Font("Monaco", 13, true));

		listView = ListView(win, Rect(20, 80, 250, 520))
			.background_(Color.gray(0.2))
			.stringColor_(fgColor)
			.hiliteColor_(accentColor)
			.font_(Font("Monaco", 11))
			.action_({ |lv|
				var patternName = self.getPatternNameFromIndex(lv.value);
				if(patternName.notNil, {
					self.selectPattern(patternName);
				});
			});

		self.patternList = listView;

		// ═══════════════════════════════════════════════════
		// RIGHT PANEL: Preview and Controls
		// ═══════════════════════════════════════════════════

		StaticText(win, Rect(290, 50, 250, 25))
			.string_("Preview")
			.stringColor_(accentColor)
			.font_(Font("Monaco", 13, true));

		// Waveform preview (like LFO spectrograms)
		previewView = UserView(win, Rect(290, 80, 490, 150))
			.background_(Color.gray(0.2))
			.drawFunc_({ |view|
				if(self.currentPattern.notNil, {
					self.drawWaveform(view);
				});
			});

		self.previewView = previewView;

		// Description
		descLabel = StaticText(win, Rect(290, 245, 490, 20))
			.string_("Description:")
			.stringColor_(fgColor)
			.font_(Font("Monaco", 11, true));

		descText = TextView(win, Rect(290, 270, 490, 80))
			.background_(Color.gray(0.2))
			.stringColor_(fgColor)
			.font_(Font("Monaco", 11))
			.editable_(false);

		self.descriptionText = descText;

		// ═══════════════════════════════════════════════════
		// LOAD BUTTONS
		// ═══════════════════════════════════════════════════

		StaticText(win, Rect(290, 365, 490, 20))
			.string_("Load to Track:")
			.stringColor_(fgColor)
			.font_(Font("Monaco", 11, true));

		loadTrack1 = Button(win, Rect(290, 390, 115, 30))
			.states_([["Track 1", fgColor, Color.gray(0.3)]])
			.action_({ self.loadToTrack(0); });

		loadTrack2 = Button(win, Rect(415, 390, 115, 30))
			.states_([["Track 2", fgColor, Color.gray(0.3)]])
			.action_({ self.loadToTrack(1); });

		loadTrack3 = Button(win, Rect(540, 390, 115, 30))
			.states_([["Track 3", fgColor, Color.gray(0.3)]])
			.action_({ self.loadToTrack(2); });

		loadTrack4 = Button(win, Rect(665, 390, 115, 30))
			.states_([["Track 4", fgColor, Color.gray(0.3)]])
			.action_({ self.loadToTrack(3); });

		// ═══════════════════════════════════════════════════
		// DISABLE SEQUENCES BUTTONS
		// ═══════════════════════════════════════════════════

		StaticText(win, Rect(290, 430, 490, 20))
			.string_("Disable Sequences:")
			.stringColor_(fgColor)
			.font_(Font("Monaco", 11, true));

		Button(win, Rect(290, 455, 115, 30))
			.states_([["Clear Track 1", fgColor, Color.gray(0.25)]])
			.action_({ self.disableSequences(0); });

		Button(win, Rect(415, 455, 115, 30))
			.states_([["Clear Track 2", fgColor, Color.gray(0.25)]])
			.action_({ self.disableSequences(1); });

		Button(win, Rect(540, 455, 115, 30))
			.states_([["Clear Track 3", fgColor, Color.gray(0.25)]])
			.action_({ self.disableSequences(2); });

		Button(win, Rect(665, 455, 115, 30))
			.states_([["Clear Track 4", fgColor, Color.gray(0.25)]])
			.action_({ self.disableSequences(3); });

		// ═══════════════════════════════════════════════════
		// SHOW CODE BUTTON
		// ═══════════════════════════════════════════════════

		showCodeBtn = Button(win, Rect(290, 500, 490, 35))
			.states_([["Show Code", fgColor, Color(0.3, 0.5, 0.7)]])
			.font_(Font("Monaco", 12, true))
			.action_({ self.showCode; });

		// ═══════════════════════════════════════════════════
		// INFO TEXT
		// ═══════════════════════════════════════════════════

		StaticText(win, Rect(290, 545, 490, 80))
			.string_("30 built-in patterns across 6 categories.\nClick a pattern to preview, then load to any track.\n'Clear Track' buttons disable sequences (turn off jitter).\n'Show Code' reveals the generator function (educational).\n\nTip: Use Search to filter by keyword.")
			.stringColor_(Color.gray(0.6))
			.font_(Font("Monaco", 10));

		self.window = win;
		self.categoryMenu = categoryMenu;
		self.searchField = searchField;

		// Initialize pattern list
		self.updatePatternList;

		win.front;
	},

	// Update the pattern list based on category/search
	updatePatternList: { arg self, searchTerm = "";
		var patterns, displayNames;

		if(~patternLibrary.isNil, {
			"Error: Pattern library not initialized".warn;
			^self;
		});

		// Get patterns
		patterns = if(self.currentCategory == \all, {
			~patternLibrary.patterns.values;
		}, {
			~patternLibrary.getByCategory(self.currentCategory);
		});

		// Filter by search term
		if(searchTerm != "", {
			patterns = patterns.select({ |p|
				p.name.asString.toLower.contains(searchTerm.toLower) or: {
					p.description.toLower.contains(searchTerm.toLower)
				};
			});
		});

		// Sort by name
		patterns = patterns.asArray.sort({ |a, b| a.name.asString < b.name.asString });

		// Create display names
		displayNames = patterns.collect({ |p|
			var typeIcon = if(p.type == \pitch, { "♪" }, { "◉" });
			"% %".format(typeIcon, p.name.asString.replace("yoshimura", "Y:").replace("eno", "E:"));
		});

		self.patternList.items = displayNames;

		// Store for lookup
		self[\patternNames] = patterns.collect(_.name);
	},

	// Get pattern name from list index
	getPatternNameFromIndex: { arg self, index;
		if(self[\patternNames].notNil and: { index < self[\patternNames].size }, {
			self[\patternNames][index];
		}, {
			nil;
		});
	},

	// Select a pattern and update preview
	selectPattern: { arg self, patternName;
		var pattern = ~patternLibrary.get(patternName);

		if(pattern.isNil, {
			"Pattern not found: %".format(patternName).warn;
			^self;
		});

		self.currentPattern = pattern;

		// Update description
		{
			self.descriptionText.string = pattern.description;
		}.defer;

		// Update waveform preview
		{
			self.previewView.refresh;
		}.defer;
	},

	// Draw waveform preview
	drawWaveform: { arg self, view;
		var pattern, width, height, step, pen;
		var patternData;

		if(self.currentPattern.isNil, { ^self });

		// Generate pattern
		patternData = self.currentPattern.generator.value;

		width = view.bounds.width;
		height = view.bounds.height;
		step = width / 64;

		pen = Pen;

		// Draw grid
		pen.color = Color.gray(0.25);
		pen.width = 1;

		// Horizontal center line
		pen.line(0 @ (height/2), width @ (height/2));
		pen.stroke;

		// Vertical grid lines (every 16 steps)
		4.do({ |i|
			var x = i * 16 * step;
			pen.line(x @ 0, x @ height);
		});
		pen.stroke;

		// Draw waveform
		pen.color = Color(0.4, 0.7, 0.9);  // Blue
		pen.width = 2;

		patternData.do({ |val, i|
			var x = i * step;
			var normalizedVal = val.linlin(-24, 24, height, 0);  // Assume ±24 semitone range
			var y = normalizedVal.clip(0, height);

			if(i == 0, {
				pen.moveTo(x @ y);
			}, {
				pen.lineTo(x @ y);
			});
		});
		pen.stroke;

		// Draw step indicators
		pen.color = Color(0.5, 0.8, 1.0, 0.5);
		pen.width = 1;

		patternData.do({ |val, i|
			var x = i * step;
			var normalizedVal = val.linlin(-24, 24, height, 0);
			var y = normalizedVal.clip(0, height);

			pen.addOval(Rect(x - 2, y - 2, 4, 4));
		});
		pen.fill;

		// Draw value range labels
		pen.color = Color.gray(0.5);
		pen.font = Font("Monaco", 9);
		pen.stringAtPoint("+24", 5 @ 5);
		pen.stringAtPoint("0", 5 @ (height/2 - 10));
		pen.stringAtPoint("-24", 5 @ (height - 20));
	},

	// Load pattern to track
	loadToTrack: { arg self, trackNum;
		var pattern, patternData, paramName, jitterName;

		if(self.currentPattern.isNil, {
			"No pattern selected".warn;
			^self;
		});

		if(~trackManager.isNil, {
			"Track manager not available".warn;
			^self;
		});

		pattern = self.currentPattern;
		patternData = pattern.generator.value;

		// Determine parameter names based on type
		paramName = if(pattern.type == \pitch, { \pitchSeq }, { \posSeq });
		jitterName = if(pattern.type == \pitch, { \pitchJitter }, { \posJitter });

		// Apply to track
		~trackManager.setParam(trackNum, paramName, patternData);
		~trackManager.setParam(trackNum, jitterName, 1);  // Enable jitter

		"✓ Loaded '%' to Track % (% sequence)".format(
			pattern.name,
			trackNum + 1,
			pattern.type
		).postln;
	},

	// Disable sequences for a track
	disableSequences: { arg self, trackNum;
		if(~trackManager.isNil, {
			"Track manager not available".warn;
			^self;
		});

		// Turn off both pitch and position jitter
		~trackManager.setParam(trackNum, \posJitter, 0);
		~trackManager.setParam(trackNum, \pitchJitter, 0);

		"✓ Sequences disabled on Track %".format(trackNum + 1).postln;
		"  Back to static grain position and pitch".postln;
	},

	// Show code window
	showCode: { arg self;
		var codeWin, codeView, code;

		if(self.currentPattern.isNil, {
			"No pattern selected".warn;
			^self;
		});

		// Generate example code
		code = "// Pattern: %\n".format(self.currentPattern.name)
		++ "// Category: %\n".format(self.currentPattern.category)
		++ "// Type: %\n".format(self.currentPattern.type)
		++ "// Description: %\n\n".format(self.currentPattern.description)
		++ "// Generator function:\n"
		++ "(\n"
		++ "var pattern = %;\n\n".format(self.currentPattern.generator.asCompileString)
		++ "// Apply to Track 1:\n"
		++ "~trackManager.setParam(0, \\%, pattern);\n".format(
			if(self.currentPattern.type == \pitch, { "pitchSeq" }, { "posSeq" })
		)
		++ "~trackManager.setParam(0, \\%, 1);  // Enable jitter\n".format(
			if(self.currentPattern.type == \pitch, { "pitchJitter" }, { "posJitter" })
		)
		++ ")";

		codeWin = Window("Pattern Code - %".format(self.currentPattern.name), Rect(300, 200, 700, 500))
			.background_(Color.gray(0.15))
			.alwaysOnTop_(true);

		codeView = TextView(codeWin, Rect(10, 10, 680, 480))
			.background_(Color.gray(0.2))
			.stringColor_(Color.gray(0.9))
			.font_(Font("Monaco", 11))
			.string_(code)
			.editable_(true)
			.syntaxColorize;

		codeWin.front;
	}
);

"✓ Pattern browser loaded".postln;
"  Open with: ~patternBrowser.open".postln;

/*
Usage:

// Open pattern browser
~patternBrowser.open;

// The browser window allows you to:
// 1. Filter by category (All, Yoshimura, Eno, etc.)
// 2. Search by keyword
// 3. Preview waveform
// 4. Load to any track
// 5. Clear/disable sequences on any track
// 6. View generator code (educational)
*/
