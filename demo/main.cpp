#include <verilated.h>
#include "Vproject.h"
#include <SDL3/SDL.h>

const uint32_t H_DISPLAY = 800;
const uint32_t V_DISPLAY = 600;
const uint32_t H_TOTAL = 1056;
const uint32_t V_TOTAL = 628;

void reset(Vproject &top) {
	top.rst_n = 1;
	top.clk = 0; top.eval(); top.clk = 1; top.eval();
	top.rst_n = 0;
	top.clk = 0; top.eval(); top.clk = 1; top.eval();
	top.rst_n = 1;
}

int main(const int argc, char **argv) {
	const auto ctx = std::make_unique<VerilatedContext>();
	ctx->commandArgs(argc, argv);
	const auto top = std::make_unique<Vproject>(ctx.get());

	top->ena = 1;
	top->ui_in = 1;

	reset(*top);

	if (!SDL_Init(SDL_INIT_VIDEO)) {
		SDL_Log("Failed to initialize SDL: %s", SDL_GetError());
		return 1;
	}

	SDL_Window *sdl_window = SDL_CreateWindow("VGA Demo", H_DISPLAY, V_DISPLAY, SDL_WINDOW_OPENGL);

	if (sdl_window == nullptr) {
		SDL_Log("Failed to create window: %s", SDL_GetError());
		SDL_Quit();
		return 1;
	}

	SDL_Renderer* renderer = SDL_CreateRenderer(sdl_window, nullptr);

	if (renderer == nullptr) {
		SDL_Log("Failed to create renderer: %s", SDL_GetError());
		SDL_DestroyWindow(sdl_window);
		SDL_Quit();
		return 1;
	}

	SDL_Texture* texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, H_DISPLAY, V_DISPLAY);

	if (texture == nullptr) {
		SDL_Log("Failed to create texture: %s", SDL_GetError());
		SDL_DestroyRenderer(renderer);
		SDL_DestroyWindow(sdl_window);
		SDL_Quit();
		return 1;
	}

	bool quit = false;

	while (!quit) {
		SDL_Event event;

		while (SDL_PollEvent(&event)) {
			if (event.type == SDL_EVENT_QUIT) {
				quit = true;
			} else if (event.type == SDL_EVENT_KEY_DOWN && event.key.scancode == SDL_SCANCODE_SPACE) {
				top->ui_in = 0;
			}
		}

		uint32_t* pixels;
		int pitch;

		if (!SDL_LockTexture(texture, nullptr, reinterpret_cast<void **>(&pixels), &pitch)) {
			SDL_Log("Failed to lock texture: %s", SDL_GetError());
			break;
		}

		int cursor = 0;

		for(int y = 0; y < V_TOTAL; y++) {
			for(int x = 0; x < H_TOTAL; x++) {
				top->clk = 0; top->eval(); top->clk = 1; top->eval();

				if (y < V_DISPLAY && x < H_DISPLAY) {
					const uint8_t o = top->uo_out;
					const uint32_t r = ((o & 1) << 17 | (o & 16) << 12) * 0x55;
					const uint32_t g = ((o & 2) << 8 | (o & 32) << 3) * 0x55;
					const uint32_t b = ((o & 4) >> 1 | (o & 64) >> 6) * 0x55;

					pixels[cursor] = 0xFF000000 | r | g | b;

					cursor += 1;
				}
			}
		}

		top->ui_in = 1;

		SDL_UnlockTexture(texture);
		SDL_RenderTexture(renderer, texture, nullptr, nullptr);
		SDL_RenderPresent(renderer);
	}

	SDL_DestroyRenderer(renderer);
	SDL_DestroyWindow(sdl_window);
	SDL_Quit();

	top->final();

	return 0;
}
