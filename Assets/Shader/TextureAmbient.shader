Shader "Unlit/TextureAmbient"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Tint Color", Color) = (1,1,1,1)
        _AmbientColor("Ambient Light Color", Color) = (0.3, 0.3, 0.3, 1)
        _AmbientStrength("Ambient Strength", Range(0, 1)) = 0.5
    }

        SubShader
        {
            Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
            LOD 100

            Pass
            {
                Tags { "LightMode" = "UniversalForward" }

                HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag

            // Librerías base del URP
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float4 _AmbientColor;
            float _AmbientStrength;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // Color base (textura * tinte)
                float3 texColor = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                // Luz ambiental (uniforme)
                float3 ambientLight = _AmbientColor.rgb * _AmbientStrength;

                // Color final
                float3 finalColor = texColor * (ambientLight + 1 - _AmbientStrength);

                return float4(finalColor, 1.0);
            }

            ENDHLSL
        }
        }
}
