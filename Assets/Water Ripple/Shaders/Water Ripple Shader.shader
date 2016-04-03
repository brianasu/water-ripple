Shader "Hidden/Water Ripple/Render"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "" {}
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	struct v2f
	{
		float4 pos : POSITION;
		float2 uv : TEXCOORD0;
	};
	
	struct v2fMultiTap
	{
		float4 pos : POSITION;
		float2 uv[5] : TEXCOORD0;
	};


	sampler2D _PrevTex;
	sampler2D _MainTex;
	float4 _MainTex_TexelSize;

	float _DropSize;
	float _Damping;

	float4 _MousePos;

	v2f vert(appdata_img v)
	{
		v2f o;

		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

		o.uv = v.texcoord.xy;

		return o;
	}
	
	v2fMultiTap vertMultiTap(appdata_img v)
	{
		v2fMultiTap o;

		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

		float3 size = float3(_MainTex_TexelSize.x, -_MainTex_TexelSize.x, 0);

		o.uv[0] = v.texcoord.xy;
		o.uv[1] = v.texcoord.xy + size.xz;
		o.uv[2] = v.texcoord.xy + size.yz;
		o.uv[3] = v.texcoord.xy + size.zx;
		o.uv[4] = v.texcoord.xy + size.zy;

	

		return o;
	}

	fixed4 frag(v2f i) : COLOR
	{
		fixed orig = (tex2D(_MainTex, i.uv).r - 0.5) * 2.0;
		float newVal = orig + step(1 - _DropSize, 1 - length(_MousePos.xy - i.uv)) * 0.5;
		return (newVal / 2.0) + 0.5;
	}

	fixed4 fragPropogate(v2fMultiTap i) : COLOR
	{
		float sample = (tex2D(_MainTex, i.uv[1]).r - 0.5) * 2;
		sample += (tex2D(_MainTex, i.uv[2]).r - 0.5) * 2;
		sample += (tex2D(_MainTex, i.uv[3]).r - 0.5) * 2;
		sample += (tex2D(_MainTex, i.uv[4]).r - 0.5) * 2;
		sample /= 2.0;

		float newValue = sample - ((tex2D(_PrevTex, i.uv[0]).r - 0.5) * 2);

		float dampedValue = newValue * _Damping;
		
		return (dampedValue / 2.0) + 0.5;
	}

	ENDCG

Subshader {
	Pass {
		ZTest Always Cull Off ZWrite Off
		Fog { Mode off }
		Blend Off

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		ENDCG
	}

	Pass {
		ZTest Always Cull Off ZWrite Off
		Fog { Mode off }
		Blend Off

		CGPROGRAM
		#pragma vertex vertMultiTap
		#pragma fragment fragPropogate
		ENDCG
	}
}

Fallback off

} // shader