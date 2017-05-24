//
//  ViewController.m
//  OpenGLES-5.6模拟地月系
//
//  Created by ShiWen on 2017/5/23.
//  Copyright © 2017年 ShiWen. All rights reserved.
//

#import "ViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "AGLKContext.h"
#import "sphere.h"

// 地球倾斜角
static const GLfloat  SceneEarthAxialTiltDeg = 23.5f;
//月球转一周时间
static const GLfloat  SceneDaysPerMoonOrbit = 28.0f;
//地球月球半径比
static const GLfloat  SceneMoonRadiusFractionOfEarth = 0.25;
//月球距离地球距离
static const GLfloat  SceneMoonDistanceFromEarth = 1.0;

@interface ViewController ()
@property (nonatomic,strong) GLKBaseEffect *mBaseEffect;
@property (nonatomic,strong) AGLKVertexAttribArrayBuffer *mPostionBuffer;
@property (nonatomic,strong) AGLKVertexAttribArrayBuffer *mNomalBuffer;
@property (nonatomic,strong) AGLKVertexAttribArrayBuffer *mTextureBuffer;
@property (nonatomic,strong) GLKTextureInfo *moonInfo;
@property (nonatomic,strong) GLKTextureInfo *earthInfo;
@property (nonatomic,assign) GLKMatrixStackRef matrixRef;
@property (nonatomic,assign) float earthAngle;
@property (nonatomic,assign) float moonAngle;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.moonAngle = -20.0f;

    [self setupConfig];
    
}
-(void)setupConfig{
    self.matrixRef = GLKMatrixStackCreate(kCFAllocatorDefault);
    
    GLKView *glView = (GLKView *)self.view;
    glView.drawableDepthFormat = GLKViewDrawableDepthFormat16;
//
    glView.context = [[AGLKContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [AGLKContext setCurrentContext:glView.context];
    [((AGLKContext *)glView.context) setClearColor:GLKVector4Make(0.0, 0.0,0.0, 1.0)];
//
    self.mBaseEffect = [[GLKBaseEffect alloc] init];
    self.mBaseEffect.useConstantColor = GL_TRUE;
    self.mBaseEffect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    [self setupLight];
    
    // Set a reasonable initial projection
    self.mBaseEffect.transform.projectionMatrix =
    GLKMatrix4MakeOrtho(
                        -1.0 * 4.0 / 3.0,
                        1.0 * 4.0 / 3.0,
                        -1.0,
                        1.0,
                        1.0,
                        120.0);
    
    // Position scene with Earth near center of viewing volume
    self.mBaseEffect.transform.modelviewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -5.0);
    self.mPostionBuffer = [[AGLKVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(GLfloat) *3 numberOfVertices:sizeof(sphereVerts)/(sizeof(GLfloat) *3) bytes:sphereVerts usage:GL_STATIC_DRAW];
    self.mNomalBuffer = [[AGLKVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(GLfloat) *3 numberOfVertices:sizeof(sphereNormals)/(sizeof(GLfloat) *3) bytes:sphereNormals usage:GL_STATIC_DRAW];
    self.mTextureBuffer = [[AGLKVertexAttribArrayBuffer alloc] initWithAttribStride:sizeof(GLfloat) *2 numberOfVertices:sizeof(sphereTexCoords)/(sizeof(GLfloat) *2) bytes:sphereTexCoords usage:GL_STATIC_DRAW];
    
    CGImageRef earthRef = [[UIImage imageNamed:@"Earth.jpg"] CGImage];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
    self.earthInfo = [GLKTextureLoader textureWithCGImage:earthRef options:options error:nil];
    CGImageRef moonRef = [[UIImage imageNamed:@"Moon.png"] CGImage];
    self.moonInfo = [GLKTextureLoader textureWithCGImage:moonRef options:options error:nil];
    GLKMatrixStackLoadMatrix4(self.matrixRef,self.mBaseEffect.transform.modelviewMatrix);
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    self.earthAngle += 360.0f / 60.0f;
    self.moonAngle += (360.0f / 60.0f) / SceneDaysPerMoonOrbit;
    [((AGLKContext *) view.context) clear:GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT];
    [self.mPostionBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
    [self.mNomalBuffer prepareToDrawWithAttrib:GLKVertexAttribNormal numberOfCoordinates:3 attribOffset:0 shouldEnable:YES];
    [self.mTextureBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0 numberOfCoordinates:2 attribOffset:0 shouldEnable:YES];
    
    [self drawEarth];
    [self drawMoon];
    [(AGLKContext *)view.context enable:GL_DEPTH_TEST];
}
-(void)drawEarth{
    self.mBaseEffect.texture2d0.target = self.earthInfo.target;
    self.mBaseEffect.texture2d0.name = self.earthInfo.name;
    //设置地球纹理形变
    GLKMatrixStackPush(self.matrixRef);
    //地球倾斜角
    GLKMatrixStackRotate(self.matrixRef, GLKMathDegreesToRadians(SceneEarthAxialTiltDeg), 1.0, 0.0, 0.0);
    //地球自转
    GLKMatrixStackRotate(self.matrixRef, GLKMathDegreesToRadians(self.earthAngle), 0.0, 1.0, 0.0);
    self.mBaseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.matrixRef);
    self.mBaseEffect.transform.modelviewMatrix = GLKMatrix4Scale(self.mBaseEffect.transform.modelviewMatrix, 1.0, 1.0, 1.0  );
    [self.mBaseEffect prepareToDraw];
    [AGLKVertexAttribArrayBuffer drawPreparedArraysWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sphereNumVerts];
    
    GLKMatrixStackPop(self.matrixRef);
    self.mBaseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.matrixRef);

}
-(void)drawMoon{
    self.mBaseEffect.texture2d0.target = self.moonInfo.target;
    self.mBaseEffect.texture2d0.name = self.moonInfo.name;
    
    GLKMatrixStackPush(self.matrixRef);
    //公转
    GLKMatrixStackRotate(self.matrixRef, GLKMathDegreesToRadians(self.moonAngle), 0.0, 1.0, 0.0);
    //拉开月球与地球距离
    GLKMatrixStackTranslate(self.matrixRef, 0.0, 0.0, SceneMoonDistanceFromEarth);
    //缩小月球为地球的 SceneMoonRadiusFractionOfEarth
    GLKMatrixStackScale(self.matrixRef, SceneMoonRadiusFractionOfEarth, SceneMoonRadiusFractionOfEarth, SceneMoonRadiusFractionOfEarth);
    
    GLKMatrixStackRotate(self.matrixRef, GLKMathDegreesToRadians(self.moonAngle), 0.0, 1.0, 0.0);

    
    self.mBaseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.matrixRef);
    [self.mBaseEffect prepareToDraw];
    [AGLKVertexAttribArrayBuffer drawPreparedArraysWithMode:GL_TRIANGLES startVertexIndex:0 numberOfVertices:sphereNumVerts];
    GLKMatrixStackPop(self.matrixRef);
    self.mBaseEffect.transform.modelviewMatrix = GLKMatrixStackGetMatrix4(self.matrixRef);
    
}
-(void)setupLight{
    //灯光设置
    self.mBaseEffect.light0.enabled = GL_TRUE;
    //    漫反射颜色
    self.mBaseEffect.light0.diffuseColor = GLKVector4Make(0.7f, 0.7f, 0.7f, 1.0f);
    //环境颜色 RGBA
    self.mBaseEffect.light0.ambientColor = GLKVector4Make(0.2f, 0.2f, 0.2f, 1.0f);
    //光源位置
    self.mBaseEffect.light0.position = GLKVector4Make(1.0f, 0.7f, 0.3f, 0.0f);
}
- (IBAction)changeLineOfSight:(UISwitch *)sender {
    
}
- (IBAction)changeLineOfSightAction:(UISegmentedControl *)sender {
    GLfloat   aspectRatio =
    (float)((GLKView *)self.view).drawableWidth /
    (float)((GLKView *)self.view).drawableHeight;
    
    if([sender selectedSegmentIndex] == 1)
    {
        //透视投影变换
        self.mBaseEffect.transform.projectionMatrix = GLKMatrix4MakeFrustum(-1.0 * aspectRatio,1.0 * aspectRatio,-1.0,1.0,1.0,120.0);
    }
    else
    {
        //正视投影变换
        self.mBaseEffect.transform.projectionMatrix = GLKMatrix4MakeOrtho(-1.0 * aspectRatio, 1.0 * aspectRatio, -1.0, 1.0,1.0,120.0);
    }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown &&
            interfaceOrientation !=
            UIInterfaceOrientationPortrait);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
