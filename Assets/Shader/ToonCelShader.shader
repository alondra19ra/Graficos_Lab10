Shader "Custom/ToonCelShader"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}
        _Color("Tint Color", Color) = (1,1,1,1)
        _ShadowColor("Shadow Color", Color) = (0.2,0.2,0.2,1)
        _ShadeLevels("Shade Levels", Range(1,8)) = 4
        _AmbientColor("Ambient Color", Color) = (0.3,0.3,0.3,1)
    }

        SubShader
        {
            Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
            LOD 200

            Pass
            {
                Tags { "LightMode" = "UniversalForward" }

                HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

                struct appdata
                {
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                    float2 uv : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float2 uv : TEXCOORD0;
                    float3 worldNormal : TEXCOORD1;
                    float3 worldPos : TEXCOORD2;
                };

                TEXTURE2D(_MainTex);
                SAMPLER(sampler_MainTex);
                float4 _MainTex_ST;

                float4 _Color;
                float4 _ShadowColor;
                float _ShadeLevels;
                float4 _AmbientColor;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    o.worldNormal = TransformObjectToWorldNormal(v.normal);
                    o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                    return o;
                }

                half4 frag(v2f i) : SV_Target
                {
                    // Textura base
                    float3 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * _Color.rgb;

                    // Iluminación
                    Light mainLight = GetMainLight();
                    float3 L = normalize(mainLight.direction);
                    float3 N = normalize(i.worldNormal);

                    // Luz difusa (Lambert)
                    float NdotL = saturate(dot(N, -L));

                    // Cuantización (divide la luz en "bandas")
                    float stepValue = floor(NdotL * _ShadeLevels) / (_ShadeLevels - 1);

                    // Interpolación entre sombra y luz
                    float3 diffuseColor = lerp(_ShadowColor.rgb, mainLight.color.rgb, stepValue);

                    // Luz ambiental
                    float3 ambient = _AmbientColor.rgb;

                    float3 finalColor = texColor * (diffuseColor + ambient);

                    return float4(finalColor, 1.0);
                }
                ENDHLSL
            }
        }
}