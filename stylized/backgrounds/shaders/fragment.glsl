precision highp float;

// panel uniforms
uniform highp float time;
uniform highp vec2 resolution;
uniform int front;
uniform int back;

// metaball uniforms
const int MAX_METABALLS = 40;
uniform vec3 metaballs[MAX_METABALLS];
uniform int level;

// from vertex
varying vec2 fragment_position;

// ballon texture for clouds
uniform sampler2D balloon_texture;
uniform highp vec2 balloon_dimensions;
uniform highp vec2 balloon_offset;

// general smooth noise
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
vec3 fade(vec3 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}

float cnoise(vec3 P){
    vec3 Pi0 = floor(P); // Integer part for indexing
    vec3 Pi1 = Pi0 + vec3(1.0); // Integer part + 1
    Pi0 = mod(Pi0, 289.0);
    Pi1 = mod(Pi1, 289.0);
    vec3 Pf0 = fract(P); // Fractional part for interpolation
    vec3 Pf1 = Pf0 - vec3(1.0); // Fractional part - 1.0
    vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
    vec4 iy = vec4(Pi0.yy, Pi1.yy);
    vec4 iz0 = Pi0.zzzz;
    vec4 iz1 = Pi1.zzzz;

    vec4 ixy = permute(permute(ix) + iy);
    vec4 ixy0 = permute(ixy + iz0);
    vec4 ixy1 = permute(ixy + iz1);

    vec4 gx0 = ixy0 / 7.0;
    vec4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
    gx0 = fract(gx0);
    vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
    vec4 sz0 = step(gz0, vec4(0.0));
    gx0 -= sz0 * (step(0.0, gx0) - 0.5);
    gy0 -= sz0 * (step(0.0, gy0) - 0.5);

    vec4 gx1 = ixy1 / 7.0;
    vec4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
    gx1 = fract(gx1);
    vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
    vec4 sz1 = step(gz1, vec4(0.0));
    gx1 -= sz1 * (step(0.0, gx1) - 0.5);
    gy1 -= sz1 * (step(0.0, gy1) - 0.5);

    vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
    vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
    vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
    vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
    vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
    vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
    vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
    vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);

    vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
    g000 *= norm0.x;
    g010 *= norm0.y;
    g100 *= norm0.z;
    g110 *= norm0.w;
    vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
    g001 *= norm1.x;
    g011 *= norm1.y;
    g101 *= norm1.z;
    g111 *= norm1.w;

    float n000 = dot(g000, Pf0);
    float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
    float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
    float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
    float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
    float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
    float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
    float n111 = dot(g111, Pf1);

    vec3 fade_xyz = fade(Pf0);
    vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
    vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
    float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
    return 2.2 * n_xyz;
}

// noise (for clouds) - Simplex 3d + FBM
vec3 random3(vec3 c) {
	float j = 4096.0 * sin(dot(c,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= 0.125;
	r.x = fract(512.0*j);
	j *= 0.125;
	r.y = fract(512.0*j);
	return r-0.5;
}

const float F3 =  0.3333333;
const float G3 =  0.1666667;

/* 3d simplex noise */
float simplex3d(vec3 p) {
	 vec3 s = floor(p + dot(p, vec3(F3)));
	 vec3 x = p - s + dot(s, vec3(G3));
	 
	 vec3 e = step(vec3(0.0), x - x.yzx);
	 vec3 i1 = e*(1.0 - e.zxy);
	 vec3 i2 = 1.0 - e.zxy*(1.0 - e);
	 	
	 vec3 x1 = x - i1 + G3;
	 vec3 x2 = x - i2 + 2.0*G3;
	 vec3 x3 = x - 1.0 + 3.0*G3;
	 
	 vec4 w, d;
	 
	 w.x = dot(x, x);
	 w.y = dot(x1, x1);
	 w.z = dot(x2, x2);
	 w.w = dot(x3, x3);
	 
	 w = max(0.6 - w, 0.0);
	 
	 d.x = dot(random3(s), x);
	 d.y = dot(random3(s + i1), x1);
	 d.z = dot(random3(s + i2), x2);
	 d.w = dot(random3(s + 1.0), x3);
	 
	 w *= w;
	 w *= w;
	 d *= w;
	 
	 return dot(d, vec4(52.0));
}

float fbm(vec3 pos){
    const int NUM_OCTAVES = 8;
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * simplex3d(pos);
        pos.xy = rot * pos.xy * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

vec3 cloud(vec2 pos){
    float noise = fbm(vec3(pos.x - time * 0.02, pos.y, time / 10.0)) * 2.0;
    return mix(vec3(0.388,0.769,0.859), vec3(1.0, 1.0, 1.0), noise);
}

// metaball logic
vec3 metaball(vec2 pos){
    vec3 color;

    float x = gl_FragCoord.x;
    float y = gl_FragCoord.y;

    float sum = 0.0;
    
    if(level == 0){
        for(int i = 0; i < 4; ++i){
            vec3 md = metaballs[i];

            float dx = md.x - x;
            float dy = md.y - y;
            float r  = md.z;

            sum += r * r / (dx * dx + dy * dy);
        }
    } else if(level == 1){
        for(int i = 0; i < 6; ++i){
            vec3 md = metaballs[i];

            float dx = md.x - x;
            float dy = md.y - y;
            float r  = md.z;

            sum += r * r / (dx * dx + dy * dy);
        }
    } else if(level == 2){
        for(int i = 0; i < 20; ++i){
            vec3 md = metaballs[i];

            float dx = md.x - x;
            float dy = md.y - y;
            float r  = md.z;

            sum += r * r / (dx * dx + dy * dy);
        }
    } else if(level == 3){
        for(int i = 0; i < 30; ++i){
            vec3 md = metaballs[i];

            float dx = md.x - x;
            float dy = md.y - y;
            float r  = md.z;

            sum += r * r / (dx * dx + dy * dy);
        }
    } else if(level == 4){
        for(int i = 0; i < MAX_METABALLS; ++i){
            vec3 md = metaballs[i];

            float dx = md.x - x;
            float dy = md.y - y;
            float r  = md.z;

            sum += r * r / (dx * dx + dy * dy);
        }
    }

    vec2 origin = vec2(0.5, 0.5);
    pos -= origin;
    float angle = 3.92699 + atan(pos.y, pos.x);
    float t = sin(angle) * length(pos) + origin.x;

    if(sum > 1.0){
        vec3 A = vec3(0.639,0.467,0.812);
        vec3 B = vec3(0.706,0.996,0.906);
        color = mix(A, B, t);
    } else {
        vec3 A = vec3(0.945, 0.561, 0.004);
        vec3 B = vec3(1.0, 0.984, 0.275);
        color = mix(A, B, t);
    }

    return color;
}

// noise blips
vec3 noiseblip(vec2 pos){
    if(cnoise(vec3(gl_FragCoord.x / 500.0, gl_FragCoord.y / 500.0, time / 40.0)) > 0.0){
        pos -= vec2(0.5);
        float angle = 3.92699 + atan(pos.y, pos.x);
        float t = sin(angle) * length(pos) + -0.5;

        vec3 A = vec3(0.816, 0.749, 1.0);
        vec3 B = vec3(0.875, 0.8, 0.984);
        return mix(A, B, t);
    }

    return vec3(1.0, 0.953, 0.855);
}

vec3 smoothblib(vec2 pos){
    vec2 origin = vec2(0.5, 0.5);
    pos -= origin;
    float angle = 3.92699 + atan(pos.y, pos.x);
    float t = sin(angle) * length(pos) + origin.x;
    vec3 A = vec3(0.639,0.467,0.812);
    vec3 B = vec3(0.706,0.996,0.906);
    return mix(A, B, t);
}

// main
void main(){
    // shift time
    float t = time / 4.0;

    // get screen space position
    vec2 pos = fragment_position / resolution;

    // get page id
    int pid = back;
    if(gl_FrontFacing){
        pid = front;
    }

    // default color
    vec3 color = vec3(1.0, 0.0, 0.0);

    // set color
    if(pid == 0){
        color = metaball(pos);
    } else if(pid == 1){
        vec4 balloon = texture2D(balloon_texture, (fragment_position - balloon_offset) / balloon_dimensions);
        color = cloud(fragment_position / 900.0) * (1.0 - balloon.w) + balloon.xyz * balloon.w;
    } else if(pid == 2){
        color = noiseblip(pos);
    } else if(pid == 3){
        color = smoothblib(pos);
    }
    
    gl_FragColor = vec4(color, 1.0);
}