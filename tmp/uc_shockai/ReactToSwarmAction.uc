class ReactToSwarmAction extends BioshockCharacterAction
	collapsecategories
	hidecategories(Object,InternalParameters);

state Running
{Begin:

	useResources(Class'VengeanceShared.AI_Resource'.4);
	__NFUN_256__(ShockAI(m_Pawn).GetSwarmReactionBehaviorTime());
	succeed();
	stop;	
	@NULL
	@NULL
	@NULL
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.ReactToSwarmGoal'
	bExclusiveAction=true
}