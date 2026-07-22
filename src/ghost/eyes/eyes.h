#ifndef EYES_H
#define EYES_H

#include <TFT_eSPI.h>


class Eyes
{

public:

    void draw(
        TFT_eSPI& tft,
        int x,
        int y,
        int height
    );

};


#endif