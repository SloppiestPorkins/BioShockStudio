class AggressorSpawner extends EcologyFighterSpawner
	native
	config(Spawning)
	placeable
	hidecategories(DrawScale3D,DisplayAdvanced,Advanced,Collision,Display,Force,Havok,LightColor,Lighting,Sound);

var name GlobalPatrol;
var name InitialPatrol;
var name RepopulationPatrol;
var bool GlobalSpawnStartOutAsMimic;
var bool InitialSpawnStartOutAsMimic;
var bool RepopulationSpawnStartOutAsMimic;
var PoseData SpawnedMimicInitialPose;

function OutputTypesToBox(LevelInfo Level, out array< Class<ShockAI> > S)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x5B
	/*@Error*/
	SpawningManager(Level.SpawningManager).DisplayAggressorTypes(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OutputPatrolsToBox(LevelInfo Level, out array<name> S)
{
	Class'ShockAI.SpawningManager'.static.OutputPatrolsToBox(Level, S);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function enumAnimationsForType(Class<Aggressor> AggressorType, LevelInfo Level, out array<name> S)
{
	local int i;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x82
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x82
	/*@Error*/
	S[S.Length] = AggressorType.default.MimicPoseAnimations[i];
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1A;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function enumAnimations(LevelInfo Level, out array<name> S)
{
	local int i;

	// End:0x8B
	if(__NFUN_130__(GlobalSpawnStartOutAsMimic, __NFUN_151__(GlobalAITypes.Length, 0)))
	{
		i = 0;
		// End:0x88
		if(__NFUN_150__(i, GlobalAITypes.Length))
		{
			enumAnimationsForType(Class<Aggressor>(GlobalAITypes[i]), Level, S);
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x2A;
			goto J0x19E;
			// End:0x116
			if(__NFUN_130__(InitialSpawnStartOutAsMimic, __NFUN_151__(InitialAITypes.Length, 0)))
			{
				i = 0;
				// End:0x113
				if(__NFUN_150__(i, InitialAITypes.Length))
				{
				}
			}
			enumAnimationsForType(Class<Aggressor>(InitialAITypes[i]), Level, S);
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0xB5;
			goto J0x19E;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x19E
			/*@Error*/
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x19E
			/*@Error*/
			enumAnimationsForType(Class<Aggressor>(RepopulationAITypes[i]), Level, S);
			__NFUN_163__(i);
		}
	}
	goto J0x140;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	Texture=Texture'ShockAI.Bioshock_Editor_Textures.S_Spawner_Aggressor'
}