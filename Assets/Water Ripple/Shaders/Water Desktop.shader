Shader "Custom/Water Ripple/Desktop" 
{	
	Properties 
	{
		_Color ("Color Tint", COLOR) = (1, 1, 1, 1)
		_WaterTex ("Diffuse", 2D) = "white" {}
		
		//_MainTex ("Base (RGB)", 2D) = "black" {}
		
		_Height ("Splash Height", Range(0, 1)) = 0.1		
		_SpecColor ("Specular Color", COLOR) = (1, 1, 1 ,1)
		_Cube ("Cubemap", CUBE) = "" {}
	}
	
	
	Subshader 
	{
		Tags { "IgnoreProjector"="True" "Queue"="Transparent"}
 
 		
        GrabPass 
        {
            Name "WaterGrab"
        }
 		
 		//Blend SrcAlpha OneMinusSrcAlpha
 		//ZWrite Off
 		
		CGPROGRAM
		#pragma surface surf BlinnPhong vertex:vert noshadow
		#pragma target 3.0
		//#pragma glsl
 		#include "UnityCG.cginc"
	
		float _Height;
		float4 _LightDir;

		sampler2D _MainTex;
		float4 _MainTex_TexelSize;
		
		sampler2D _WaterTex;
		samplerCUBE _Cube;
		
		float4 _Color;
		
		struct Input 
		{
			float2 uv_MainTex;
			float2 uv_WaterTex;
			float3 worldRefl;
			float3 waterNormal;
			float4 screenPos;
          	INTERNAL_DATA
		};

		void vert(inout appdata_full v, out Input o) 
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);

			float3 texSize = float3(_MainTex_TexelSize.x, -_MainTex_TexelSize.x, 0);
	 		float4 uv = float4(v.texcoord.xy, 0, 0);
	 		
			float samples = tex2Dlod(_MainTex, float4(v.texcoord.xy, 0, 0)).r;
			samples += tex2Dlod(_MainTex, uv + texSize.xzzz).r;
			samples += tex2Dlod(_MainTex, uv + texSize.yzzz).r;
			samples += tex2Dlod(_MainTex, uv + texSize.zxzz).r;
			samples += tex2Dlod(_MainTex, uv + texSize.zyzz).r;
			samples /= 5;
			v.vertex.y += samples * _Height;
			
			fixed right		= tex2Dlod(_MainTex, uv + texSize.xzzz).r;
			fixed left		= tex2Dlod(_MainTex, uv + texSize.yzzz).r;
			fixed top		= tex2Dlod(_MainTex, uv + texSize.zxzz).r;
			fixed bottom	= tex2Dlod(_MainTex, uv + texSize.zyzz).r;
			
            float3 va = normalize(float3(1, left - right, 0));
            float3 vb = normalize(float3(0, bottom - top, 1));
			
			v.normal = normalize(float3(1, 1, 1));
	    	v.normal.xz = cross(va, vb).xz * (_Height);
	    	v.normal = normalize(v.normal);
	    	
	    	o.waterNormal = v.normal;
		}

		sampler2D _GrabTexture;
		void surf(Input IN, inout SurfaceOutput o)
		{
			float4 screenPos = IN.screenPos;
			screenPos.xy += (IN.waterNormal.xz) / IN.screenPos.w;
		
			float4 col = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(screenPos)) * _Color;
			o.Albedo = col.rgb;
			o.Alpha = col.a;
			o.Gloss = 0.5;
			o.Specular = 0.5;
			o.Emission = texCUBE (_Cube, WorldReflectionVector (IN, o.Normal)).rgb * 0.5;
		}
		ENDCG
	}
	Fallback "Specular"
} // shader