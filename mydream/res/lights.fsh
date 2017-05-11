#define kMaxNumShaderLights 16
#define kNumFloatsPreShaderLight 8

uniform int numLights;//灯光数量
uniform float lights[kMaxNumShaderLights*kNumFloatsPreShaderLight];//灯光数据
uniform float minDarkness;//暗度
uniform float maxBrightness;//明度

float get_mask(float dist, float radius, float gradient)//gradient变化率 渐变梯度
{
    float brightness = 1.;
    if (dist < radius) {
        float dd = dist / radius;
        return 1.0 - smoothstep(0.0, gradient, pow(dd, brightness));
    }
    return 0.0;
}

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
    vec4 texcolor = Texel(texture, texture_coords);
    vec3 bufColor = vec3(0.0);

    float x,y;
    float w,h;
    float r,g,b,a;

    for(int i=0; i<numLights; i++)
    {
        x = lights[i*kNumFloatsPreShaderLight+0];
        y = lights[i*kNumFloatsPreShaderLight+1];
        w = lights[i*kNumFloatsPreShaderLight+2];
        h = lights[i*kNumFloatsPreShaderLight+3];
        r = lights[i*kNumFloatsPreShaderLight+4];
        g = lights[i*kNumFloatsPreShaderLight+5];
        b = lights[i*kNumFloatsPreShaderLight+6];
        a = lights[i*kNumFloatsPreShaderLight+7];

        float dist = distance(screen_coords, vec2(x, y));

        // TODO 目前只支持正圆形灯光，需要支持椭圆形灯光
        bufColor += vec3(r, g, b) * get_mask(dist, w, a);
    }

    bufColor = clamp(bufColor, minDarkness, maxBrightness);

    return texcolor * vec4(bufColor, 1.0);
}