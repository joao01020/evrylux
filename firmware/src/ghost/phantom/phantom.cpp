#include "phantom.h"

#include "ghost/blink/blink.h"
#include "ghost/breathing/breathing.h"
#include "ghost/eyes/eyes.h"

// =====================================
// COMPONENTES DO FANTASMA
// =====================================

static Blink blink;

static Breathing breathing;

static Eyes eyes;

// =====================================
// POSIÇÃO DO FANTASMA
// =====================================

static int lastX = 120;

static int lastY = 160;

// =====================================
// DESENHA BASE DO FANTASMA
// =====================================

static void drawPhantomBase(
    TFT_eSPI &tft,
    int x,
    int y)
{

    tft.fillRoundRect(
        x - 20,
        y - 20,
        40,
        45,
        8,
        TFT_GREEN);

    // pés

    tft.fillCircle(
        x - 12,
        y + 22,
        4,
        TFT_GREEN);

    tft.fillCircle(
        x,
        y + 25,
        4,
        TFT_GREEN);

    tft.fillCircle(
        x + 12,
        y + 22,
        4,
        TFT_GREEN);
}

// =====================================
// DESENHA FANTASMA COMPLETO
// =====================================

void drawPhantom(
    TFT_eSPI &tft,
    int x,
    int y)
{

    lastX = x;

    lastY = y;

    int yPos =
        y + breathing.getOffset();

    // corpo

    drawPhantomBase(
        tft,
        x,
        yPos);

    // olhos

    eyes.draw(
        tft,
        x,
        yPos,
        blink.getEyeHeight());
}

// =====================================
// RESET
// =====================================

void resetPhantomAnimation()
{

    blink.reset();

    breathing.reset();
}

// =====================================
// UPDATE
// =====================================

void updatePhantom(
    TFT_eSPI &tft)
{

    // =============================
    // ATUALIZA COMPONENTES
    // =============================

    blink.update();

    breathing.update();

    // =============================
    // RESPIRAÇÃO
    // =============================

    static int lastBreath = 999;

    if (
        breathing.getOffset() != lastBreath)
    {

        drawPhantom(
            tft,
            lastX,
            lastY);

        lastBreath =
            breathing.getOffset();
    }

    // =============================
    // PISCAR
    // =============================

    if (blink.hasChanged())
    {

        eyes.draw(
            tft,
            lastX,
            lastY + breathing.getOffset(),
            blink.getEyeHeight());
    }
}