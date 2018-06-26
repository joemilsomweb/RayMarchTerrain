precision mediump float;

uniform vec4 iMouse;
uniform vec2 iResolution;
uniform float iTime;

float smin(float, float, float);
float distanceFunc(vec3, vec4);
vec3 estimateNormal(vec3, vec4);
float displace(vec3);

//#define EPSILON = 0.0000001
const float EPSILON = 0.0000001;
#define NUM_OCTAVES 5

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
}

float fbm(vec2 x) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(x);
        x = rot * x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}


void main()
{
    //set vec positions
    vec3 eye = vec3(0, 1., -10.);

    vec2 xy = gl_FragCoord.xy - iResolution.xy/2.;
    float fov = radians(45./2.);
    //ehy not iResolution/2?
    float z = (iResolution.y) / tan(fov);
    vec3 rayDirection = normalize(vec3(xy, z));

    vec4 col = vec4(0, 0., 1., 1.);

    vec3 pos;
    //start raymarching
    float t = 0.;
    const int maxSteps = 64;

    float a = radians(45. + iTime);
    mat3 rot = mat3(cos(a), 0, sin(a), 0, 1., 0, -sin(a), 0, cos(a));
    mat3 rotZ = mat3(cos(a), 0, sin(a), 0, 1., 0, -sin(a), 0, cos(a));

    vec4 n = vec4(0., 1., 0, 1.);
    float error = 0.0;

    int hit = 0;

    for(int i = 0; i < maxSteps; i++){

        pos = eye + rayDirection * t;
        // pos.y /= 4.;
        // pos = rot * pos;
        pos = pos;

        float d = distanceFunc(pos, n);

        if(d < EPSILON + error){
            hit = 1;
            col = vec4(float(i) / 32.);
            break;
        }

        t += d;
        //reduce sensitivity the further away
         error += 0.01;
    }

    // vec3 dis = displace(pos);
    // pos += dis;

    vec4 resultCol = vec4(0, 0, gl_FragCoord.y/iResolution.y, 1.);

    // directional light
    if(hit == 1){
        vec3 lightPos = vec3(4., 4., -5.);
        vec3 lightDir = normalize(lightPos - pos);
        vec3 normal = estimateNormal(pos, n);

        //apply lighting
        vec3 diffuse = vec3(1., 1., 1.);
        // vec3 diffuse = normalize(vec3(pos.y, pos.y/2., 0));
        // vec3 diffuse = pos;
        // vec3 diffuse = ;
        float brightness = 1.;
        float rCoefficient = 0.4;
        vec3 diffCol = col.rgb * diffuse * (brightness * rCoefficient * dot(lightDir, normal) * 3.14/2.);
        resultCol = vec4(diffCol, 1.);
    }

    gl_FragColor = resultCol;
}

float distanceFunc(vec3 p, vec4 n){
    // float displace = sin(p.x  + p.y + iTime) / 10.; 
     // float displace = sin(p.y) * 100.   ;
     // displace /= 50.;
    // float displace = fbm(p.xz) * 1.;
    float displace = sin(p.x * 1.) * sin(p.z * 1.);
    // * 1. + sin(iTime + p.y + p.x)/10.;
    // float displace = 0.; 
    // displace = 10.;
    // return dot(p,n.xyz) + n.w;

  // n must be normalized

    // n = vec4(0, 1, 0, 1.);

  return dot(p, n.xyz) + n.w + displace;


    // return length(max(abs(p)-,0.0))-.05 + displace;
}


float displace(vec3 pos){
    vec3 d = pos;
    d.x += sin(pos.x * 20.);
    d.y += sin(pos.y * 20.);
    d.z += sin(pos.z * 20.);
    return 1.;
}

vec3 estimateNormal(vec3 p, vec4 boxDim) {
    return normalize(vec3(        
        distanceFunc(vec3(p.x + EPSILON, p.y, p.z), boxDim) - distanceFunc(vec3(p.x - EPSILON, p.y, p.z), boxDim),
        distanceFunc(vec3(p.x, p.y + EPSILON, p.z), boxDim) - distanceFunc(vec3(p.x, p.y - EPSILON, p.z), boxDim),
        distanceFunc(vec3(p.x, p.y, p.z  + EPSILON), boxDim) - distanceFunc(vec3(p.x, p.y, p.z - EPSILON), boxDim)
    ));
    return vec3(0);
}

//from inigo iquliez
// polynomial smooth min (k = 0.1);
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
