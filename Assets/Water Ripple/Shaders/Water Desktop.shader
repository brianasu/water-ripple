Shader "Custom/Water Ripple/Desktop" 
{	
	Properties 
	{
		_Color ("Color Tint", COLOR) = (1, 1, 1, 1)
		_Height ("Splash Height", Range(0, 1)) = 0.1	
		_SpecColor ("Specular Color", COLOR) = (1, 1, 1 ,1)
		_Cube ("Cubemap", CUBE) = "black" {}
		_Fade ("Fade", FLOAT) = 0.1
		
		[HideInInspector] _MainTex ("Wave Map", 2D) = "gray" {}
	}
	
	
	Subshader 
	{
		Tags { "IgnoreProjector" = "True" "Queue" = "Transparent" "RenderType" = "Transparent" }
 		
        GrabPass 
        {
            Name "WaterGrab"
        }
 		
 		//ZWrite Off
 		//Blend SrcAlpha OneMinusSrcAlpha
 		
		CGPROGRAM
		#pragma surface surf BlinnPhong vertex:vert noshadow
		#pragma target 3.0
		//#pragma glsl
 		#include "UnityCG.cginc"
	
		float4 _Color;
		float _Height;

		sampler2D _MainTex;
		float4 _MainTex_TexelSize;
		
		sampler2D _CameraDepthTexture;
		
		samplerCUBE _Cube;
		
		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_WaterTex;
			float3 worldRefl;
			float4 screenPos;
			float depth;
          	INTERNAL_DATA
		};

		void vert(inout appdata_full v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);

			float3 texSize = float3(_MainTex_TexelSize.x, -_MainTex_TexelSize.x, 0);
	 		float4 uv = float4(v.texcoord.xy, 0, 0);
	 		
			
			float samples = tex2Dlod(_MainTex, uv + texSize.xzzz).r * 2 - 1;
			samples += tex2Dlod(_MainTex, uv + texSize.yzzz).r * 2 - 1;
			samples += tex2Dlod(_MainTex, uv + texSize.zxzz).r * 2 - 1;
			samples += tex2Dlod(_MainTex, uv + texSize.zyzz).r * 2 - 1;
			samples  /= 4;
			v.vertex.y += (samples - 0.5) * _Height;
			
			fixed right		= tex2Dlod(_MainTex, uv + texSize.xzzz * 2).r * 2 - 15;
			fixed left		= tex2Dlod(_MainTex, uv + texSize.yzzz * 2).r * 2 - 15;
			fixed top		= tex2Dlod(_MainTex, uv + texSize.zxzz * 2).r * 2 - 15;
			fixed bottom	= tex2Dlod(_MainTex, uv + texSize.zyzz * 2).r * 2 - 15;
			
            float3 va = normalize(float3(1, left - right, 0));
            float3 vb = normalize(float3(0, bottom - top, 1));
			
			v.normal = normalize(float3(1, 1, 1));
	    	v.normal.xz = cross(va, vb).xz;
	    	v.normal = normalize(v.normal);
	    	
	    	o.depth = -mul(UNITY_MATRIX_MV, v.vertex).z * _ProjectionParams.w;
		}

		float _Fade;
		sampler2D _GrabTexture;
		void surf(Input IN, inout SurfaceOutput o)
		{
			float4 screenPos = IN.screenPos;
			#if UNITY_UV_STARTS_AT_TOP 
			screenPos.y = IN.screenPos.w-screenPos.y;
			#endif
			
			screenPos.xy += (o.Normal.xz * _Height) / IN.screenPos.w;
			
		
		
			float depth = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(screenPos)));
			
			//float4 col = lerp(tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(screenPos)), _Color, saturate((depth - IN.depth) * _Fade));
			float4 col = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(screenPos)) * _Color;
			
			o.Albedo = col.rgb;
			o.Alpha = col.a;
			
			o.Gloss = 0.5;
			o.Specular = 0.5;
			o.Emission = texCUBE (_Cube, WorldReflectionVector (IN, o.Normal)).rgb;
		}
		ENDCG
	}
	Fallback "Transparent/Specular"
} // shader