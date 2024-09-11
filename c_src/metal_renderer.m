#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Cocoa/Cocoa.h>
#include <erl_nif.h>

typedef struct {
    id<MTLDevice> device;
    id<MTLCommandQueue> commandQueue;
    id<MTLRenderPipelineState> pipelineState;
    id<MTLBuffer> vertexBuffer;
    CAMetalLayer *metalLayer;
    NSView *view;
} MetalRenderer;

static ErlNifResourceType *METAL_RENDERER_RESOURCE;

static bool createPipelineState(MetalRenderer* renderer, char *priv_dir);
static bool createVertexBuffer(MetalRenderer* renderer);

static ERL_NIF_TERM create_metal_renderer(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    if (argc != 2) {
        return enif_make_badarg(env);
    }

    unsigned long handle;
    if (!enif_get_uint64(env, argv[0], &handle)) {
        return enif_make_badarg(env);
    }

    unsigned length;
    if (enif_get_string_length(env, argv[1], &length, ERL_NIF_UTF8) <= 0) {
        return enif_make_badarg(env);
    }

    char *priv_dir = enif_alloc(length + 1);
    if (enif_get_string(env, argv[1], priv_dir, length + 1, ERL_NIF_UTF8) <= 0) {
        enif_free(priv_dir);
        return enif_make_badarg(env);
    }

    MetalRenderer* renderer = enif_alloc_resource(METAL_RENDERER_RESOURCE, sizeof(MetalRenderer));

    renderer->device = MTLCreateSystemDefaultDevice();
    if (!renderer->device) {
      return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_atom(env, "failed_to_create_device"));
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        renderer->view = (NSView*)handle;

        renderer->metalLayer = [CAMetalLayer layer];
        [renderer->view setWantsLayer:YES];
        [renderer->view setLayer:renderer->metalLayer];

        renderer->metalLayer.device = renderer->device;
        renderer->metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    });

    NSLog(@"metalLayer: %p", renderer->metalLayer);
    NSLog(@"view: %p", renderer->view);
    NSLog(@"view layer: %@", renderer->view.layer);
    NSLog(@"renderer device: %@", renderer->device);

    renderer->commandQueue = [renderer->device newCommandQueue];
    if (!renderer->commandQueue) {
      return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_atom(env, "failed_to_create_command_queue"));
    }

    NSLog(@"renderer command queue: %@", renderer->commandQueue);

    if (!createPipelineState(renderer, priv_dir) || !createVertexBuffer(renderer)) {
        enif_release_resource(renderer);
        return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_atom(env, "initialization_failed"));
    }

    NSLog(@"pipeline state: %@", renderer->pipelineState);
    NSLog(@"vertex buffer: %@", renderer->vertexBuffer);

    ERL_NIF_TERM result = enif_make_resource(env, renderer);
    enif_release_resource(renderer);
    return enif_make_tuple2(env, enif_make_atom(env, "ok"), result);
}

static bool createPipelineState(MetalRenderer* renderer, char *priv_dir) {
    NSError* error = nil;

    NSString* metalLibPath = [NSString stringWithFormat:@"%s/default.metallib", priv_dir];
    NSURL* metalLibURL = [NSURL fileURLWithPath:metalLibPath];

    id<MTLLibrary> library = [renderer->device newLibraryWithURL:metalLibURL error:&error];
    if (!library) {
        NSLog(@"Failed to load Metal library: %@", error);
        return false;
    }

    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragmentShader"];

    if (!vertexFunction || !fragmentFunction) {
        NSLog(@"Failed to load shader functions");
        return false;
    }

    MTLRenderPipelineDescriptor* pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = renderer->metalLayer.pixelFormat;

    renderer->pipelineState = [renderer->device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!renderer->pipelineState) {
        NSLog(@"Failed to create pipeline state: %@", error);
        return false;
    }

    return true;
}

static bool createVertexBuffer(MetalRenderer* renderer) {
    static const float triangleVertices[] = {
        0.0f,  0.5f, 0.0f,
       -0.5f, -0.5f, 0.0f,
        0.5f, -0.5f, 0.0f
    };

    renderer->vertexBuffer = [renderer->device newBufferWithBytes:triangleVertices
                                                           length:sizeof(triangleVertices)
                                                          options:MTLResourceStorageModeShared];
    if (!renderer->vertexBuffer) {
        NSLog(@"Failed to create vertex buffer");
        return false;
    }

    return true;
}

static ERL_NIF_TERM render_frame(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  NSLog(@"render_frame");
  MetalRenderer* renderer;
  if (argc != 1 ||
      !enif_get_resource(env, argv[0], METAL_RENDERER_RESOURCE, (void**)&renderer)) {
      return enif_make_badarg(env);
  }

// typedef struct {
//     id<MTLDevice> device;
//     id<MTLCommandQueue> commandQueue;
//     id<MTLRenderPipelineState> pipelineState;
//     id<MTLBuffer> vertexBuffer;
//     CAMetalLayer *metalLayer;
// } MetalRenderer;

  NSLog(@"device: %@\ncommandQueue: %@\npipelineState: %@\nvertexBuffer: %@\nmetalLayer: %p\nsuperlayer: %p\nview: %p\nview layer: %p\n",
    renderer->device,
    renderer->commandQueue,
    renderer->pipelineState,
    renderer->vertexBuffer,
    renderer->metalLayer,
    renderer->metalLayer.superlayer,
    renderer->view,
    renderer->view.layer
  );

  id<CAMetalDrawable> drawable = [renderer->metalLayer nextDrawable];
  if (!drawable) {
    return enif_make_tuple2(env, enif_make_atom(env, "error"), enif_make_atom(env, "no_drawable"));
  }

  id<MTLCommandBuffer> commandBuffer = [renderer->commandQueue commandBuffer];
  MTLRenderPassDescriptor* renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
  renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
  renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
  renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.7, 1.0);

  id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
  [renderEncoder setRenderPipelineState:renderer->pipelineState];
  [renderEncoder setVertexBuffer:renderer->vertexBuffer offset:0 atIndex:0];
  [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
  [renderEncoder endEncoding];

  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];

  // ERL_NIF_TERM result = enif_make_resource(env, renderer);
  // enif_release_resource(renderer);
  // return enif_make_tuple2(env, enif_make_atom(env, "ok"), result);
  return enif_make_atom(env, "ok");
}

static ERL_NIF_TERM resize_metal_renderer(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
    MetalRenderer* renderer;
    unsigned int width, height;

    if (argc != 3 ||
        !enif_get_resource(env, argv[0], METAL_RENDERER_RESOURCE, (void**)&renderer) ||
        !enif_get_uint(env, argv[1], &width) ||
        !enif_get_uint(env, argv[2], &height)) {
        return enif_make_badarg(env);
    }

    renderer->metalLayer.drawableSize = CGSizeMake(width, height);

    return enif_make_atom(env, "ok");
}

static ErlNifFunc nif_funcs[] = {
    {"create_metal_renderer", 2, create_metal_renderer, ERL_NIF_DIRTY_JOB_IO_BOUND},
    {"resize_metal_renderer", 3, resize_metal_renderer, ERL_NIF_DIRTY_JOB_IO_BOUND},
    {"render_frame", 1, render_frame, ERL_NIF_DIRTY_JOB_IO_BOUND}
};

static int load(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
    METAL_RENDERER_RESOURCE = enif_open_resource_type(env, NULL, "MetalRenderer", NULL, ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER, NULL);
    return 0;
}

ERL_NIF_INIT(Elixir.ElixirMetal.MetalRenderer, nif_funcs, load, NULL, NULL, NULL)