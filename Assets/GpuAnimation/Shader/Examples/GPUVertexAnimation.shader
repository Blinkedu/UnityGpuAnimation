Shader "GPUAnimation/GPUVertexAnimation"
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
                float2 uv : TEXCOORD0;
                uint vid : SV_VERTEXID;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
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
                uint currentFrame = (uint)floor(_Time.y * _FrameRate) % (uint)(_AnimFrameCount - 1);

                // +0.5 将采样点移动到纹素的中心，（不加0.5表示你正采样纹理中对应纹素的左下角位置）
                float x = (v.vid + 0.5) / _AnimTex_TexelSize.z;
                float y = ((uint)_StartIndex + currentFrame + 0.5) /_AnimTex_TexelSize.w;

                float4 uvAnim = float4(x, y, 0, 0);
                float3 pos = tex2Dlod(_AnimTex, uvAnim).rgb;

                v.vertex = float4(pos.xyz, v.vertex.w);
                o.vertex = UnityObjectToClipPos(v.vertex);
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
