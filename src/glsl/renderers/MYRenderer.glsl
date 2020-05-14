// #package glsl/shaders

// #include ../mixins/unproject.glsl
// #include ../mixins/intersectCube.glsl

// #section MYGenerate/vertex

#version 300 es
precision mediump float;

uniform mat4 uMvpInverseMatrix;

layout(location = 0) in vec2 aPosition;
out vec3 vRayFrom;
out vec3 vRayTo;

@unproject

void main() {
    unproject(aPosition, uMvpInverseMatrix, vRayFrom, vRayTo);
    gl_Position = vec4(aPosition, 0.0, 1.0);
}

// #section MYGenerate/fragment

#version 300 es
precision mediump float;

uniform mediump sampler3D uVolume;
uniform mediump sampler2D uTransferFunction;
uniform vec3 uLight;
uniform float uStepSize;
uniform float uOffset;
uniform float uAlphaCorrection;

in vec3 vRayFrom;
in vec3 vRayTo;
out vec4 oColor;

@intersectCube

void main() {
    // Ray direction
    vec3 rayDirection = vRayTo - vRayFrom;
    // Intersection with bounding box => vec2(tnear, tfar)
    vec2 tbounds = max(intersectCube(vRayFrom, rayDirection), 0.0);
    // euler constant
    float e = 2.7182818284;
    // If tnear intersection is further or equal than tfar intersection
    if (tbounds.x >= tbounds.y) {
        // Set color to black with opacity 1 (max)
        oColor = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        // Starting interpolation point
        vec3 from = mix(vRayFrom, vRayTo, tbounds.x);
        // Ending interpolation point
        vec3 to = mix(vRayFrom, vRayTo, tbounds.y);
        // Length of every step based on distanc between both bounding box intersections
        float rayStepLength = distance(from, to) * uStepSize;
        // Used for interpolation (from = 0, to = 1) increasing by step size
        float t = 0.0;
        // Coordinates of current point in box
        vec3 pos;
        // Values of current point in box
        float val;
        // Used for color of current voxel (on the way)
        vec4 colorSample;
        float lambert;
        // Ray accumulation (sum of all colors and alphas on the way)
        vec4 accumulator = vec4(0.0);
        vec3 light = normalize(uLight);
        // Repeat process between both intersection points (0 < t < 1)
        // and stop if accumulation = 1 (other voxels don't have effect)
        while (t < 1.0 && accumulator.a < 0.99) {
            // Calculate current position in box (based on step)
            pos = mix(from, to, t);
            // Get intensity of current voxel
            val = texture(uVolume, pos).r;
            	
            vec3 grad = texture(uVolume, pos).gba;
            grad /= 255.0;
            grad -= 0.5;
            grad *= 2.0;
            grad *= 255.0;
            float mag = length(grad);
            vec3 normal = normalize(grad);

            lambert = max(dot(normal, light), 0.0);

            // Get color of voxel based on transfer function
            float k = 1.0 - exp(-1.0*mag);
            colorSample = texture(uTransferFunction, vec2(val, 0.5))  * lambert;
            colorSample.a *= rayStepLength * uAlphaCorrection;
            colorSample.rgb *= colorSample.a * mag;
            accumulator += (1.0 - accumulator.a) * colorSample;
            // Increase t by step size
            t += uStepSize;
        }

        // Refine rgb if aplha greater than 1 (max)
        if (accumulator.a > 1.0) {
            // Scales down
            accumulator.rgb /= accumulator.a;
        }


        // Output color vector
        oColor = vec4(accumulator.rgb, 1.0);
    }
}

// #section MYIntegrate/vertex

#version 300 es
precision mediump float;

layout(location = 0) in vec2 aPosition;
out vec2 vPosition;

void main() {
    vPosition = (aPosition + 1.0) * 0.5;
    gl_Position = vec4(aPosition, 0.0, 1.0);
}

// #section MYIntegrate/fragment

#version 300 es
precision mediump float;

uniform mediump sampler2D uAccumulator;
uniform mediump sampler2D uFrame;

in vec2 vPosition;
out vec4 oColor;

void main() {
    oColor = texture(uFrame, vPosition);
}

// #section MYRender/vertex

#version 300 es
precision mediump float;

layout(location = 0) in vec2 aPosition;
out vec2 vPosition;

void main() {
    vPosition = (aPosition + 1.0) * 0.5;
    gl_Position = vec4(aPosition, 0.0, 1.0);
}

// #section MYRender/fragment

#version 300 es
precision mediump float;

uniform mediump sampler2D uAccumulator;

in vec2 vPosition;
out vec4 oColor;

void main() {
    oColor = texture(uAccumulator, vPosition);
}

// #section MYReset/vertex

#version 300 es
precision mediump float;

layout(location = 0) in vec2 aPosition;

void main() {
    gl_Position = vec4(aPosition, 0.0, 1.0);
}

// #section MYReset/fragment

#version 300 es
precision mediump float;

out vec4 oColor;

void main() {
    oColor = vec4(0.0, 0.0, 0.0, 1.0);
}
