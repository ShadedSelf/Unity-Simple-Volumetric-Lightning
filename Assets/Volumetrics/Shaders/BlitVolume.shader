Shader "Hidden/BlitVolume"
{
	Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert (appdata_base v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}

			int flattenIndex(int3 index, int3 dim)
			{
				return index.x + dim.x * (index.y + dim.y * index.z);
			}

						
			sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			sampler3D _Volume;

			StructuredBuffer<float3> _Test;

			float _POW;
			int3 _Res;

			float trinterpolate(float a, float b, float c, float t)
			{
				if (t < 0.5) return lerp(a, b, t + 0.5);
				return lerp(b, c, t - 0.5);
			}			
			float3 trinterpolate(float3 a, float3 b, float3 c, float t)
			{
				if (t < 0.5) return lerp(a, b, t + 0.5);
				return lerp(b, c, t - 0.5);
			}

			float3 sampleSlice(float3 uv, int3 index)
			{
				float3 me = _Test[flattenIndex(index, _Res)];

				float3 u = _Test[flattenIndex(clamp(index + int3(0, 1, 0), 0, _Res - 1), _Res)];
				float3 r = _Test[flattenIndex(clamp(index + int3(1, 0, 0), 0, _Res - 1), _Res)];
				float3 d = _Test[flattenIndex(clamp(index - int3(0, 1, 0), 0, _Res - 1), _Res)];
				float3 l = _Test[flattenIndex(clamp(index - int3(1, 0, 0), 0, _Res - 1), _Res)];

				float3 ul = _Test[flattenIndex(clamp(index + int3(-1, 1, 0), 0, _Res - 1), _Res)];
				float3 ur = _Test[flattenIndex(clamp(index + int3(1, 1, 0), 0, _Res - 1), _Res)];
				float3 dl = _Test[flattenIndex(clamp(index + int3(-1, -1, 0), 0, _Res - 1), _Res)];
				float3 dr = _Test[flattenIndex(clamp(index + int3(1, -1, 0), 0, _Res - 1), _Res)];

				float3 fuv 		= frac(uv * (_Res - 1));
				float3 top 		= trinterpolate(ul, u, ur, fuv.x);
				float3 mid 		= trinterpolate(l, me, r, fuv.x);
				float3 bot 		= trinterpolate(dl, d, dr, fuv.x);
				float3 total	= trinterpolate(bot, mid, top, fuv.y);

				return total;
			}

			float3 sampleBuffer(float3 uv)
			{
				int3 index = floor(uv * (_Res - 1));

				float3 back		= sampleSlice(uv, index - int3(0, 0, 1));
				float3 mid		= sampleSlice(uv, index);
				float3 front	= sampleSlice(uv, index + int3(0, 0, 1));

				float3 fuv = frac(uv * (_Res - 1));
				return trinterpolate(back, mid, front, fuv.z);
			}

			float4 frag (v2f i) : SV_Target
			{
				float depth = Linear01Depth(tex2D(_CameraDepthTexture, i.uv).r);
				depth = pow(depth, 1 / _POW);

				// float3 uvs = (rand(float3(i.uv.xy, depth) * _Time.x) * 2 - .5) * 0.007;
				float3 col = sampleBuffer(saturate(float3(i.uv, depth)));

				if (depth == 1) //Interesting...
					return float4(col, 1);

				float3 ac = tex2D(_MainTex, i.uv).xyz;
				// ac = 0;
				return  float4(ac + col, 1);
			}
			ENDCG
		}
	}
}
