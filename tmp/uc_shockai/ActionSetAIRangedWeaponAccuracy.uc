class ActionSetAIRangedWeaponAccuracy extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name RangedWeaponLabel;
var travel Range AccuracyRangeVsPlayer;
var travel Range AccuracyChangeTimeRangeVsPlayer;
var travel Range AccuracyRangeVsAI;
var travel Range AccuracyChangeTimeRangeVsAI;

function Variable execute()
{
	local AIRangedWeapon RangedWeapon;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x93
	/*@Error*/
	// End:0x92
	foreach parentScript.dynamicActorLabel(Class'ShockAI.AIRangedWeapon', RangedWeapon, RangedWeaponLabel)
	{
		RangedWeapon.ScriptedSetAccuracyValues(AccuracyRangeVsPlayer, AccuracyChangeTimeRangeVsPlayer, AccuracyRangeVsAI, AccuracyChangeTimeRangeVsAI);				
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

defaultproperties
{
	actionDisplayName="Change the accuracy on an AI's ranged weapon"
	actionHelp="Change the accuracy on an AI's ranged weapon"
	Category="AI"
}