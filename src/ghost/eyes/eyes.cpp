#include "eyes.h"


void Eyes::draw(
    TFT_eSPI& tft,
    int x,
    int y,
    int height
)
{

    // limpa região dos olhos

    tft.fillRect(
        x - 15,
        y - 10,
        30,
        20,
        TFT_GREEN
    );



    // olho esquerdo

    tft.fillRect(
        x - 10,
        y - 5,
        5,
        height,
        TFT_BLACK
    );



    // olho direito

    tft.fillRect(
        x + 5,
        y - 5,
        5,
        height,
        TFT_BLACK
    );

}