#ifndef BLINK_H
#define BLINK_H

#include <Arduino.h>


class Blink
{

public:


    enum class State
    {
        OPEN,
        CLOSING,
        CLOSED,
        OPENING
    };


    enum class Type
    {
        NORMAL,
        SLOW,
        DOUBLE
    };



    void reset();

    void update();



    int getEyeHeight();


    bool hasChanged();



private:


    State state;

    Type type;



    int eyeHeight;


    int previousEyeHeight;



    unsigned long lastFrame;

    unsigned long nextBlink;



    bool doubleBlink;



    void chooseBlink();

};


#endif