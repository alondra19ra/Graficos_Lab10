Shader "Custom/Flag_LambertAmbientSpecular"
{
    Properties
    {
        _MainTex("Flag Texture", 2D) = "white" {}
        _Color("Tint Color", Color) = (1,1,1,1)
        _AmbientColor("Ambient Color", Color) = (0.3,0.3,0.3,1)
        _AmbientStrength("Ambient Strength", Range(0,1)) = 0.4
        _SpecColor("Specular Color", Color) = (1,1,1,1)
        _SpecPower("Specular Power", Range(1,64)) = 16
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
                float4 _AmbientColor;
                float _AmbientStrength;
                float4 _SpecColor;
                float _SpecPower;

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
                    // Muestra la textura correctamente en URP
                    float3 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv).rgb * _Color.rgb;

                    float3 N = normalize(i.worldNormal);
                    Light mainLight = GetMainLight();
                    float3 L = normalize(mainLight.direction);
                    float3 lightColor = mainLight.color.rgb;

                    float3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

                    // Luz difusa (Lambert)
                    float NdotL = saturate(dot(N, -L));
                    float3 diffuse = texColor * lightColor * NdotL;

                    // Luz especular (Blinn o Phong)
                    float3 R = reflect(L, N);
                    float spec = pow(saturate(dot(V, R)), _SpecPower);
                    float3 specular = _SpecColor.rgb * spec;

                    // Luz ambiental
                    float3 ambient = _AmbientColor.rgb * _AmbientStrength;

                    float3 finalColor = texColor * (ambient + diffuse) + specular;

                    return float4(finalColor, 1.0);
                }

                ENDHLSL
            }
        }
}
