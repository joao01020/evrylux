#include "display.h"

#include <TFT_eSPI.h>

#include "../ghost/phantom.h"

TFT_eSPI tft;

void displayInit()
{
    tft.init();

    tft.setRotation(0);

    tft.fillScreen(TFT_BLACK);

    resetPhantomAnimation();
}

void displayUpdate()
{


    updatePhantom(tft);
}