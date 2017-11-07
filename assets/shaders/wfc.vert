#version 410

in vec3 vertices;
in vec3 normals;
in vec4 vertex_color;


uniform mat4 projection, view, model;

uniform uint objectid;
out vec3 o_vertex;
out vec3 o_normal;
out vec4 o_color;
out vec3 eyeposition;

void main()
{
    o_color = vertex_color;
    mat4 viewmodel = view*model;
    vec4 position_camspace = viewmodel * vec4(vertices,  1);
    o_normal               = vec3(viewmodel* vec4(normals,0));
    
    o_vertex               = position_camspace.xyz;
    o_color                = vertex_color;
    gl_Position            = projection * position_camspace;
}

