#version 420 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)
uniform float fFrameTime; // duration of the last frame, in seconds

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texPreviousFrame; // screenshot of the previous frame
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout( r32ui ) uniform coherent restrict uimage2D[3] computeTex;
layout( r32ui ) uniform coherent restrict uimage2D[3] computeTexBack;

layout( location = 0 ) out vec4 out_color; // out_color must be written in order to see anything

#define U gl_FragCoord.xy
#define R vec2(v2Resolution.xy)
#define T fGlobalTime 
#define pi acos( -1.0f )
#define tau ( acos( -1.0f ) * 2.0f )


#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))

// referencing a pixel, for an extended ASCII character in Code Page 37
//    expected ranges of char are 0-255
//    expected ranges of offset are within the 8x16 neighborhood
//    inverting on either axis will let you orient as desired
const uint data[ 1024 ] = uint[](0u, 0u, 4278255360u, 0u, 0u, 0u, 4278255360u, 0u, 0u, 0u, 4278255360u, 0u, 8289792u, 1579008u,
4278255390u, 1010794240u, 8519532u, 272382976u, 4278255374u, 1714643736u, 10869758u, 943488512u, 4282172186u, 1715437336u, 8519678u,
2095578904u, 3882260786u, 1714447323u, 8519678u, 4276617020u, 3275931000u, 1714447164u, 12436478u, 2095545916u, 3275931084u,
1009804263u, 10086268u, 941103128u, 3882260940u, 405824316u, 8519480u, 270014464u, 4282172364u, 2121295835u, 8519440u, 3947520u,
4278255564u, 418440984u, 8289792u, 0u, 4278255480u, 417392152u, 0u, 0u, 4278255360u, 49152u, 0u, 0u, 4278255360u, 0u, 0u, 0u,
4278255360u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 2147614720u, 8126464u, 0u, 0u, 3221624934u, 2143682584u, 404226048u, 0u, 3759029350u,
3680501820u, 1008205824u, 0u, 4028530278u, 3677880446u, 2115502080u, 4350u, 4164819046u, 3681288216u, 404232240u, 2636030u, 4278065254u,
2076573720u, 404229216u, 3228317820u, 4164819046u, 465960984u, 404291326u, 3237903484u, 4028530278u, 460127870u, 404229216u,
3228335160u, 3759029248u, 456719932u, 410916912u, 4264099384u, 3221624934u, 453836312u, 406585344u, 65040u, 2147614822u, 466026110u,
404226048u, 0u, 0u, 8126464u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 402653184u, 0u, 0u, 26112u, 402653232u, 0u,
0u, 1598976u, 2080389168u, 204472320u, 0u, 3958380u, 3321916464u, 404226048u, 0u, 3941484u, 3267521632u, 806092800u, 2u, 3932414u,
3234215936u, 806118936u, 6u, 1572972u, 2081191424u, 806108184u, 12u, 1572972u, 102292480u, 806158206u, 16646168u, 1572972u, 103861248u, 
806108184u, 48u, 254u, 2254490624u, 806118936u, 402653280u, 1572972u, 3334917120u, 404226048u, 402659520u, 1572972u, 2089186816u, 
204472320u, 402659456u, 0u, 402653184u, 0u, 805306368u, 0u, 402653184u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 
0u, 0u, 941128828u, 217987326u, 2088501248u, 124u, 1815660230u, 482369734u, 3334864896u, 100688070u, 3329754630u, 1019265030u, 
3334871064u, 201339078u, 3323464710u, 1824571398u, 3334871064u, 410916876u, 3591903292u, 3439131660u, 2088632320u, 805309464u, 
3591909382u, 4261856792u, 3322281984u, 1610614296u, 3323486214u, 201770544u, 3322281984u, 813567000u, 3323510790u, 201770544u,
3322288152u, 402659328u, 1813563078u, 214353456u, 3322681368u, 201338904u, 947846780u, 511474736u, 2088239152u, 100687896u, 0u, 0u, 0u,
0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 1113148u, 4177460796u, 3325828838u, 4039558780u,
2084071014u, 1818650214u, 3323464806u, 1626269382u, 3328992962u, 1717723842u, 3323464806u, 1627322054u, 3334891200u, 1718118592u, 
3323464812u, 1627324102u, 3737550016u, 1719171264u, 4262988920u, 1624694470u, 3741214400u, 1718118622u, 3323464824u, 1623641798u, 
3737544384u, 1717592262u, 3323513964u, 1623639750u, 3703989954u, 1717723334u, 3323513958u, 1657194182u, 3234227814u, 1818648678u, 
3323513958u, 1724303046u, 2093415484u, 4177457210u, 3325851878u, 4274439804u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u,
0u, 0u, 0u, 0u, 0u, 4096u, 0u, 0u, 0u, 14336u, 4236049532u, 2126956230u, 3328638524u, 3959808u, 1724278470u, 2126956230u, 3328624176u,
2148320768u, 1724278470u, 1522976454u, 1818658352u, 3222011904u, 1724278368u, 415680198u, 2087062576u, 3758882816u, 2093382712u, 
415680214u, 943462448u, 1879834624u, 1623616524u, 415680214u, 941109296u, 940310528u, 1623614982u, 415680214u, 2081972272u, 470548480u,
1624663750u, 415657214u, 1813561904u, 235667456u, 1625188038u, 415643886u, 3323512368u, 101449728u, 4034717308u, 1014763628u, 
3325886012u, 37486592u, 786432u, 0u, 0u, 0u, 917504u, 0u, 0u, 255u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 805306368u, 0u, 0u, 0u, 805306368u,
0u, 0u, 0u, 402710528u, 469776384u, 3759671008u, 939524096u, 24576u, 201354240u, 1612187232u, 402653184u, 24576u, 201352192u,
1610612832u, 402653184u, 7895164u, 1014784118u, 1815613030u, 418176124u, 814278u, 1824977100u, 1981285996u, 419325638u, 8152768u, 
3439222988u, 1712850552u, 416704198u, 13395648u, 3435159756u, 1712850552u, 416704198u, 13395648u, 3435159756u, 1712850540u, 416704198u,
13395654u, 3435552972u, 1712850534u, 416704198u, 7765116u, 1987899516u, 3862693606u, 1019635324u, 0u, 12u, 26112u, 0u, 0u, 204u, 26112u,
0u, 0u, 120u, 15360u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 268435456u, 7u, 205011712u, 0u, 805306368u, 12u, 
202141184u, 0u, 805306368u, 12u, 202113032u, 3698777212u, 4234556259u, 1667464972u, 202113052u, 1724675782u, 812004195u, 912483896u,
458806u, 1724671584u, 812004203u, 476253196u, 202113123u, 1724670008u, 812004203u, 476256268u, 202113123u, 1724669964u, 812004203u, 
476262412u, 202113123u, 1724670150u, 912662143u, 912483084u, 202113151u, 2088562812u, 473631798u, 1665105671u, 204996608u, 1611399168u,
0u, 196608u, 0u, 1611399168u, 0u, 393216u, 0u, 4028497920u, 0u, 8126464u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 56u, 3088u, 6305792u, 
268460032u, 408995436u, 1020008504u, 3425725440u, 952512614u, 1009778744u, 1711288428u, 1587200u, 1811945472u, 1712852992u, 3254779904u,
60u, 0u, 14392u, 3234626680u, 2021161062u, 2088533048u, 943221868u, 3234645516u, 202116192u, 3334915608u, 404276934u, 3234659964u, 
2088533088u, 4278124056u, 404276934u, 3268198604u, 3435973734u, 3233857560u, 404291326u, 1724694732u, 3435973692u, 3233857560u, 
404276934u, 1020053196u, 3435973644u, 3334915608u, 404276934u, 209091702u, 1987474950u, 2088533052u, 1010616006u, 100663296u, 60u, 0u, 
0u, 2080374784u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 402653184u, 0u, 0u, 0u, 805306384u, 6303840u, 13026840u, 939587598u, 
1610628664u, 3325065264u, 3321888792u, 1818676251u, 27756u, 1625112u, 8177212u, 1684458520u, 4261465088u, 0u, 13026918u, 1614608408u,
1724697724u, 2088553676u, 3334915680u, 4028154904u, 1618411206u, 3334917324u, 3334915680u, 1618922622u, 2083966150u, 3334917324u, 
3334915680u, 1612242456u, 1618922694u, 3334917324u, 3334915686u, 1618922520u, 1624820934u, 3334917324u, 3334915644u, 1612237848u,
1725484230u, 3334917324u, 3334915608u, 3860384792u, 4268674684u, 2088531574u, 2122087448u, 4229482008u, 0u, 0u, 100663296u, 216u, 0u,
0u, 201326592u, 112u, 0u, 0u, 2013265920u, 0u, 0u, 0u, 0u, 0u, 0u, 7733248u, 0u, 0u, 403445784u, 14433336u, 192u, 3221225472u, 
806891568u, 1979739244u, 805306560u, 3222798336u, 1613783136u, 3703991404u, 805306562u, 3256352768u, 0u, 15089208u, 198u, 3321888768u,
2016967884u, 3707109376u, 805306572u, 3424138968u, 202950348u, 1727954556u, 822017560u, 404253804u, 2081998540u, 1725825024u, 
1623197232u, 806934582u, 3424175820u, 1724776448u, 3233810016u, 1715235948u, 3424175820u, 1724252160u, 3334473436u, 3460052696u, 
3424175820u, 1724252160u, 3334473350u, 2654732288u, 1983675510u, 1724252160u, 2080374796u, 1041760256u, 0u, 0u, 24u, 100663296u,
0u, 0u, 62u, 100663296u, 0u, 0u, 0u, 0u, 290839832u, 404239872u, 3552768u, 909514752u, 1152022296u, 404239872u, 3552768u, 909514752u,
290839832u, 404239872u, 3552768u, 909514752u, 1152022296u, 404239872u, 3552768u, 909514752u, 290839832u, 404239872u, 3552768u, 
909514752u, 1152022296u, 418919936u, 4176885502u, 4130797568u, 290839832u, 404239872u, 403060230u, 104208384u, 1152022296u, 4177065726u,
4176885494u, 4278122744u, 290839832u, 404239926u, 406206006u, 24u, 1152022296u, 404239926u, 406206006u, 24u, 290839832u, 404239926u, 
406206006u, 24u, 1152022296u, 404239926u, 406206006u, 24u, 290839832u, 404239926u, 406206006u, 24u, 1152022296u, 404239926u, 406206006u,
24u, 290839832u, 404239926u, 406206006u, 24u, 1152022296u, 404239926u, 406206006u, 24u, 404226072u, 1579062u, 905983488u, 905983512u, 
404226072u, 1579062u, 905983488u, 905983512u, 404226072u, 1579062u, 905983488u, 905983512u, 404226072u, 1579062u, 905983488u,
905983512u, 404226072u, 1579062u, 905983488u, 905983512u, 404226072u, 1580854u, 926939135u, 939522047u, 404226072u, 1579062u,
808452096u, 805306368u, 536870687u, 4294909751u, 1060634615u, 939522047u, 6168u, 1579062u, 3538998u, 905983488u, 6168u, 1579062u, 
3538998u, 905983488u, 6168u, 1579062u, 3538998u, 905983488u, 6168u, 1579062u, 3538998u, 905983488u, 6168u, 1579062u, 3538998u, 
905983488u, 6168u, 1579062u, 3538998u, 905983488u, 6168u, 1579062u, 3538998u, 905983488u, 6168u, 1579062u, 3538998u, 905983488u, 
905969718u, 402653238u, 404226303u, 15732735u, 905969718u, 402653238u, 404226303u, 15732735u, 905969718u, 402653238u, 404226303u,
15732735u, 905969718u, 402653238u, 404226303u, 15732735u, 905969718u, 402653238u, 404226303u, 15732735u, 922681398u, 522125366u,
4279763199u, 15732735u, 905969718u, 404226102u, 404226303u, 15732735u, 4294967103u, 522141695u, 4294451199u, 4293922560u, 1586688u, 
1586742u, 402659583u, 4293922560u, 1586688u, 1586742u, 402659583u, 4293922560u, 1586688u, 1586742u, 402659583u, 4293922560u, 1586688u,
1586742u, 402659583u, 4293922560u, 1586688u, 1586742u, 402659583u, 4293922560u, 1586688u, 1586742u, 402659583u, 4293922560u, 1586688u, 
1586742u, 402659583u, 4293922560u, 1586688u, 1586742u, 402659583u, 4293922560u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u,
7929344u, 0u, 14366u, 7168u, 13420032u, 4261412864u, 2117626928u, 209020u, 13420286u, 3321914998u, 409781784u, 417990u, 1993130092u, 
1618896604u, 1019659788u, 2122211526u, 3705192556u, 819488280u, 1724302910u, 3688594630u, 3637297260u, 416835096u, 1727949926u, 
3688587462u, 3636904044u, 819488280u, 1724279910u, 3690160326u, 3636904044u, 1624800280u, 1019636838u, 2122211526u, 3704012908u, 
3336069144u, 409758822u, 6303942u, 1993130092u, 4268777496u, 2117660220u, 12590278u, 0u, 49152u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u,
0u, 1572864u, 0u, 0u, 0u, 1572864u, 0u, 0u, 0u, 1572864u, 939524111u, 3631218688u, 0u, 236453888u, 1811939340u, 1826095104u, 12300u,
454557696u, 1811939340u, 1815085056u, 4262991896u, 454563840u, 939524108u, 1818262528u, 1575984u, 404232310u, 12u, 1825078272u,
8259168u, 404226268u, 12u, 1828224000u, 4262988848u, 404258304u, 1573100u, 31744u, 1579032u, 416809078u, 1579116u, 31744u, 12300u,
416815324u, 108u, 31744u, 4261412864u, 416815104u, 60u, 31744u, 16744062u, 409993216u, 28u, 0u, 0u, 402653184u, 0u, 0u, 0u, 402653184u,
0u, 0u, 0u, 402653184u, 0u, 0u );

int fontRef ( in uint char, in ivec2 offset, in bvec2 invert ) {
    if ( invert.x ) offset.x = 7 - offset.x;
    if ( invert.y ) offset.y = 15 - offset.y;
    bool offsetOOB = any( lessThan(         offset, ivec2( 0,  0 ) ) ) ||
                     any( greaterThanEqual( offset, ivec2( 8, 16 ) ) );
    bool charOOB = bool( clamp( char, 0u, 255u ) != char );
    if ( offsetOOB || charOOB ) return -1; // oob
    uvec2 sampleLoc = uvec2( char % 16u, char / 16u ) * uvec2( 8u, 16u ) + uvec2( offset );
    uint idx = ( sampleLoc.x + sampleLoc.y * 128u ) / 32u;
    uint packedData = data[ idx ];
    uint bitMask = 1u << ( 31u - sampleLoc.x % 32u );
    return int( ( packedData & bitMask ) != 0u );
}

int fontRef ( uint char, ivec2 offset ) {
    return fontRef( char, offset, bvec2( false, true ) );
}

// hashes
uint seed = 12512;
uint hashi ( uint x ) {
  x ^= x >> 16; x *= 0x7feb352dU;
  x ^= x >> 15; x *= 0x846ca68bU;
  x ^= x >> 16;
  return x;
}

#define hash_s(s)  ( float( hashi( uint( s ) ) ) / float( 0xffffffffU ) )
#define hash()     ( float( seed = hashi( seed ) ) / float( 0xffffffffU ) )
#define hash2()    vec2( hash(), hash() )
#define hash3()    vec3( hash(), hash(), hash() )
#define hash4()    vec3( hash(), hash(), hash(), hash() )

vec2 sampleDisk () {
    vec2 r = hash2();
    return vec2( sin( r.x * tau ), cos( r.x * tau ) ) * sqrt( r.y );
}

void storePixel ( ivec2 p, vec3 col ) {
  // colour quantized to integer.
  ivec3 quantized = ivec3( col * 10000 );
  imageStore( computeTex[ 0 ], p, ivec4( quantized.x ) ); 
  imageStore( computeTex[ 1 ], p, ivec4( quantized.y ) ); 
  imageStore( computeTex[ 2 ], p, ivec4( quantized.z ) ); 
}

void addToPixel ( ivec2 p, vec3 color ) {
  // colour quantized to integer.
  ivec3 quantized = ivec3( color * 10000 );
  imageAtomicAdd( computeTex[ 0 ], p, quantized.x );
  imageAtomicAdd( computeTex[ 1 ], p, quantized.y );
  imageAtomicAdd( computeTex[ 2 ], p, quantized.z );
}

vec3 readPixel ( ivec2 p ) {
  return 0.0001f * vec3(
    imageLoad( computeTexBack[ 0 ], p ).x,
    imageLoad( computeTexBack[ 1 ], p ).x,
    imageLoad( computeTexBack[ 2 ], p ).x
  );
}

vec3 palette ( float i ) {
    return vec3(
    sin( i * ( pi / 2.0f ) ),
    sin( i * pi ),
    cos( i * ( pi / 2.0f ) )
  );
}

void updateProbe ( ivec2 lightIndex ) {
   // update distance samples for the probes, write the lines, checking the depth buffer per texel
  storePixel( lightIndex, vec3( palette( mod( hash_s( U.x * U.y * 100 ) * 0.2f + hash_s( U.x + U.y * U.x * 200 ) * T, 2.8f ) ) ) );
}


void main ( void ) {
  // Init hash
  seed = 42069;
  seed += hashi( uint( U.x ) ) + hashi( uint( U.y ) * 125 );

  bvec4 boundsChecks = bvec4(
    U.x < 96,
    U.y < 64,
    U.x > ( textureSize( texPreviousFrame, 0 ).x - 96 ),
    U.y > ( textureSize( texPreviousFrame, 0 ).y - 64 )
  );

  if ( boundsChecks.x && boundsChecks.y || 
       boundsChecks.z && boundsChecks.w ||
       boundsChecks.x && boundsChecks.w || 
       boundsChecks.z && boundsChecks.y ) {

    // logic is slightly more complex, but I prefer it visually - put the data into the corners
         // don't strictly have to show it, but I want to

    updateProbe( ivec2( U ) );
    out_color = vec4( vec3( 1.0f ) - readPixel( ivec2( U.xy ) ), 1.0f );

  } else {

    vec3 color = vec3( 0.0f );
    vec3 prevColor = texelFetch( texPreviousFrame, ivec2( U.xy ), 0 ).xyz;
    int xIters = 2;
    int yIters = 2;
    for ( int x = 0; x < xIters; x++ )
    for ( int y = 0; y < yIters; y++ ) {
      
      
      // this is the code for the screenspace roving text
      vec2 screenPos = ( U.xy + hash_s( x + y + x * y ) ) / textureSize( texPreviousFrame, 0 ).xy - vec2( 0.5f );
      
      // lens distort, broekn
      // screenPos = screenPos * ( 100.1f * pow( length( screenPos ), 2.0f ) + 1.0f * pow( length( screenPos ), 4.0f ) );

      float t = float( fGlobalTime ) * 0.25f;
      vec2 uv = rot( 0.5f + 0.1f * sin( T * 0.2f ) ) *
        ( screenPos ) * ( 500.0f + 50.0f * sin( t ) ) +
        ivec2( int( 1000 + 50 * T ) ) + 
        ivec2( sin( t * hash_s( 619 ) ) * 300 * hash_s( 69 ),
               cos( t * hash_s( 29745 ) ) * 500 * hash_s( 420 ) );
      ivec2 bin = ivec2( floor( uv / vec2( 8.0f, 16.0f ) ) );
      ivec2 offset = ivec2( uv ) % ivec2( 8, 16 );
      float glyphValNoMod = ( hash_s( bin.x * bin.y ) + t ) / 1.0f;
      float glyphVal = mod( glyphValNoMod, hash_s( bin.x * bin.y + 600 ) );
      uint pick = uint( hashi( bin.x + bin.y * 102026 ) ) % 255u;
      int onGlyph = fontRef( ( pick + int( glyphValNoMod ) ) % 255u, offset );
      color += ( onGlyph == 0 ? vec3( 0.0f ) : palette( sin( glyphVal.x + cos( T / 50.0f ) ) ) );
      
    }

    color = mix( prevColor, color / float( xIters * yIters * 1.3f ), 0.375f );
    out_color = vec4( color, 1.0f );

  }
}