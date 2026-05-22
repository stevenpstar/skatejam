// Shader from https://godotshaders.com/shader/fisheye-shader/

shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture;
uniform float fish_intensity : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    vec2 iResolution = vec2(textureSize(screen_texture, 0));
    vec2 uv = UV;
    uv.y = 1.0 - uv.y; // 翻转Y轴
    float aspectRatio = iResolution.x / iResolution.y;
    float strength = fish_intensity * 0.03;
    vec2 intensity = vec2(
        strength * aspectRatio,
        strength * aspectRatio
    );

    vec2 coords = uv;
    coords = (coords - 0.5) * 2.0;

    vec2 realCoordOffs;
    realCoordOffs.x = (1.0 - coords.y * coords.y) * intensity.y * coords.x;
    realCoordOffs.y = (1.0 - coords.x * coords.x) * intensity.x * coords.y;

    vec2 fuv = uv - realCoordOffs;
    if(fuv.x < 0.0 || fuv.x > 1.0 || fuv.y < 0.0 || fuv.y > 1.0) {
        COLOR= vec4(0.0); 
		vec4 color = texture(screen_texture,fuv);
		COLOR.rgb=mix(color.rgb,color.bgr,length(fuv-0.5));
    } else {
        fuv.y = 1.0 - fuv.y;
        COLOR = texture(screen_texture, fuv);
		vec4 color = texture(screen_texture,fuv);
		COLOR.rgb=mix(color.rgb,color.bgr,length(fuv-0.5));
    }
}