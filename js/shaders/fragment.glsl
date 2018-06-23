void main() {
    gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}



// float getFog();
// float opDisplace(vec3);
// float smin(float, float, float);
// float sphereFunc(vec3);
// vec3 estimateNormal(vec3);

// //#define EPSILON = 0.0000001
// const float EPSILON = 0.0001;

// float rand(vec2 n) { 
//     return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
// }

// float noise(vec2 p){
//     vec2 ip = floor(p);
//     vec2 u = fract(p);
//     u = u*u*(3.0-2.0*u);
    
//     float res = mix(
//         mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
//         mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
//     return res*res;
// }

// void mainImage( out vec4 fragColor, in vec2 fragCoord )
// {
//     // Normalized pixel coordinates (from -1 to 1)
//     vec2 uv;

//     //position of camera
//     vec3 eye = vec3(0, 0, -10.);
//     //up vector for basis
//     vec3 up = vec3(0, 1., 0);
//     //right vector for basis
//     vec3 right = vec3(1., 0, 0);
    
//     //point on image plane
//     vec3 p = vec3(uv.x, uv.y, 0);
    
//     //center coords around 0
//     vec2 xy = fragCoord.xy - iResolution.xy/2.0;
//     //calculate depth of z based on the resolution, imagining that the size is 
//     //the resolution we can get z and normalize the result
//     float fov = 45.;
//     float z = iResolution.y / tan(radians(fov) / 2.0);
//     vec3 rayDirection = normalize(vec3(xy, z));
    
//     vec4 col = vec4(0.);
//     vec3 pos;
    
//     float t = 0.;
//     //a - (b * floor(a/b))
//     //perform raymarching 
//     //int maxSteps = int(iTime - (16. * floor(iTime/16.))) + 8;
//     const int maxSteps = 32;
//     for(int i = 0; i < maxSteps; ++i)
//     {
//         //float distImage;
//         pos = eye + (rayDirection * t);
//         float d = sphereFunc(pos); // Distance to sphere of radius 0.5
//         if(d < EPSILON)
//         {
//             col = vec4(1.); // Sphere color
//             break;
//         }
//         t += d;
//     }
    
//     //lighting pos
//     vec3 lightPos = vec3(-3, 0, -20.);
//     vec3 lightDir = normalize(lightPos - pos);
//     vec3 normal = estimateNormal(pos);
    
//     //colors
//     vec3 diffuse = vec3(1., sin(iTime) * 2. - 1., sin((pos.z + iTime) * 20.));
//     vec3 ambient = vec3(0, 1., 1.);
    
//     float brightness = .4;
//     float reflectionC = 0.5;
//     vec3 diffCol = diffuse * (brightness * reflectionC * dot(lightDir, normal) * 3.14/2.);
//     vec3 ambientCol = ambient * 0.5;
//     float specular = dot(normalize(reflect(lightPos, normal)), normalize(eye - pos));
//     specular = 0. * pow(specular, ((sin(iTime * 10.) + 2.) * 0.5) * 50. + 20.);
//     fragColor = vec4(ambientCol + diffCol + specular, 1.);
//     //fragColor = col; 
// }


// vec4 getFog(float distance){
//     float NEAR = 0.;
//     float FAR = 100.;
//     return vec4(0.);
// }

// float sphereFunc(vec3 pos){
//     //float d1 = length(pos) - radius;
//     //vec3 t = vec3(pos.xyz);
//     //t.x += .5;
//     //float d2 = (length(t) - radius/2.);
//     //return d2;
//     //return max(-d1,d2);
    
//     float a = iTime + (sin(iTime) * 10.);
//     mat3 rotMat = mat3(cos(a), 0., sin(a),
//                        0., 1., 0.,
//                        -sin(a), 0., cos(a));
    
//     pos *= rotMat;

//     float r = 0.5;
    
//     float d1 = length(pos) - r;
//     //return d1;
//     float s = (sin(iTime * 0.5)) + 1.;
    
//     //float d2 = sin(s*pos.x)*cos(s*pos.y)*sin(s*pos.z);
//     float d2 = noise(pos.xy + iTime);
    
//     //shape1
//     float primitive1 = d1+d2;
//     //shape 2
//     pos.x -= noise(pos.yz + iTime * 1.);
//     float primitive2 = (length(pos) - r);
//     primitive2 += noise(pos.xz + iTime * 1.);
    
//     float resultPrim = smin(primitive1, primitive2, 2.5);
    
//     //shape 3
    
    
//     vec3 p = pos;
    
//     for(int i = 0; i < 2; i++){
//         pos.y = p.y + sin(iTime + float(i)/2. * 2.) * .75;
//         pos.x = p.x + cos(iTime + float(i)/2. * 2.) * .75;

//         float primitive3 = (length(pos) - r);
//         primitive3 -= noise(pos.xy * float(i) * 0.1)* sin(iTime) * 0.85; 

//         resultPrim = smin(resultPrim, primitive3, 0.5);
//     }
    
//     return resultPrim;
// }


// vec3 estimateNormal(vec3 p) {
//     return normalize(vec3(        
//         sphereFunc(vec3(p.x + EPSILON, p.y, p.z)) - sphereFunc(vec3(p.x - EPSILON, p.y, p.z)),
//         sphereFunc(vec3(p.x, p.y + EPSILON, p.z)) - sphereFunc(vec3(p.x, p.y - EPSILON, p.z)),
//         sphereFunc(vec3(p.x, p.y, p.z  + EPSILON)) - sphereFunc(vec3(p.x, p.y, p.z - EPSILON))
//     ));
// }

// //from inigo iquliez
// // polynomial smooth min (k = 0.1);
// float smin( float a, float b, float k )
// {
//     float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
//     return mix( b, a, h ) - k*h*(1.0-h);
// }
