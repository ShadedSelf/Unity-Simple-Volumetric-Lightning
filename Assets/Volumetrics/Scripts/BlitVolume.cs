using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BlitVolume : MonoBehaviour
{
    private Material mat;

    void OnEnable()
    {
        mat = new Material(Shader.Find("Hidden/BlitVolume"));
    }

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        Graphics.Blit(src, dst, mat);
    }
}

