class RangedAggressorPistol extends RangedAggressor
	abstract
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

function AddInitialKeywords()
{
	super(Aggressor).AddInitialKeywords();
	AddLocomotionKeyword('RangedAggressorPistol', Class'ShockAI.ShockAI'.0);
	GetRagdoll().AddRequiredRiseFromRagdollKeyword('RangedAggressorPistol');
	return;
	@NULL
	CommanderAction
}

function CharacterAICreated()
{
	super(Aggressor).CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.RangedAggressorPistolAttackAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}
