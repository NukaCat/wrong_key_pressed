#version 330 core
in vec2 tex_coord;

out vec4 FragColor;

uniform sampler2D aTexture;
uniform vec4 aColor;

void main()
{
   vec3 color = texture(aTexture, tex_coord).rgb + aColor.rgb;
   FragColor = vec4(color.rgb, 1.0);
}