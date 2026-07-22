#ifndef BREATHING_H
#define BREATHING_H

class Breathing
{

public:

    enum class State
    {
        INHALE,
        HOLD,
        EXHALE,
        REST
    };


    void reset();

    void update();


    int getOffset();



private:

    State state;


    int offset;


    int direction;


    unsigned long timer;


    unsigned long stateTimer;

};


#endif