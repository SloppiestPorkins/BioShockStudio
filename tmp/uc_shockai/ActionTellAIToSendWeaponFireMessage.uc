class ActionTellAIToSendWeaponFireMessage extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel name WeaponLabel;
var travel Class<AIWeapon> weaponClass;

function Variable execute()
{
	local ShockAI Target;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA4
	/*@Error*/
	// End:0xA3
	foreach parentScript.dynamicActorLabel(Class'ShockAI.ShockAI', Target, AILabel)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xA2
		/*@Error*/
		Target.SetWeaponFireMessage(WeaponLabel, weaponClass);				
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function editorDisplayString(out string S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x12C
	/*@Error*/
	S = __NFUN_112__(__NFUN_112__("AI with label ", string(AILabel)), " will send a message when firing");
	// End:0xB5
	if(__NFUN_255__(WeaponLabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__(S, " a weapon with label "), string(WeaponLabel));
		goto J0x129;
		// End:0xFE
		if(__NFUN_119__(weaponClass, none))
		{
			S = __NFUN_112__(__NFUN_112__(S, " a weapon of class "), string(weaponClass));
		}
		goto J0x129;
		S = __NFUN_112__(S, " any of its weapons.");
		goto J0x148;
		S = "AILabel not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Tell AI to send weapon fire message"
	actionHelp="Tell AI to send weapon fire message"
	Category="AI"
}