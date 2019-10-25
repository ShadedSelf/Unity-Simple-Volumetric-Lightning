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

			float3 rand(float3 p)
			{
				p = float3(dot(p, float3(127.1, 311.7, 475.6)), dot(p, float3(269.5, 676.5, 475.6)), dot(p, float3(318.5, 183.3, 713.4)));
				return frac(sin(p) * 43758.5453);
			}

			int flattenIndex(int3 index, int3 dim)
			{
				return index.x + dim.x * (index.y + dim.y * index.z);
			}

						
			sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			sampler3D _Volume;

			StructuredBuffer<float> _Test;

			float _POW;
			int3 _Res;

			float trinterpolate(float a, float b, float c, float t)
			{
				if (t < 0.5)
					return lerp(a, b, t + 0.5);
				return lerp(b, c, t - 0.5);
			}

			float sampleSlice(float3 uv, int3 index)
			{
				float me = _Test[flattenIndex(index, _Res)];

				float u = _Test[flattenIndex(clamp(index + int3(0, 1, 0), 0, _Res - 1), _Res)];
				float r = _Test[flattenIndex(clamp(index + int3(1, 0, 0), 0, _Res - 1), _Res)];
				float d = _Test[flattenIndex(clamp(index - int3(0, 1, 0), 0, _Res - 1), _Res)];
				float l = _Test[flattenIndex(clamp(index - int3(1, 0, 0), 0, _Res - 1), _Res)];

				float ul = _Test[flattenIndex(clamp(index + int3(-1, 1, 0), 0, _Res - 1), _Res)];
				float ur = _Test[flattenIndex(clamp(index + int3(1, 1, 0), 0, _Res - 1), _Res)];
				float dl = _Test[flattenIndex(clamp(index + int3(-1, -1, 0), 0, _Res - 1), _Res)];
				float dr = _Test[flattenIndex(clamp(index + int3(1, -1, 0), 0, _Res - 1), _Res)];

				float3 fuv = frac(uv * (_Res - 1));
				float top = trinterpolate(ul, u, ur, fuv.x);
				float mid = trinterpolate(l, me, r, fuv.x);
				float bot = trinterpolate(dl, d, dr, fuv.x);
				float total = trinterpolate(bot, mid, top, fuv.y);

				return total;
			}

			float sampleBuffer(float3 uv)
			{
				int3 index = floor(uv * (_Res - 1));

				float back	= sampleSlice(uv, index - int3(0, 0, 1));
				float mid	= sampleSlice(uv, index);
				float front	= sampleSlice(uv, index + int3(0, 0, 1));

				float3 fuv = frac(uv * (_Res - 1));
				return trinterpolate(back, mid, front, fuv.z);
			}

			float4 frag (v2f i) : SV_Target
			{
				float depth = Linear01Depth(tex2D(_CameraDepthTexture, i.uv).r);
				depth = pow(depth, 1 / _POW);

				float3 uvs = (rand(float3(i.uv.xy, depth) * _Time.x) * 2 - .5) * 0.007;
				float col = sampleBuffer(saturate(float3(i.uv, depth) + uvs * 0));

				float4 ac = tex2D(_MainTex, i.uv);
				return  ac + col;
			}
			ENDCG
		}
	}
}
