class BioAmmoAdvisor extends DifficultyAdvisor
	config(Difficulty);

function int AssessInternal(ShockPlayer Player, out int BaseEase)
{
	local array<DifficultyStat> CheckedStats;

	CheckedStats[0] = DifficultyManager.DifficultyStatsManager.TotalBioAmmoStats;
	return DifficultyEvaluator.Evaluate(CheckedStats, DifficultyManager, BaseEase);
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

defaultproperties
{
	AdjustmentRecommendations[0]=(AdjustmentClass=Class'ShockGame.SpawnBioAmmoAdjustment',ProbabilityTableName="BioAmmoProbabilityTable",Count=10,Priority=5,Weight=-1.0000000)
	AdjustmentRecommendations[1]=(AdjustmentClass=Class'ShockGame.RemoveBioAmmoAdjustment',ProbabilityTableName="DefaultProbabilityTable",Count=0,Priority=4,Weight=1.0000000)
	DifficultyEvaluatorClass=Class'ShockGame.EaseTableEvaluator'
	DifficultyEvaluatorName="BioAmmoEaseTableEvaluator"
	CreditsNeededToBeConsideredRich=100
	AdvisorCategory="Bioammo"
}