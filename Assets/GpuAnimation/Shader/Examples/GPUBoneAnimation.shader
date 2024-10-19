Shader "GPUAnimation/GPUBoneAnimation"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _AnimTex ("AnimTex", 2D) = "white" {}
        _FrameRate ("FrameRate", Float) = 30
        _AnimFrameCount("AnimFrameCount", Float) = 30
        _CurrentTime ("CurrentTime", Float) = 0
        _StartIndex("StartIndex", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 boneWeights : BLENDWEIGHTS;
                int4 boneIndices : BLENDINDICES;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _AnimTex;
            float4 _AnimTex_ST;
            float4 _AnimTex_TexelSize;

            float _FrameRate;
            float _AnimFrameCount;
            float _CurrentTime;
            float _StartIndex;

            v2f vert (appdata v)
            {
                v2f o;
                //uint currentFrame = (uint)floor(_CurrentTime * _FrameRate) % (uint)_AnimFrameCount;
                uint frameIndex = (uint)floor(_Time.y * _FrameRate) % (uint)(_AnimFrameCount - 1);

                 // 初始化顶点和法线的最终结果
                float4 finalPosition = float4(0, 0, 0, 0);
                float3 finalNormal = float3(0, 0, 0);

                // 归一化纹理坐标
                float texFrame = ((uint)_StartIndex + frameIndex + 0.5) * _AnimTex_TexelSize.y;

                // 遍历每个骨骼权重（最多4个）
                for (int i = 0; i < 4; i++){
                    // 获取骨骼索引和权重
                    int boneIndex = v.boneIndices[i];
                    float boneWeight = v.boneWeights[i];

                    // 如果权重为0，跳过计算
                    if (boneWeight == 0)
                        continue;

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

                    // 构建骨骼矩阵
                    float4x4 boneMatrix = float4x4(boneMatrixRow0, boneMatrixRow1, boneMatrixRow2, boneMatrixRow3);
                    finalPosition += mul(boneMatrix, v.vertex) * boneWeight;
                    finalNormal += mul((float3x3)boneMatrix, v.normal) * boneWeight;
                } 

                 // 将最终位置和法线传递给输出
                o.vertex = UnityObjectToClipPos(finalPosition);;
                o.normal = normalize(finalNormal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
