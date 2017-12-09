#version 410


uniform vec3 light[4];
uniform vec3 eyeposition;

in vec3 o_normal;
in vec3 o_vertex;
in vec4 o_color;

out vec4 color;
uniform int pass;

void main(){
    if (pass == 1){
        color = vec4(vec3(o_color.xyz),0*o_color[3]);
    }
    else if (pass==2){
        color = vec4(vec3(o_color.xyz),0.75*o_color[3]);
    }
    else if (pass==3){
        color = vec4(vec3(o_color.xyz), (o_color[3]-0.75*o_color[3])/(1.0-0.75*o_color[3]));
    }
    float amb_intensity = 0.3;
    float diffuse_intensity = 0.2;
    float specular_power = 0.2;
    float specular_intensity = 0.1;
    //vec3 light_color = light[0];
    vec3 light_color = vec3(1.0f,1f,1f);
    vec3 light_position = normalize(vec3(0f,0f,20f) - o_vertex); 
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
    color = color*(ambient_color+diffuse_color+specular_color) ;
    //color = color ;
    //color = color*(ambient_color) ;
    //color = vec4(1.0f,0.0f,0.0f,0.6f);
}

