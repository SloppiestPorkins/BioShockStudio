class AnimNotify_PhotoScore extends AnimNotify
	native
	config(ResearchCamera)
	editinlinenew
	collapsecategories
	hidecategories(Object);

var config array<PhotoScoreGradeMapping> AnimationGradeToScoreMapping;
var private ShockPlayer.EPhotoGrade Grade;

function int GetScoreFromGrade(ShockPlayer.EPhotoGrade Grade)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8C
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7E
	/*@Error*/
	return AnimationGradeToScoreMapping[i].Score;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return 0;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

defaultproperties
{
	AnimationGradeToScoreMapping[0]=(Grade=0,Score=0)
	AnimationGradeToScoreMapping[1]=(Grade=1,Score=0)
	AnimationGradeToScoreMapping[2]=(Grade=2,Score=0)
	AnimationGradeToScoreMapping[3]=(Grade=3,Score=0)
	AnimationGradeToScoreMapping[4]=(Grade=4,Score=20)
	Grade=1
}