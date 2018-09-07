precision mediump float;

uniform vec4 iMouse;
uniform vec2 iResolution;
uniform float iTime;

//for the raymarching,
// just so i can put it inside its own
//function
struct RayResult{
    bool hit;
    float t;
};

vec3 calculateRayDirection(float);

//distance functions
float distanceFunc(vec3);
float smin(float, float, float);
float displace(vec3);
RayResult rayMarch(vec3, vec3);

vec3 addXRotation(vec3, float);

//lighting
vec3 estimateNormal(vec3);
vec3 calculateDiffuse(vec3, vec3, vec3, vec3);
vec3 calculateSpecular(vec3, vec3);
float calculateFogInterpolater(vec3, vec3);

//sky color
vec4 calculateSky();
vec4 addSnow(vec4, vec3, vec3);

//#define EPSILON = 0.0000001
const float EPSILON = 0.00001;
#define NUM_OCTAVES 5
#define MAX_DIST 5.

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

//can easily estimate normals though via derivative
float fbm(vec2 x) {
    float v = 0.0;

    float amplitude = 2.;

 
    for (int i = 0; i < NUM_OCTAVES; i++) {
        float n = abs(noise(x));
        n =  n;
        n = n*n;

        v += amplitude * n;
        x *= 3.;
        amplitude *= .2;
    }

    return v;
}


void main()
{
    vec3 eye = vec3(0, .4, -5.);
    vec3 rayDirection = calculateRayDirection(45.);

    //start ray marching
    RayResult result = rayMarch(rayDirection, eye);

    vec3 pos = (eye + rayDirection * result.t);

    vec4 col;

    if(result.hit == true){
        // brown colour rgb(205,133,63)
        col = vec4(205./255., 133./255., 63./255., 1.);

        vec3 lightPos = vec3(0, 5., -2.);
        vec3 normal = estimateNormal(pos);

        // col.r *= normal.y;  
        col = addSnow(col, pos, normal);

        vec3 diffuseCol = vec3(1., 1., 1.);
        // if(normal.z < 0.){
        vec3 diff = calculateDiffuse(pos, normal, lightPos, diffuseCol);
        //apply lighting
        col *= vec4(diff, 1.);

        vec4 fogCol = vec4(1., 1., 1., 1.);
        float fogInterp = calculateFogInterpolater(pos, eye);
        col = mix(col, fogCol, fogInterp);
    }
    else{
        col = calculateSky();
        //shade sky
    }
     //calc sun?
    // float lightDist = distance(lightPos, pos);
    // if(lightDist < 30.){
    //     col.rgb += (lightDist/30.);         
    // }

    gl_FragColor = col;
}

vec3 calculateRayDirection(float fov){
    vec2 xy = gl_FragCoord.xy - iResolution.xy/2.;
    fov = radians(fov/2.);
    float z = (iResolution.y) / tan(fov);
    vec3 rayDirection = normalize(vec3(xy, z));

    return rayDirection;
}


RayResult rayMarch(vec3 rayDirection, vec3 eye){
    //set vec positions
    vec3 pos;

    //start raymarching
    float t = 1.;

    float error = 0.0;
    const float tInc = 0.01;
    const float maxDist = 5.; 

    //maybe can rename d h
    float lastH = 0.;
    float lastY = 0.;

    for(float i = 0.; i < maxDist; i+=tInc){

        pos = eye + rayDirection * t;
        // pos = addXRotation(pos, iTime*2.);

        float h = distanceFunc(pos);

        if(pos.y < h){
            //interpolate the t to reduce error
            t = (t - tInc) + tInc * (lastH-lastY)/(pos.y - lastY - h + lastH);

            return RayResult(true, t);
        }

        lastH = h;
        lastY = pos.y;
        t += tInc;

        //decreasing error sensitivity as you move further away
        error = 0.01 * t;
    }

    return RayResult(false, t);
}

//logic for distance field calc goes here
float distanceFunc(vec3 p){
  vec4 n = vec4(0., 1., 0, 1.);

  // float dPlane = planeFunc(p, n);
  // float dDisplace = sin(p.x * 1.) * sin(p.z * 1.);
  float dDisplace = displace(p);

  // return dPlane + dDisplace;
  return dDisplace;
}

//displacement of terrain 
float displace(vec3 pos){
    // float scale = 0.1;
    // return sin(pos.x * 10. + iTime) * scale + sin(pos.y * 5.) * scale + sin(pos.z * 5.) * scale;

    // return noise(pos.xz + iTime) * 0.5 + noise(pos.xz) * 0.5;
    // return sin(pos.x * 1. + iTime) * sin(pos.z * 1. + iTime);

    return fbm(vec2(pos.x, pos.z + iTime));
}


vec3 addXRotation(vec3 pos, float angle){
    float a = radians(angle);

    //need to transpose for glsl...
    //and put pos on the other side, but this works ok...
    mat3 rot = mat3(
        cos(a), 0,  sin(a), 
        0,      1., 0,
        -sin(a),0, cos(a)
        );

    //this is not good
    return pos * rot;
}

//from inigo iquliez
// polynomial smooth min (k = 0.1); 
//blends shapes together
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

//lighting equations
vec3 calculateDiffuse(vec3 pos, vec3 normal, vec3 lightPos, vec3 diffuseCol){
    vec3 lightDir = normalize(lightPos - pos);

    float brightness = 1.;
    float rCoefficient = 0.4;
    vec3 diffuse = diffuseCol * (brightness * rCoefficient * dot(lightDir, normal) * 3.14/2.);

    return diffuse;
}

vec3 calculateSpecular(vec3 pos, vec3 lightPos){
    return vec3(0);
}

float calculateFogInterpolater(vec3 pos, vec3 eye){
     float distance = distance(pos, eye);
     float nearFog = 8.;
     float farFog = 10.;

     if(distance < nearFog){
        return 0.;
     }
     else{
        return (distance - nearFog) / (farFog - nearFog);
     }
}

vec3 estimateNormal(vec3 p) {
    //from inigo iquilez
    //uses central difference method to estimate normal.
    //approximates the derivatives by sampling either side of where the ray intersects
    //then we can say that this is the point where x and z changes the most rapidly, and
    //use this as the normal...
    //dont know why y isnt affected though      

    //for fbm though i think there is a more efficient way of estimating the normals
    vec3 n = vec3( distanceFunc(vec3(p.x-EPSILON,p.y,p.z)) - distanceFunc(vec3(p.x+EPSILON,p.y,p.z)),
                    2.0*EPSILON,
                    distanceFunc(vec3(p.x,p.y,p.z-EPSILON)) - distanceFunc(vec3(p.x,p.y,p.z+EPSILON)));
    return normalize( n );

    // return normalize(vec3(        
    //     distanceFunc(vec3(p.x + EPSILON, p.y, p.z)) - distanceFunc(vec3(p.x - EPSILON, p.y, p.z)),
    //     distanceFunc(vec3(p.x, p.y + EPSILON, p.z)) - distanceFunc(vec3(p.x, p.y - EPSILON, p.z)),
    //     distanceFunc(vec3(p.x, p.y, p.z  + EPSILON)) - distanceFunc(vec3(p.x, p.y, p.z - EPSILON))
    // ));
}

vec4 calculateSky(){
    // float lerp = noise(gl_FragCoord.xy / 50.);
    float lerp = gl_FragCoord.y / iResolution.y;

    //interpolate between white and blue for sky col
    return mix(vec4(1.), vec4(68./255., 112./255., 201./255., 1.), lerp);
}

vec4 addSnow(vec4 col, vec3 pos, vec3 normal){
    float hMin = 1.;
    float hMax = 1.2;

    float lerp = 0.;
    if(pos.y > hMin){
        // lerp = 1.;
        lerp = (pos.y - hMin) / (hMax - hMin);
        // lerp * normal.y;
    }

    lerp = normal.y;

    return mix(col, vec4(1.), lerp);
}
