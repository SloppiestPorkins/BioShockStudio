class PatrolPoint extends PathNode
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced,Lighting,LightColor,Force);

struct native atomic EditorPatrolPreviewAnimSet
{
	var name AnimName;
	var SkeletalMesh SkeletalMesh;

	structdefaultproperties
	{
		CheckpointTypePadding=1850700389
	}
};

var private const transient bool HaveBuiltEditorPreviewPatrolAnimSets;
var private const transient int CurrentPreviewPatrolAnimSetIndex;
var private const transient float CurrentPreviewPatrolAnimLastUpdateTime;
var private const transient float CurrentPreviewPatrolAnimFirstUpdateTime;
var const transient array<EditorPatrolPreviewAnimSet> EditorPreviewPatrolAnimSets;

defaultproperties
{
	Texture=Texture'ShockAI.Bioshock_Editor_Textures.S_PatrolPoint'
	bDirectional=true
}