class ActionAttackTarget extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel name TargetLabel;
var travel bool bAttackOnSight;

function Variable execute()
{
	local int i;
	local ShockAI IterAI;
	local array<ShockAI> AIs;
	local ShockPawn Iter, Target;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3F7
	/*@Error*/
	// End:0xAD
	if(__NFUN_129__(bAttackOnSight))
	{
		// End:0xAC
		foreach parentScript.Level.dynamicActorLabel(Class'ShockGame.ShockPawn', Iter, TargetLabel)
		{
			// End:0xAB
			if(Class'Engine.Pawn'.static.checkAlive(Iter))
			{
				Target = Iter;
				// End:0xAC
				break;								
				// End:0x340
				if(__NFUN_132__(bAttackOnSight, __NFUN_119__(Target, none)))
				{
					// End:0x2B7
					if(__NFUN_255__(AILabel, 'None'))
					{
						// End:0x166
						foreach parentScript.Level.dynamicActorLabel(Class'ShockAI.ShockAI', IterAI, AILabel)
						{
						}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x09E! */
					}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x08B! */
				}
				// End:0x165
				if(Class'Engine.Pawn'.static.checkAlive(IterAI))
				{
					AIs[AIs.Length] = IterAI;										
					// End:0x20F
					if(__NFUN_151__(AIs.Length, 0))
					{
						i = 0;
						// End:0x20C
						if(__NFUN_150__(i, AIs.Length))
						{
							// End:0x1D4
							if(bAttackOnSight)
							{
								AIs[i].AddTargetToAttackOnSight(TargetLabel);
								goto J0x1FE;
								AIs[i].ScriptedAttackTarget(Target);
								__NFUN_163__(i);
							}
							goto J0x182;
						}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x106! */
						goto J0x2B4;
						log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " in script: "), string(parentScript.Name)), " - Could not find any AIs with label "), string(AILabel)), " to attack: "), string(Target.Name)));
					}
					goto J0x33D;
					log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " in script: "), string(parentScript.Name)), " - No AILabel specified to attack: "), string(Target.Name)));
				}
			}
			goto J0x3F4;
			log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " in script: "), string(parentScript.Name)), " - Could not find any target with label: "), string(TargetLabel)), " for AIs with label: "), string(AILabel)), " to attack!"));
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x024! */
		goto J0x47C;
		log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " in script: "), string(parentScript.Name)), " - No TargetLabel specified for "), string(AILabel)), " to attack."));
	}
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("AIs with label ", string(AILabel)), " will attack target with label "), string(TargetLabel));
	// End:0x92
	if(bAttackOnSight)
	{
		S = __NFUN_112__(S, " when they see them");
		goto J0xB4;
		S = __NFUN_112__(S, " right away");
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="AIs Attack Target"
	actionHelp="Tell an AI or group of AIs to attack a particular target"
	Category="AI"
}