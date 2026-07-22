#ifndef PHANTOM_H
#define PHANTOM_H

#include <TFT_eSPI.h>

void drawPhantom(TFT_eSPI& tft, int x, int y);

void updatePhantom(TFT_eSPI& tft);

void resetPhantomAnimation();

#endif