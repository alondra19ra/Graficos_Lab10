Shader "Custom/MultiTextureMask"
{
    Properties
    {
        _MainTex1("Textura Base 1", 2D) = "white" {}
        _MainTex2("Textura Base 2", 2D) = "white" {}
        _Mask("Máscara (blanco = textura 2)", 2D) = "gray" {}

        _Color("Tint Color", Color) = (1,1,1,1)
        _AmbientColor("Ambient Color", Color) = (0.3,0.3,0.3,1)
        _SpecColor("Specular Color", Color) = (1,1,1,1)
        _SpecPower("Specular Power", Range(8,64)) = 16
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

                TEXTURE2D(_MainTex1);
                SAMPLER(sampler_MainTex1);
                float4 _MainTex1_ST;

                TEXTURE2D(_MainTex2);
                SAMPLER(sampler_MainTex2);
                float4 _MainTex2_ST;

                TEXTURE2D(_Mask);
                SAMPLER(sampler_Mask);
                float4 _Mask_ST;

                float4 _Color;
                float4 _AmbientColor;
                float4 _SpecColor;
                float _SpecPower;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.pos = TransformObjectToHClip(v.vertex.xyz);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex1);
                    o.worldNormal = TransformObjectToWorldNormal(v.normal);
                    o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                    return o;
                }

                half4 frag(v2f i) : SV_Target
                {
                    // --- Texturas base ---
                    float3 tex1 = SAMPLE_TEXTURE2D(_MainTex1, sampler_MainTex1, i.uv).rgb;
                    float3 tex2 = SAMPLE_TEXTURE2D(_MainTex2, sampler_MainTex2, i.uv).rgb;
                    float mask = SAMPLE_TEXTURE2D(_Mask, sampler_Mask, i.uv).r;

                    // --- Mezcla por máscara ---
                    float3 combinedTex = lerp(tex1, tex2, mask) * _Color.rgb;

                    // --- Iluminación ---
                    Light mainLight = GetMainLight();
                    float3 N = normalize(i.worldNormal);
                    float3 L = normalize(-mainLight.direction);
                    float3 V = normalize(GetWorldSpaceViewDir(i.worldPos));
                    float3 R = reflect(-L, N);

                    // Difusa (Lambert)
                    float NdotL = saturate(dot(N, L));
                    float3 diffuse = combinedTex * mainLight.color.rgb * NdotL;

                    // Especular (Phong simple)
                    float spec = pow(saturate(dot(R, V)), _SpecPower);
                    float3 specular = _SpecColor.rgb * spec * mainLight.color.rgb;

                    // Luz ambiental
                    float3 ambient = _AmbientColor.rgb * combinedTex;

                    float3 finalColor = diffuse + specular + ambient;

                    return float4(finalColor, 1.0);
                }
                ENDHLSL
            }
        }
}
