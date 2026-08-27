class ActionSetEffectsSystemContext extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

enum ValidContextTargets
{
	CT_Player,                      // 0
	CT_PlayerHands,                 // 1
	CT_All,                         // 2
	CT_PlayerHead                   // 3
};

var travel name Context;
var travel ActionSetEffectsSystemContext.ValidContextTargets ContextAppliesTo;
var travel bool RemoveInsteadOfAdd;
var travel bool LogTriggerInfo;

function Variable execute()
{
	local IGEffectsSystemBase EffectsSystem;
	local Pawn PlayerPawn;
	local Hands PlayerHands;
	local Head PlayerHead;
	local string LogMessage;

	super.execute();
	AssertWithDescription(__NFUN_255__(Context, default.Context), __NFUN_112__(__NFUN_112__(__NFUN_112__("Designer forgot to change the default value for the Context field in ", string(Name)), " in script "), string(parentScript.Name)));
	EffectsSystem = parentScript.Level.EffectsSystem;
	// End:0x174
	if(__NFUN_154__(int(ContextAppliesTo), int(0)))
	{
		PlayerPawn = parentScript.Level.GetLocalPlayerController().Pawn;
		// End:0x151
		if(RemoveInsteadOfAdd)
		{
			PlayerPawn.RemovePersistentEffectsSystemContext(Context);
			goto J0x171;
			PlayerPawn.AddPersistentEffectsSystemContext(Context);
			goto J0x370;
			// End:0x240
			if(__NFUN_154__(int(ContextAppliesTo), int(1)))
			{
				PlayerPawn = parentScript.Level.GetLocalPlayerController().Pawn;
			}
			PlayerHands = ShockPlayer(PlayerPawn).GetHands();
			J0x171:

			// End:0x21D
			if(RemoveInsteadOfAdd)
			{
			}
			else
			{
				PlayerHands.RemovePersistentEffectsSystemContext(Context);
				goto J0x23D;
				PlayerHands.AddPersistentEffectsSystemContext(Context);
				goto J0x370;
				// End:0x2A7
				if(__NFUN_154__(int(ContextAppliesTo), int(2)))
				{
					// End:0x284
					if(RemoveInsteadOfAdd)
					{
						EffectsSystem.RemovePersistentContext(Context);
						goto J0x2A4;
						EffectsSystem.AddPersistentContext(Context);
						goto J0x370;
						/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
							
						*/

						// End:0x370
						/*@Error*/
						PlayerPawn = parentScript.Level.GetLocalPlayerController().Pawn;
					}/* !MISMATCHING REMOVE, tried Else got Type:If Position:0x1C0! */
				}
				PlayerHead = ShockPlayer(PlayerPawn).GetHead();
			}/* !MISMATCHING REMOVE, tried If got Type:Else Position:0x174! */
			// End:0x350
			if(RemoveInsteadOfAdd)
			{
				PlayerHead.RemovePersistentEffectsSystemContext(Context);
				goto J0x370;
				PlayerHead.AddPersistentEffectsSystemContext(Context);
			}
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x466
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x3F2
			/*@Error*/
			LogMessage = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Removed Effects Context '", string(Context)), "' from '"), string(GetEnum(Enum'ShockGame.ActionSetEffectsSystemContext.ValidContextTargets', int(ContextAppliesTo)))), "'");
		}
		goto J0x453;
		LogMessage = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Added Effects Context '", string(Context)), "' to '"), string(GetEnum(Enum'ShockGame.ActionSetEffectsSystemContext.ValidContextTargets', int(ContextAppliesTo)))), "'");
		SLog(LogMessage);
	}
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x5F
	if(RemoveInsteadOfAdd)
	{
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Remove Effects Context '", string(Context)), "' from '"), string(ContextAppliesTo)), "'");
		goto J0xA9;
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Add Effects Context '", string(Context)), "' to '"), string(ContextAppliesTo)), "'");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	Context="ONE_WORD_THAT_DESCRIBES_THE_NEW_CONTEXT"
	actionDisplayName="Add/Remove an Effects System Context"
	actionHelp="Adds or removes a Context that will be present when future effect events are triggered"
	Category="AudioVisual"
	bIsGameCritical=false
}