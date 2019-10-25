using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

//[ExecuteInEditMode]
public class Get : MonoBehaviour
{
    public int resolution = 512;
    public RenderTextureFormat format = RenderTextureFormat.RHalf;
    public RenderTexture shadowMapRT;
    public Mesh quadMesh;
    public ComputeShader cs;

    private Material getMatrixMat;
    private CommandBuffer getMatrixCMD, getShadowMapCMD;
    private ComputeBuffer cb;

    private Light l;

    void OnEnable()
    {
		l = GetComponent<Light>();
        l.RemoveAllCommandBuffers();

		//-- Write lights matrix to buffer: --
        getMatrixMat = new Material(Shader.Find("Hidden/GetMatrix"));
        
		cb = new ComputeBuffer(1, sizeof(float) * 16);
        getMatrixCMD = new CommandBuffer();
        getMatrixCMD.name = "Get Shadow Matrix";

        getMatrixCMD.SetRandomWriteTarget(1, cb);
        getMatrixCMD.DrawMesh(quadMesh, Matrix4x4.identity, getMatrixMat, 0);
        getMatrixCMD.ClearRandomWriteTargets();

        //-- Blit lights depth map to custom rt: --
        shadowMapRT = new RenderTexture(resolution, resolution, 0, format, RenderTextureReadWrite.Linear);
        shadowMapRT.autoGenerateMips = false;
        shadowMapRT.Create();

        getShadowMapCMD = new CommandBuffer();
        getShadowMapCMD.name = "Get Shadow Map";

        RenderTargetIdentifier shadowmap = BuiltinRenderTextureType.CurrentActive;

        getShadowMapCMD.SetShadowSamplingMode(shadowmap, ShadowSamplingMode.RawDepth);
        getShadowMapCMD.Blit(shadowmap, new RenderTargetIdentifier(shadowMapRT));
        //

        l.AddCommandBuffer(LightEvent.BeforeScreenspaceMask, getMatrixCMD);
        l.AddCommandBuffer(LightEvent.AfterShadowMap, getShadowMapCMD);

        Shader.SetGlobalBuffer("_B", cb);
        Shader.SetGlobalTexture("_LightDepthMap", shadowMapRT);

        cs.SetBuffer(0, "_B", cb);
        cs.SetTexture(0, "_LightDepthMap", shadowMapRT);
    }

    void Update()
    {
        cs.SetVector("_LightDir", transform.forward);
    }

    void OnDisable()
    {
        cb.Release();
        getMatrixCMD.Clear();
        getMatrixCMD.Release();
        getShadowMapCMD.Clear();
        getShadowMapCMD.Release();
        l.RemoveAllCommandBuffers();
    }
}