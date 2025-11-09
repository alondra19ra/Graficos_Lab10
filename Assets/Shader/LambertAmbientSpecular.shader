Shader "Unlit/LambertAmbientSpecular"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color("Tint Color", Color) = (1,1,1,1)
        _MySpecColor("Specular Color", Color) = (1,1,1,1)
        _Shininess("Shininess", Range(1,128)) = 16
        _AmbientStrength("Ambient Strength", Range(0,1)) = 0.2
        _GlossIntensity("Specular Intensity", Range(0,5)) = 1.0
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

            // Incluimos las librerías correctas del URP
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
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float4 _MySpecColor;
            float _Shininess;
            float _AmbientStrength;
            float _GlossIntensity;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.worldNormal = normalize(TransformObjectToWorldNormal(v.normal));
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                // Obtener la luz principal del URP
                Light mainLight = GetMainLight();
                float3 L = normalize(mainLight.direction);
                float3 N = normalize(i.worldNormal);
                float3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

                // --- Difusa Lambert ---
                float NdotL = saturate(dot(N, -L));
                float3 diffuse = albedo * mainLight.color.rgb * NdotL;

                // --- Luz Ambiental ---
                float3 ambient = albedo * _AmbientStrength;

                // --- Especular tipo Phong ---
                float3 R = reflect(L, N);
                float RdotV = saturate(dot(R, V));
                float spec = pow(RdotV, _Shininess) * _GlossIntensity;
                float3 specular = _MySpecColor.rgb * spec * mainLight.color.rgb;

                // --- Color Final ---
                float3 finalColor = diffuse + ambient + specular;

                return float4(finalColor, 1.0);
            }

            ENDHLSL
        }
        }
}
