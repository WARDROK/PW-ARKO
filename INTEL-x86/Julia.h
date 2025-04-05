#ifndef GENERATE_JULIA
#define GENERATE_JULIA
#include <stdint.h>
#include <stdbool.h>


void generateJulia(uint8_t* pixels, int width, int height, double thresholdRadius,
                    double cReal, double cImage, double centerReal, double centerImage,
                    double zoom, int* colors, bool isColored);

#endif