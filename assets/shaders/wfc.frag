#version 410


uniform vec3 light[4];
uniform vec3 eyeposition;

in vec3 o_normal;
in vec3 o_vertex;
in vec4 o_color;

out vec4 color;

void main(){
    float amb_intensity = 0.8;
    float diffuse_intensity = 0.6;
    float specular_power = 0.6;
    float specular_intensity = 1.0;
    vec3 light_color = light[0];
    vec3 light_position = normalize(light[3] - o_vertex); 
    vec4 ambient_color = vec4(light_color * amb_intensity,1.0f);
    vec3 normal = normalize(o_normal);
    float diffuse_factor = dot(normal,light_position);

    vec4 diffuse_color = vec4(light_color,1.0f) *  diffuse_intensity * diffuse_factor;
    vec4 specular_color = vec4(0.0f);
    vec3 vertex_to_eye = normalize(eyeposition-o_vertex);
    vec3 light_reflect = normalize(reflect(-light_position,normal));
    float specular_factor = dot(vertex_to_eye,light_reflect);
    if(specular_factor>0){
        specular_factor = pow(specular_factor,specular_power);
        specular_color = vec4(light_color*specular_intensity*specular_factor,1.0f);
    }
    color = o_color*(ambient_color);
}

