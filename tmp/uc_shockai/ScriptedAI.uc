class ScriptedAI extends ShockAI
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

function AddCommanderAbility()
{
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.ScriptedAICommanderAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function MovementAICreated()
{
	super.MovementAICreated();
	MovementAI.addAbility_Class(Class'ShockAI.MoveToAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.CharacterMoveToAction');
	CharacterAI.addAbility_Class(Class'ShockAI.HeadTrackingAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function int GetDesiredAnimationCapabilities()
{
	return __NFUN_158__(__NFUN_158__(super.GetDesiredAnimationCapabilities(), 64), 16);
	return;
	@NULL
}

defaultproperties
{
	bShouldUseLocomotion=true
	DeadFadeRadius=0.0000000
	ShadowMapScale=2.0000000
	bRotateToDesired=false
}