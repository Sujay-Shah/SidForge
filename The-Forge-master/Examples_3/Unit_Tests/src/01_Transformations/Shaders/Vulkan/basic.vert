#version 450 core

/*
 * Copyright (c) 2018-2019 Confetti Interactive Inc.
 * 
 * This file is part of The-Forge
 * (see https://github.com/ConfettiFX/The-Forge).
 * 
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
*/


// Shader for simple shading with a point light
// for planets in Unit Test 12 - Transformations

#define MAX_PLANETS 20

layout(location = 0) in vec4 Position;
layout(location = 1) in vec4 Normal;

layout(location = 0) out vec4 Color;

layout (std140, set=0, binding=0) uniform uniformBlock {
	uniform mat4 mvp;
    uniform mat4 toWorld[MAX_PLANETS];
    uniform vec4 color[MAX_PLANETS];

	uniform float animationSpeed;
	uniform float amplitude;
	uniform float frequency;

    // Point Light Information
    uniform vec4 lightPositiontime;
    uniform vec3 lightColor;

};

void vert(inout vec4 data, inout vec3 normal)
{
	float _Amplitude = 0.4;
	float _Frequency = 2.0;
	float pi = 3.14;
	float radius = 1.0;

	normalize(normal);

	float u = atan(normal.x, normal.y);
	float v = acos(normal.z);
	vec2 uv = vec2(u/ 2 * pi, v / pi);

	vec3 tangent;
	tangent.x = -radius * cos(u) * sin(v);
	tangent.y = 0;
	tangent.z = radius * cos(u) * cos(v);

	normalize(tangent);

	vec3 bitangent;
	bitangent = cross(tangent, normal.xyz);
	normalize(bitangent);

    vec4 modifiedPos = data;
    modifiedPos.y += sin(data.x * frequency + lightPositiontime.w * animationSpeed) * amplitude;
            
    vec3 posPlusTangent = data.xyz + tangent.xyz * 0.01;
    posPlusTangent.y += sin(posPlusTangent.x * frequency + lightPositiontime.w * animationSpeed) * amplitude;

    vec3 posPlusBitangent = data.xyz + bitangent * 0.01;
    posPlusBitangent.y += sin(posPlusBitangent.x * frequency + lightPositiontime.w * animationSpeed) * amplitude;

    vec3 modifiedTangent = posPlusTangent - modifiedPos.xyz;
    vec3 modifiedBitangent = posPlusBitangent - modifiedPos.xyz;

    vec3 modifiedNormal = cross(modifiedTangent, modifiedBitangent);

    normal = normalize(modifiedNormal);
    data = modifiedPos;
}

void main ()
{
	vec4 data = Position;
	vec4 norm = Normal;
	vert(data, norm.xyz);

	mat4 tempMat = mvp * toWorld[gl_InstanceIndex];

	gl_Position = tempMat * vec4(data.xyz , 1.0f);
	
	vec4 normal = normalize(toWorld[gl_InstanceIndex] * vec4(Normal.xyz, 0.0f));
	vec4 pos = toWorld[gl_InstanceIndex] * vec4(Position.xyz, 1.0f);
	
	float lightIntensity = 1.0f;
    float quadraticCoeff = 1.2;
    float ambientCoeff = 0.4;
	
	vec3 lightDir;

    if (color[gl_InstanceIndex].w == 0) // Special case for Sun, so that it is lit from its top
        lightDir = vec3(0.0f, 1.0f, 0.0f);
    else
        lightDir = normalize(lightPositiontime.xyz - pos.xyz);
	
    float distance = length(lightDir);
    float attenuation = 1.0 / (quadraticCoeff * distance * distance);
    float intensity = lightIntensity * attenuation;

    vec3 baseColor = color[gl_InstanceIndex].xyz;
    vec3 blendedColor = lightColor * baseColor * lightIntensity;
    vec3 diffuse = blendedColor * max(dot(normal.xyz, lightDir), 0.0);
    vec3 ambient = baseColor * ambientCoeff;
    Color = vec4(diffuse + ambient, 1.0);
}
