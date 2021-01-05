--version 0.91
--made by Katboi01

try (destroyDialog KF3Importer ) catch ()
rollout KF3Importer "Kemono Friends 3 Import Tool" width:162 height:404
(
	-- User Interface
	button btn_selfolder "Select Import Folder"	
	label lbl_path "Folder Path:" 
	editText edt_path text:"R:\Assets\com.sega.KemonoFriends3\Charas" --put your path here
	label lbl_id "Friend ID:"
	editText edt_ID text:"0004" --defaults to Arai
	label lbl_cos "Costume"
	editText edt_cos text:"a" --default costume
	button btn_import "import models"
	button btn_resize "resize dummies"
	button btn_IK "Apply IK" 
	button btn_help "visual guide"
	
	--variables
	local filePath
	
	on btn_help pressed do
	(
	ShellLaunch "https://drive.google.com/open?id=1oiYm8bS8PI7wULClNG0YtAsoe2XmmIyV" ""
	)
	
	on btn_selfolder pressed do
	(
	filePath = getSavepath initialDir:(GetDir #maxroot)
	edt_path.text = filePath
	)
	on btn_import pressed do
	(
		aImportOrder = #("hair", "ear", "tail")
		charaName = "ch_" + edt_ID.text + "_" 
		defaultName = charaName + "a"
		cosName = charaName + edt_cos.text

		-- import ch_xxxx_yy.fbx
		tempPath = edt_path.text + "\\" + cosName
		FBXImporterSetParam "Mode" #create
		importfile (tempPath + "\\" + cosName + ".fbx") #noPrompt using:FBXIMP

		partName = charaName + "a_" + aImportOrder[2]
		tempPath = edt_path.text + "\\" + partName + "\\" + partName + ".fbx"

		-- check for /ch_xxxx_a_ear/ folder
		-- edit: KF3 stopped using separate ear/tail models for alt costumes
		if (doesFileExist tempPath) do
		(
			--import ear
			importfile (tempPath) #noPrompt using:FBXIMP
			tempModel = execute("$" + partName + "/" + "model")
			tempBone = execute("$" + partName + "/.../" + "j_ear_root")
			tempModel.name = "ears"
			-- has to be rotated before being linked or it won't work (?)
			in coordsys local tempModel.rotation = eulerangles 0 0 -90
			in coordsys local tempBone.rotation = eulerangles 0 0 -90
			tempBone.pos = $j_head.pos
			tempBone.parent = $j_head
			tempModel.pos = $j_head.pos
			tempModel.parent = $model
			-- remove empty leftover root bone
			delete (execute("$" + partName + "/...*"))
		)

		partName = charaName + "a_" + aImportOrder[3]
		tempPath = edt_path.text + "\\" + partName + "\\" + partName + ".fbx"
		-- check for /ch_xxxx_y_tail/ folder
		if (doesFileExist tempPath) do
		(
			importfile (tempPath) #noPrompt using:FBXIMP
			tempModel = execute("$" + partName + "/" + "model")
			tempBone = execute("$" + partName + "/.../" + "j_tail_root")
			tempModel.name = "tail"
			tempBone.pos = $j_lowerbody.pos
			tempBone.parent = $j_lowerbody
			tempModel.pos = $j_lowerbody.pos
			tempModel.parent = $model
			-- remove empty leftover root bone
			delete (execute("$" + partName + "/...*"))
		)

		--importing done, cleanup time
		--step 1: resize
		partName = charaName + "a"
		friend = $ch_*
		friend.scale = [1, 1, 1]
		--applies 100x scale to selection only (will make it easier to import multiple characters, maybe one day)
		select (execute("$" + "ch_" + edt_ID.text + "_" + edt_cos.text + "/...*"))
		rescaleWorldUnits 100 #selOnly
		resetXForm $md_eye_r
		resetXForm $md_eye_l	
		
		--step 1.5: edit poly
		--for o in geometry where classof o == Editable_mesh do (
		--addmodifier o (Poly_Select()) before:1
		--maxOps.CollapseNodeTo o 2 on
		--)		
		--step 2: fix normals (non destructive)		
		tempObjects = #($md_face, $md_mouth_base, $md_eye_base)
		addmodifier tempObjects (Edit_Normals())
		select tempObjects
		$md_eye_base.modifiers[#Edit_Normals].EditNormalsMod.Reset selection:#{1..4000} node:$md_face
		select tempObjects
		$md_eye_base.modifiers[#Edit_Normals].EditNormalsMod.SetSelection #{1..4000} node:$md_face
		$md_eye_base.modifiers[#Edit_Normals].EditNormalsMod.SetSelection #{1..4000} node:$md_mouth_base
		$md_eye_base.modifiers[#Edit_Normals].EditNormalsMod.SetSelection #{1..4000} node:$md_eye_base
		$md_eye_base.modifiers[#Edit_Normals].EditNormalsMod.Average useThresh:on Threshold:0.001 node:$md_face
		$md_eye_base.modifiers[#Edit_Normals].EditNormalsMod.Average useThresh:on Threshold:0.001 node:$md_mouth_base
		$md_eye_base.modifiers[#Edit_Normals].EditNormalsMod.Average useThresh:on Threshold:0.001 node:$md_eye_base
		$md_eye_base.modifiers[#Edit_Normals].EditNormalsMod.AverageGlobal useThresh:on Threshold:0.001
		select tempObjects
		--step 3: hide stuff
		tempObjects = #($md_eye_special_a, $md_eye_special_b)
		hide tempObjects
		--step 4: materials
		aNames = #()
		aMats = #()
		aNames[1] = charaName + edt_cos.text + "_body_mat"
		aNames[2] = defaultName + "_face_mat"
		aNames[3] = defaultName + "_ear_tail_mat"
		aNames[4] = defaultName + "_eye_mat"
		aNames[5] = "cheek_mat"
		aNames[6] = defaultName + "_hair_mat"

		for i = 1 to aNames.count do
		(
			tempMaterial = Standardmaterial()
			tempMaterial.name = aNames[i]
			tempMaterial.specularLevel = 0
			showTextureMap tempMaterial on
			aMats[i] = tempMaterial
		)
		aMats[6] = Standard name:"Default Material"

		aMeshes = $model/...*
		for tempMesh in aMeshes do
		(
			tempMaterial = tempMesh.mat
			case of
			(
				(tempMaterial.name == aNames[1]):
				(
					tempMaterial = aMats[1]
					if (edt_cos.text == "a") then fileTemp = edt_path.text + "\\" + cosName + "\\" + cosName + "_body.png" 
					else if (edt_cos.text =="b") then fileTemp = edt_path.text + "\\" + charaName + edt_cos.text + "\\" + charaName + edt_cos.text + "_body.png"
					else fileTemp = edt_path.text + "\\" + charaName + edt_cos.text + "\\" + "ch_0000_" + edt_cos.text + "_body.png"
					tempTexture = bitmaptexture filename:fileTemp
					tempMaterial.diffusemap = tempTexture
				)
				(tempMaterial.name == aNames[2]):
				(
					tempMaterial = aMats[2]
					filePath = edt_path.text + "\\" + defaultName + "\\" + defaultName + "_face.png"
					tempTexture = bitmaptexture filename:filePath
					tempMaterial.diffusemap = tempTexture
				)
				(tempMaterial.name == aNames[3]):
				(
					tempMaterial = aMats[3]
					filePath = edt_path.text + "\\" + defaultName + "_tail\\" + "ch_" + edt_ID.text + "_a_ear_tail.png"
					tempTexture = bitmaptexture filename:filePath
					tempMaterial.diffusemap = tempTexture
				)
				(tempMaterial.name == aNames[5]):
				(						
					tempMaterial = aMats[5]
					filePath = edt_path.text + "\\" + defaultName + "\\" + "cheek.png"
					if (doesfileexist filePath) then ()
					else filePath = edt_path.text + "\\" + defaultName + "\\" + "cheek2.png"
					if (doesfileexist filePath) then ()
					else filePath = edt_path.text + "\\" + defaultName + "\\" + "cheek3.png"
					if (doesfileexist filePath) then ()
					else filePath = edt_path.text + "\\" + defaultName + "\\" + "cheek4.png"
					if (doesfileexist filePath) then ()
					else filePath = edt_path.text + "\\" + defaultName + "\\" + "cheek5.png"
					tempTexture = bitmaptexture filename:filePath
					tempTexture.monoOutput = 1
					tempTexture.preMultAlpha = false
					tempMaterial.diffusemap = tempTexture
					tempMaterial.opacityMap = tempTexture
				)
				(tempMaterial.name == aNames[6]):
				(
					tempMaterial = aMats[6]
					filePath = edt_path.text + "\\" + cosName + "\\" + cosName + "_head.png"
					if (doesfileexist filePath) then ()
					filePath = edt_path.text + "\\" + defaultName + "\\" + defaultName + "_head.png"
					tempTexture = bitmaptexture filename:filePath
					tempTexture.alphasource = 2
					tempMaterial.diffusemap = tempTexture
				)
				default:
				(
					print (tempMaterial.name + " is not " + aNames[3])
					showTextureMap tempMaterial on
				)
			)
			tempMesh.mat = tempMaterial
		)

		
		tempMaterial = aMats[4]
		filePath = edt_path.text + "\\" + defaultName + "\\" + defaultName + "_head.png"
		tempTexture = bitmaptexture filename:filePath
		tempTexture.alphasource = 2 --sets to opaque so eyes don't glow
		tempMaterial.diffusemap = tempTexture
		$md_eye_l.mat = tempMaterial
		$md_eye_r.mat = tempMaterial	


		--final step
		tempObjects = #($md_face, $md_mouth_base, $md_eye_base)
		select tempObjects
		messageBox "3ds max can't move modifiers via script, drag and drop the edit_normals modifier of selected meshes under the skin modifier.
		Press z once to reset view." title:"we're almost done"
		
	)
	on btn_resize pressed do
	(
		select $root/...*
		deselect $md_eye_r
		deselect $md_eye_l
		for o in selection do 
		(
			o.boxsize = [ 10, 10, 10]
			o.showLinks = true
			o.showLinksOnly = false
		)
		
	)
	on btn_IK pressed do
	(
	-- defining le' bone chains
	ikStart = #("j_arm_r", "j_arm_l","j_thigh_r","j_foot_r","j_thigh_l","j_foot_l")
	ikMid = #("j_forearm_r","j_forearm_l","j_leg_r","false","j_leg_l","false")
	ikEnd = #("j_wrist_r", "j_wrist_l","j_foot_r","j_toe_r","j_foot_l","j_toe_l")
	ikName = #("IK_Arm_R","IK_Arm_L","IK_Leg_R","IK_Foot_R","IK_Leg_L","IK_Foot_L")
	
	--iterating through the bone chains
	for loop = 1 to ikStart.count do
	(	
		bone1 = execute ("$" + ikStart[loop])
		bone2 = execute ("$" + ikEnd[loop])
	
		ik1 = iksys.ikchain bone1 bone2 "IKHiSolver"
		ik1.name = ikName[loop]
		ik1.controller.posThresh = 0
		ik1.controller.rotThresh = 0
		ik1.controller.swivelAngle = 0
		ik1.controller.goalSize = 30
			
		if ikMid[loop] != "false" then (
			elbow = execute ("$" + ikMid[loop])
			elbow.controller.RotXActive = false
			elbow.controller.RotYActive = false
			elbow.controller.PrefZAngle = -90
			ik1.parent = $root
		)
		else (
			ik1.parent = execute ("$" + ikName[loop-1])
		)
	)
	)
)
createDialog KF3Importer