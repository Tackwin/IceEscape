
extern void* jai_malloc(size_t size);
extern void jai_free(void* ptr);
extern void* jai_realloc(void* ptr, size_t old_sze, size_t new_size);

#define STBI_MALLOC(x) jai_malloc(x)
#define STBI_FREE(x) jai_free(x)
#define STBI_REALLOC_SIZED(p, oldsz, newsz) jai_realloc(p, oldsz, newsz)

#ifdef WIN32
#define __EXPORT __declspec(dllexport)
#else
#define __EXPORT
#endif

#define STBIDEF extern __EXPORT

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"
