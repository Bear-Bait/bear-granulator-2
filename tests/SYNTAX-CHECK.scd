/*
SYNTAX VALIDATION SCRIPT
Checks all modified files for common syntax errors
Run this before committing to git
*/

(
var files, errors, warnings;

files = [
	"main.scd",
	"core/grain-engine.scd",
	"core/mix-bus.scd",
	"core/track-manager.scd",
	"gui/viewfinder.scd",
	"gui/four-track-view.scd"
];

errors = 0;
warnings = 0;

"=== SYNTAX VALIDATION ===".postln;
"".postln;

files.do({ arg file;
	var path = thisProcess.nowExecutingPath.dirname +/+ file;
	var contents, lines;

	("Checking: " ++ file).postln;

	if(File.exists(path), {
		contents = File.readAllString(path);
		lines = contents.split($\n);

		// Check 1: Balanced braces
		{
			var openCount = contents.occurrencesOf(${);
			var closeCount = contents.occurrencesOf($});

			if(openCount != closeCount, {
				("  ERROR: Unbalanced braces! { = %, } = %".format(openCount, closeCount)).error;
				errors = errors + 1;
			}, {
				("  ✓ Braces balanced: " ++ openCount).postln;
			});
		}.value;

		// Check 2: Balanced parentheses
		{
			var openCount = contents.occurrencesOf($();
			var closeCount = contents.occurrencesOf($));

			if(openCount != closeCount, {
				("  ERROR: Unbalanced parentheses! ( = %, ) = %".format(openCount, closeCount)).error;
				errors = errors + 1;
			}, {
				("  ✓ Parentheses balanced: " ++ openCount).postln;
			});
		}.value;

		// Check 3: Balanced square brackets
		{
			var openCount = contents.occurrencesOf($[);
			var closeCount = contents.occurrencesOf($]);

			if(openCount != closeCount, {
				("  WARNING: Unbalanced brackets! [ = %, ] = %".format(openCount, closeCount)).warn;
				warnings = warnings + 1;
			}, {
				("  ✓ Brackets balanced: " ++ openCount).postln;
			});
		}.value;

		// Check 4: Common syntax errors
		{
			var issues = [];

			lines.do({ arg line, idx;
				// Check for missing semicolons (basic check)
				if(line.contains("var ") and: { line.endsWith(";").not } and: { line.contains("//").not }, {
					if(line.contains("=").not, {
						issues = issues.add("Line %: var declaration may need semicolon".format(idx + 1));
					});
				});

				// Check for unmatched quotes
				if((line.occurrencesOf($") % 2) != 0, {
					issues = issues.add("Line %: Unmatched double quotes".format(idx + 1));
				});
			});

			if(issues.size > 0, {
				"  WARNINGS:".warn;
				issues.do({ arg issue;
					("    " ++ issue).warn;
				});
				warnings = warnings + issues.size;
			});
		}.value;

	}, {
		("  ERROR: File not found: " ++ path).error;
		errors = errors + 1;
	});

	"".postln;
});

"=== VALIDATION COMPLETE ===".postln;
if(errors == 0 and: { warnings == 0 }, {
	"✅ All files passed!".postln;
}, {
	if(errors > 0, {
		("❌ Found % error(s)".format(errors)).error;
	});
	if(warnings > 0, {
		("⚠️  Found % warning(s)".format(warnings)).warn;
	});
});
"".postln;

// Return summary
(errors: errors, warnings: warnings);
)
