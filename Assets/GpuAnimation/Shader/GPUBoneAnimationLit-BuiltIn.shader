// Upgrade NOTE: upgraded instancing buffer 'GPUAnimationGPUBoneAnimationLitBuiltIn' to new syntax.

// Made with Amplify Shader Editor v1.9.6.3
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "GPUAnimation/GPUBoneAnimationLit-BuiltIn"
{
	Properties
	{
		_MainTex("_MainTex", 2D) = "white" {}
		_Color("_Color", Color) = (1,1,1,1)
		_AnimTex("_AnimTex", 2D) = "white" {}
		_FrameRate("_FrameRate", Float) = 0
		_AnimFrameCount("_AnimFrameCount", Int) = 0
		_StartIndex("_StartIndex", Int) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
		//[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		//[ToggleOff] _GlossyReflections("Reflections", Float) = 1.0
	}

	SubShader
	{
		
		Tags { "RenderType"="Opaque" "Queue"="Geometry" "DisableBatching"="False" }
	LOD 0

		Cull Back
		AlphaToMask Off
		ZWrite On
		ZTest LEqual
		ColorMask RGBA
		
		Blend Off
		

		CGINCLUDE
		#pragma target 3.0

		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		ENDCG

		
		Pass
		{
			
			Name "ForwardBase"
			Tags { "LightMode"="ForwardBase" }

			Blend One Zero

			CGPROGRAM
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#ifndef UNITY_PASS_FORWARDBASE
				#define UNITY_PASS_FORWARDBASE
			#endif
			#include "HLSLSupport.cginc"
			#ifndef UNITY_INSTANCED_LOD_FADE
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#ifndef UNITY_INSTANCED_SH
				#define UNITY_INSTANCED_SH
			#endif
			#ifndef UNITY_INSTANCED_LIGHTMAPSTS
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "AutoLight.cginc"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma multi_compile_instancing

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				uint4 ase_blendIndices : BLENDINDICES;
				float4 ase_blendWeights : BLENDWEIGHTS;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				#if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
				#else
					float4 pos : SV_POSITION;
				#endif
				#if defined(LIGHTMAP_ON) || (!defined(LIGHTMAP_ON) && SHADER_TARGET >= 30)
					float4 lmap : TEXCOORD0;
				#endif
				#if !defined(LIGHTMAP_ON) && UNITY_SHOULD_SAMPLE_SH
					half3 sh : TEXCOORD1;
				#endif
				#if defined(UNITY_HALF_PRECISION_FRAGMENT_SHADER_REGISTERS) && UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHTING_COORDS(2,3)
				#elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if UNITY_VERSION >= 201710
						UNITY_SHADOW_COORDS(2)
					#else
						SHADOW_COORDS(2)
					#endif
				#endif
				#ifdef ASE_FOG
					UNITY_FOG_COORDS(4)
				#endif
				float4 tSpace0 : TEXCOORD5;
				float4 tSpace1 : TEXCOORD6;
				float4 tSpace2 : TEXCOORD7;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD8;
				#endif
				float4 ase_texcoord9 : TEXCOORD9;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform sampler2D _AnimTex;
			float4 _AnimTex_TexelSize;
			uniform sampler2D _MainTex;
			UNITY_INSTANCING_BUFFER_START(GPUAnimationGPUBoneAnimationLitBuiltIn)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
#define _MainTex_ST_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
#define _Color_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(float, _FrameRate)
#define _FrameRate_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(int, _AnimFrameCount)
#define _AnimFrameCount_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(int, _StartIndex)
#define _StartIndex_arr GPUAnimationGPUBoneAnimationLitBuiltIn
			UNITY_INSTANCING_BUFFER_END(GPUAnimationGPUBoneAnimationLitBuiltIn)


			float4x4 GetBoneMatrix( int boneIndex, float texFrame )
			{
				// 计算纹理坐标
				                float vIndex0 = (boneIndex * 4 + 0.5) * _AnimTex_TexelSize.x;
				                float vIndex1 = (boneIndex * 4 + 1.5) * _AnimTex_TexelSize.x;
				                float vIndex2 = (boneIndex * 4 + 2.5) * _AnimTex_TexelSize.x;
				                float vIndex3 = (boneIndex * 4 + 3.5) * _AnimTex_TexelSize.x;
				                // 从动画贴图中读取骨骼矩阵
				                float4 boneMatrixRow0 = tex2Dlod(_AnimTex, float4(vIndex0, texFrame, 0, 0));
				                float4 boneMatrixRow1 = tex2Dlod(_AnimTex, float4(vIndex1, texFrame, 0, 0));
				                float4 boneMatrixRow2 = tex2Dlod(_AnimTex, float4(vIndex2, texFrame, 0, 0));
				                float4 boneMatrixRow3 = tex2Dlod(_AnimTex, float4(vIndex3, texFrame, 0, 0));
				                float4x4 boneMatrix = float4x4(boneMatrixRow0, boneMatrixRow1, boneMatrixRow2, boneMatrixRow3);
				                return boneMatrix;
			}
			
			float4 CalcPosition( float4 vertex, float4x4 boneMatrix, float boneWeight )
			{
				  float4 position = mul(boneMatrix,vertex) * boneWeight;
				                return position;
			}
			
			float3 CalcNormal( float3 normal, float4x4 boneMatrix, float boneWeight )
			{
				float3 newNormal = mul((float3x3)boneMatrix, normal) * boneWeight;
				                return newNormal;
			}
			

			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 vertex320 = v.vertex;
				float4 break264 = v.ase_blendIndices;
				int boneIndex318 = (int)break264.x;
				float _FrameRate_Instance = UNITY_ACCESS_INSTANCED_PROP(_FrameRate_arr, _FrameRate);
				int _AnimFrameCount_Instance = UNITY_ACCESS_INSTANCED_PROP(_AnimFrameCount_arr, _AnimFrameCount);
				int _StartIndex_Instance = UNITY_ACCESS_INSTANCED_PROP(_StartIndex_arr, _StartIndex);
				float temp_output_19_0 = ( ( ( floor( ( _Time.y * _FrameRate_Instance ) ) % (float)( _AnimFrameCount_Instance - 1 ) ) + _StartIndex_Instance + 0.5 ) * _AnimTex_TexelSize.y );
				float texFrame318 = temp_output_19_0;
				float4x4 localGetBoneMatrix318 = GetBoneMatrix( boneIndex318 , texFrame318 );
				float4x4 boneMatrix320 = localGetBoneMatrix318;
				float4 break265 = v.ase_blendWeights;
				float boneWeight320 = break265.x;
				float4 localCalcPosition320 = CalcPosition( vertex320 , boneMatrix320 , boneWeight320 );
				float4 vertex324 = v.vertex;
				int boneIndex329 = (int)break264.y;
				float texFrame329 = temp_output_19_0;
				float4x4 localGetBoneMatrix329 = GetBoneMatrix( boneIndex329 , texFrame329 );
				float4x4 boneMatrix324 = localGetBoneMatrix329;
				float boneWeight324 = break265.y;
				float4 localCalcPosition324 = CalcPosition( vertex324 , boneMatrix324 , boneWeight324 );
				float4 vertex326 = v.vertex;
				int boneIndex330 = (int)break264.z;
				float texFrame330 = temp_output_19_0;
				float4x4 localGetBoneMatrix330 = GetBoneMatrix( boneIndex330 , texFrame330 );
				float4x4 boneMatrix326 = localGetBoneMatrix330;
				float boneWeight326 = break265.z;
				float4 localCalcPosition326 = CalcPosition( vertex326 , boneMatrix326 , boneWeight326 );
				float4 vertex328 = v.vertex;
				int boneIndex331 = (int)break264.w;
				float texFrame331 = temp_output_19_0;
				float4x4 localGetBoneMatrix331 = GetBoneMatrix( boneIndex331 , texFrame331 );
				float4x4 boneMatrix328 = localGetBoneMatrix331;
				float boneWeight328 = break265.w;
				float4 localCalcPosition328 = CalcPosition( vertex328 , boneMatrix328 , boneWeight328 );
				
				float3 normal335 = v.normal;
				float4x4 boneMatrix335 = localGetBoneMatrix318;
				float boneWeight335 = break265.x;
				float3 localCalcNormal335 = CalcNormal( normal335 , boneMatrix335 , boneWeight335 );
				float3 normal338 = v.normal;
				float4x4 boneMatrix338 = localGetBoneMatrix329;
				float boneWeight338 = break265.y;
				float3 localCalcNormal338 = CalcNormal( normal338 , boneMatrix338 , boneWeight338 );
				float3 normal339 = v.normal;
				float4x4 boneMatrix339 = localGetBoneMatrix330;
				float boneWeight339 = break265.z;
				float3 localCalcNormal339 = CalcNormal( normal339 , boneMatrix339 , boneWeight339 );
				float3 normal340 = v.normal;
				float4x4 boneMatrix340 = localGetBoneMatrix331;
				float boneWeight340 = break265.w;
				float3 localCalcNormal340 = CalcNormal( normal340 , boneMatrix340 , boneWeight340 );
				
				o.ase_texcoord9.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord9.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( localCalcPosition320 + localCalcPosition324 + localCalcPosition326 + localCalcPosition328 ).xyz;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = ( localCalcNormal335 + localCalcNormal338 + localCalcNormal339 + localCalcNormal340 );
				v.tangent = v.tangent;

				o.pos = UnityObjectToClipPos(v.vertex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
				o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				#ifdef DYNAMICLIGHTMAP_ON
				o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#endif
				#ifdef LIGHTMAP_ON
				o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				#ifndef LIGHTMAP_ON
					#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						o.sh = 0;
						#ifdef VERTEXLIGHT_ON
						o.sh += Shade4PointLights (
							unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
							unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
							unity_4LightAtten0, worldPos, worldNormal);
						#endif
						o.sh = ShadeSHPerVertex (worldNormal, o.sh);
					#endif
				#endif

				#if UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy);
				#elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if UNITY_VERSION >= 201710
						UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
					#else
						TRANSFER_SHADOW(o);
					#endif
				#endif

				#ifdef ASE_FOG
					UNITY_TRANSFER_FOG(o,o.pos);
				#endif
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					o.screenPos = ComputeScreenPos(o.pos);
				#endif
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				uint4 ase_blendIndices : BLENDINDICES;
				float4 ase_blendWeights : BLENDWEIGHTS;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_blendIndices = v.ase_blendIndices;
				o.ase_blendWeights = v.ase_blendWeights;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_blendIndices = patch[0].ase_blendIndices * bary.x + patch[1].ase_blendIndices * bary.y + patch[2].ase_blendIndices * bary.z;
				o.ase_blendWeights = patch[0].ase_blendWeights * bary.x + patch[1].ase_blendWeights * bary.y + patch[2].ase_blendWeights * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			fixed4 frag (v2f IN 
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
				) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif
				float3 WorldTangent = float3(IN.tSpace0.x,IN.tSpace1.x,IN.tSpace2.x);
				float3 WorldBiTangent = float3(IN.tSpace0.y,IN.tSpace1.y,IN.tSpace2.y);
				float3 WorldNormal = float3(IN.tSpace0.z,IN.tSpace1.z,IN.tSpace2.z);
				float3 worldPos = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
				#else
					half atten = 1;
				#endif
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif

				float4 _MainTex_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_MainTex_ST_arr, _MainTex_ST);
				float2 uv_MainTex = IN.ase_texcoord9.xy * _MainTex_ST_Instance.xy + _MainTex_ST_Instance.zw;
				float4 _Color_Instance = UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color);
				
				o.Albedo = ( tex2D( _MainTex, uv_MainTex ) * _Color_Instance ).rgb;
				o.Normal = fixed3( 0, 0, 1 );
				o.Emission = half3( 0, 0, 0 );
				#if defined(_SPECULAR_SETUP)
					o.Specular = fixed3( 0, 0, 0 );
				#else
					o.Metallic = 0;
				#endif
				o.Smoothness = 0;
				o.Occlusion = 1;
				o.Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				#ifndef USING_DIRECTIONAL_LIGHT
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif

				fixed4 c = 0;
				float3 worldN;
				worldN.x = dot(IN.tSpace0.xyz, o.Normal);
				worldN.y = dot(IN.tSpace1.xyz, o.Normal);
				worldN.z = dot(IN.tSpace2.xyz, o.Normal);
				worldN = normalize(worldN);
				o.Normal = worldN;

				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = lightDir;

				UnityGIInput giInput;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
				giInput.light = gi.light;
				giInput.worldPos = worldPos;
				giInput.worldViewDir = worldViewDir;
				giInput.atten = atten;
				#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
					giInput.lightmapUV = IN.lmap;
				#else
					giInput.lightmapUV = 0.0;
				#endif
				#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					giInput.ambient = IN.sh;
				#else
					giInput.ambient.rgb = 0.0;
				#endif
				giInput.probeHDR[0] = unity_SpecCube0_HDR;
				giInput.probeHDR[1] = unity_SpecCube1_HDR;
				#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
					giInput.boxMin[0] = unity_SpecCube0_BoxMin;
				#endif
				#ifdef UNITY_SPECCUBE_BOX_PROJECTION
					giInput.boxMax[0] = unity_SpecCube0_BoxMax;
					giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
					giInput.boxMax[1] = unity_SpecCube1_BoxMax;
					giInput.boxMin[1] = unity_SpecCube1_BoxMin;
					giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
				#endif

				#if defined(_SPECULAR_SETUP)
					LightingStandardSpecular_GI(o, giInput, gi);
				#else
					LightingStandard_GI( o, giInput, gi );
				#endif

				#ifdef ASE_BAKEDGI
					gi.indirect.diffuse = BakedGI;
				#endif

				#if UNITY_SHOULD_SAMPLE_SH && !defined(LIGHTMAP_ON) && defined(ASE_NO_AMBIENT)
					gi.indirect.diffuse = 0;
				#endif

				#if defined(_SPECULAR_SETUP)
					c += LightingStandardSpecular (o, worldViewDir, gi);
				#else
					c += LightingStandard( o, worldViewDir, gi );
				#endif

				#ifdef ASE_TRANSMISSION
				{
					float shadow = _TransmissionShadow;
					#ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
					#else
						float3 lightAtten = gi.light.color;
					#endif
					half3 transmission = max(0 , -dot(o.Normal, gi.light.dir)) * lightAtten * Transmission;
					c.rgb += o.Albedo * transmission;
				}
				#endif

				#ifdef ASE_TRANSLUCENCY
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					#ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
					#else
						float3 lightAtten = gi.light.color;
					#endif
					half3 lightDir = gi.light.dir + o.Normal * normal;
					half transVdotL = pow( saturate( dot( worldViewDir, -lightDir ) ), scattering );
					half3 translucency = lightAtten * (transVdotL * direct + gi.indirect.diffuse * ambient) * Translucency;
					c.rgb += o.Albedo * translucency * strength;
				}
				#endif

				//#ifdef ASE_REFRACTION
				//	float4 projScreenPos = ScreenPos / ScreenPos.w;
				//	float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
				//	projScreenPos.xy += refractionOffset.xy;
				//	float3 refraction = UNITY_SAMPLE_SCREENSPACE_TEXTURE( _GrabTexture, projScreenPos ) * RefractionColor;
				//	color.rgb = lerp( refraction, color.rgb, color.a );
				//	color.a = 1;
				//#endif

				c.rgb += o.Emission;

				#ifdef ASE_FOG
					UNITY_APPLY_FOG(IN.fogCoord, c);
				#endif
				return c;
			}
			ENDCG
		}

		
		Pass
		{
			
			Name "ForwardAdd"
			Tags { "LightMode"="ForwardAdd" }
			ZWrite Off
			Blend One One

			CGPROGRAM
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma skip_variants INSTANCING_ON
			#pragma multi_compile_fwdadd_fullshadows
			#ifndef UNITY_PASS_FORWARDADD
				#define UNITY_PASS_FORWARDADD
			#endif
			#include "HLSLSupport.cginc"
			#if !defined( UNITY_INSTANCED_LOD_FADE )
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#if !defined( UNITY_INSTANCED_SH )
				#define UNITY_INSTANCED_SH
			#endif
			#if !defined( UNITY_INSTANCED_LIGHTMAPSTS )
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "AutoLight.cginc"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma multi_compile_instancing

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				uint4 ase_blendIndices : BLENDINDICES;
				float4 ase_blendWeights : BLENDWEIGHTS;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct v2f {
				#if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
				#else
					float4 pos : SV_POSITION;
				#endif
				#if UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHTING_COORDS(1,2)
				#elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if UNITY_VERSION >= 201710
						UNITY_SHADOW_COORDS(1)
					#else
						SHADOW_COORDS(1)
					#endif
				#endif
				#ifdef ASE_FOG
					UNITY_FOG_COORDS(3)
				#endif
				float4 tSpace0 : TEXCOORD5;
				float4 tSpace1 : TEXCOORD6;
				float4 tSpace2 : TEXCOORD7;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD8;
				#endif
				float4 ase_texcoord9 : TEXCOORD9;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef ASE_TRANSMISSION
				float _TransmissionShadow;
			#endif
			#ifdef ASE_TRANSLUCENCY
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform sampler2D _AnimTex;
			float4 _AnimTex_TexelSize;
			uniform sampler2D _MainTex;
			UNITY_INSTANCING_BUFFER_START(GPUAnimationGPUBoneAnimationLitBuiltIn)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
#define _MainTex_ST_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
#define _Color_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(float, _FrameRate)
#define _FrameRate_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(int, _AnimFrameCount)
#define _AnimFrameCount_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(int, _StartIndex)
#define _StartIndex_arr GPUAnimationGPUBoneAnimationLitBuiltIn
			UNITY_INSTANCING_BUFFER_END(GPUAnimationGPUBoneAnimationLitBuiltIn)


			float4x4 GetBoneMatrix( int boneIndex, float texFrame )
			{
				// 计算纹理坐标
				                float vIndex0 = (boneIndex * 4 + 0.5) * _AnimTex_TexelSize.x;
				                float vIndex1 = (boneIndex * 4 + 1.5) * _AnimTex_TexelSize.x;
				                float vIndex2 = (boneIndex * 4 + 2.5) * _AnimTex_TexelSize.x;
				                float vIndex3 = (boneIndex * 4 + 3.5) * _AnimTex_TexelSize.x;
				                // 从动画贴图中读取骨骼矩阵
				                float4 boneMatrixRow0 = tex2Dlod(_AnimTex, float4(vIndex0, texFrame, 0, 0));
				                float4 boneMatrixRow1 = tex2Dlod(_AnimTex, float4(vIndex1, texFrame, 0, 0));
				                float4 boneMatrixRow2 = tex2Dlod(_AnimTex, float4(vIndex2, texFrame, 0, 0));
				                float4 boneMatrixRow3 = tex2Dlod(_AnimTex, float4(vIndex3, texFrame, 0, 0));
				                float4x4 boneMatrix = float4x4(boneMatrixRow0, boneMatrixRow1, boneMatrixRow2, boneMatrixRow3);
				                return boneMatrix;
			}
			
			float4 CalcPosition( float4 vertex, float4x4 boneMatrix, float boneWeight )
			{
				  float4 position = mul(boneMatrix,vertex) * boneWeight;
				                return position;
			}
			
			float3 CalcNormal( float3 normal, float4x4 boneMatrix, float boneWeight )
			{
				float3 newNormal = mul((float3x3)boneMatrix, normal) * boneWeight;
				                return newNormal;
			}
			

			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 vertex320 = v.vertex;
				float4 break264 = v.ase_blendIndices;
				int boneIndex318 = (int)break264.x;
				float _FrameRate_Instance = UNITY_ACCESS_INSTANCED_PROP(_FrameRate_arr, _FrameRate);
				int _AnimFrameCount_Instance = UNITY_ACCESS_INSTANCED_PROP(_AnimFrameCount_arr, _AnimFrameCount);
				int _StartIndex_Instance = UNITY_ACCESS_INSTANCED_PROP(_StartIndex_arr, _StartIndex);
				float temp_output_19_0 = ( ( ( floor( ( _Time.y * _FrameRate_Instance ) ) % (float)( _AnimFrameCount_Instance - 1 ) ) + _StartIndex_Instance + 0.5 ) * _AnimTex_TexelSize.y );
				float texFrame318 = temp_output_19_0;
				float4x4 localGetBoneMatrix318 = GetBoneMatrix( boneIndex318 , texFrame318 );
				float4x4 boneMatrix320 = localGetBoneMatrix318;
				float4 break265 = v.ase_blendWeights;
				float boneWeight320 = break265.x;
				float4 localCalcPosition320 = CalcPosition( vertex320 , boneMatrix320 , boneWeight320 );
				float4 vertex324 = v.vertex;
				int boneIndex329 = (int)break264.y;
				float texFrame329 = temp_output_19_0;
				float4x4 localGetBoneMatrix329 = GetBoneMatrix( boneIndex329 , texFrame329 );
				float4x4 boneMatrix324 = localGetBoneMatrix329;
				float boneWeight324 = break265.y;
				float4 localCalcPosition324 = CalcPosition( vertex324 , boneMatrix324 , boneWeight324 );
				float4 vertex326 = v.vertex;
				int boneIndex330 = (int)break264.z;
				float texFrame330 = temp_output_19_0;
				float4x4 localGetBoneMatrix330 = GetBoneMatrix( boneIndex330 , texFrame330 );
				float4x4 boneMatrix326 = localGetBoneMatrix330;
				float boneWeight326 = break265.z;
				float4 localCalcPosition326 = CalcPosition( vertex326 , boneMatrix326 , boneWeight326 );
				float4 vertex328 = v.vertex;
				int boneIndex331 = (int)break264.w;
				float texFrame331 = temp_output_19_0;
				float4x4 localGetBoneMatrix331 = GetBoneMatrix( boneIndex331 , texFrame331 );
				float4x4 boneMatrix328 = localGetBoneMatrix331;
				float boneWeight328 = break265.w;
				float4 localCalcPosition328 = CalcPosition( vertex328 , boneMatrix328 , boneWeight328 );
				
				float3 normal335 = v.normal;
				float4x4 boneMatrix335 = localGetBoneMatrix318;
				float boneWeight335 = break265.x;
				float3 localCalcNormal335 = CalcNormal( normal335 , boneMatrix335 , boneWeight335 );
				float3 normal338 = v.normal;
				float4x4 boneMatrix338 = localGetBoneMatrix329;
				float boneWeight338 = break265.y;
				float3 localCalcNormal338 = CalcNormal( normal338 , boneMatrix338 , boneWeight338 );
				float3 normal339 = v.normal;
				float4x4 boneMatrix339 = localGetBoneMatrix330;
				float boneWeight339 = break265.z;
				float3 localCalcNormal339 = CalcNormal( normal339 , boneMatrix339 , boneWeight339 );
				float3 normal340 = v.normal;
				float4x4 boneMatrix340 = localGetBoneMatrix331;
				float boneWeight340 = break265.w;
				float3 localCalcNormal340 = CalcNormal( normal340 , boneMatrix340 , boneWeight340 );
				
				o.ase_texcoord9.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord9.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( localCalcPosition320 + localCalcPosition324 + localCalcPosition326 + localCalcPosition328 ).xyz;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = ( localCalcNormal335 + localCalcNormal338 + localCalcNormal339 + localCalcNormal340 );
				v.tangent = v.tangent;

				o.pos = UnityObjectToClipPos(v.vertex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
				o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				#if UNITY_VERSION >= 201810 && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy);
				#elif defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if UNITY_VERSION >= 201710
						UNITY_TRANSFER_SHADOW(o, v.texcoord1.xy);
					#else
						TRANSFER_SHADOW(o);
					#endif
				#endif

				#ifdef ASE_FOG
					UNITY_TRANSFER_FOG(o,o.pos);
				#endif
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
					o.screenPos = ComputeScreenPos(o.pos);
				#endif
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				uint4 ase_blendIndices : BLENDINDICES;
				float4 ase_blendWeights : BLENDWEIGHTS;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_blendIndices = v.ase_blendIndices;
				o.ase_blendWeights = v.ase_blendWeights;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_blendIndices = patch[0].ase_blendIndices * bary.x + patch[1].ase_blendIndices * bary.y + patch[2].ase_blendIndices * bary.z;
				o.ase_blendWeights = patch[0].ase_blendWeights * bary.x + patch[1].ase_blendWeights * bary.y + patch[2].ase_blendWeights * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			fixed4 frag ( v2f IN 
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
				) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif
				float3 WorldTangent = float3(IN.tSpace0.x,IN.tSpace1.x,IN.tSpace2.x);
				float3 WorldBiTangent = float3(IN.tSpace0.y,IN.tSpace1.y,IN.tSpace2.y);
				float3 WorldNormal = float3(IN.tSpace0.z,IN.tSpace1.z,IN.tSpace2.z);
				float3 worldPos = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
				#else
					half atten = 1;
				#endif
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif


				float4 _MainTex_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_MainTex_ST_arr, _MainTex_ST);
				float2 uv_MainTex = IN.ase_texcoord9.xy * _MainTex_ST_Instance.xy + _MainTex_ST_Instance.zw;
				float4 _Color_Instance = UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color);
				
				o.Albedo = ( tex2D( _MainTex, uv_MainTex ) * _Color_Instance ).rgb;
				o.Normal = fixed3( 0, 0, 1 );
				o.Emission = half3( 0, 0, 0 );
				#if defined(_SPECULAR_SETUP)
					o.Specular = fixed3( 0, 0, 0 );
				#else
					o.Metallic = 0;
				#endif
				o.Smoothness = 0;
				o.Occlusion = 1;
				o.Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float3 Transmission = 1;
				float3 Translucency = 1;

				#ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				#ifndef USING_DIRECTIONAL_LIGHT
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif

				fixed4 c = 0;
				float3 worldN;
				worldN.x = dot(IN.tSpace0.xyz, o.Normal);
				worldN.y = dot(IN.tSpace1.xyz, o.Normal);
				worldN.z = dot(IN.tSpace2.xyz, o.Normal);
				worldN = normalize(worldN);
				o.Normal = worldN;

				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = _LightColor0.rgb;
				gi.light.dir = lightDir;
				gi.light.color *= atten;

				#if defined(_SPECULAR_SETUP)
					c += LightingStandardSpecular( o, worldViewDir, gi );
				#else
					c += LightingStandard( o, worldViewDir, gi );
				#endif

				#ifdef ASE_TRANSMISSION
				{
					float shadow = _TransmissionShadow;
					#ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
					#else
						float3 lightAtten = gi.light.color;
					#endif
					half3 transmission = max(0 , -dot(o.Normal, gi.light.dir)) * lightAtten * Transmission;
					c.rgb += o.Albedo * transmission;
				}
				#endif

				#ifdef ASE_TRANSLUCENCY
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					#ifdef DIRECTIONAL
						float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, shadow );
					#else
						float3 lightAtten = gi.light.color;
					#endif
					half3 lightDir = gi.light.dir + o.Normal * normal;
					half transVdotL = pow( saturate( dot( worldViewDir, -lightDir ) ), scattering );
					half3 translucency = lightAtten * (transVdotL * direct + gi.indirect.diffuse * ambient) * Translucency;
					c.rgb += o.Albedo * translucency * strength;
				}
				#endif

				//#ifdef ASE_REFRACTION
				//	float4 projScreenPos = ScreenPos / ScreenPos.w;
				//	float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
				//	projScreenPos.xy += refractionOffset.xy;
				//	float3 refraction = UNITY_SAMPLE_SCREENSPACE_TEXTURE( _GrabTexture, projScreenPos ) * RefractionColor;
				//	color.rgb = lerp( refraction, color.rgb, color.a );
				//	color.a = 1;
				//#endif

				#ifdef ASE_FOG
					UNITY_APPLY_FOG(IN.fogCoord, c);
				#endif
				return c;
			}
			ENDCG
		}

		
		Pass
		{
			
			Name "Deferred"
			Tags { "LightMode"="Deferred" }

			AlphaToMask Off

			CGPROGRAM
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#pragma multi_compile_prepassfinal
			#ifndef UNITY_PASS_DEFERRED
				#define UNITY_PASS_DEFERRED
			#endif
			#include "HLSLSupport.cginc"
			#if !defined( UNITY_INSTANCED_LOD_FADE )
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#if !defined( UNITY_INSTANCED_SH )
				#define UNITY_INSTANCED_SH
			#endif
			#if !defined( UNITY_INSTANCED_LIGHTMAPSTS )
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma multi_compile_instancing

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				uint4 ase_blendIndices : BLENDINDICES;
				float4 ase_blendWeights : BLENDWEIGHTS;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				#if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
				#else
					float4 pos : SV_POSITION;
				#endif
				float4 lmap : TEXCOORD2;
				#ifndef LIGHTMAP_ON
					#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						half3 sh : TEXCOORD3;
					#endif
				#else
					#ifdef DIRLIGHTMAP_OFF
						float4 lmapFadePos : TEXCOORD4;
					#endif
				#endif
				float4 tSpace0 : TEXCOORD5;
				float4 tSpace1 : TEXCOORD6;
				float4 tSpace2 : TEXCOORD7;
				float4 ase_texcoord8 : TEXCOORD8;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef LIGHTMAP_ON
			float4 unity_LightmapFade;
			#endif
			fixed4 unity_Ambient;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform sampler2D _AnimTex;
			float4 _AnimTex_TexelSize;
			uniform sampler2D _MainTex;
			UNITY_INSTANCING_BUFFER_START(GPUAnimationGPUBoneAnimationLitBuiltIn)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
#define _MainTex_ST_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
#define _Color_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(float, _FrameRate)
#define _FrameRate_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(int, _AnimFrameCount)
#define _AnimFrameCount_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(int, _StartIndex)
#define _StartIndex_arr GPUAnimationGPUBoneAnimationLitBuiltIn
			UNITY_INSTANCING_BUFFER_END(GPUAnimationGPUBoneAnimationLitBuiltIn)


			float4x4 GetBoneMatrix( int boneIndex, float texFrame )
			{
				// 计算纹理坐标
				                float vIndex0 = (boneIndex * 4 + 0.5) * _AnimTex_TexelSize.x;
				                float vIndex1 = (boneIndex * 4 + 1.5) * _AnimTex_TexelSize.x;
				                float vIndex2 = (boneIndex * 4 + 2.5) * _AnimTex_TexelSize.x;
				                float vIndex3 = (boneIndex * 4 + 3.5) * _AnimTex_TexelSize.x;
				                // 从动画贴图中读取骨骼矩阵
				                float4 boneMatrixRow0 = tex2Dlod(_AnimTex, float4(vIndex0, texFrame, 0, 0));
				                float4 boneMatrixRow1 = tex2Dlod(_AnimTex, float4(vIndex1, texFrame, 0, 0));
				                float4 boneMatrixRow2 = tex2Dlod(_AnimTex, float4(vIndex2, texFrame, 0, 0));
				                float4 boneMatrixRow3 = tex2Dlod(_AnimTex, float4(vIndex3, texFrame, 0, 0));
				                float4x4 boneMatrix = float4x4(boneMatrixRow0, boneMatrixRow1, boneMatrixRow2, boneMatrixRow3);
				                return boneMatrix;
			}
			
			float4 CalcPosition( float4 vertex, float4x4 boneMatrix, float boneWeight )
			{
				  float4 position = mul(boneMatrix,vertex) * boneWeight;
				                return position;
			}
			
			float3 CalcNormal( float3 normal, float4x4 boneMatrix, float boneWeight )
			{
				float3 newNormal = mul((float3x3)boneMatrix, normal) * boneWeight;
				                return newNormal;
			}
			

			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 vertex320 = v.vertex;
				float4 break264 = v.ase_blendIndices;
				int boneIndex318 = (int)break264.x;
				float _FrameRate_Instance = UNITY_ACCESS_INSTANCED_PROP(_FrameRate_arr, _FrameRate);
				int _AnimFrameCount_Instance = UNITY_ACCESS_INSTANCED_PROP(_AnimFrameCount_arr, _AnimFrameCount);
				int _StartIndex_Instance = UNITY_ACCESS_INSTANCED_PROP(_StartIndex_arr, _StartIndex);
				float temp_output_19_0 = ( ( ( floor( ( _Time.y * _FrameRate_Instance ) ) % (float)( _AnimFrameCount_Instance - 1 ) ) + _StartIndex_Instance + 0.5 ) * _AnimTex_TexelSize.y );
				float texFrame318 = temp_output_19_0;
				float4x4 localGetBoneMatrix318 = GetBoneMatrix( boneIndex318 , texFrame318 );
				float4x4 boneMatrix320 = localGetBoneMatrix318;
				float4 break265 = v.ase_blendWeights;
				float boneWeight320 = break265.x;
				float4 localCalcPosition320 = CalcPosition( vertex320 , boneMatrix320 , boneWeight320 );
				float4 vertex324 = v.vertex;
				int boneIndex329 = (int)break264.y;
				float texFrame329 = temp_output_19_0;
				float4x4 localGetBoneMatrix329 = GetBoneMatrix( boneIndex329 , texFrame329 );
				float4x4 boneMatrix324 = localGetBoneMatrix329;
				float boneWeight324 = break265.y;
				float4 localCalcPosition324 = CalcPosition( vertex324 , boneMatrix324 , boneWeight324 );
				float4 vertex326 = v.vertex;
				int boneIndex330 = (int)break264.z;
				float texFrame330 = temp_output_19_0;
				float4x4 localGetBoneMatrix330 = GetBoneMatrix( boneIndex330 , texFrame330 );
				float4x4 boneMatrix326 = localGetBoneMatrix330;
				float boneWeight326 = break265.z;
				float4 localCalcPosition326 = CalcPosition( vertex326 , boneMatrix326 , boneWeight326 );
				float4 vertex328 = v.vertex;
				int boneIndex331 = (int)break264.w;
				float texFrame331 = temp_output_19_0;
				float4x4 localGetBoneMatrix331 = GetBoneMatrix( boneIndex331 , texFrame331 );
				float4x4 boneMatrix328 = localGetBoneMatrix331;
				float boneWeight328 = break265.w;
				float4 localCalcPosition328 = CalcPosition( vertex328 , boneMatrix328 , boneWeight328 );
				
				float3 normal335 = v.normal;
				float4x4 boneMatrix335 = localGetBoneMatrix318;
				float boneWeight335 = break265.x;
				float3 localCalcNormal335 = CalcNormal( normal335 , boneMatrix335 , boneWeight335 );
				float3 normal338 = v.normal;
				float4x4 boneMatrix338 = localGetBoneMatrix329;
				float boneWeight338 = break265.y;
				float3 localCalcNormal338 = CalcNormal( normal338 , boneMatrix338 , boneWeight338 );
				float3 normal339 = v.normal;
				float4x4 boneMatrix339 = localGetBoneMatrix330;
				float boneWeight339 = break265.z;
				float3 localCalcNormal339 = CalcNormal( normal339 , boneMatrix339 , boneWeight339 );
				float3 normal340 = v.normal;
				float4x4 boneMatrix340 = localGetBoneMatrix331;
				float boneWeight340 = break265.w;
				float3 localCalcNormal340 = CalcNormal( normal340 , boneMatrix340 , boneWeight340 );
				
				o.ase_texcoord8.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord8.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( localCalcPosition320 + localCalcPosition324 + localCalcPosition326 + localCalcPosition328 ).xyz;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = ( localCalcNormal335 + localCalcNormal338 + localCalcNormal339 + localCalcNormal340 );
				v.tangent = v.tangent;

				o.pos = UnityObjectToClipPos(v.vertex);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;
				o.tSpace0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.tSpace1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.tSpace2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				#ifdef DYNAMICLIGHTMAP_ON
					o.lmap.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
				#else
					o.lmap.zw = 0;
				#endif
				#ifdef LIGHTMAP_ON
					o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
					#ifdef DIRLIGHTMAP_OFF
						o.lmapFadePos.xyz = (mul(unity_ObjectToWorld, v.vertex).xyz - unity_ShadowFadeCenterAndType.xyz) * unity_ShadowFadeCenterAndType.w;
						o.lmapFadePos.w = (-UnityObjectToViewPos(v.vertex).z) * (1.0 - unity_ShadowFadeCenterAndType.w);
					#endif
				#else
					o.lmap.xy = 0;
					#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
						o.sh = 0;
						o.sh = ShadeSHPerVertex (worldNormal, o.sh);
					#endif
				#endif
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				uint4 ase_blendIndices : BLENDINDICES;
				float4 ase_blendWeights : BLENDWEIGHTS;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_blendIndices = v.ase_blendIndices;
				o.ase_blendWeights = v.ase_blendWeights;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_blendIndices = patch[0].ase_blendIndices * bary.x + patch[1].ase_blendIndices * bary.y + patch[2].ase_blendIndices * bary.z;
				o.ase_blendWeights = patch[0].ase_blendWeights * bary.x + patch[1].ase_blendWeights * bary.y + patch[2].ase_blendWeights * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			void frag (v2f IN 
				, out half4 outGBuffer0 : SV_Target0
				, out half4 outGBuffer1 : SV_Target1
				, out half4 outGBuffer2 : SV_Target2
				, out half4 outEmission : SV_Target3
				#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
				, out half4 outShadowMask : SV_Target4
				#endif
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
			)
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif
				float3 WorldTangent = float3(IN.tSpace0.x,IN.tSpace1.x,IN.tSpace2.x);
				float3 WorldBiTangent = float3(IN.tSpace0.y,IN.tSpace1.y,IN.tSpace2.y);
				float3 WorldNormal = float3(IN.tSpace0.z,IN.tSpace1.z,IN.tSpace2.z);
				float3 worldPos = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				half atten = 1;

				float4 _MainTex_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_MainTex_ST_arr, _MainTex_ST);
				float2 uv_MainTex = IN.ase_texcoord8.xy * _MainTex_ST_Instance.xy + _MainTex_ST_Instance.zw;
				float4 _Color_Instance = UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color);
				
				o.Albedo = ( tex2D( _MainTex, uv_MainTex ) * _Color_Instance ).rgb;
				o.Normal = fixed3( 0, 0, 1 );
				o.Emission = half3( 0, 0, 0 );
				#if defined(_SPECULAR_SETUP)
					o.Specular = fixed3( 0, 0, 0 );
				#else
					o.Metallic = 0;
				#endif
				o.Smoothness = 0;
				o.Occlusion = 1;
				o.Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float3 BakedGI = 0;

				#ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				#ifndef USING_DIRECTIONAL_LIGHT
					fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				#else
					fixed3 lightDir = _WorldSpaceLightPos0.xyz;
				#endif

				float3 worldN;
				worldN.x = dot(IN.tSpace0.xyz, o.Normal);
				worldN.y = dot(IN.tSpace1.xyz, o.Normal);
				worldN.z = dot(IN.tSpace2.xyz, o.Normal);
				worldN = normalize(worldN);
				o.Normal = worldN;

				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
				gi.indirect.diffuse = 0;
				gi.indirect.specular = 0;
				gi.light.color = 0;
				gi.light.dir = half3(0,1,0);

				UnityGIInput giInput;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
				giInput.light = gi.light;
				giInput.worldPos = worldPos;
				giInput.worldViewDir = worldViewDir;
				giInput.atten = atten;
				#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
					giInput.lightmapUV = IN.lmap;
				#else
					giInput.lightmapUV = 0.0;
				#endif
				#if UNITY_SHOULD_SAMPLE_SH && !UNITY_SAMPLE_FULL_SH_PER_PIXEL
					giInput.ambient = IN.sh;
				#else
					giInput.ambient.rgb = 0.0;
				#endif
				giInput.probeHDR[0] = unity_SpecCube0_HDR;
				giInput.probeHDR[1] = unity_SpecCube1_HDR;
				#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
					giInput.boxMin[0] = unity_SpecCube0_BoxMin;
				#endif
				#ifdef UNITY_SPECCUBE_BOX_PROJECTION
					giInput.boxMax[0] = unity_SpecCube0_BoxMax;
					giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
					giInput.boxMax[1] = unity_SpecCube1_BoxMax;
					giInput.boxMin[1] = unity_SpecCube1_BoxMin;
					giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
				#endif

				#if defined(_SPECULAR_SETUP)
					LightingStandardSpecular_GI( o, giInput, gi );
				#else
					LightingStandard_GI( o, giInput, gi );
				#endif

				#ifdef ASE_BAKEDGI
					gi.indirect.diffuse = BakedGI;
				#endif

				#if UNITY_SHOULD_SAMPLE_SH && !defined(LIGHTMAP_ON) && defined(ASE_NO_AMBIENT)
					gi.indirect.diffuse = 0;
				#endif

				#if defined(_SPECULAR_SETUP)
					outEmission = LightingStandardSpecular_Deferred( o, worldViewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2 );
				#else
					outEmission = LightingStandard_Deferred( o, worldViewDir, gi, outGBuffer0, outGBuffer1, outGBuffer2 );
				#endif

				#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
					outShadowMask = UnityGetRawBakedOcclusions (IN.lmap.xy, float3(0, 0, 0));
				#endif
				#ifndef UNITY_HDR_ON
					outEmission.rgb = exp2(-outEmission.rgb);
				#endif
			}
			ENDCG
		}

		
		Pass
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }
			Cull Off

			CGPROGRAM
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#pragma shader_feature EDITOR_VISUALIZATION
			#ifndef UNITY_PASS_META
				#define UNITY_PASS_META
			#endif
			#include "HLSLSupport.cginc"
			#if !defined( UNITY_INSTANCED_LOD_FADE )
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#if !defined( UNITY_INSTANCED_SH )
				#define UNITY_INSTANCED_SH
			#endif
			#if !defined( UNITY_INSTANCED_LIGHTMAPSTS )
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			#include "UnityMetaPass.cginc"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma multi_compile_instancing

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				uint4 ase_blendIndices : BLENDINDICES;
				float4 ase_blendWeights : BLENDWEIGHTS;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			struct v2f {
				#if UNITY_VERSION >= 201810
					UNITY_POSITION(pos);
				#else
					float4 pos : SV_POSITION;
				#endif
				#ifdef EDITOR_VISUALIZATION
					float2 vizUV : TEXCOORD1;
					float4 lightCoord : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform sampler2D _AnimTex;
			float4 _AnimTex_TexelSize;
			uniform sampler2D _MainTex;
			UNITY_INSTANCING_BUFFER_START(GPUAnimationGPUBoneAnimationLitBuiltIn)
				UNITY_DEFINE_INSTANCED_PROP(float4, _MainTex_ST)
#define _MainTex_ST_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
#define _Color_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(float, _FrameRate)
#define _FrameRate_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(int, _AnimFrameCount)
#define _AnimFrameCount_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(int, _StartIndex)
#define _StartIndex_arr GPUAnimationGPUBoneAnimationLitBuiltIn
			UNITY_INSTANCING_BUFFER_END(GPUAnimationGPUBoneAnimationLitBuiltIn)


			float4x4 GetBoneMatrix( int boneIndex, float texFrame )
			{
				// 计算纹理坐标
				                float vIndex0 = (boneIndex * 4 + 0.5) * _AnimTex_TexelSize.x;
				                float vIndex1 = (boneIndex * 4 + 1.5) * _AnimTex_TexelSize.x;
				                float vIndex2 = (boneIndex * 4 + 2.5) * _AnimTex_TexelSize.x;
				                float vIndex3 = (boneIndex * 4 + 3.5) * _AnimTex_TexelSize.x;
				                // 从动画贴图中读取骨骼矩阵
				                float4 boneMatrixRow0 = tex2Dlod(_AnimTex, float4(vIndex0, texFrame, 0, 0));
				                float4 boneMatrixRow1 = tex2Dlod(_AnimTex, float4(vIndex1, texFrame, 0, 0));
				                float4 boneMatrixRow2 = tex2Dlod(_AnimTex, float4(vIndex2, texFrame, 0, 0));
				                float4 boneMatrixRow3 = tex2Dlod(_AnimTex, float4(vIndex3, texFrame, 0, 0));
				                float4x4 boneMatrix = float4x4(boneMatrixRow0, boneMatrixRow1, boneMatrixRow2, boneMatrixRow3);
				                return boneMatrix;
			}
			
			float4 CalcPosition( float4 vertex, float4x4 boneMatrix, float boneWeight )
			{
				  float4 position = mul(boneMatrix,vertex) * boneWeight;
				                return position;
			}
			
			float3 CalcNormal( float3 normal, float4x4 boneMatrix, float boneWeight )
			{
				float3 newNormal = mul((float3x3)boneMatrix, normal) * boneWeight;
				                return newNormal;
			}
			

			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 vertex320 = v.vertex;
				float4 break264 = v.ase_blendIndices;
				int boneIndex318 = (int)break264.x;
				float _FrameRate_Instance = UNITY_ACCESS_INSTANCED_PROP(_FrameRate_arr, _FrameRate);
				int _AnimFrameCount_Instance = UNITY_ACCESS_INSTANCED_PROP(_AnimFrameCount_arr, _AnimFrameCount);
				int _StartIndex_Instance = UNITY_ACCESS_INSTANCED_PROP(_StartIndex_arr, _StartIndex);
				float temp_output_19_0 = ( ( ( floor( ( _Time.y * _FrameRate_Instance ) ) % (float)( _AnimFrameCount_Instance - 1 ) ) + _StartIndex_Instance + 0.5 ) * _AnimTex_TexelSize.y );
				float texFrame318 = temp_output_19_0;
				float4x4 localGetBoneMatrix318 = GetBoneMatrix( boneIndex318 , texFrame318 );
				float4x4 boneMatrix320 = localGetBoneMatrix318;
				float4 break265 = v.ase_blendWeights;
				float boneWeight320 = break265.x;
				float4 localCalcPosition320 = CalcPosition( vertex320 , boneMatrix320 , boneWeight320 );
				float4 vertex324 = v.vertex;
				int boneIndex329 = (int)break264.y;
				float texFrame329 = temp_output_19_0;
				float4x4 localGetBoneMatrix329 = GetBoneMatrix( boneIndex329 , texFrame329 );
				float4x4 boneMatrix324 = localGetBoneMatrix329;
				float boneWeight324 = break265.y;
				float4 localCalcPosition324 = CalcPosition( vertex324 , boneMatrix324 , boneWeight324 );
				float4 vertex326 = v.vertex;
				int boneIndex330 = (int)break264.z;
				float texFrame330 = temp_output_19_0;
				float4x4 localGetBoneMatrix330 = GetBoneMatrix( boneIndex330 , texFrame330 );
				float4x4 boneMatrix326 = localGetBoneMatrix330;
				float boneWeight326 = break265.z;
				float4 localCalcPosition326 = CalcPosition( vertex326 , boneMatrix326 , boneWeight326 );
				float4 vertex328 = v.vertex;
				int boneIndex331 = (int)break264.w;
				float texFrame331 = temp_output_19_0;
				float4x4 localGetBoneMatrix331 = GetBoneMatrix( boneIndex331 , texFrame331 );
				float4x4 boneMatrix328 = localGetBoneMatrix331;
				float boneWeight328 = break265.w;
				float4 localCalcPosition328 = CalcPosition( vertex328 , boneMatrix328 , boneWeight328 );
				
				float3 normal335 = v.normal;
				float4x4 boneMatrix335 = localGetBoneMatrix318;
				float boneWeight335 = break265.x;
				float3 localCalcNormal335 = CalcNormal( normal335 , boneMatrix335 , boneWeight335 );
				float3 normal338 = v.normal;
				float4x4 boneMatrix338 = localGetBoneMatrix329;
				float boneWeight338 = break265.y;
				float3 localCalcNormal338 = CalcNormal( normal338 , boneMatrix338 , boneWeight338 );
				float3 normal339 = v.normal;
				float4x4 boneMatrix339 = localGetBoneMatrix330;
				float boneWeight339 = break265.z;
				float3 localCalcNormal339 = CalcNormal( normal339 , boneMatrix339 , boneWeight339 );
				float3 normal340 = v.normal;
				float4x4 boneMatrix340 = localGetBoneMatrix331;
				float boneWeight340 = break265.w;
				float3 localCalcNormal340 = CalcNormal( normal340 , boneMatrix340 , boneWeight340 );
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( localCalcPosition320 + localCalcPosition324 + localCalcPosition326 + localCalcPosition328 ).xyz;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = ( localCalcNormal335 + localCalcNormal338 + localCalcNormal339 + localCalcNormal340 );
				v.tangent = v.tangent;

				#ifdef EDITOR_VISUALIZATION
					o.vizUV = 0;
					o.lightCoord = 0;
					if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
						o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.texcoord.xy, v.texcoord1.xy, v.texcoord2.xy, unity_EditorViz_Texture_ST);
					else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
					{
						o.vizUV = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
						o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
					}
				#endif

				o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				uint4 ase_blendIndices : BLENDINDICES;
				float4 ase_blendWeights : BLENDWEIGHTS;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_blendIndices = v.ase_blendIndices;
				o.ase_blendWeights = v.ase_blendWeights;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_blendIndices = patch[0].ase_blendIndices * bary.x + patch[1].ase_blendIndices * bary.y + patch[2].ase_blendIndices * bary.z;
				o.ase_blendWeights = patch[0].ase_blendWeights * bary.x + patch[1].ase_blendWeights * bary.y + patch[2].ase_blendWeights * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			fixed4 frag (v2f IN 
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
				) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif

				float4 _MainTex_ST_Instance = UNITY_ACCESS_INSTANCED_PROP(_MainTex_ST_arr, _MainTex_ST);
				float2 uv_MainTex = IN.ase_texcoord3.xy * _MainTex_ST_Instance.xy + _MainTex_ST_Instance.zw;
				float4 _Color_Instance = UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color);
				
				o.Albedo = ( tex2D( _MainTex, uv_MainTex ) * _Color_Instance ).rgb;
				o.Normal = fixed3( 0, 0, 1 );
				o.Emission = half3( 0, 0, 0 );
				o.Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip( o.Alpha - AlphaClipThreshold );
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				UnityMetaInput metaIN;
				UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);
				metaIN.Albedo = o.Albedo;
				metaIN.Emission = o.Emission;
				#ifdef EDITOR_VISUALIZATION
					metaIN.VizUV = IN.vizUV;
					metaIN.LightCoord = IN.lightCoord;
				#endif
				return UnityMetaFragment(metaIN);
			}
			ENDCG
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }
			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			CGPROGRAM
			#define ASE_NEEDS_FRAG_SHADOWCOORDS
			#pragma multi_compile __ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_ABSOLUTE_VERTEX_POS 1

			#pragma vertex vert
			#pragma fragment frag
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#pragma multi_compile_shadowcaster
			#ifndef UNITY_PASS_SHADOWCASTER
				#define UNITY_PASS_SHADOWCASTER
			#endif
			#include "HLSLSupport.cginc"
			#ifndef UNITY_INSTANCED_LOD_FADE
				#define UNITY_INSTANCED_LOD_FADE
			#endif
			#ifndef UNITY_INSTANCED_SH
				#define UNITY_INSTANCED_SH
			#endif
			#ifndef UNITY_INSTANCED_LIGHTMAPSTS
				#define UNITY_INSTANCED_LIGHTMAPSTS
			#endif
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityShaderVariables.cginc"
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"

			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma multi_compile_instancing

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				uint4 ase_blendIndices : BLENDINDICES;
				float4 ase_blendWeights : BLENDWEIGHTS;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				V2F_SHADOW_CASTER;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#ifdef UNITY_STANDARD_USE_DITHER_MASK
				sampler3D _DitherMaskLOD;
			#endif
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			uniform sampler2D _AnimTex;
			float4 _AnimTex_TexelSize;
			UNITY_INSTANCING_BUFFER_START(GPUAnimationGPUBoneAnimationLitBuiltIn)
				UNITY_DEFINE_INSTANCED_PROP(float, _FrameRate)
#define _FrameRate_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(int, _AnimFrameCount)
#define _AnimFrameCount_arr GPUAnimationGPUBoneAnimationLitBuiltIn
				UNITY_DEFINE_INSTANCED_PROP(int, _StartIndex)
#define _StartIndex_arr GPUAnimationGPUBoneAnimationLitBuiltIn
			UNITY_INSTANCING_BUFFER_END(GPUAnimationGPUBoneAnimationLitBuiltIn)


			float4x4 GetBoneMatrix( int boneIndex, float texFrame )
			{
				// 计算纹理坐标
				                float vIndex0 = (boneIndex * 4 + 0.5) * _AnimTex_TexelSize.x;
				                float vIndex1 = (boneIndex * 4 + 1.5) * _AnimTex_TexelSize.x;
				                float vIndex2 = (boneIndex * 4 + 2.5) * _AnimTex_TexelSize.x;
				                float vIndex3 = (boneIndex * 4 + 3.5) * _AnimTex_TexelSize.x;
				                // 从动画贴图中读取骨骼矩阵
				                float4 boneMatrixRow0 = tex2Dlod(_AnimTex, float4(vIndex0, texFrame, 0, 0));
				                float4 boneMatrixRow1 = tex2Dlod(_AnimTex, float4(vIndex1, texFrame, 0, 0));
				                float4 boneMatrixRow2 = tex2Dlod(_AnimTex, float4(vIndex2, texFrame, 0, 0));
				                float4 boneMatrixRow3 = tex2Dlod(_AnimTex, float4(vIndex3, texFrame, 0, 0));
				                float4x4 boneMatrix = float4x4(boneMatrixRow0, boneMatrixRow1, boneMatrixRow2, boneMatrixRow3);
				                return boneMatrix;
			}
			
			float4 CalcPosition( float4 vertex, float4x4 boneMatrix, float boneWeight )
			{
				  float4 position = mul(boneMatrix,vertex) * boneWeight;
				                return position;
			}
			
			float3 CalcNormal( float3 normal, float4x4 boneMatrix, float boneWeight )
			{
				float3 newNormal = mul((float3x3)boneMatrix, normal) * boneWeight;
				                return newNormal;
			}
			

			v2f VertexFunction (appdata v  ) {
				UNITY_SETUP_INSTANCE_ID(v);
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 vertex320 = v.vertex;
				float4 break264 = v.ase_blendIndices;
				int boneIndex318 = (int)break264.x;
				float _FrameRate_Instance = UNITY_ACCESS_INSTANCED_PROP(_FrameRate_arr, _FrameRate);
				int _AnimFrameCount_Instance = UNITY_ACCESS_INSTANCED_PROP(_AnimFrameCount_arr, _AnimFrameCount);
				int _StartIndex_Instance = UNITY_ACCESS_INSTANCED_PROP(_StartIndex_arr, _StartIndex);
				float temp_output_19_0 = ( ( ( floor( ( _Time.y * _FrameRate_Instance ) ) % (float)( _AnimFrameCount_Instance - 1 ) ) + _StartIndex_Instance + 0.5 ) * _AnimTex_TexelSize.y );
				float texFrame318 = temp_output_19_0;
				float4x4 localGetBoneMatrix318 = GetBoneMatrix( boneIndex318 , texFrame318 );
				float4x4 boneMatrix320 = localGetBoneMatrix318;
				float4 break265 = v.ase_blendWeights;
				float boneWeight320 = break265.x;
				float4 localCalcPosition320 = CalcPosition( vertex320 , boneMatrix320 , boneWeight320 );
				float4 vertex324 = v.vertex;
				int boneIndex329 = (int)break264.y;
				float texFrame329 = temp_output_19_0;
				float4x4 localGetBoneMatrix329 = GetBoneMatrix( boneIndex329 , texFrame329 );
				float4x4 boneMatrix324 = localGetBoneMatrix329;
				float boneWeight324 = break265.y;
				float4 localCalcPosition324 = CalcPosition( vertex324 , boneMatrix324 , boneWeight324 );
				float4 vertex326 = v.vertex;
				int boneIndex330 = (int)break264.z;
				float texFrame330 = temp_output_19_0;
				float4x4 localGetBoneMatrix330 = GetBoneMatrix( boneIndex330 , texFrame330 );
				float4x4 boneMatrix326 = localGetBoneMatrix330;
				float boneWeight326 = break265.z;
				float4 localCalcPosition326 = CalcPosition( vertex326 , boneMatrix326 , boneWeight326 );
				float4 vertex328 = v.vertex;
				int boneIndex331 = (int)break264.w;
				float texFrame331 = temp_output_19_0;
				float4x4 localGetBoneMatrix331 = GetBoneMatrix( boneIndex331 , texFrame331 );
				float4x4 boneMatrix328 = localGetBoneMatrix331;
				float boneWeight328 = break265.w;
				float4 localCalcPosition328 = CalcPosition( vertex328 , boneMatrix328 , boneWeight328 );
				
				float3 normal335 = v.normal;
				float4x4 boneMatrix335 = localGetBoneMatrix318;
				float boneWeight335 = break265.x;
				float3 localCalcNormal335 = CalcNormal( normal335 , boneMatrix335 , boneWeight335 );
				float3 normal338 = v.normal;
				float4x4 boneMatrix338 = localGetBoneMatrix329;
				float boneWeight338 = break265.y;
				float3 localCalcNormal338 = CalcNormal( normal338 , boneMatrix338 , boneWeight338 );
				float3 normal339 = v.normal;
				float4x4 boneMatrix339 = localGetBoneMatrix330;
				float boneWeight339 = break265.z;
				float3 localCalcNormal339 = CalcNormal( normal339 , boneMatrix339 , boneWeight339 );
				float3 normal340 = v.normal;
				float4x4 boneMatrix340 = localGetBoneMatrix331;
				float boneWeight340 = break265.w;
				float3 localCalcNormal340 = CalcNormal( normal340 , boneMatrix340 , boneWeight340 );
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( localCalcPosition320 + localCalcPosition324 + localCalcPosition326 + localCalcPosition328 ).xyz;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.vertex.w = 1;
				v.normal = ( localCalcNormal335 + localCalcNormal338 + localCalcNormal339 + localCalcNormal340 );
				v.tangent = v.tangent;

				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				uint4 ase_blendIndices : BLENDINDICES;
				float4 ase_blendWeights : BLENDWEIGHTS;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( appdata v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_blendIndices = v.ase_blendIndices;
				o.ase_blendWeights = v.ase_blendWeights;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, UNITY_MATRIX_M, _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, UNITY_MATRIX_M, _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			v2f DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				appdata o = (appdata) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
				o.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_blendIndices = patch[0].ase_blendIndices * bary.x + patch[1].ase_blendIndices * bary.y + patch[2].ase_blendIndices * bary.z;
				o.ase_blendWeights = patch[0].ase_blendWeights * bary.x + patch[1].ase_blendWeights * bary.y + patch[2].ase_blendWeights * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].normal * (dot(o.vertex.xyz, patch[i].normal) - dot(patch[i].vertex.xyz, patch[i].normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			v2f vert ( appdata v )
			{
				return VertexFunction( v );
			}
			#endif

			fixed4 frag (v2f IN 
				#ifdef _DEPTHOFFSET_ON
				, out float outputDepth : SV_Depth
				#endif
				#if !defined( CAN_SKIP_VPOS )
				, UNITY_VPOS_TYPE vpos : VPOS
				#endif
				) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);

				#ifdef LOD_FADE_CROSSFADE
					UNITY_APPLY_DITHER_CROSSFADE(IN.pos.xy);
				#endif

				#if defined(_SPECULAR_SETUP)
					SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
				#else
					SurfaceOutputStandard o = (SurfaceOutputStandard)0;
				#endif

				
				o.Normal = fixed3( 0, 0, 1 );
				o.Occlusion = 1;
				o.Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_SHADOW_ON
					if (unity_LightShadowBias.z != 0.0)
						clip(o.Alpha - AlphaClipThresholdShadow);
					#ifdef _ALPHATEST_ON
					else
						clip(o.Alpha - AlphaClipThreshold);
					#endif
				#else
					#ifdef _ALPHATEST_ON
						clip(o.Alpha - AlphaClipThreshold);
					#endif
				#endif

				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif

				#ifdef UNITY_STANDARD_USE_DITHER_MASK
					half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy*0.25,o.Alpha*0.9375)).a;
					clip(alphaRef - 0.01);
				#endif

				#ifdef _DEPTHOFFSET_ON
					outputDepth = IN.pos.z;
				#endif

				SHADOW_CASTER_FRAGMENT(IN)
			}
			ENDCG
		}
		
	}
	CustomEditor "ASEMaterialInspector"
	
	Fallback Off
}
/*ASEBEGIN
Version=19603
Node;AmplifyShaderEditor.RangedFloatNode;9;-4368,768;Inherit;False;InstancedProperty;_FrameRate;_FrameRate;3;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;255;-4368,624;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;14;-4048,880;Inherit;False;Constant;_Int0;Int 0;3;0;Create;True;0;0;0;False;0;False;1;0;False;0;1;INT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;-4096,624;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;12;-4112,768;Inherit;False;InstancedProperty;_AnimFrameCount;_AnimFrameCount;4;0;Create;True;0;0;0;False;0;False;0;0;False;0;1;INT;0
Node;AmplifyShaderEditor.FloorOpNode;10;-3840,624;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;13;-3872,768;Inherit;False;2;0;INT;0;False;1;INT;0;False;1;INT;0
Node;AmplifyShaderEditor.SimpleRemainderNode;11;-3648,624;Inherit;False;2;0;FLOAT;0;False;1;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-3648,896;Inherit;False;Constant;_Float0;Float 0;3;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;22;-3888,1024;Inherit;True;Property;_AnimTex;_AnimTex;2;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.IntNode;16;-3680,784;Inherit;False;InstancedProperty;_StartIndex;_StartIndex;5;0;Create;True;0;0;0;False;0;False;0;0;False;0;1;INT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;17;-3392,704;Inherit;False;3;3;0;FLOAT;0;False;1;INT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexelSizeNode;20;-3456,912;Inherit;False;-1;1;0;SAMPLER2D;;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BlendIndicesNode;23;-2992,352;Inherit;False;0;5;FLOAT4;0;UINT;1;UINT;2;UINT;3;UINT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;264;-2784,352;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.BlendWeightsNode;220;-2992,160;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;19;-3200,880;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;265;-2784,160;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.PosVertexDataNode;322;-2192,160;Inherit;False;1;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CustomExpressionNode;329;-2432,720;Inherit;False;// 计算纹理坐标$                float vIndex0 = (boneIndex * 4 + 0.5) * _AnimTex_TexelSize.x@$                float vIndex1 = (boneIndex * 4 + 1.5) * _AnimTex_TexelSize.x@$                float vIndex2 = (boneIndex * 4 + 2.5) * _AnimTex_TexelSize.x@$                float vIndex3 = (boneIndex * 4 + 3.5) * _AnimTex_TexelSize.x@$$                // 从动画贴图中读取骨骼矩阵$                float4 boneMatrixRow0 = tex2Dlod(_AnimTex, float4(vIndex0, texFrame, 0, 0))@$                float4 boneMatrixRow1 = tex2Dlod(_AnimTex, float4(vIndex1, texFrame, 0, 0))@$                float4 boneMatrixRow2 = tex2Dlod(_AnimTex, float4(vIndex2, texFrame, 0, 0))@$                float4 boneMatrixRow3 = tex2Dlod(_AnimTex, float4(vIndex3, texFrame, 0, 0))@$$                float4x4 boneMatrix = float4x4(boneMatrixRow0, boneMatrixRow1, boneMatrixRow2, boneMatrixRow3)@$                return boneMatrix@;6;Create;2;True;boneIndex;INT;0;In;;Inherit;False;True;texFrame;FLOAT;0;In;;Inherit;False;GetBoneMatrix;False;True;0;;False;2;0;INT;0;False;1;FLOAT;0;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.CustomExpressionNode;330;-2432,880;Inherit;False;// 计算纹理坐标$                float vIndex0 = (boneIndex * 4 + 0.5) * _AnimTex_TexelSize.x@$                float vIndex1 = (boneIndex * 4 + 1.5) * _AnimTex_TexelSize.x@$                float vIndex2 = (boneIndex * 4 + 2.5) * _AnimTex_TexelSize.x@$                float vIndex3 = (boneIndex * 4 + 3.5) * _AnimTex_TexelSize.x@$$                // 从动画贴图中读取骨骼矩阵$                float4 boneMatrixRow0 = tex2Dlod(_AnimTex, float4(vIndex0, texFrame, 0, 0))@$                float4 boneMatrixRow1 = tex2Dlod(_AnimTex, float4(vIndex1, texFrame, 0, 0))@$                float4 boneMatrixRow2 = tex2Dlod(_AnimTex, float4(vIndex2, texFrame, 0, 0))@$                float4 boneMatrixRow3 = tex2Dlod(_AnimTex, float4(vIndex3, texFrame, 0, 0))@$$                float4x4 boneMatrix = float4x4(boneMatrixRow0, boneMatrixRow1, boneMatrixRow2, boneMatrixRow3)@$                return boneMatrix@;6;Create;2;True;boneIndex;INT;0;In;;Inherit;False;True;texFrame;FLOAT;0;In;;Inherit;False;GetBoneMatrix;False;True;1;318;;False;2;0;INT;0;False;1;FLOAT;0;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.CustomExpressionNode;331;-2432,1072;Inherit;False;// 计算纹理坐标$                float vIndex0 = (boneIndex * 4 + 0.5) * _AnimTex_TexelSize.x@$                float vIndex1 = (boneIndex * 4 + 1.5) * _AnimTex_TexelSize.x@$                float vIndex2 = (boneIndex * 4 + 2.5) * _AnimTex_TexelSize.x@$                float vIndex3 = (boneIndex * 4 + 3.5) * _AnimTex_TexelSize.x@$$                // 从动画贴图中读取骨骼矩阵$                float4 boneMatrixRow0 = tex2Dlod(_AnimTex, float4(vIndex0, texFrame, 0, 0))@$                float4 boneMatrixRow1 = tex2Dlod(_AnimTex, float4(vIndex1, texFrame, 0, 0))@$                float4 boneMatrixRow2 = tex2Dlod(_AnimTex, float4(vIndex2, texFrame, 0, 0))@$                float4 boneMatrixRow3 = tex2Dlod(_AnimTex, float4(vIndex3, texFrame, 0, 0))@$$                float4x4 boneMatrix = float4x4(boneMatrixRow0, boneMatrixRow1, boneMatrixRow2, boneMatrixRow3)@$                return boneMatrix@;6;Create;2;True;boneIndex;INT;0;In;;Inherit;False;True;texFrame;FLOAT;0;In;;Inherit;False;GetBoneMatrix;False;True;0;;False;2;0;INT;0;False;1;FLOAT;0;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.CustomExpressionNode;318;-2432,528;Inherit;False;// 计算纹理坐标$                float vIndex0 = (boneIndex * 4 + 0.5) * _AnimTex_TexelSize.x@$                float vIndex1 = (boneIndex * 4 + 1.5) * _AnimTex_TexelSize.x@$                float vIndex2 = (boneIndex * 4 + 2.5) * _AnimTex_TexelSize.x@$                float vIndex3 = (boneIndex * 4 + 3.5) * _AnimTex_TexelSize.x@$$                // 从动画贴图中读取骨骼矩阵$                float4 boneMatrixRow0 = tex2Dlod(_AnimTex, float4(vIndex0, texFrame, 0, 0))@$                float4 boneMatrixRow1 = tex2Dlod(_AnimTex, float4(vIndex1, texFrame, 0, 0))@$                float4 boneMatrixRow2 = tex2Dlod(_AnimTex, float4(vIndex2, texFrame, 0, 0))@$                float4 boneMatrixRow3 = tex2Dlod(_AnimTex, float4(vIndex3, texFrame, 0, 0))@$$                float4x4 boneMatrix = float4x4(boneMatrixRow0, boneMatrixRow1, boneMatrixRow2, boneMatrixRow3)@$                return boneMatrix@;6;Create;2;True;boneIndex;INT;0;In;;Inherit;False;True;texFrame;FLOAT;0;In;;Inherit;False;GetBoneMatrix;False;True;0;;False;2;0;INT;0;False;1;FLOAT;0;False;1;FLOAT4x4;0
Node;AmplifyShaderEditor.NormalVertexDataNode;336;-2432,1360;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CustomExpressionNode;320;-1776,512;Inherit;False;  float4 position = mul(boneMatrix,vertex) * boneWeight@$                return position@;4;Create;3;True;vertex;FLOAT4;0,0,0,0;In;;Inherit;False;True;boneMatrix;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;In;;Inherit;False;True;boneWeight;FLOAT;0;In;;Inherit;False;CalcPosition;False;True;0;;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CustomExpressionNode;326;-1776,864;Inherit;False;  float4 position = mul(boneMatrix,vertex) * boneWeight@$                return position@;4;Create;3;True;vertex;FLOAT4;0,0,0,0;In;;Inherit;False;True;boneMatrix;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;In;;Inherit;False;True;boneWeight;FLOAT;0;In;;Inherit;False;CalcPosition;False;True;0;;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CustomExpressionNode;328;-1776,1056;Inherit;False;  float4 position = mul(boneMatrix,vertex) * boneWeight@$                return position@;4;Create;3;True;vertex;FLOAT4;0,0,0,0;In;;Inherit;False;True;boneMatrix;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;In;;Inherit;False;True;boneWeight;FLOAT;0;In;;Inherit;False;CalcPosition;False;True;0;;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CustomExpressionNode;324;-1776,704;Inherit;False;  float4 position = mul(boneMatrix,vertex) * boneWeight@$                return position@;4;Create;3;True;vertex;FLOAT4;0,0,0,0;In;;Inherit;False;True;boneMatrix;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;In;;Inherit;False;True;boneWeight;FLOAT;0;In;;Inherit;False;CalcPosition;False;True;0;;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CustomExpressionNode;335;-1792,1376;Inherit;False;float3 newNormal = mul((float3x3)boneMatrix, normal) * boneWeight@$                return newNormal@;3;Create;3;True;normal;FLOAT3;0,0,0;In;;Inherit;False;True;boneMatrix;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;In;;Inherit;False;True;boneWeight;FLOAT;0;In;;Inherit;False;CalcNormal;False;True;0;;False;3;0;FLOAT3;0,0,0;False;1;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;338;-1792,1536;Inherit;False;float3 newNormal = mul((float3x3)boneMatrix, normal) * boneWeight@$                return newNormal@;3;Create;3;True;normal;FLOAT3;0,0,0;In;;Inherit;False;True;boneMatrix;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;In;;Inherit;False;True;boneWeight;FLOAT;0;In;;Inherit;False;CalcNormal;False;True;0;;False;3;0;FLOAT3;0,0,0;False;1;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;339;-1792,1696;Inherit;False;float3 newNormal = mul((float3x3)boneMatrix, normal) * boneWeight@$                return newNormal@;3;Create;3;True;normal;FLOAT3;0,0,0;In;;Inherit;False;True;boneMatrix;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;In;;Inherit;False;True;boneWeight;FLOAT;0;In;;Inherit;False;CalcNormal;False;True;0;;False;3;0;FLOAT3;0,0,0;False;1;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;340;-1792,1856;Inherit;False;float3 newNormal = mul((float3x3)boneMatrix, normal) * boneWeight@$                return newNormal@;3;Create;3;True;normal;FLOAT3;0,0,0;In;;Inherit;False;True;boneMatrix;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;In;;Inherit;False;True;boneWeight;FLOAT;0;In;;Inherit;False;CalcNormal;False;True;0;;False;3;0;FLOAT3;0,0,0;False;1;FLOAT4x4;1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;310;-1248,784;Inherit;False;4;4;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TexturePropertyNode;228;-1680,-592;Inherit;True;Property;_MainTex;_MainTex;0;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;231;-1424,-592;Inherit;True;Property;_TextureSample0;Texture Sample 0;5;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;230;-1040,-592;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;229;-1360,-368;Inherit;False;InstancedProperty;_Color;_Color;1;0;Create;True;0;0;0;False;0;False;1,1,1,1;0,0,0,0;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleAddOpNode;337;-1237.951,1382.595;Inherit;False;4;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;312;-672,-352;Float;False;False;-1;2;ASEMaterialInspector;0;4;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;ExtraPrePass;0;0;ExtraPrePass;6;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;False;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;314;-336,-384;Float;False;False;-1;2;ASEMaterialInspector;0;4;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;ForwardAdd;0;2;ForwardAdd;0;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;False;0;False;True;4;1;False;;1;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;True;1;LightMode=ForwardAdd;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;315;-336,-384;Float;False;False;-1;2;ASEMaterialInspector;0;4;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;Deferred;0;3;Deferred;0;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Deferred;True;2;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;316;-336,-384;Float;False;False;-1;2;ASEMaterialInspector;0;4;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;Meta;0;4;Meta;0;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;317;-336,-384;Float;False;False;-1;2;ASEMaterialInspector;0;4;New Amplify Shader;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;ShadowCaster;0;5;ShadowCaster;0;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;313;-672,-352;Float;False;True;-1;2;ASEMaterialInspector;0;4;GPUAnimation/GPUBoneAnimationLit-BuiltIn;ed95fe726fd7b4644bb42f4d1ddd2bcd;True;ForwardBase;0;1;ForwardBase;18;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;False;True;3;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;DisableBatching=False=DisableBatching;True;2;False;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;40;Workflow,InvertActionOnDeselection;1;0;Surface;0;0;  Blend;0;0;  Refraction Model;0;0;  Dither Shadows;1;0;Two Sided;1;0;Deferred Pass;1;0;Transmission;0;0;  Transmission Shadow;0.5,False,;0;Translucency;0;0;  Translucency Strength;1,False,;0;  Normal Distortion;0.5,False,;0;  Scattering;2,False,;0;  Direct;0.9,False,;0;  Ambient;0.1,False,;0;  Shadow;0.5,False,;0;Cast Shadows;1;0;  Use Shadow Threshold;0;0;Receive Shadows;1;0;GPU Instancing;1;0;LOD CrossFade;1;0;Built-in Fog;1;0;Ambient Light;1;0;Meta Pass;1;0;Add Pass;1;0;Override Baked GI;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Fwd Specular Highlights Toggle;0;0;Fwd Reflections Toggle;0;0;Disable Batching;0;638647769310070702;Vertex Position,InvertActionOnDeselection;0;638647749357410888;0;6;False;True;True;True;True;True;False;;False;0
WireConnection;8;0;255;0
WireConnection;8;1;9;0
WireConnection;10;0;8;0
WireConnection;13;0;12;0
WireConnection;13;1;14;0
WireConnection;11;0;10;0
WireConnection;11;1;13;0
WireConnection;17;0;11;0
WireConnection;17;1;16;0
WireConnection;17;2;18;0
WireConnection;20;0;22;0
WireConnection;264;0;23;0
WireConnection;19;0;17;0
WireConnection;19;1;20;2
WireConnection;265;0;220;0
WireConnection;329;0;264;1
WireConnection;329;1;19;0
WireConnection;330;0;264;2
WireConnection;330;1;19;0
WireConnection;331;0;264;3
WireConnection;331;1;19;0
WireConnection;318;0;264;0
WireConnection;318;1;19;0
WireConnection;320;0;322;0
WireConnection;320;1;318;0
WireConnection;320;2;265;0
WireConnection;326;0;322;0
WireConnection;326;1;330;0
WireConnection;326;2;265;2
WireConnection;328;0;322;0
WireConnection;328;1;331;0
WireConnection;328;2;265;3
WireConnection;324;0;322;0
WireConnection;324;1;329;0
WireConnection;324;2;265;1
WireConnection;335;0;336;0
WireConnection;335;1;318;0
WireConnection;335;2;265;0
WireConnection;338;0;336;0
WireConnection;338;1;329;0
WireConnection;338;2;265;1
WireConnection;339;0;336;0
WireConnection;339;1;330;0
WireConnection;339;2;265;2
WireConnection;340;0;336;0
WireConnection;340;1;331;0
WireConnection;340;2;265;3
WireConnection;310;0;320;0
WireConnection;310;1;324;0
WireConnection;310;2;326;0
WireConnection;310;3;328;0
WireConnection;231;0;228;0
WireConnection;230;0;231;0
WireConnection;230;1;229;0
WireConnection;337;0;335;0
WireConnection;337;1;338;0
WireConnection;337;2;339;0
WireConnection;337;3;340;0
WireConnection;313;0;230;0
WireConnection;313;15;310;0
WireConnection;313;16;337;0
ASEEND*/
//CHKSM=F9E03E2069E8A0EBB9B6ADF58D76D6ED325D1719