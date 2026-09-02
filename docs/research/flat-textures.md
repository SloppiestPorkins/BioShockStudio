# Flat exported texture census

Status: **VERIFIED** for the exported PNG files currently present in the directory below. 
The `suspect` label identifies files requiring source/decode investigation; it does not by 
itself prove a particular decoder fault.

Export directory: `C:/Users/Jack/Documents/BioShockUE5/Exports/slice/1-Medical/Textures`

RGB flatness is per-channel standard deviation `< 3` after a 32x32 Lanczos downsample. 
Alpha carriers have sampled alpha standard deviation `> 5`. Legitimate named constants 
must also be at most 4,096 bytes. Flat normals require a normal-map name and 
sampled mean RGB within 20 of `(128, 128)` with blue at least 235. Remaining flat-RGB, 
flat-alpha images are suspects, including small files: compression size cannot establish 
that source art was intentionally uniform.

## Counts

| Class | Count |
|---|---:|
| legit-flat | 4 |
| alpha-carrier | 1 |
| flat-normal | 33 |
| suspect | 130 |
| non-flat | 964 |
| **Total PNGs** | **1132** |

## Suspects

| Texture | Size (bytes) | Dimensions | Mean RGB | Alpha range | Material bindings |
|---|---:|---:|---|---:|---|
| `alan_metal_diffuse.png` | 980,177 | 1024x1024 | (51.96, 53.51, 56.98) | 255..255 | alan_metal_mat (`Shader_alan_metal_mat_29359`) [diffuse] |
| `bio_sinklongnor.png` | 61,684 | 1024x1024 | (126.88, 126.86, 254.77) | 255..255 | bio_sinklong_shader (`Shader_bio_sinklong_shader_29052`) [normalMap] |
| `blood_smear_diffuse.png` | 117,775 | 1024x2048 | (34.61, 0.00, 0.00) | 255..255 | blood_smear_shader (`Shader_blood_smear_shader_31654`) [diffuse]<br>blood_smear_shader (`Shader_blood_smear_shader_31654`) [specular] |
| `blood_smear_nor.png` | 140,897 | 1024x2048 | (128.89, 126.02, 255.00) | 255..255 | blood_smear_shader (`Shader_blood_smear_shader_31654`) [normalMap] |
| `BloodSplat1.png` | 50,680 | 1024x1024 | (34.81, 0.00, 0.00) | 255..255 | bloodsplat1_shader (`Shader_bloodsplat1_shader_31489`) [diffuse]<br>bloodsplat1_shader (`Shader_bloodsplat1_shader_31489`) [specular] |
| `bloodsplat1nor.png` | 199,189 | 2048x2048 | (128.97, 126.01, 255.00) | 255..255 | bloodsplat1_shader (`Shader_bloodsplat1_shader_31489`) [normalMap] |
| `BloodSplat2.png` | 73,184 | 1024x1024 | (34.61, 0.00, 0.00) | 255..255 | bloodsplat2_shader (`Shader_bloodsplat2_shader_8401`) [diffuse]<br>bloodsplat2_shader (`Shader_bloodsplat2_shader_8401`) [specular] |
| `bloodsplat2nor.png` | 263,648 | 2048x2048 | (128.96, 126.01, 255.00) | 255..255 | bloodsplat2_shader (`Shader_bloodsplat2_shader_8401`) [normalMap] |
| `BloodSplat3.png` | 137,728 | 1024x1024 | (33.98, 0.00, 0.00) | 255..255 | bloodsplat3_shader (`Shader_bloodsplat3_shader_12769`) [diffuse]<br>bloodsplat3_shader (`Shader_bloodsplat3_shader_12769`) [specular] |
| `bloodsplat3nor.png` | 528,521 | 2048x2048 | (128.81, 127.91, 255.00) | 255..255 | bloodsplat3_shader (`Shader_bloodsplat3_shader_12769`) [normalMap] |
| `cord_diffuse.png` | 5,954 | 512x512 | (8.00, 16.00, 18.00) | 255..255 | cord_diffuse_shader (`Shader_cord_diffuse_shader_29516`) [diffuse] |
| `Cubemap100_Face_1.png` | 797 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap100_Face_2.png` | 904 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap100_Face_3.png` | 1,018 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap100_Face_4.png` | 804 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap100_Face_5.png` | 491 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap101_Face_0.png` | 2,563 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap101_Face_1.png` | 2,458 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap101_Face_2.png` | 2,663 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap101_Face_3.png` | 2,890 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap101_Face_4.png` | 2,680 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap101_Face_5.png` | 2,380 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap104_Face_1.png` | 2,883 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap104_Face_2.png` | 2,372 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap104_Face_4.png` | 2,019 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap104_Face_5.png` | 2,296 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap105_Face_0.png` | 3,365 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap105_Face_1.png` | 3,266 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap105_Face_4.png` | 1,945 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap105_Face_5.png` | 2,804 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap106_Face_0.png` | 3,769 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap106_Face_1.png` | 3,986 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap106_Face_3.png` | 3,595 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap106_Face_4.png` | 3,122 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap106_Face_5.png` | 4,281 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap107_Face_4.png` | 3,672 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap108_Face_5.png` | 3,885 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap109_Face_0.png` | 4,040 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap109_Face_1.png` | 4,370 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap109_Face_2.png` | 4,342 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap109_Face_3.png` | 3,999 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap109_Face_5.png` | 5,230 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap110_Face_0.png` | 3,895 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap110_Face_1.png` | 3,555 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap110_Face_4.png` | 2,788 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap110_Face_5.png` | 3,507 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap111_Face_0.png` | 2,473 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap111_Face_1.png` | 2,410 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap111_Face_2.png` | 3,079 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap111_Face_4.png` | 2,366 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap111_Face_5.png` | 2,781 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap112_Face_1.png` | 4,000 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap112_Face_3.png` | 3,884 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap112_Face_4.png` | 2,417 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap113_Face_0.png` | 3,038 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap113_Face_1.png` | 4,492 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap113_Face_2.png` | 3,692 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap113_Face_3.png` | 3,820 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap113_Face_4.png` | 3,997 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap113_Face_5.png` | 2,641 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap114_Face_0.png` | 4,235 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap114_Face_1.png` | 4,104 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap114_Face_2.png` | 4,444 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap115_Face_0.png` | 2,980 | 64x64 | (0.08, 0.08, 0.00) | 0..17 | Not found in manifest |
| `Cubemap115_Face_1.png` | 3,151 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap115_Face_2.png` | 3,341 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap115_Face_3.png` | 2,380 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap115_Face_5.png` | 2,598 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap116_Face_0.png` | 3,263 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap116_Face_2.png` | 3,495 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap116_Face_3.png` | 2,423 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap116_Face_4.png` | 2,430 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap116_Face_5.png` | 2,838 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap117_Face_2.png` | 3,447 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap117_Face_3.png` | 3,580 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap117_Face_4.png` | 2,234 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap117_Face_5.png` | 1,497 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap118_Face_0.png` | 3,795 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap118_Face_1.png` | 3,635 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap118_Face_4.png` | 3,245 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap118_Face_5.png` | 3,486 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap119_Face_0.png` | 3,260 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap119_Face_1.png` | 3,193 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap119_Face_5.png` | 1,984 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap120_Face_0.png` | 4,351 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap120_Face_1.png` | 4,313 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap120_Face_5.png` | 3,369 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap122_Face_0.png` | 3,440 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap122_Face_1.png` | 3,148 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap122_Face_2.png` | 3,262 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap122_Face_3.png` | 3,555 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap122_Face_4.png` | 2,570 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap122_Face_5.png` | 2,811 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap123_Face_2.png` | 3,815 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap123_Face_4.png` | 2,296 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap123_Face_5.png` | 3,190 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap124_Face_1.png` | 4,505 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap124_Face_5.png` | 4,778 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap125_Face_0.png` | 2,844 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap125_Face_1.png` | 2,961 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap125_Face_2.png` | 2,573 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap125_Face_3.png` | 2,682 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap125_Face_4.png` | 3,009 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap125_Face_5.png` | 1,484 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap126_Face_1.png` | 4,026 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap126_Face_2.png` | 3,299 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap126_Face_5.png` | 4,740 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap127_Face_2.png` | 3,599 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap97_Face_0.png` | 3,636 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap97_Face_1.png` | 3,959 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap97_Face_2.png` | 4,118 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap97_Face_3.png` | 3,342 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap97_Face_5.png` | 3,817 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap98_Face_0.png` | 4,160 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap98_Face_4.png` | 3,404 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap99_Face_3.png` | 3,538 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap99_Face_4.png` | 3,745 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `Cubemap99_Face_5.png` | 4,125 | 64x64 | (0.00, 0.00, 0.00) | 0..0 | Not found in manifest |
| `debris_luggageB_NOR.png` | 79,548 | 512x512 | (127.12, 126.26, 253.28) | 255..255 | debris_luggageB_shader (`Shader_debris_luggageB_shader_28444`) [normalMap] |
| `decor_paperstacksnor.png` | 308,244 | 1024x1024 | (126.82, 126.65, 254.62) | 255..255 | decor_paperstack_shader (`Shader_decor_paperstack_shader_11832`) [normalMap] |
| `decor_sofanor.png` | 1,114,183 | 1024x1024 | (125.66, 125.35, 254.15) | 255..255 | decor_sofa_shader (`Shader_decor_sofa_shader_12815`) [normalMap] |
| `DripsSparse_Diffuse.png` | 75 | 8x8 | (68.00, 68.00, 68.00) | 255..255 | dripping2_shader (`Shader_dripping2_shader_10187`) [diffuse] |
| `girder_03_diffuse.png` | 89,112 | 256x512 | (33.30, 34.77, 25.53) | 255..255 | girder_03_diffuse_shader (`Shader_girder_03_diffuse_shader_29531`) [diffuse] |
| `glass_diffuse.png` | 3,390 | 128x128 | (118.72, 121.71, 131.58) | 255..255 | glass_shader (`Shader_glass_shader_28649`) [diffuse] |
| `glasscon_diffuse.png` | 228 | 64x64 | (0.00, 40.00, 46.00) | 255..255 | Exterior_Window_Glass_Shader (`WindowShader_Exterior_Window_Glass_Shader_8375`) [diffuse]<br>TunnelGlassDist_Shader (`WindowShader_TunnelGlassDist_Shader_12838`) [diffuse]<br>Exterior_Window_02_Glass_Shader (`WindowShader_Exterior_Window_02_Glass_Shader_12831`) [diffuse]<br>Round_Window_Glass_Shader (`WindowShader_Round_Window_Glass_Shader_29061`) [diffuse] |
| `Medical_ceilling02Normal.png` | 4,118,746 | 2048x2048 | (127.21, 127.14, 251.72) | 255..255 | Medical_ceilling02_Diffuse_shader (`Shader_Medical_ceilling02_Diffuse_shader_3362`) [normalMap] |
| `sickbay_roomdivider_nor.png` | 1,015,345 | 1024x1024 | (125.50, 125.26, 254.56) | 255..255 | sickbay_roomdivider_shader (`Shader_sickbay_roomdivider_shader_29054`) [normalMap] |
| `tunnelset_glass_diffuse.png` | 84,659 | 2048x2048 | (0.00, 40.00, 46.00) | 255..255 | tunnelset_window_shader (`WindowShader_tunnelset_window_shader_7335`) [diffuse] |
| `windowspecular.png` | 251,782 | 512x512 | (0.00, 0.00, 0.00) | 0..9 | Window_Mat (`Shader_Window_Mat_29500`) [specular] |
| `wire_hanging_diffuse.png` | 612 | 128x128 | (51.00, 50.00, 51.00) | 255..255 | wire_hanging_diffuse_shader (`Shader_wire_hanging_diffuse_shader_12837`) [diffuse] |
