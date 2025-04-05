#include <stdio.h>
#include <stdlib.h>
#include <SDL.h>
#include "Julia.h"

int main(int argc, char* argv[])
{
    int colors[32] = {
        0x000000FF, // black
        0xFF00FF00, // Green
        0xFF0000FF, // Blue
        0xFFFFFF00, // Yellow

        0xFFFF00FF, // Magenta
        0xFF00FFFF, // Cyan
        0xFFFFA500, // Orange
        0xFF800080, // Purple

        0xFF808080, // Gray
        0xFFA52A2A, // Brown
        0xFFA52A2A, // Brown
        0xFF006400, // Dark Green

        0xFF00008B, // Dark Blue
        0xFF2E8B57, // Sea Green
        0xFF4682B4, // Steel Blue
        0xFFD2691E, // Chocolate

        0xFFFFD700, // Gold
        0xFF7FFF00, // Chartreuse
        0xFFADFF2F, // Green Yellow
        0xFF32CD32, // Lime Green

        0xFF87CEEB, // Sky Blue
        0xFF00FA9A, // Medium Spring Green
        0xFF8FBC8F, // Dark Sea Green
        0xFF6495ED, // Cornflower Blue

        0xFF00BFFF, // Deep Sky Blue
        0xFF1E90FF, // Dodger Blue
        0xFF20B2AA, // Light Sea Green
        0xFF7FFFD4, // Aquamarine

        0xFF40E0D0, // Turquoise
        0xFF00CED1, // Dark Turquoise
        0xFF00FFFF, // Aqua
        0xFFADD8E6 // Light Blue
    };

    // Initialization
    int width = 800;
    int height = 800;

    double tresholdRadius = 4;
    double cReal = 0;
    double cImage = 0;
    double centerX = width/2;
    double centerY = height/2;
    double zoom = 1.0;
    bool isColored = false;

    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        printf("Could not initialize SDL: %s\n", SDL_GetError());
        return 1;
    }

    // Create a window
    SDL_Window* window = SDL_CreateWindow("Fractal Julia", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, SDL_WINDOW_SHOWN);
    if (window == NULL) 
    {
        // Window creation failed
        printf("Could not create window: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    // Create renderer
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (renderer == NULL)
    {
        // Renderer creation failed
        printf("Could not create renderer: %s\n", SDL_GetError());
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Create a texture
    SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, width, height);
    if (texture == NULL) 
    {
        // Texture creation failed
        printf("Could not create texture: %s\n", SDL_GetError());
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 1;
    }

    // Lock the texture to access its pixel data
    void* pixels;
    int pitch;
    SDL_LockTexture(texture, NULL, (void**)&pixels, &pitch);

    // Generate initial Fractal Julia
    generateJulia((uint8_t*)pixels, width, height, tresholdRadius, cReal, cImage, width/2.0, height/2.0, 1.0, colors, isColored);

    // Unlock the texture
    SDL_UnlockTexture(texture);

    // Main loop flag
    bool quit = false;

    // Event handler
    SDL_Event event;

    // Flag to check if new fractal should be generated
    bool generateWhileDragging = true;
    bool generate = false;

    // Variables for dragging
    bool isDragging = false;
    int dragStartX = 0;
    int dragStartY = 0;
    double dragStartCenterReal = 0;
    double dragStartCenterImage = 0;

    // Main loop
    while (!quit)
    {
        // Events
        while (SDL_PollEvent(&event) != 0)
        {
            // Quit request
            if (event.type == SDL_QUIT)
            {
                quit = true;
            }

            // Zoom event
            else if (event.type == SDL_MOUSEWHEEL)
            {
                double fractalCenterX = width / 2.0;
                double fractalCenterY = height / 2.0;

                // Zoom in
                if (event.wheel.y > 0)
                {
                    double zoomFactor = 1.25;
                    zoom *= zoomFactor;
                    centerX = (centerX - fractalCenterX) * zoomFactor + fractalCenterX;
                    centerY = (centerY - fractalCenterY) * zoomFactor + fractalCenterY;
                    generate = true;
                }

                // Zoom out
                else if (event.wheel.y < 0)
                {
                    double zoomFactor = 0.8;
                    zoom *= zoomFactor;
                    centerX = (centerX - fractalCenterX) * zoomFactor + fractalCenterX;
                    centerY = (centerY - fractalCenterY) * zoomFactor + fractalCenterY;
                    generate = true;
                }
            }

            // Change parametr "c" event
            else if (event.type == SDL_KEYDOWN)
            {
                switch (event.key.keysym.sym)
                {
                    case SDLK_UP:
                        cImage += 0.01;
                        generate = true;
                        break;
                    case SDLK_DOWN:
                        cImage -= 0.01;
                        generate = true;
                        break;
                    case SDLK_RIGHT:
                        cReal += 0.01;
                        generate = true;
                        break;
                    case SDLK_LEFT:
                        cReal -= 0.01;
                        generate = true;
                        break;

                    // Change isColored
                    case SDLK_c:
                        isColored = !isColored;
                        generate = true;
                        break;

                    // Simple parametrs
                    case SDLK_0:
                        cReal = 0;
                        cImage = 0;
                        centerX = width / 2;
                        centerY = height / 2;
                        zoom = 1;
                        generate = true;
                        break;
                    case SDLK_1:
                        cReal = -0.75;
                        cImage = 0.15;
                        centerX = width / 2;
                        centerY = height / 2;
                        zoom = 1;
                        generate = true;
                        break;
                    case SDLK_2:
                        cReal = -0.4;
                        cImage = 0.6;
                        centerX = width / 2;
                        centerY = height / 2;
                        zoom = 1;
                        generate = true;
                        break;
                    case SDLK_3:
                        cReal = 0.28;
                        cImage = 0;
                        centerX = width / 2;
                        centerY = height / 2;
                        zoom = 1;
                        generate = true;
                        break;
                    case SDLK_4:
                        cReal = 0.3;
                        cImage = 0.02;
                        centerX = width / 2;
                        centerY = height / 2;
                        zoom = 1;
                        generate = true;
                        break;
                    case SDLK_5:
                        cReal = -0.7;
                        cImage = -0.35;
                        centerX = width / 2;
                        centerY = height / 2;
                        zoom = 1;
                        generate = true;
                        break;
                    case SDLK_6:
                        cReal = -0.8;
                        cImage = 0.16;
                        centerX = width / 2;
                        centerY = height / 2;
                        zoom = 1;
                        generate = true;
                        break;
                    case SDLK_7:
                        cReal = -1.4;
                        cImage = 0;
                        centerX = width / 2;
                        centerY = height / 2;
                        zoom = 1;
                        generate = true;
                        break;
                    case SDLK_8:
                        cReal = -0.85;
                        cImage = 0;
                        centerX = width / 2;
                        centerY = height / 2;
                        zoom = 1;
                        generate = true;
                        break;
                    case SDLK_9:
                        cReal = -0.6;
                        cImage = 0;
                        centerX = width / 2;
                        centerY = height / 2;
                        zoom = 1;
                        generate = true;
                        break;
                    case SDLK_ESCAPE:
                        quit = true;
                        return 0;
                    default:
                        break;
                }
            }

            // Dragging event
            else if (event.type == SDL_MOUSEBUTTONDOWN && event.button.button == SDL_BUTTON_LEFT)
            {
                isDragging = true;
                SDL_GetMouseState(&dragStartX, &dragStartY);
                dragStartCenterReal = centerX;
                dragStartCenterImage = centerY;
            }
            else if (event.type == SDL_MOUSEMOTION && isDragging)
            {
                // Mouse coordinates relative to fractal
                double mouseX = (event.motion.x - width / 2) + centerX;
                double mouseY = (event.motion.y - height / 2) + centerY;

                // Compute shifts delta
                double deltaX = mouseX - (dragStartX - width / 2) - dragStartCenterReal;
                double deltaY = mouseY - (dragStartY - height / 2) - dragStartCenterImage;

                // Update center postion
                centerX -= deltaX;
                centerY -= deltaY;
                if (generateWhileDragging)
                {
                    generate = true;
                }
            }
            else if (event.type == SDL_MOUSEBUTTONUP && event.button.button == SDL_BUTTON_LEFT)
            {
                    isDragging = false;
                    generate = true;
            }
        }

        // Generate fractal if modified
        if (generate)
        {
            SDL_LockTexture(texture, NULL, (void**)&pixels, &pitch);
            generateJulia((uint8_t*)pixels, width, height, tresholdRadius, cReal, cImage, centerX, centerY, zoom, colors, isColored);
            SDL_UnlockTexture(texture);
            generate = false;
        }

        // Clear screen
        SDL_RenderClear(renderer);

        // Copy the texture to renderer
        SDL_RenderCopy(renderer, texture, NULL, NULL);

        // Update screen
        SDL_RenderPresent(renderer);
    }

    // Destroy window, renderer, texture
    SDL_DestroyTexture(texture);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);

    // Quit SDL
    SDL_Quit();

    return 0;
}
